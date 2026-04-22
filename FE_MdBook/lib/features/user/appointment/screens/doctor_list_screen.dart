import 'package:flutter/material.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/constants/app_strings.dart';
import 'package:tbdd/features/user/appointment/screens/doctor_detail_screen.dart';
import 'package:tbdd/features/user/widgets/doctor_card.dart';

class DoctorListScreen extends StatefulWidget {
  final String? specialty;
  final String? specialtyId;
  final String? searchQuery;
  final bool isGeneralView;
  const DoctorListScreen({super.key, this.specialty, this.specialtyId, this.searchQuery, this.isGeneralView = false});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final DoctorService _doctorService = DoctorService();
  final SpecialtyService _specialtyService = SpecialtyService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<DoctorProfile> _allDoctors = [];
  List<DoctorProfile> _filteredDoctors = [];
  List<Specialty> _specialties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.searchQuery ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _doctorService.fetchAll(),
        _specialtyService.fetchAll(),
      ]);
      setState(() {
        _allDoctors = results[0] as List<DoctorProfile>;
        _specialties = results[1] as List<Specialty>;
        _filterDoctors(_searchCtrl.text);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      final q = query.toLowerCase();
      _filteredDoctors = _allDoctors.where((doc) {
        final matchesSpecialtyId = widget.specialtyId == null || (doc.specialtyIds.contains(widget.specialtyId));
        
        // Find specialty names for this doctor
        final docSpecialtyNames = _specialties
            .where((s) => doc.specialtyIds.contains(s.id))
            .map((s) => s.name.toLowerCase());

        final matchesSearch = q.isEmpty || 
          (doc.fullName.toLowerCase().contains(q)) ||
          (doc.position?.toLowerCase().contains(q) ?? false) ||
          (doc.degree?.toLowerCase().contains(q) ?? false) ||
          (docSpecialtyNames.any((name) => name.contains(q)));

        return matchesSpecialtyId && matchesSearch;
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DoctorCard(
                      doctor: doctor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor)),
                        );
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
