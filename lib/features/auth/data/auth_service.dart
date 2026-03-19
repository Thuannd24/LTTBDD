import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = dotenv.get('API_URL', fallback: 'http://localhost:8080/identity');

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/token');
    
    try {
      debugPrint('🚀 [AUTH] ĐANG GỌI: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('✅ [AUTH] PHẢN HỒI: ${response.statusCode}');
      debugPrint('Nội dung: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['code'] == 1000) {
        String token = data['result']['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        return {'success': true, 'token': token};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      debugPrint('❌ [AUTH] LỖI CHI TIẾT: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyInfo() async {
    final url = Uri.parse('$baseUrl/users/my-info');
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['code'] == 1000) {
        return {'success': true, 'data': data['result']};
      }
      return {'success': false, 'message': 'Lỗi lấy info'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    
    try {
      debugPrint('🚀 [REGISTER] ĐANG GỌI: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('✅ [REGISTER] PHẢN HỒI: ${response.statusCode}');
      debugPrint('Nội dung: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['code'] == 1000) {
        return {'success': true, 'message': 'Đăng ký thành công'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký thất bại'
        };
      }
    } catch (e) {
      debugPrint('❌ [REGISTER] LỖI CHI TIẾT: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
