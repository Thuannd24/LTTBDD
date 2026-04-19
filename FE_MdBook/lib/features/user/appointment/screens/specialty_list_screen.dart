import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import 'specialty_detail_screen.dart';

class SpecialtyListScreen extends StatefulWidget {
  final bool isGeneralView;
  const SpecialtyListScreen({super.key, this.isGeneralView = false});

  @override
  State<SpecialtyListScreen> createState() => _SpecialtyListScreenState();
}

class _SpecialtyListScreenState extends State<SpecialtyListScreen> {
  final List<Map<String, dynamic>> _specialties = [
    {'name': 'Tim mạch', 'icon': Icons.favorite, 'count': 12},
    {'name': 'Nhi khoa', 'icon': Icons.child_care, 'count': 8},
    {'name': 'Thần kinh', 'icon': Icons.psychology, 'count': 15},
    {'name': 'Nhãn khoa', 'icon': Icons.visibility, 'count': 6},
    {'name': 'Da liễu', 'icon': Icons.spa, 'count': 10},
    {'name': 'Sản phụ khoa', 'icon': Icons.pregnant_woman, 'count': 14},
    {'name': 'Răng Hàm Mặt', 'icon': Icons.medical_services, 'count': 9},
  ];

  @override
  Widget build(BuildContext context) {
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
          'Danh sách chuyên khoa',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.searchSpecialtyHint,
                  icon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _specialties.length,
              itemBuilder: (context, index) {
                final specialty = _specialties[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(specialty['icon'], color: const Color(0xFF38A3A5)),
                    ),
                    title: Text(
                      specialty['name'], 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))
                    ),
                    subtitle: Text('${specialty['count']} bác sĩ chuyên khoa'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      if (widget.isGeneralView) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpecialtyDetailScreen(specialtyName: specialty['name']),
                          ),
                        );
                      } else {
                        // Trả về kết quả cho màn hình đặt lịch
                        Navigator.pop(context, specialty['name']);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
