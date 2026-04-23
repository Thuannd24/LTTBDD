class DoctorScheduleModel {
  final int id;
  final String doctorId;
  final int? facilityId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? appointmentId;
  final String? notes;

  DoctorScheduleModel({
    required this.id,
    required this.doctorId,
    this.facilityId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.appointmentId,
    this.notes,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      doctorId: json['doctorId'] ?? '',
      facilityId: (json['facilityId'] as num?)?.toInt(),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? '',
      appointmentId: json['appointmentId'],
      notes: json['notes'],
    );
  }
}
