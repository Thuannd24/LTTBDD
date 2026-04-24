import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatApiService {

  String get _chatBaseUrl {
    return dotenv.env['CHAT_URL'] ?? 'http://192.168.0.100:5006';
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Creates a new conversation or gets the existing one with a specific user
  Future<Map<String, dynamic>?> createOrGetConversation(String targetUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_chatBaseUrl/chat/conversations'),
        headers: headers,
        body: jsonEncode({
          'targetUserId': targetUserId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if ((data['status'] == 200 || data['status'] == 201 || data['status'] == 1) && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }
}
