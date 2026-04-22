import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';

class DoctorScheduleService {
  final ApiClient _client = ApiClient();

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
