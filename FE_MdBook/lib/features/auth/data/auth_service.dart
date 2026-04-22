import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  
  // Login via Keycloak (through Gateway)
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/auth/token');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'client_id': 'medbook-web',
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        
        return {
          'success': true,
          'token': accessToken
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sai tên đăng nhập hoặc mật khẩu. Vui lòng thử lại.'
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Tài khoản không tồn tại.'
        };
      } else {
        return {
          'success': false,
          'message': 'Đăng nhập không thành công (Lỗi ${response.statusCode})'
        };
      }
    } catch (e) {
      debugPrint('🚨 LOGIN ERROR: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng.'
      };
    }
  }

  // Get current user info by merging Identity (roles) and Profile (details) service data
  Future<UserProfile?> getMyInfo() async {
    try {
      final identityRes = await _apiClient.get('/identity/users/my-info');
      final profileRes = await _apiClient.get('/profile/users/me');
      
      if (identityRes.statusCode == 200 && profileRes.statusCode == 200) {
        final identityData = jsonDecode(identityRes.body)['result'] as Map<String, dynamic>;
        final profileData = jsonDecode(profileRes.body)['result'] as Map<String, dynamic>;
        
        final merged = { ...identityData, ...profileData };
        return UserProfile.fromJson(merged);
      } else if (profileRes.statusCode == 200) {
        final profileData = jsonDecode(profileRes.body)['result'] as Map<String, dynamic>;
        return UserProfile.fromJson(profileData);
      }
      return null;
    } catch (e) {
      debugPrint('getMyInfo Exception: $e');
      return null;
    }
  }

  // Admin: Get all users
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final response = await _apiClient.get('/identity/users');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['result'] ?? []) as List;
        return list.map((e) => UserProfile.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getAllUsers Error: $e');
      return [];
    }
  }

  Future<UserProfile?> getUserInfo(String userId) async {
    try {
      final response = await _apiClient.get('/profile/users/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          return UserProfile.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('getUserInfo Error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiClient.post('/identity/users/registration', {
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Đăng ký thành công'
        };
      } else {
        // Xử lý các mã lỗi từ ErrorCode.java của Backend
        String errorMsg = _mapErrorCode(data['code']);
        return {
          'success': false,
          'message': errorMsg
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: Không thể đăng ký lúc này.'
      };
    }
  }

  String _mapErrorCode(int? code) {
    switch (code) {
      case 1001: return 'Tên đăng nhập hoặc Email đã được sử dụng.';
      case 1002: return 'Người dùng không tồn tại.';
      case 1008: return 'Định dạng email không hợp lệ.';
      case 1009: return 'Mật khẩu phải có ít nhất 6 ký tự.';
      case 1010: return 'Tên đăng nhập phải có ít nhất 4 ký tự.';
      case 1006: return 'Bạn phải đủ 10 tuổi trở lên để đăng ký.';
      // Profile Service Codes (2xxx)
      case 2001: return 'Hồ sơ không tồn tại.';
      case 2003: return 'Ngày sinh phải ở trong quá khứ.';
      case 2004: return 'Số điện thoại không hợp lệ (7-15 chữ số).';
      case 2007: return 'Họ quá dài (tối đa 100 ký tự).';
      case 2008: return 'Tên quá dài (tối đa 100 ký tự).';
      case 2009: return 'Địa chỉ quá dài (tối đa 255 ký tự).';
      default: return 'Giao dịch thất bại. Vui lòng thử lại sau. (Mã lỗi: $code)';
    }
  }

  Future<Map<String, dynamic>> adminCreateUser({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    List<String>? roles,
  }) async {
    try {
      final response = await _apiClient.post('/identity/users', {
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'roles': roles,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Tạo tài khoản thành công'
        };
      } else {
        String errorMsg = _mapErrorCode(data['code']);
        return {
          'success': false,
          'message': errorMsg
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: Không thể tạo tài khoản bác sĩ.'
      };
    }
  }

  Future<Map<String, dynamic>> updateMyInfo(String userId, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.put('/profile/users/me', payload);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Cập nhật thành công',
          'result': data['result']
        };
      } else {
        return {
          'success': false,
          'message': _mapErrorCode(data['code'])
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối khi cập nhật thông tin.'
      };
    }
  }

  Future<Map<String, dynamic>> updateUserInfo(String userId, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.put('/profile/users/$userId', payload);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Cập nhật thành công',
          'result': data['result']
        };
      } else {
        return {
          'success': false,
          'message': _mapErrorCode(data['code'])
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối khi cập nhật hồ sơ bệnh nhân.'
      };
    }
  }

  Future<Map<String, dynamic>> updateAvatar(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/profile/users/me/avatar'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật ảnh đại diện thành công'};
      } else {
        return {'success': false, 'message': 'Lỗi khi upload ảnh: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> generateAiSummary() async {
    try {
      final response = await _apiClient.post('/profile/users/me/ai-summary', {});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': 'Tóm tắt thành công', 'data': data['result']};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Lỗi tạo tóm tắt'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
