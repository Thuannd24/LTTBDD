import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/chat_socket_service.dart';
import '../../data/profile_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool isEmbedded;
  const ChatListScreen({super.key, this.isEmbedded = false});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatSocketService _chatService = ChatSocketService();
  final ProfileService _profileService = ProfileService.instance;

  List<_ConversationItem> _items = [];
  bool _isLoading = true;
  String? _currentUserId;

  StreamSubscription? _convSub;
  StreamSubscription? _errSub;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _convSub?.cancel();
    _errSub?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    // connect() tự xử lý: cùng user → return sớm, user khác → reset streams
    await _chatService.connect();

    // Cancel subscription cũ TRƯỚC khi đọc currentUserId
    // (connect() có thể đã reset streams nếu account thay đổi)
    await _convSub?.cancel();
    await _errSub?.cancel();

    // Đọc userId SAU khi connect() hoàn thành — luôn đúng với user hiện tại
    _currentUserId = _chatService.currentUserId;

    _convSub = _chatService.conversationsStream.listen((data) async {
      if (!mounted) return;

      // Lọc conversations của user hiện tại
      final filtered = data.where((conv) {
        final ids = conv['participantIds'] as List? ?? [];
        return ids.contains(_currentUserId);
      }).toList();

      // Enrich với profile API để có tên + avatar thật
      final items = await Future.wait(
        filtered.map((conv) => _enrichConversation(conv)),
      );

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    });

    _errSub = _chatService.errorStream.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $error')));
    });

    if (_chatService.isConnected) {
      _chatService.getConversations();
    }

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });
  }

  /// Lấy profile thật từ API, merge với dữ liệu socket
  Future<_ConversationItem> _enrichConversation(Map conv) async {
    final other = Map<String, dynamic>.from(conv['otherParticipant'] ?? {});
    final lastMsg = Map<String, dynamic>.from(conv['lastMessage'] ?? {});
    final otherUserId = other['userId'] as String? ?? '';
    // Role của người kia — dùng để chọn đúng endpoint profile
    final otherRole = other['role'] as String? ?? '';

    // Tên/avatar từ socket (có thể null nếu chưa được cache)
    String displayName = _resolveNameFromSocket(other);
    String? avatarUrl = other['avatarUrl'] as String?;

    // Gọi profile API với roleHint để tránh gọi nhầm endpoint
    if (otherUserId.isNotEmpty) {
      try {
        final profile = await _profileService.getProfile(
          otherUserId,
          roleHint: otherRole.isNotEmpty ? otherRole : null,
        );
        // Ưu tiên kết quả API nếu có tên thật
        if (profile.displayName.isNotEmpty &&
            profile.displayName != 'Người dùng' &&
            profile.displayName != 'Bệnh nhân' &&
            profile.displayName != 'Bác sĩ') {
          displayName = profile.displayName;
        }
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
          avatarUrl = profile.avatarUrl;
        }
      } catch (_) {
        // Giữ nguyên dữ liệu socket nếu API lỗi
      }
    }

    return _ConversationItem(
      id: conv['id'] as String? ?? '',
      otherUserId: otherUserId,
      otherUserRole: otherRole,
      displayName: displayName,
      avatarUrl: avatarUrl,
      lastContent: lastMsg['content'] as String? ?? 'Chưa có tin nhắn',
      lastTime: lastMsg['createdAt'] as String?,
      isUnread: lastMsg['status'] == 'DELIVERED' &&
          lastMsg['senderId'] != _currentUserId,
      rawConv: conv,
    );
  }

  String _resolveNameFromSocket(Map other) {
    final name = other['displayName'] as String? ?? '';
    if (name.isNotEmpty && name != 'Unknown') return name;
    final role = other['role'] as String? ?? '';
    return role.contains('DOCTOR') ? 'Bác sĩ' : 'Người dùng';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return DateFormat('HH:mm').format(date);
      } else {
        return DateFormat('dd/MM').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF38A3A5)))
        : _items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: Color(0xFFBDBDBD)),
                    SizedBox(height: 16),
                    Text('Chưa có tin nhắn nào',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 76, endIndent: 16),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final time = _formatTime(item.lastTime);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: Stack(
                      children: [
                        _buildAvatar(item.avatarUrl, item.displayName),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      item.displayName,
                      style: TextStyle(
                        fontWeight: item.isUnread
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      item.lastContent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.isUnread
                            ? Colors.black87
                            : Colors.grey[500],
                        fontWeight: item.isUnread
                            ? FontWeight.w500
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(time,
                            style: TextStyle(
                                color: item.isUnread
                                    ? const Color(0xFF38A3A5)
                                    : Colors.grey,
                                fontSize: 11)),
                        const SizedBox(height: 4),
                        if (item.isUnread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF38A3A5),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            conversationId: item.id,
                            otherUserId: item.otherUserId,
                            otherUserRole: item.otherUserRole,
                            otherUserName: item.displayName,
                            otherUserImage: item.avatarUrl,
                            currentUserId: _currentUserId ?? '',
                          ),
                        ),
                      ).then((_) => _chatService.getConversations());
                    },
                  );
                },
              );

    if (widget.isEmbedded) {
      return Container(color: Colors.white, child: body);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tin nhắn',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: body,
    );
  }

  /// Avatar tròn: dùng NetworkImage nếu có URL, fallback là chữ cái đầu
  Widget _buildAvatar(String? avatarUrl, String displayName) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFE0F4F4),
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    // Fallback: chữ cái đầu của tên
    final initials = _initials(displayName);
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFF38A3A5),
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Model nội bộ cho một conversation đã enriched
class _ConversationItem {
  final String id;
  final String otherUserId;
  final String otherUserRole;   // role từ socket — để truyền sang ChatDetailScreen
  final String displayName;
  final String? avatarUrl;
  final String lastContent;
  final String? lastTime;
  final bool isUnread;
  final Map rawConv;

  const _ConversationItem({
    required this.id,
    required this.otherUserId,
    required this.otherUserRole,
    required this.displayName,
    this.avatarUrl,
    required this.lastContent,
    this.lastTime,
    required this.isUnread,
    required this.rawConv,
  });
}
