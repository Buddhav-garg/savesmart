class UserSession {
  const UserSession({required this.token, required this.user});

  final String token;
  final UserProfile user;

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    token: json['token']?.toString() ?? '',
    user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'User',
    phone: json['phone']?.toString() ?? '',
  );
}
