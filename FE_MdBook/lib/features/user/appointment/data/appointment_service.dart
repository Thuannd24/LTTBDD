import 'dart:convert';

import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/appointment_request_model.dart';

class AppointmentService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> createAppointmentRequest({
    required String doctorId,
    required String packageId,
    required int doctorScheduleId,
    String? note,
  }) async {
    final payload = {
      'packageId': packageId,
      'doctorId': doctorId,
      'doctorScheduleId': doctorScheduleId,
      'note': note ?? 'Khám tổng quát',
    };

    final response = await _client.post('/appointment/appointment-requests', payload);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to create appointment request: ${response.statusCode} - ${response.body}',
    );
  }

  Future<List<AppointmentRequestModel>> getMyAppointmentRequests() async {
    final response = await _client.get('/appointment/appointment-requests/my?page=0&size=50');

    if (response.statusCode != 200) {
      throw Exception('Failed to load appointment requests: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['result']?['content'] ?? []) as List<dynamic>;

    return content
        .map((item) => AppointmentRequestModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    final response = await _client.post('/appointment/appointments/$appointmentId/cancel', {
      'reason': reason,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment: ${response.body}');
    }
  }
}
