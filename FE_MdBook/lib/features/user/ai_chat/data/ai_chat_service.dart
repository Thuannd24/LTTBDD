import 'dart:convert';
import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/ai_suggestion_model.dart';

class AiChatService {
  final ApiClient _api = ApiClient();

  Future<AiSuggestion> suggestSpecialty(String userMessage) async {
    final response = await _api.post(
      '/chat/ai/suggest',
      {'message': userMessage},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('AI service returned no data');
      }
      return AiSuggestion.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Bạn cần đăng nhập để sử dụng tính năng này');
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Không thể kết nối đến AI. Vui lòng thử lại.');
    }
  }
}
