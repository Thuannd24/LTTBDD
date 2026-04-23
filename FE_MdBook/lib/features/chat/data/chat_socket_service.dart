import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Decode JWT `sub` claim without verifying signature.
String? _jwtSub(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    String payload = parts[1];
    switch (payload.length % 4) {
      case 2: payload += '=='; break;
      case 3: payload += '='; break;
    }
    final decoded = utf8.decode(base64Url.decode(payload));
    final data = jsonDecode(decoded) as Map<String, dynamic>;
    return data['sub'] as String?;
  } catch (_) {
    return null;
  }
}

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IO.Socket? _socket;

  /// Keycloak `sub` of the currently connected user.
  /// Matches exactly what the server stores as `senderId` in every message.
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // ── Each StreamController is recreated fresh on every new login ────────────
  StreamController<List<dynamic>> _conversationsCtrl =
      StreamController<List<dynamic>>.broadcast();
  StreamController<Map<String, dynamic>> _historyCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamController<Map<String, dynamic>> _newMessageCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamController<String> _errorCtrl =
      StreamController<String>.broadcast();

  Stream<List<dynamic>>          get conversationsStream => _conversationsCtrl.stream;
  Stream<Map<String, dynamic>>   get historyStream       => _historyCtrl.stream;
  Stream<Map<String, dynamic>>   get newMessageStream    => _newMessageCtrl.stream;
  Stream<String>                 get errorStream         => _errorCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  // ── Reset all stream controllers (called when switching accounts) ──────────
  void _resetStreams() {
    _conversationsCtrl.close();
    _historyCtrl.close();
    _newMessageCtrl.close();
    _errorCtrl.close();

    _conversationsCtrl = StreamController<List<dynamic>>.broadcast();
    _historyCtrl       = StreamController<Map<String, dynamic>>.broadcast();
    _newMessageCtrl    = StreamController<Map<String, dynamic>>.broadcast();
    _errorCtrl         = StreamController<String>.broadcast();
  }

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _errorCtrl.add('No access token found');
      return;
    }

    final newUserId = _jwtSub(token);

    // If same account already connected — nothing to do.
    if (_socket != null && _socket!.connected && _currentUserId == newUserId) {
      return;
    }

    // Different account (or first connect) → tear down old session completely.
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    // Reset streams so old-account listeners get no new data.
    _resetStreams();
    _currentUserId = newUserId;

    final String chatUrl =
        dotenv.env['CHAT_URL'] ?? 'http://172.17.158.253:5006';
    print('🔌 Chat connect  userId=$_currentUserId  url=$chatUrl');

    _socket = IO.io(
      chatUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/chat/socket.io')
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Socket connected  id=${_socket!.id}  user=$_currentUserId');
      getConversations();
    });

    _socket!.onDisconnect((_) =>
        print('❌ Socket disconnected  user=$_currentUserId'));

    _socket!.onConnectError((e) {
      print('🚨 Socket error: $e');
      _errorCtrl.add('Kết nối thất bại: $e');
    });

    _socket!.on('chat:error', (data) {
      if (data is Map && data['message'] != null) {
        _errorCtrl.add(data['message'].toString());
      }
    });

    _socket!.on('conversation:list', (data) {
      if (data is List) _conversationsCtrl.add(data);
    });

    _socket!.on('message:history', (data) {
      if (data is Map<String, dynamic>) _historyCtrl.add(data);
    });

    _socket!.on('message:new', (data) {
      if (data is Map<String, dynamic>) _newMessageCtrl.add(data);
    });

    _socket!.on('conversation:joined', (data) =>
        print('📥 Joined: $data'));

    _socket!.connect();
  }

  void getConversations() => _socket?.emit('conversation:list');

  void joinConversation(String conversationId) =>
      _socket?.emit('conversation:join', {'conversationId': conversationId});

  void getHistory(String conversationId, {String? before, int limit = 50}) =>
      _socket?.emit('message:history', {
        'conversationId': conversationId,
        if (before != null) 'before': before,
        'limit': limit,
      });

  void sendMessage(String conversationId, String content,
          {String contentType = 'TEXT'}) =>
      _socket?.emit('message:send', {
        'conversationId': conversationId,
        'content': content,
        'contentType': contentType,
      });

  void markAsRead(String conversationId, String messageId) =>
      _socket?.emit('message:read', {
        'conversationId': conversationId,
        'messageId': messageId,
      });

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    _resetStreams(); // clear pending events for the logged-out user
    print('🔴 Chat disconnected and streams reset');
  }
}
