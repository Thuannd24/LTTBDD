import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_screen.dart';

class DoctorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            _buildHeaderCard(context),
            
            const SizedBox(height: 8),
            
            // Content Sections
            _buildInfoSection(
              title: 'Giới thiệu',
              icon: Icons.info_outline,
              content: '${doctor['name']} tốt nghiệp Trường Đại học Y Hà Nội và học tiếp Bác sĩ Nội trú Ngoại tại Trường Y Hà Nội – Bệnh viện Hữu Nghị - Việt Đức. Tu nghiệp sau đại học nhiều lần tại Cộng hòa Pháp với các vị trí khác nhau như: Bác sĩ Nội trú (FFI), Bác sĩ điều trị (Chef de Clinique) Phẫu thuật mạch máu; Phẫu thuật Tim bẩm sinh trẻ em; Phẫu thuật Tim người lớn...',
            ),
            
            _buildInfoSection(
              title: 'Chức vụ',
              icon: Icons.badge_outlined,
              content: 'Phó Chủ tịch Hội đồng chuyên ngành Tim mạch - Hệ thống Y tế Vinmec\nGiám đốc Bệnh viện Vinmec Ocean Park 2',
            ),
            
            _buildInfoSection(
              title: 'Nơi làm việc',
              icon: Icons.location_on_outlined,
              content: 'Bệnh viện Đa khoa Quốc tế Vinmec Ocean Park 2',
            ),
            
            _buildInfoSection(
              title: 'Dịch vụ chuyên sâu',
              icon: Icons.medical_services_outlined,
              isList: true,
              items: [
                'Khám, tư vấn và điều trị các bệnh lý về tim mạch',
                'Phẫu thuật mạch máu',
                'Phẫu thuật tim người lớn và trẻ em',
                'Phẫu thuật lồng ngực',
                'Phẫu thuật tuyến giáp',
              ],
            ),
            
            const SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
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
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Doctor Image with beautiful frame
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(doctor['image']),
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
                      child: const Text(
                        'GS. TS. BS',
                        style: TextStyle(
                          color: Color(0xFF38A3A5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['specialty'],
                      style: const TextStyle(
                        color: Color(0xFF38A3A5),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor['rating']} (120 Đánh giá)',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Kinh nghiệm', '25 Năm'),
              _buildStatItem('Bệnh nhân', '1000+'),
              _buildStatItem('Thành tích', 'Ưu tú'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF38A3A5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    String? content,
    bool isList = false,
    List<String>? items,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF38A3A5), size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A4A7C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isList && items != null)
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF4A4E69), height: 1.5),
                    ),
                  ),
                ],
              ),
            ))
          else
            Text(
              content ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4E69),
                height: 1.6,
              ),
            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giá khám dự kiến',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(doctor['price'] ?? 500000),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
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
                    MaterialPageRoute(builder: (context) => const BookingScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'ĐẶT LỊCH NGAY',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
