import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/chat_socket_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String doctorName;
  final String doctorImage;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.doctorName,
    required this.doctorImage,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatSocketService _chatService = ChatSocketService();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    _chatService.joinConversation(widget.conversationId);
    _chatService.getHistory(widget.conversationId);

    _chatService.historyStream.listen((data) {
      if (mounted && data['conversationId'] == widget.conversationId) {
        setState(() {
          _messages = List.from(data['messages'] ?? []).reversed.toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });

    _chatService.newMessageStream.listen((message) {
      if (mounted && message['conversationId'] == widget.conversationId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        
        // Mark as read if I am the recipient
        if (message['recipientId'] == widget.currentUserId) {
          _chatService.markAsRead(widget.conversationId, message['id']);
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final text = _messageController.text.trim();
    _messageController.clear();
    
    _chatService.sendMessage(widget.conversationId, text);
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.doctorImage),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName,
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Đang hoạt động',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: Color(0xFF38A3A5)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call_outlined, color: Color(0xFF38A3A5)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38A3A5)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == widget.currentUserId;
                      return _buildMessageBubble(
                        msg['content'] ?? '', 
                        isMe, 
                        _formatTime(msg['createdAt']),
                        msg['status'] ?? 'SENT'
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF38A3A5) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  status == 'READ' ? Icons.done_all : Icons.check,
                  size: 12,
                  color: status == 'READ' ? Colors.blue : Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF38A3A5)), onPressed: () {}),
            IconButton(icon: const Icon(Icons.image_outlined, color: Color(0xFF38A3A5)), onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF38A3A5)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
