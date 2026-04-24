import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/features/user/appointment/screens/booking_screen.dart';
import 'package:tbdd/features/chat/data/chat_api_service.dart';
import 'package:tbdd/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/core/models/user_model.dart';

class DoctorDetailScreen extends StatelessWidget {
  final DoctorProfile doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  void _startChat(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF38A3A5))),
    );

    try {
      final chatApi = ChatApiService();
      final conversation = await chatApi.createOrGetConversation(doctor.userId);
      
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        if (conversation != null) {
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getString('user_id') ?? '';
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                conversationId: conversation['id'],
                otherUserId: doctor.userId,
                otherUserRole: 'ROLE_DOCTOR',
                otherUserName: doctor.fullName,
                otherUserImage: doctor.avatar,
                currentUserId: currentUserId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tạo cuộc trò chuyện')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hồ sơ chuyên gia',
          style: TextStyle(color: Color(0xFF2D3142), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF38A3A5)),
            onPressed: () => _startChat(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildDetailedInfoSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: doctor.avatar != null && doctor.avatar!.isNotEmpty
                        ? NetworkImage(doctor.avatar!)
                        : const NetworkImage('https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38A3A5).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF38A3A5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<UserProfile?>(
            future: AuthService().getUserInfo(doctor.userId),
            builder: (context, snapshot) {
              String name = doctor.fullName;
              if (snapshot.hasData && snapshot.data != null) {
                final p = snapshot.data!;
                name = '${p.firstName ?? ""} ${p.lastName ?? ""}'.trim();
                if (name.isEmpty) name = p.username;
              }
              return Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doctor.degree ?? "Bác sĩ"} • ${doctor.position ?? "Chuyên gia y tế"}',
                    style: const TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildModernStatItem('Kinh nghiệm', '${doctor.experienceYears} năm', Icons.history_edu),
              _buildModernStatItem('Bệnh nhân', '500+', Icons.people_outline),
              _buildModernStatItem('Đánh giá', '4.9', Icons.star_border),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF38A3A5), size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard(
            'Giới thiệu chuyên gia',
            doctor.biography ?? 'Bác sĩ ${doctor.fullName} là chuyên gia giàu kinh nghiệm trong lĩnh vực y tế, luôn tận tâm với sự nghiệp chăm sóc sức khỏe cộng đồng.',
            Icons.person_pin_outlined,
            const Color(0xFFE0F2F1),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Dịch vụ chuyên biệt',
            doctor.services ?? 'Thực hiện khám và điều trị các bệnh lý theo chuyên khoa chuyên sâu, tư vấn phác đồ điều trị cá thể hóa.',
            Icons.medical_services_outlined,
            const Color(0xFFE1F5FE),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Nơi làm việc & Công tác',
            doctor.workLocation ?? 'Hiện đang công tác tại hệ thống bệnh viện đa khoa quốc tế, trung tâm can thiệp y tế kỹ thuật cao.',
            Icons.location_on_outlined,
            const Color(0xFFFFF3E0),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF38A3A5), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Giá khám dự kiến', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                doctor.hourlyRate != null
                    ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(doctor.hourlyRate)
                    : 'Liên hệ',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookingScreen(initialDoctor: doctor)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('ĐẶT LỊCH NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
