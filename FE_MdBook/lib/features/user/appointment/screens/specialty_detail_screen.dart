import 'package:flutter/material.dart';
import 'doctor_list_screen.dart';

class SpecialtyDetailScreen extends StatelessWidget {
  final String specialtyName;
  final String specialtyId;

  const SpecialtyDetailScreen({super.key, required this.specialtyName, required this.specialtyId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            specialtyName,
            style: const TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: false, // Giữ cố định để không bị lệch
            labelColor: Color(0xFF38A3A5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF38A3A5),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: EdgeInsets.zero, // Loại bỏ khoảng cách giữa các tab để lấy tối đa không gian
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Dịch vụ'),
              Tab(text: 'Công nghệ'),
              Tab(text: 'Bác sĩ'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            child: TabBarView(
              children: [
                _buildOverview(),
                _buildServices(),
                _buildTechnology(),
                DoctorListScreen(specialty: specialtyName, isGeneralView: true), // Thêm isGeneralView: true
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'GIỚI THIỆU CHUNG',
              style: TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trung tâm Tim mạch Vinmec',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A4A7C)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trung tâm Tim mạch Vinmec hiện là một trong số ít các Trung tâm tim mạch có quy mô lớn và uy tín ở Việt Nam, được trang bị các phương tiện hiện đại, tuân thủ các quy trình thăm khám bệnh chuyên nghiệp, được cấp chứng chỉ quản lý, chăm sóc bệnh mạch vành và suy tim theo tiêu chuẩn của trường môn tim mạch Hoa Kỳ (ACC).',
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chuyên khoa Tim mạch của Vinmec cung cấp dịch vụ điều trị, chăm sóc bệnh lý tim mạch cho bệnh nhân trong nước và quốc tế theo các tiêu chuẩn quốc tế. Tùy theo tình trạng bệnh lý, người bệnh sẽ được thăm khám và điều trị tại các đơn vị tim mạch chuyên sâu: Nội tim mạch, can thiệp tim mạch và ngoại tim mạch.',
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nhằm đạt kết quả tối ưu cho từng người bệnh, các bác sĩ Vinmec điều trị bệnh lý tim mạch theo phương thức cá thể hóa bằng các phương pháp nội khoa, phẫu thuật, thông tim can thiệp và nhiều kỹ thuật cao cấp khác.',
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildServices() {
    final services = [
      'Điều trị suy tim chuyên sâu',
      'Điều trị sau nhồi máu cơ tim',
      'Điều trị tăng huyết áp phức tạp',
      'Điều trị các rối loạn nhịp dai dẳng (rung nhĩ, ngoại tâm thu)',
      'Điều trị các bệnh tim mạch khác',
      'Quản lý bệnh nhân ngoại trú: Các bệnh nhân có tiền sử tăng huyết áp, bệnh mạch vành, nhồi máu cơ tim.',
      'Điều trị và quản lý các bệnh lý mạch máu: Bệnh động mạch chi trên - chi dưới, mạch cảnh, bệnh lý suy tĩnh mạch chi dưới, huyết khối tĩnh mạch, bệnh lý mạch tạng.',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dịch vụ Chẩn đoán & Điều trị',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A4A7C)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chuyên khoa Nội tim mạch',
            style: TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ...services.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF38A3A5), size: 20),
                const SizedBox(width: 16),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4E69), height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTechnology() {
    final tech = [
      'Máy điện tim kỹ thuật số 12 cần GE',
      'Máy Holter điện tim 24h và Holter huyết áp 24h',
      'Máy siêu âm tim 3D, 4D GE ViViD95',
      'Bàn nghiêng và máy gắng sức xe đạp',
      'Máy gắng sức thảm chạy Welch Allyn',
      'Các hệ thống monitor theo dõi trung tâm',
      'Máy chụp mạch ANGIO 2 bình diện SIEMENS',
      'Máy siêu âm trong lòng mạch IVUS and FFR',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trang thiết bị hiện đại',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A4A7C)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ngang tầm với các bệnh viện uy tín trên thế giới.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: tech.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_suggest_rounded, color: Color(0xFF38A3A5), size: 24),
                    const SizedBox(height: 8),
                    Text(
                      tech[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A4E69)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
