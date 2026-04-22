import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IO.Socket? _socket;
  
  // Controllers to broadcast events to UI
  final _conversationsController = StreamController<List<dynamic>>.broadcast();
  final _historyController = StreamController<Map<String, dynamic>>.broadcast();
  final _newMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<List<dynamic>> get conversationsStream => _conversationsController.stream;
  Stream<Map<String, dynamic>> get historyStream => _historyController.stream;
  Stream<Map<String, dynamic>> get newMessageStream => _newMessageController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _errorController.add("No access token found");
      return;
    }

    String chatUrl = dotenv.env['CHAT_URL'] ?? 'http://172.17.158.253:5006';
    print('Connecting to chat server at: $chatUrl');

    // Clean up old socket if it exists
    if (_socket != null) {
      _socket!.dispose();
    }

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
      print('✅ Socket connected: ${_socket!.id}');
      // Khi connect thành công, lấy danh sách conversation
      getConversations();
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print('🚨 Socket connect error: $error');
      _errorController.add('Kết nối thất bại: $error');
    });

    _socket!.on('chat:error', (data) {
      print('Socket chat error: $data');
      if (data is Map && data['message'] != null) {
        _errorController.add(data['message'].toString());
      }
    });

    _socket!.on('conversation:list', (data) {
      if (data is List) {
        _conversationsController.add(data);
      }
    });

    _socket!.on('message:history', (data) {
      if (data is Map<String, dynamic>) {
        _historyController.add(data);
      }
    });

    _socket!.on('message:new', (data) {
      if (data is Map<String, dynamic>) {
        _newMessageController.add(data);
      }
    });
    
    _socket!.on('conversation:joined', (data) {
       print('Joined conversation: $data');
    });

    _socket!.connect();
  }

  void getConversations() {
    _socket?.emit('conversation:list');
  }

  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', {'conversationId': conversationId});
  }

  void getHistory(String conversationId, {String? before, int limit = 20}) {
    _socket?.emit('message:history', {
      'conversationId': conversationId,
      if (before != null) 'before': before,
      'limit': limit,
    });
  }

  void sendMessage(String conversationId, String content, {String contentType = 'TEXT'}) {
    _socket?.emit('message:send', {
      'conversationId': conversationId,
      'content': content,
      'contentType': contentType,
    });
  }

  void markAsRead(String conversationId, String messageId) {
    _socket?.emit('message:read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
