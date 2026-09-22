import 'package:flutter/foundation.dart';

/// Same base URL the ApiClient uses (lib/auth/auth_controller.dart:19).
const String _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get kApiBaseUrl {
  if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
  return kIsWeb || defaultTargetPlatform != TargetPlatform.android
      ? 'http://127.0.0.1:5000/api'
      : 'http://10.0.2.2:5000/api';
}

const Set<String> _devHosts = {'127.0.0.1', 'localhost', '0.0.0.0'};

Uri? _baseUri() => Uri.tryParse(kApiBaseUrl);

bool _isDevHost(String host) {
  if (_devHosts.contains(host)) return true;
  if (host.startsWith('192.168.')) return true;
  if (host.startsWith('10.')) return true;
  return false;
}

/// Rewrites dev-server image URLs (127.0.0.1 / localhost / LAN IP) so the
/// Android emulator can reach them. URLs on any other host (a real CDN) are
/// returned untouched. Relative paths are returned as-is.
String? resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return trimmed;

  final base = _baseUri();
  if (base == null) return trimmed;

  if (!_isDevHost(uri.host)) return trimmed;

  return uri
      .replace(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
      )
      .toString();
}

@visibleForTesting
bool debugIsDevHost(String host) => _isDevHost(host);
