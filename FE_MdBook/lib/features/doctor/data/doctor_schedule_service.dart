import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';

class DoctorScheduleService {
  final ApiClient _client = ApiClient();
  final DateFormat _dateTimeFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  Future<List<DoctorScheduleModel>> getSchedulesByDoctor(String doctorId) async {
    final response = await _client.get('/doctor/doctors/$doctorId/schedules');

    if (response.statusCode != 200) {
      throw Exception('Failed to load doctor schedules: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (data['result'] ?? []) as List<dynamic>;
    return list
        .map((item) => DoctorScheduleModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorScheduleModel> createSchedule({
    required String doctorId,
    required DateTime startTime,
    required DateTime endTime,
    int facilityId = 1,
    String? notes,
    int? roomSlotId,
  }) async {
    final response = await _client.post('/doctor/doctors/$doctorId/schedules', {
      'facilityId': facilityId,
      'startTime': _dateTimeFormat.format(startTime),
      'endTime': _dateTimeFormat.format(endTime),
      'notes': notes,
      'roomSlotId': roomSlotId,
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create doctor schedule: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DoctorScheduleModel.fromJson(data['result'] as Map<String, dynamic>);
  }

  Future<List<DoctorScheduleModel>> getAvailableSchedules({
    required String doctorId,
    required DateTime date,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await _client.get(
      '/doctor/doctors/$doctorId/schedules/available?date=$formattedDate',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load doctor schedules: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (data['result'] ?? []) as List<dynamic>;
    return list
        .map((item) => DoctorScheduleModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
