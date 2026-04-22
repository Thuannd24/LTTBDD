import 'package:flutter/material.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'doctor_list_screen.dart';

class SpecialtyDetailScreen extends StatelessWidget {
  final Specialty specialty;

  const SpecialtyDetailScreen({super.key, required this.specialty});

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
            specialty.name,
            style: const TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: false,
            labelColor: Color(0xFF38A3A5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF38A3A5),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: EdgeInsets.zero,
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
                DoctorListScreen(specialty: specialty.name, specialtyId: specialty.id, isGeneralView: false),
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
          if (specialty.image != null && specialty.image!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(specialty.image!),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
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
          Text(
            specialty.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A4A7C)),
          ),
          const SizedBox(height: 16),
          Text(
            specialty.overview ?? 'Đang cập nhật...',
            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildServices() {
    final services = (specialty.services ?? '').split('\n').where((s) => s.trim().isNotEmpty).toList();

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
          Text(
            specialty.name,
            style: const TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (services.isEmpty) 
            const Center(child: Text('Đang cập nhật...'))
          else
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
    final tech = (specialty.technology ?? '').split('\n').where((s) => s.trim().isNotEmpty).toList();

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
          if (tech.isEmpty)
             const Center(child: Text('Đang cập nhật...'))
          else
            GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
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
                    const Icon(Icons.settings_suggest_rounded, color: Color(0xFF38A3A5), size: 28),
                    const SizedBox(height: 8),
                    Text(
                      tech[index],
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A4E69)),
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
