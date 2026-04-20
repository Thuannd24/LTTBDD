class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final List<String> roles;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    required this.roles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      address: json['address'],
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  bool get isAdmin => roles.contains('ADMIN');
  bool get isDoctor => roles.contains('DOCTOR');
  bool get isUser => roles.contains('USER');
}
