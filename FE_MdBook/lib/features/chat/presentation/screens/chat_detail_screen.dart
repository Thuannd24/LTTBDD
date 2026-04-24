import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/chat_socket_service.dart';
import '../../data/profile_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserRole;
  final String otherUserName;
  final String? otherUserImage;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    this.otherUserRole = '',
    required this.otherUserName,
    this.otherUserImage,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ChatSocketService _chatService = ChatSocketService();
  final ProfileService _profileService = ProfileService.instance;

  List<dynamic> _messages = [];
  bool _isLoading = true;
  String _myUserId = '';
  String _storedUserId = '';

  String _resolvedName = '';
  String? _resolvedAvatar;

  StreamSubscription? _historySub;
  StreamSubscription? _newMsgSub;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _newMsgSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    await _chatService.connect();

    // Lấy ID từ nhiều nguồn để đảm bảo chắc chắn
    _myUserId = _chatService.currentUserId ?? '';
    final prefs = await SharedPreferences.getInstance();
    _storedUserId = prefs.getString('user_id') ?? '';
    if (_myUserId.isEmpty) _myUserId = _storedUserId;

    debugPrint('💬 ChatDetail myUserId=$_myUserId storedId=$_storedUserId');

    _resolvedName = widget.otherUserName;
    _resolvedAvatar = widget.otherUserImage;

    // Cố gắng lấy thông tin người kia từ profile
    _loadOtherProfile();

    _historySub = _chatService.historyStream.listen((data) {
      if (!mounted || data['conversationId'] != widget.conversationId) return;
      final List<dynamic> msgs = List.from(data['messages'] ?? []);
      msgs.sort((a, b) =>
          (DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(0))
              .compareTo(DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(0)));
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });

    _newMsgSub = _chatService.newMessageStream.listen((msg) {
      if (!mounted || msg['conversationId'] != widget.conversationId) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });

    _chatService.joinConversation(widget.conversationId);
    _chatService.getHistory(widget.conversationId);
  }

  Future<void> _loadOtherProfile() async {
    try {
      final profile = await _profileService.getProfile(
        widget.otherUserId,
        roleHint: widget.otherUserRole,
      );
      if (mounted) {
        setState(() {
          if (profile.displayName.isNotEmpty) {
            _resolvedName = profile.displayName;
          }
          if (profile.avatarUrl != null) {
            _resolvedAvatar = profile.avatarUrl;
          }
        });
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    _chatService.sendMessage(widget.conversationId, text);
  }

  String _fmt(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leadingWidth: 30,
        title: Row(
          children: [
            _resolvedAvatar != null && _resolvedAvatar!.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(_resolvedAvatar!),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF38A3A5),
                    child: Text(
                      _resolvedName.isNotEmpty
                          ? _resolvedName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resolvedName,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Đang hoạt động',
                    style: TextStyle(
                        color: Color(0xFF38A3A5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF38A3A5)));
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện!',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];

        // So sánh ID - chuẩn hóa lowercase+trim để tránh lệch case
        final myId =
            (_chatService.currentUserId ?? _storedUserId).trim().toLowerCase();
        final senderId =
            (msg['senderId'] ?? msg['sender_id'] ?? '').toString().trim().toLowerCase();
        final isMe = myId.isNotEmpty && senderId == myId;

        final time = _fmt(msg['createdAt']?.toString());
        final status = (msg['status'] ?? '').toString();
        final content = (msg['content'] ?? '').toString();

        return _buildBubble(
          text: content,
          isMe: isMe,
          time: time,
          status: status,
        );
      },
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isMe,
    required String time,
    required String status,
  }) {
    final otherAvatar = _resolvedAvatar;
    final otherName = _resolvedName;

    return Padding(
      padding: EdgeInsets.only(
          bottom: 6, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            otherAvatar != null && otherAvatar.isNotEmpty
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(otherAvatar),
                  )
                : CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF38A3A5),
                    child: Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF38A3A5)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 10)),
                    if (isMe) ...[
                      const SizedBox(width: 2),
                      Icon(
                        status == 'READ'
                            ? Icons.done_all
                            : Icons.done,
                        size: 12,
                        color: status == 'READ'
                            ? const Color(0xFF38A3A5)
                            : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: InputBorder.none),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF38A3A5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
