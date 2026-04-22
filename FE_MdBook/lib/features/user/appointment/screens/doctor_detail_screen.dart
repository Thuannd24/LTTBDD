import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/features/user/appointment/screens/booking_screen.dart';

class DoctorDetailScreen extends StatelessWidget {
  final DoctorProfile doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 8),
            _buildInfoSection(
              title: 'Giới thiệu',
              icon: Icons.info_outline,
              content: doctor.biography ?? 'Chưa có thông tin giới thiệu chi tiết cho bác sĩ này.',
            ),
            _buildInfoSection(
              title: 'Chức vụ',
              icon: Icons.badge_outlined,
              content: doctor.position ?? 'Chuyên gia y tế',
            ),
            _buildInfoSection(
              title: 'Nơi làm việc',
              icon: Icons.location_on_outlined,
              content: doctor.workLocation ?? 'Hệ thống y tế đối tác',
            ),
            _buildInfoSection(
              title: 'Dịch vụ chuyên sâu',
              icon: Icons.medical_services_outlined,
              content: doctor.services ?? 'Các dịch vụ khám chữa bệnh theo chuyên khoa.',
            ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: doctor.avatar != null && doctor.avatar!.isNotEmpty
                        ? NetworkImage(doctor.avatar!)
                        : const NetworkImage('https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: const Color(0xFFE0F2F1), width: 4),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doctor.degree ?? 'Bác sĩ',
                        style: const TextStyle(
                          color: Color(0xFF38A3A5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                    ),
                    Text(
                      doctor.position ?? 'Chuyên gia y tế',
                      style: const TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Kinh nghiệm', '${doctor.experienceYears} năm'),
              _buildStatItem('Bệnh nhân', '100+'),
              _buildStatItem('Trạng thái', doctor.status ?? 'Hoạt động'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38A3A5))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildInfoSection({required String title, required IconData icon, required String content}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF38A3A5), size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A4A7C))),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4E69), height: 1.6)),
          const Divider(height: 32, thickness: 1, color: Color(0xFFF5F5F5)),
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
