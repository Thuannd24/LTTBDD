import 'dart:convert';
import 'package:tbdd/core/api/api_client.dart';

class SlotService {
  final ApiClient _client = ApiClient();

  // Create recurring slots
  Future<Map<String, dynamic>> createRecurringSlot({
    required String targetId,
    required String dayOfWeek, // MONDAY, TUESDAY, etc
    required String startTime, // HH:mm
    required String endTime, // HH:mm
    int slotDurationMinutes = 30,
    String targetType = 'DOCTOR',
    int facilityId = 1,
  }) async {
    final payload = {
      'targetType': targetType,
      'targetId': targetId,
      'facilityId': facilityId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'slotDurationMinutes': slotDurationMinutes,
    };

    final resp = await _client.post('/slot/schedule-configs', payload);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to create slots: ${resp.body}');
  }

  // Get current configs
  Future<List<dynamic>> getScheduleConfigs({
    required String targetId,
    String targetType = 'DOCTOR',
    int facilityId = 1,
  }) async {
    final resp = await _client.get('/slot/schedule-configs?targetType=$targetType&targetId=$targetId&facilityId=$facilityId');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['result'] ?? [];
    }
    return [];
  }
}
