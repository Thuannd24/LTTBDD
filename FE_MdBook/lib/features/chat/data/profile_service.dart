import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kết quả profile đơn giản để hiển thị trong chat
class ChatUserProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? phone;
  final String? medicalHistory;
  final String? allergies;

  const ChatUserProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.phone,
    this.medicalHistory,
    this.allergies,
  });
}

/// Service gọi thẳng profile-service API để lấy tên + avatar.
/// Dùng [roleHint] để chọn đúng endpoint — tránh nhầm profile khi
/// bác sĩ query bệnh nhân và ngược lại.
/// Có in-memory cache (per session) để tránh gọi thừa.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  /// Cache key: "userId|roleHint" để tránh dùng lại kết quả sai role
  final Map<String, ChatUserProfile> _cache = {};

  String get _baseUrl {
    try {
      return dotenv.env['API_URL'] ?? 'http://192.168.0.100:8080/api/v1';
    } catch (_) {
      return 'http://192.168.0.100:8080/api/v1';
    }
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Lấy profile của [userId].
  ///
  /// [roleHint] là role của người cần lấy profile (từ socket hoặc context):
  ///   - "ROLE_DOCTOR" / "DOCTOR" → chỉ gọi `/profile/doctors/{id}`
  ///   - "ROLE_PATIENT" / "ROLE_USER" / "USER" → chỉ gọi `/profile/users/{id}`
  ///   - null / unknown → thử patient trước, nếu trả đúng userId thì dùng,
  ///     không thì thử doctor
  Future<ChatUserProfile> getProfile(String userId, {String? roleHint}) async {
    final cacheKey = '$userId|${roleHint ?? ""}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final headers = await _headers();
    final normalizedRole = _normalizeRole(roleHint);

    ChatUserProfile? profile;

    if (normalizedRole == 'DOCTOR') {
      // Người kia là bác sĩ → chỉ gọi doctor endpoint
      profile = await _fetchDoctorProfile(userId, headers);
      profile ??= ChatUserProfile(userId: userId, displayName: 'Bác sĩ');
    } else if (normalizedRole == 'PATIENT') {
      // Người kia là bệnh nhân → chỉ gọi patient endpoint
      profile = await _fetchPatientProfile(userId, headers);
      profile ??= ChatUserProfile(userId: userId, displayName: 'Bệnh nhân');
    } else {
      // Không rõ role → thử cả hai, verify bằng userId trả về
      profile = await _fetchPatientProfile(userId, headers);
      // Nếu patient endpoint trả về userId KHÁC (bị trả profile của người khác) → bỏ qua
      if (profile != null && profile.userId.isNotEmpty && profile.userId != userId) {
        debugPrint('ProfileService: patient[$userId] trả sai userId=${profile.userId}, skip');
        profile = null;
      }
      if (profile == null) {
        profile = await _fetchDoctorProfile(userId, headers);
      }
      profile ??= ChatUserProfile(userId: userId, displayName: 'Người dùng');
    }

    _cache[cacheKey] = profile;
    return profile;
  }

  /// Normalize role string từ nhiều format khác nhau
  String? _normalizeRole(String? role) {
    if (role == null) return null;
    final r = role.toUpperCase();
    if (r.contains('DOCTOR')) return 'DOCTOR';
    if (r.contains('PATIENT') || r.contains('USER')) return 'PATIENT';
    return null;
  }

  /// Xóa cache khi logout / switch account
  void clearCache() => _cache.clear();

  // ── Patient: GET /profile/users/{userId} ─────────────────────────────────────
  Future<ChatUserProfile?> _fetchPatientProfile(
      String userId, Map<String, String> headers) async {
    try {
      final url = Uri.parse('$_baseUrl/profile/users/$userId');
      final res = await http.get(url, headers: headers).timeout(
            const Duration(seconds: 6),
          );
      debugPrint('ProfileService GET $url → ${res.statusCode}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['result'] as Map<String, dynamic>?;
        if (data != null) {
          return _mapPatient(userId, data);
        }
      }
    } catch (e) {
      debugPrint('ProfileService patient[$userId]: $e');
    }
    return null;
  }

  // ── Doctor: GET /profile/doctors/{userId} ────────────────────────────────────
  Future<ChatUserProfile?> _fetchDoctorProfile(
      String userId, Map<String, String> headers) async {
    try {
      final url = Uri.parse('$_baseUrl/profile/doctors/$userId');
      final res = await http.get(url, headers: headers).timeout(
            const Duration(seconds: 6),
          );
      debugPrint('ProfileService GET $url → ${res.statusCode}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['result'] as Map<String, dynamic>?;
        if (data != null) {
          return _mapDoctor(userId, data);
        }
      }
    } catch (e) {
      debugPrint('ProfileService doctor[$userId]: $e');
    }
    return null;
  }

  ChatUserProfile _mapPatient(String userId, Map<String, dynamic> d) {
    final firstName = d['firstName'] as String? ?? '';
    final lastName = d['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    // Dùng userId từ response để detect xem có bị trả sai profile không
    final returnedUserId = d['userId'] as String? ?? userId;
    return ChatUserProfile(
      userId: returnedUserId,
      displayName: fullName.isNotEmpty
          ? fullName
          : (d['username'] as String? ?? 'Bệnh nhân'),
      avatarUrl: d['avatar'] as String?,
      phone: d['phone'] as String?,
      medicalHistory: d['medicalHistory'] as String?,
      allergies: d['allergies'] as String?,
    );
  }

  ChatUserProfile _mapDoctor(String userId, Map<String, dynamic> d) {
    final firstName = d['firstName'] as String? ?? '';
    final lastName = d['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final name = fullName.isNotEmpty
        ? fullName
        : (d['doctorName'] as String? ?? d['name'] as String? ?? 'Bác sĩ');
    final returnedUserId = d['userId'] as String? ?? userId;
    return ChatUserProfile(
      userId: returnedUserId,
      displayName: name,
      avatarUrl: d['avatar'] as String? ?? d['avatarUrl'] as String?,
      phone: d['phone'] as String?,
    );
  }
}
