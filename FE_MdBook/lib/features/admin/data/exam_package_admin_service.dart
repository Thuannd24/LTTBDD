import 'dart:convert';

import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/exam_package_model.dart';

class ExamPackageAdminService {
  final ApiClient _client = ApiClient();

  Future<List<ExamPackageModel>> fetchAll() async {
    final response = await _client.get(
      '/appointment/exam-packages?page=0&size=100',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load exam packages: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['result']?['content'] ?? []) as List<dynamic>;

    return content
        .map((item) => ExamPackageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ExamPackageModel> create({
    required String code,
    required String name,
    required int estimatedTotalMinutes,
    String? description,
    String status = 'ACTIVE',
  }) async {
    final response = await _client.post('/appointment/admin/exam-packages', {
      'code': code,
      'name': name,
      'description': description,
      'estimatedTotalMinutes': estimatedTotalMinutes,
      'status': status,
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create exam package: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ExamPackageModel.fromJson(data['result'] as Map<String, dynamic>);
  }

  Future<ExamPackageModel> update({
    required String id,
    required String code,
    required String name,
    required int estimatedTotalMinutes,
    String? description,
    String status = 'ACTIVE',
  }) async {
    final response = await _client.put('/appointment/admin/exam-packages/$id', {
      'code': code,
      'name': name,
      'description': description,
      'estimatedTotalMinutes': estimatedTotalMinutes,
      'status': status,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update exam package: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ExamPackageModel.fromJson(data['result'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final response = await _client.delete(
      '/appointment/admin/exam-packages/$id',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete exam package: ${response.body}');
    }
  }
}
