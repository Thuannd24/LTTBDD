class UserProfile {
  final String id;
  final String username;
  final String email;
  final List<String> roles;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  bool get isAdmin => roles.contains('ADMIN');
  bool get isDoctor => roles.contains('DOCTOR');
  bool get isUser => roles.contains('USER');
}
