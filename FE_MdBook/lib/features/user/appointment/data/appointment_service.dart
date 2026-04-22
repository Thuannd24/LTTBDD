import 'dart:convert';
import 'package:tbdd/core/api/api_client.dart';

class AppointmentService {
  final ApiClient _client = ApiClient();

  Future<dynamic> createAppointment({
    required String doctorId,
    required String packageId,
    int doctorScheduleId = 1,
    int roomSlotId = 1,
    String? note,
  }) async {
    final payload = {
      "packageId": packageId,
      "doctorId": doctorId,
      "doctorScheduleId": doctorScheduleId,
      "roomSlotId": roomSlotId,
      "note": note ?? "Khám tổng quát",
      "facilityId": "default",
    };

    final response = await _client.post('/appointment/appointments', payload); // Adjust endpoint according to your Gateway routes! Wait, typically gateway maps /appointment to Appointment Service.

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create appointment: ${response.statusCode} - ${response.body}');
    }
  }
}

