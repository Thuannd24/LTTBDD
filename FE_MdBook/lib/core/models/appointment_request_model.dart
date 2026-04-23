class AppointmentRequestModel {
  final String id;
  final String patientUserId;
  final String doctorId;
  final int doctorScheduleId;
  final String packageId;
  final String? facilityId;
  final int? roomSlotId;
  final int? equipmentSlotId;
  final String status;
  final String? note;
  final String? appointmentId;
  final String? processedBy;
  final DateTime? processedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppointmentRequestModel({
    required this.id,
    required this.patientUserId,
    required this.doctorId,
    required this.doctorScheduleId,
    required this.packageId,
    this.facilityId,
    this.roomSlotId,
    this.equipmentSlotId,
    required this.status,
    this.note,
    this.appointmentId,
    this.processedBy,
    this.processedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory AppointmentRequestModel.fromJson(Map<String, dynamic> json) {
    return AppointmentRequestModel(
      id: json['id'] ?? '',
      patientUserId: json['patientUserId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorScheduleId: (json['doctorScheduleId'] as num?)?.toInt() ?? 0,
      packageId: json['packageId'] ?? '',
      facilityId: json['facilityId'],
      roomSlotId: (json['roomSlotId'] as num?)?.toInt(),
      equipmentSlotId: (json['equipmentSlotId'] as num?)?.toInt(),
      status: json['status'] ?? '',
      note: json['note'],
      appointmentId: json['appointmentId'],
      processedBy: json['processedBy'],
      processedAt: json['processedAt'] != null ? DateTime.tryParse(json['processedAt']) : null,
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
