import 'dart:convert';
import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';

class DoctorService {
  final ApiClient _client = ApiClient();

  Future<List<DoctorProfile>> fetchAll() async {
    final resp = await _client.get('/doctor/doctors');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = (data['result'] ?? data) as List;
      return list.map((e) => DoctorProfile.fromJson(e)).toList();
    }
    throw Exception('Failed to load doctors');
  }

  Future<DoctorProfile> getById(String id) async {
    final resp = await _client.get('/doctor/doctors/$id');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return DoctorProfile.fromJson(data['result'] ?? data);
    }
    throw Exception('Failed to fetch doctor profile');
  }

  Future<DoctorProfile> getByUserId(String userId) async {
    final resp = await _client.get('/doctor/doctors/user/$userId');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return DoctorProfile.fromJson(data['result'] ?? data);
    }
    throw Exception('Failed to fetch doctor profile by userId');
  }

  Future<DoctorProfile> create(Map<String, dynamic> payload) async {
    final resp = await _client.post('/doctor/doctors', payload);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return DoctorProfile.fromJson(data['result'] ?? data);
    }
    throw Exception('Failed to create doctor profile');
  }

  Future<DoctorProfile> update(String id, Map<String, dynamic> payload) async {
    final resp = await _client.put('/doctor/doctors/$id', payload);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return DoctorProfile.fromJson(data['result'] ?? data);
    }
    throw Exception('Failed to update doctor profile');
  }
}
