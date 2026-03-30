import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chats = [
      {
        'name': 'BS. Trịnh Ngọc Phát',
        'lastMessage': 'Chào bạn, kết quả xét nghiệm của bạn đã có...',
        'time': '10:30 AM',
        'unread': 2,
        'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
      },
      {
        'name': 'BS. Julianne Moore',
        'lastMessage': 'Bạn hãy uống thuốc đúng giờ nhé.',
        'time': 'Hôm qua',
        'unread': 0,
        'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
      },
      {
        'name': 'BS. Alan Cooper',
        'lastMessage': 'Hẹn gặp bạn vào tuần tới.',
        'time': 'Thứ 2',
        'unread': 0,
        'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
      },
    ];

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
          'Nhắn tin với bác sĩ',
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
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(chat['image']),
            ),
            title: Text(
              chat['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              chat['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat['unread'] > 0 ? Colors.black87 : Colors.grey,
                fontWeight: chat['unread'] > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                if (chat['unread'] > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF38A3A5),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${chat['unread']}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    doctorName: chat['name'],
                    doctorImage: chat['image'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
