import 'dart:async';
import 'package:flutter/foundation.dart';

class AuthService {
  // Giả lập Backend để test giao diện
  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('🚀 [AUTH] GIẢ LẬP ĐĂNG NHẬP: $username');
    
    await Future.delayed(const Duration(seconds: 2)); // Giả lập độ trễ mạng

    // Luôn trả về thành công để test FE
    return {
      'success': true, 
      'token': 'mock_token_123'
    };
  }

  Future<Map<String, dynamic>> getMyInfo() async {
    return {
      'success': true, 
      'data': {
        'username': 'Người dùng Test',
        'email': 'test@example.com'
      }
    };
  }

  Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
  }) async {
    debugPrint('🚀 [REGISTER] GIẢ LẬP ĐĂNG KÝ: $email');
    
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true, 
      'message': 'Đăng ký thành công (Giả lập)'
    };
  }
}
