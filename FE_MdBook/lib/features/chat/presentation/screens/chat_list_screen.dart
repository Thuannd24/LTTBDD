import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/chat_socket_service.dart';
import 'chat_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatListScreen extends StatefulWidget {
  final bool isEmbedded;
  const ChatListScreen({super.key, this.isEmbedded = false});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatSocketService _chatService = ChatSocketService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id'); // Assuming user_id is stored
    
    _chatService.conversationsStream.listen((data) {
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    });

    _chatService.errorStream.listen((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat Error: $error')),
        );
      }
    });

    await _chatService.connect();
    // If already connected, get list immediately
    if (_chatService.isConnected) {
      _chatService.getConversations();
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return DateFormat('hh:mm a').format(date);
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38A3A5)))
          : _conversations.isEmpty
              ? const Center(child: Text("Chưa có tin nhắn nào"))
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                    final otherParticipant = chat['otherParticipant'] ?? {};
                    final lastMessage = chat['lastMessage'] ?? {};
                    
                    final String name = otherParticipant['displayName'] ?? 'Unknown';
                    final String avatarUrl = otherParticipant['avatarUrl'] ?? 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg';
                    final String lastMsgContent = lastMessage['content'] ?? 'Chưa có tin nhắn';
                    final String time = _formatTime(lastMessage['createdAt']);
                    
                    // Simple unread logic check: If last message status is DELIVERED and sender is not me
                    bool isUnread = false;
                    if (lastMessage['status'] == 'DELIVERED' && lastMessage['senderId'] != _currentUserId) {
                       isUnread = true;
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(avatarUrl),
                        onBackgroundImageError: (_, __) {},
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        lastMsgContent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnread ? Colors.black87 : Colors.grey,
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF38A3A5),
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              conversationId: chat['id'],
                              doctorName: name,
                              doctorImage: avatarUrl,
                              currentUserId: _currentUserId ?? '',
                            ),
                          ),
                        ).then((_) {
                           // Refresh list when going back
                           _chatService.getConversations();
                        });
                      },
                    );
                  },
                );

    if (widget.isEmbedded) {
      return Container(
        color: Colors.white,
        child: bodyContent,
      );
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
        title: const Text(
          'Nhắn tin',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
