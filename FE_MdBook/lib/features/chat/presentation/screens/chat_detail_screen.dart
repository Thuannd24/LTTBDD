import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/chat_socket_service.dart';
import '../../data/profile_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;       // Keycloak sub của người kia
  final String otherUserRole;     // Role từ socket (để chọn đúng profile endpoint)
  final String otherUserName;     // Tên sơ bộ từ socket (có thể thiếu)
  final String? otherUserImage;   // Avatar sơ bộ từ socket (nullable)
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
  String _myUserId = ''; // = chatService.currentUserId = JWT sub = senderId

  // Tên + avatar đã được resolve từ API (hiển thị ở AppBar + bubble)
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
    // ── 1. Luôn gọi connect() — an toàn: nếu cùng user đã kết nối thì return sớm,
    //    nếu user khác (sau logout mà không tẫt app) thì reset đúng. ────────
    await _chatService.connect();
    // Chờ socket thực sự kết nối nếu vừa tạo mới
    if (!_chatService.isConnected) {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    // ── 2. Nguồn sự thật duy nhất cho "đây có phải tin của tôi" ────────────────
    _myUserId = _chatService.currentUserId ?? '';
    debugPrint('💬 ChatDetail  myUserId=$_myUserId  conv=${widget.conversationId}');

    // ── 2b. Load tên + avatar từ profile API ─────────────────────────────────
    _resolvedName = widget.otherUserName;
    _resolvedAvatar = widget.otherUserImage;
    if (widget.otherUserId.isNotEmpty) {
      _profileService.getProfile(
        widget.otherUserId,
        roleHint: widget.otherUserRole.isNotEmpty ? widget.otherUserRole : null,
      ).then((profile) {
        if (!mounted) return;
        setState(() {
          if (profile.displayName.isNotEmpty &&
              profile.displayName != 'Người dùng' &&
              profile.displayName != 'Bệnh nhân' &&
              profile.displayName != 'Bác sĩ') {
            _resolvedName = profile.displayName;
          }
          if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
            _resolvedAvatar = profile.avatarUrl;
          }
        });
      });
    }

    // ── 3. Subscribe BEFORE requesting data ──────────────────────────────────
    _historySub = _chatService.historyStream.listen((data) {
      if (!mounted) return;
      if (data['conversationId'] != widget.conversationId) return;

      final List<dynamic> msgs = List.from(data['messages'] ?? []);
      // Server returns newest-first → reverse for display (oldest at top)
      msgs.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(0);
        final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(0);
        return aTime.compareTo(bTime); // ascending → oldest at top
      });

      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    });

    _newMsgSub = _chatService.newMessageStream.listen((msg) {
      if (!mounted) return;
      if (msg['conversationId'] != widget.conversationId) return;

      setState(() => _messages.add(msg));
      _scrollToBottom();

      final msgId = msg['id']?.toString();
      if (msg['recipientId'] == _myUserId && msgId != null) {
        _chatService.markAsRead(widget.conversationId, msgId);
      }
    });

    // ── 4. Join room then request history ────────────────────────────────────
    _chatService.joinConversation(widget.conversationId);
    await Future.delayed(const Duration(milliseconds: 200));
    _chatService.getHistory(widget.conversationId);

    // ── 5. Timeout safety ────────────────────────────────────────────────────
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      appBar: _buildAppBar(),
      body: Column(children: [
        Expanded(child: _buildMessageList()),
        _buildInput(),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        // ── Avatar: NetworkImage nếu có URL, fallback chữ cái đầu ────────────
        _resolvedAvatar != null && _resolvedAvatar!.isNotEmpty
            ? CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE0F4F4),
                backgroundImage: NetworkImage(_resolvedAvatar!),
                onBackgroundImageError: (_, __) {},
              )
            : CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF38A3A5),
                child: Text(
                  _resolvedName.isNotEmpty ? _resolvedName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _resolvedName.isNotEmpty ? _resolvedName : 'Đang tải...',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const Text('Đang hoạt động',
                  style: TextStyle(color: Colors.green, fontSize: 11)),
            ],
          ),
        ),
      ]),
      actions: [
        IconButton(
            icon: const Icon(Icons.videocam_outlined,
                color: Color(0xFF38A3A5)),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.call_outlined, color: Color(0xFF38A3A5)),
            onPressed: () {}),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF38A3A5)));
    }
    if (_messages.isEmpty) {
      return const Center(
          child: Text('Hãy bắt đầu cuộc trò chuyện!',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        // ── CORE: senderId from server == JWT sub == _myUserId ──────────────
        final isMe = (msg['senderId']?.toString() ?? '') == _myUserId;

        // Show sender label only on first message or when sender changes
        final prevMsg = index > 0 ? _messages[index - 1] : null;
        final prevSenderId = prevMsg?['senderId']?.toString() ?? '';
        final currSenderId = msg['senderId']?.toString() ?? '';
        final showSenderInfo = !isMe && prevSenderId != currSenderId;

        return _buildBubble(
          text: msg['content']?.toString() ?? '',
          isMe: isMe,
          time: _fmt(msg['createdAt']?.toString()),
          status: msg['status']?.toString() ?? 'SENT',
          showSenderInfo: showSenderInfo,
        );
      },
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isMe,
    required String time,
    required String status,
    bool showSenderInfo = false,
  }) {
    // Dùng resolved values (từ API) thay vì widget params
    final otherAvatar = _resolvedAvatar;
    final otherName = _resolvedName.isNotEmpty ? _resolvedName : widget.otherUserName;

    return Padding(
      padding: EdgeInsets.only(
          bottom: 6, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // ── Avatar của người kia (bên trái) ─────────────────────────────
          if (!isMe) ...[
            otherAvatar != null && otherAvatar.isNotEmpty
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE0F4F4),
                    backgroundImage: NetworkImage(otherAvatar),
                    onBackgroundImageError: (_, __) {},
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

          // ── Bubble + metadata ────────────────────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Tên người gửi (chỉ hiện khi nhóm tin nhắn thay đổi)
                if (showSenderInfo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(
                      otherName,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                // Bubble nội dung
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF38A3A5) : Colors.white,
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

                // Thời gian + trạng thái
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
                        status == 'READ' ? Icons.done_all : Icons.done,
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
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF38A3A5)),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.image_outlined,
                  color: Color(0xFF38A3A5)),
              onPressed: () {}),
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
          IconButton(
              icon:
                  const Icon(Icons.send, color: Color(0xFF38A3A5)),
              onPressed: _sendMessage),
        ]),
      ),
    );
  }
}
