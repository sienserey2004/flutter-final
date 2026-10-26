import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiException extends AuthException {
  const ApiException(super.message, {this.status = 0, this.payload = const {}});
  final int status;
  final Map<String, dynamic> payload;
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _configuredBaseUrl();
  final String baseUrl;
  String? token;

  static String _configuredBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;

    // Android emulators reach the host machine through 10.0.2.2.
    // Desktop, web, iOS simulator, and DevicePreview use localhost instead.
    return kIsWeb || defaultTargetPlatform != TargetPlatform.android
        ? 'http://127.0.0.1:5000/api'
        : 'http://10.0.2.2:5000/api';
  }

  Future<Map<String, dynamic>> request(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    final headers = <String, String>{'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = method == 'POST'
        ? await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body ?? {}))
        : await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    Map<String, dynamic> payload;
    try { payload = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw const AuthException('The server returned an invalid response.'); }
    if (response.statusCode == 401) throw const AuthException('Your session has expired. Please log in again.');
    if (response.statusCode >= 400 || payload['success'] == false) {
      final errors = payload['errors'];
      final message = errors is List && errors.isNotEmpty ? errors.join(' ') : payload['error']?.toString();
      throw ApiException(message ?? 'Something went wrong.', status: response.statusCode, payload: payload);
    }
    return payload;
  }
}

class AuthController extends ChangeNotifier {
  AuthController({ApiClient? client}) : api = client ?? ApiClient();
  final ApiClient api;
  AuthStatus _status = AuthStatus.checking;
  User? _user;
  bool _isSubmitting = false;
  String? _errorMessage;
  SharedPreferences? _prefs;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    api.token = _prefs!.getString('auth_token');
    if (api.token == null) { _status = AuthStatus.unauthenticated; notifyListeners(); return; }
    try {
      final response = await api.request('/auth/profile');
      _user = User.fromJson(response['data'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } catch (_) { await _clearSession(); _status = AuthStatus.unauthenticated; }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _beginSubmit();
    try {
      final response = await api.request('/auth/login', method: 'POST', body: {'email': email.trim(), 'password': password});
      api.token = response['token']?.toString();
      if (api.token == null) throw const AuthException('Login did not return a session token.');
      await (_prefs ??= await SharedPreferences.getInstance()).setString('auth_token', api.token!);
      _user = User.fromJson(response['data'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) { _errorMessage = _message(e); return false; } finally { _endSubmit(); }
  }

  Future<bool> register({required String fullName, required String email, required String password, String phone = ''}) async {
    _beginSubmit();
    try {
      await api.request('/auth/register', method: 'POST', body: {'name': fullName.trim(), 'email': email.trim(), 'password': password, 'confirm': password, 'phone': phone.trim()});
      return true;
    } catch (e) { _errorMessage = _message(e); return false; } finally { _endSubmit(); }
  }

  Future<String?> requestPasswordReset(String email) async {
    _beginSubmit();
    try { await api.request('/auth/forgot-password', method: 'POST', body: {'email': email.trim()}); return null; }
    catch (e) { final message = _message(e); _errorMessage = message; return message; }
    finally { _endSubmit(); }
  }

  Future<bool> updateProfile({required String fullName, String phone = '', String? newPassword}) async {
    _beginSubmit();
    try {
      final body = <String, dynamic>{'name': fullName.trim(), 'phone': phone.trim()};
      if (newPassword != null && newPassword.isNotEmpty) body['new_password'] = newPassword;
      final response = await api.request('/auth/profile', method: 'POST', body: body);
      _user = User.fromJson(response['data'] as Map<String, dynamic>);
      return true;
    } catch (e) { _errorMessage = _message(e); return false; } finally { _endSubmit(); }
  }

  /// Returns null on success, otherwise the error message.
  Future<String?> changePassword({required String currentPassword, required String newPassword}) async {
    _beginSubmit();
    try { await api.request('/auth/change-password', method: 'POST', body: {'current_password': currentPassword, 'new_password': newPassword}); return null; }
    catch (e) { final message = _message(e); _errorMessage = message; return message; }
    finally { _endSubmit(); }
  }

  /// Returns null on success (and signs out), otherwise the error message.
  Future<String?> deleteAccount({required String password}) async {
    _beginSubmit();
    try { await api.request('/auth/delete-account', method: 'POST', body: {'password': password}); }
    catch (e) { final message = _message(e); _errorMessage = message; _endSubmit(); return message; }
    _isSubmitting = false;
    await _clearSession(); _user = null; _status = AuthStatus.unauthenticated; notifyListeners();
    return null;
  }

  Future<List<Map<String, dynamic>>> notifications() async {
    final response = await api.request('/account/notifications');
    final data = response['data'] as Map<String, dynamic>;
    return ((data['notifications'] as List?) ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
  Future<List<Map<String, dynamic>>> orders() async {
    final response = await api.request('/orders/');
    return ((response['data'] as List?) ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
  Future<void> markNotificationRead(int id) async { await api.request('/account/notifications/$id/read', method: 'POST'); }
  Future<void> markAllNotificationsRead() async { await api.request('/account/notifications/read-all', method: 'POST'); }

  Future<void> logout() async {
    try { if (api.token != null) await api.request('/auth/logout'); } catch (_) {}
    await _clearSession(); _user = null; _errorMessage = null; _status = AuthStatus.unauthenticated; notifyListeners();
  }
  void expireSession() { _clearSession(); _user = null; _status = AuthStatus.unauthenticated; notifyListeners(); }
  void clearError() { if (_errorMessage != null) { _errorMessage = null; notifyListeners(); } }
  String _message(Object error) => error is AuthException ? error.message : 'Could not connect to the server. Please try again.';
  void _beginSubmit() { _errorMessage = null; _isSubmitting = true; notifyListeners(); }
  void _endSubmit() { _isSubmitting = false; notifyListeners(); }
  Future<void> _clearSession() async { api.token = null; await (_prefs ??= await SharedPreferences.getInstance()).remove('auth_token'); }
}
