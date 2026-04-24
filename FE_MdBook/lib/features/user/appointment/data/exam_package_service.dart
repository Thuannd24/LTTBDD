import 'dart:convert';

import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/exam_package_model.dart';

class ExamPackageService {
  final ApiClient _client = ApiClient();

  Future<List<ExamPackageModel>> fetchAll({String? specialtyId}) async {
    String url = '/appointment/exam-packages?page=0&size=50';
    if (specialtyId != null && specialtyId.isNotEmpty) {
      url += '&specialtyId=$specialtyId';
    }
    
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load exam packages: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['result']?['content'] ?? []) as List<dynamic>;
    return content
        .map((item) => ExamPackageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
