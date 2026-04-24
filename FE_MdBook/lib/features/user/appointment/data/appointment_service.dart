import 'dart:convert';
import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/appointment_request_model.dart';

class AppointmentService {
  final ApiClient _client = ApiClient();

  // ── Patient APIs ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createAppointmentRequest({
    required String doctorId,
    required String packageId,
    required int doctorScheduleId,
    int? roomSlotId,
    String? note,
  }) async {
    final payload = {
      'packageId': packageId,
      'doctorId': doctorId,
      'doctorScheduleId': doctorScheduleId,
      'roomSlotId': roomSlotId,
      'note': note ?? 'Khám tổng quát',
    };

    final response =
        await _client.post('/appointment/appointment-requests', payload);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to create appointment request: ${response.statusCode} - ${response.body}',
    );
  }

  Future<List<AppointmentRequestModel>> getMyAppointmentRequests() async {
    final response = await _client
        .get('/appointment/appointment-requests/my?page=0&size=50');

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load appointment requests: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (data['result']?['content'] ?? []) as List<dynamic>;

    return content
        .map((item) =>
            AppointmentRequestModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    final response = await _client
        .post('/appointment/appointments/$appointmentId/cancel', {
      'reason': reason,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment: ${response.body}');
    }
  }

  /// Bệnh nhân hủy yêu cầu đang chờ xác nhận
  Future<void> cancelAppointmentRequest(String requestId) async {
    final response = await _client.post(
        '/appointment/appointment-requests/$requestId/cancel', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel request: ${response.body}');
    }
  }

  /// Bệnh nhân xem danh sách hồ sơ bệnh án
  Future<List<Map<String, dynamic>>> getMyMedicalRecords() async {
    final response =
        await _client.get('/appointment/medical-records/my');
    if (response.statusCode != 200) {
      throw Exception('Failed to load medical records: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['result'] ?? []) as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Xem hồ sơ khám theo appointmentId
  Future<Map<String, dynamic>?> getMedicalRecordByAppointment(
      String appointmentId) async {
    final response = await _client
        .get('/appointment/medical-records/appointment/$appointmentId');
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['result'] as Map<String, dynamic>?;
  }

  // ── Doctor APIs ───────────────────────────────────────────────────────────

  /// Lấy danh sách yêu cầu chờ xác nhận (Doctor + Admin)
  Future<List<AppointmentRequestModel>> getPendingRequests() async {
    final response = await _client
        .get('/appointment/appointment-requests/pending?page=0&size=50');
    if (response.statusCode != 200) {
      throw Exception('Failed to load pending requests: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (data['result']?['content'] ?? []) as List<dynamic>;
    return content
        .map((item) =>
            AppointmentRequestModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Doctor xác nhận yêu cầu đặt lịch
  Future<void> confirmAppointmentRequest(String requestId, {int? roomSlotId}) async {
    final payload = <String, dynamic>{
      'facilityId': 'default',
    };
    if (roomSlotId != null) {
      payload['roomSlotId'] = roomSlotId;
    }

    final response = await _client.post(
        '/appointment/appointment-requests/$requestId/confirm', payload);
    if (response.statusCode != 200) {
      throw Exception('Failed to confirm request: ${response.body}');
    }
  }

  /// Doctor từ chối yêu cầu đặt lịch
  Future<void> rejectAppointmentRequest(String requestId, String reason) async {
    final response = await _client.post(
        '/appointment/appointment-requests/$requestId/reject', {
      'reason': reason,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to reject request: ${response.body}');
    }
  }

  /// Doctor lấy danh sách lịch hẹn của mình
  Future<List<Map<String, dynamic>>> getDoctorAppointments(
      String doctorId) async {
    final response = await _client
        .get('/appointment/appointments/doctor/$doctorId?page=0&size=50');
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['result']?['content'] ?? []) as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Doctor đánh dấu đã khám xong
  Future<void> completeAppointment(String appointmentId) async {
    final response = await _client
        .post('/appointment/appointments/$appointmentId/complete', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to complete appointment: ${response.body}');
    }
  }

  /// Doctor thêm kết quả khám
  Future<void> createMedicalRecord(
      String appointmentId, Map<String, dynamic> record) async {
    final response = await _client.post(
        '/appointment/medical-records/appointment/$appointmentId', record);
    if (response.statusCode != 200) {
      throw Exception('Failed to create medical record: ${response.body}');
    }
  }
}
