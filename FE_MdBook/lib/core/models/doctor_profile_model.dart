class DoctorProfile {
  final String id;
  final String userId;
  List<String> specialtyIds;
  int experienceYears;
  double? hourlyRate;
  String? degree;
  String? position;
  String? workLocation;
  String? biography;
  String? services;
  String? qualification;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  DoctorProfile({
    required this.id,
    required this.userId,
    required this.specialtyIds,
    this.experienceYears = 0,
    this.hourlyRate,
    this.degree,
    this.position,
    this.workLocation,
    this.biography,
    this.services,
    this.qualification,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      specialtyIds: json['specialtyIds'] != null ? List<String>.from(json['specialtyIds']) : <String>[],
      experienceYears: json['experienceYears'] ?? 0,
      hourlyRate: json['hourlyRate'] != null ? (json['hourlyRate'] as num).toDouble() : null,
      degree: json['degree'],
      position: json['position'],
      workLocation: json['workLocation'],
      biography: json['biography'],
      services: json['services'],
      qualification: json['qualification'],
      status: json['status'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'specialtyIds': specialtyIds,
      'experienceYears': experienceYears,
      'hourlyRate': hourlyRate,
      'degree': degree,
      'position': position,
      'workLocation': workLocation,
      'biography': biography,
      'services': services,
      'qualification': qualification,
      'status': status,
    };
  }
}
