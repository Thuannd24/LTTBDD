import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import 'doctor_detail_screen.dart';

class DoctorListScreen extends StatefulWidget {
  final String? specialty;
  final bool isGeneralView;
  const DoctorListScreen({super.key, this.specialty, this.isGeneralView = false});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final List<Map<String, dynamic>> _allDoctors = [
    {
      'name': 'BS. Julianne Moore',
      'specialty': 'Tim mạch',
      'rating': 4.9,
      'reviews': 120,
      'price': 500000,
      'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
    },
    {
      'name': 'BS. Alan Cooper',
      'specialty': 'Thần kinh',
      'rating': 4.8,
      'reviews': 94,
      'price': 600000,
      'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
    },
    {
      'name': 'BS. Sarah Jenkins',
      'specialty': 'Nhi khoa',
      'rating': 5.0,
      'reviews': 205,
      'price': 450000,
      'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
    },
    {
      'name': 'BS. Elena Rodriguez',
      'specialty': 'Tim mạch',
      'rating': 4.7,
      'reviews': 80,
      'price': 550000,
      'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
    },
  ];

  late List<Map<String, dynamic>> _filteredDoctors;

  @override
  void initState() {
    super.initState();
    if (widget.specialty != null) {
      _filteredDoctors = _allDoctors.where((doc) => doc['specialty'] == widget.specialty).toList();
    } else {
      _filteredDoctors = _allDoctors;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isGeneralView ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.specialty ?? 'Danh sách bác sĩ',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ) : null,
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
                  hintText: AppStrings.searchDoctorHint,
                  icon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _filteredDoctors[index];
                return GestureDetector(
                  onTap: () {
                    if (widget.isGeneralView || !Navigator.canPop(context)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor)),
                      );
                    } else {
                      // Nếu đang ở luồng đặt lịch, trả kết quả về
                      Navigator.pop(context, doctor);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(doctor['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                doctor['specialty'],
                                style: const TextStyle(color: Color(0xFF38A3A5), fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${doctor['rating']} (${doctor['reviews']} Đánh giá)',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(doctor['price']),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                      ],
                    ),
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
