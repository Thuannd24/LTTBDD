import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/specialty_model.dart';

class SpecialtyService {
  final ApiClient _client = ApiClient();

  Future<List<Specialty>> fetchAll() async {
    final resp = await _client.get('/doctor/specialties');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = (data['result'] ?? data) as List;
      return list.map((e) => Specialty.fromJson(e)).toList();
    }
    throw Exception('Failed to load specialties: ${resp.statusCode}');
  }

  Future<Specialty> getById(String id) async {
    final resp = await _client.get('/doctor/specialties/$id');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Specialty.fromJson(data['result'] ?? data);
    }
    throw Exception('Failed to fetch specialty');
  }

  Future<Specialty> create(Map<String, dynamic> payload) async {
    final resp = await _client.post('/doctor/specialties', payload);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return Specialty.fromJson(data['result'] ?? data);
    }
    throw Exception('Failed to create specialty');
  }

  Future<Specialty> update(String id, Map<String, dynamic> payload) async {
    final resp = await _client.put('/doctor/specialties/$id', payload);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Specialty.fromJson(data['result'] ?? data);
    }
    throw Exception('Failed to update specialty');
  }

  Future<void> delete(String id) async {
    final resp = await _client.delete('/doctor/specialties/$id');
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      return;
    }
    throw Exception('Failed to delete specialty');
  }

  Future<String> uploadImage(dynamic file) async {
    final url = Uri.parse('${ApiClient.baseUrl}/doctor/specialties/upload');
    final request = http.MultipartRequest('POST', url);
    
    final headers = await _client.getHeaders();
    request.headers.addAll(headers);
    
    if (file is String) {
      request.files.add(await http.MultipartFile.fromPath('file', file));
    } else {
      // Handle other types if needed (e.g. XFile)
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] as String;
    }
    throw Exception('Failed to upload image');
  }
}
