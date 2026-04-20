import 'package:flutter/material.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/constants/app_strings.dart';
import 'package:tbdd/features/user/appointment/screens/doctor_detail_screen.dart';

class DoctorListScreen extends StatefulWidget {
  final String? specialty;
  final String? searchQuery;
  final bool isGeneralView;
  const DoctorListScreen({super.key, this.specialty, this.searchQuery, this.isGeneralView = false});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<DoctorProfile> _allDoctors = [];
  List<DoctorProfile> _filteredDoctors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.searchQuery ?? '';
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _doctorService.fetchAll();
      setState(() {
        _allDoctors = doctors;
        _filterDoctors(_searchCtrl.text);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      _filteredDoctors = _allDoctors.where((doc) {
        final matchesSpecialty = widget.specialty == null || (doc.specialtyIds.contains(widget.specialty));
        final matchesSearch = query.isEmpty || 
          (doc.userId.toLowerCase().contains(query.toLowerCase())) ||
          (doc.position?.toLowerCase().contains(query.toLowerCase()) ?? false);
        return matchesSpecialty && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isGeneralView ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(widget.specialty ?? 'Danh sách bác sĩ'),
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
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filterDoctors,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchDoctorHint,
                  icon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_filteredDoctors.isEmpty)
            const Expanded(child: Center(child: Text('Không tìm thấy bác sĩ nào')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = _filteredDoctors[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor)),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: NetworkImage('https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg'),
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
                                  doctor.degree ?? 'Bác sĩ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  doctor.userId, // Using userId as name for now
                                  style: const TextStyle(color: Color(0xFF38A3A5), fontSize: 13),
                                ),
                                Text(
                                  'Kinh nghiệm: ${doctor.experienceYears} năm',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                if (doctor.hourlyRate != null)
                                   Text(
                                    '${doctor.hourlyRate!.toInt()} đ',
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
