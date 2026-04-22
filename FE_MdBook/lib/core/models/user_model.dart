class UserProfile {
  final String id;
  final String userId;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final String? bloodType;
  final double? weight;
  final double? height;
  final String? medicalHistory;
  final String? allergies;
  final String? aiSummary;
  final String? avatar;
  final List<String> roles;

  UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.bloodType,
    this.weight,
    this.height,
    this.medicalHistory,
    this.allergies,
    this.aiSummary,
    this.avatar,
    required this.roles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      address: json['address'],
      bloodType: json['bloodType'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      medicalHistory: json['medicalHistory'],
      allergies: json['allergies'],
      aiSummary: json['aiSummary'],
      avatar: json['avatar'],
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  bool get isAdmin => roles.contains('ADMIN');
  bool get isDoctor => roles.contains('DOCTOR');
  bool get isUser => roles.contains('USER');

  String get fullName {
    final name = '${firstName ?? ""} ${lastName ?? ""}'.trim();
    return name.isEmpty ? username : name;
  }
}
