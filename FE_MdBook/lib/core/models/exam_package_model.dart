class ExamPackageModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? status;
  final int? estimatedTotalMinutes;
  final String? specialtyId;

  ExamPackageModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.status,
    this.estimatedTotalMinutes,
    this.specialtyId,
  });

  factory ExamPackageModel.fromJson(Map<String, dynamic> json) {
    return ExamPackageModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'],
      estimatedTotalMinutes: (json['estimatedTotalMinutes'] as num?)?.toInt(),
      specialtyId: json['specialtyId'],
    );
  }
}
