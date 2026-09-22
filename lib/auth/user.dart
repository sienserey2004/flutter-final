// lib/auth/user.dart
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['user_id'] ?? json['id']).toString(),
        fullName: (json['name'] ?? json['full_name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        avatarUrl: json['avatar_url']?.toString(),
      );

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _first(parts.first);
    return '${_first(parts.first)}${_first(parts.last)}';
  }

  String get firstName => fullName.trim().isEmpty
      ? 'there'
      : fullName.trim().split(RegExp(r'\s+')).first;

  String get name => fullName;

  static String _first(String value) =>
      value.isEmpty ? '' : value.substring(0, 1).toUpperCase();

  User copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
