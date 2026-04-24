import 'package:flutter/material.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/features/user/appointment/screens/doctor_detail_screen.dart';
import 'package:tbdd/features/user/appointment/screens/specialty_detail_screen.dart';
import 'package:tbdd/features/user/widgets/doctor_card.dart';

class GlobalSearchScreen extends StatefulWidget {
  final String initialQuery;
  const GlobalSearchScreen({super.key, this.initialQuery = ''});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final SpecialtyService _specialtyService = SpecialtyService();
  final DoctorService _doctorService = DoctorService();

  List<DoctorProfile> _allDoctors = [];
  List<Specialty> _allSpecialties = [];
  
  List<DoctorProfile> _matchedDoctors = [];
  List<Specialty> _matchedSpecialties = [];
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery;
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
        _allSpecialties = results[1] as List<Specialty>;
        _performSearch(_searchCtrl.text);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _matchedDoctors = [];
        _matchedSpecialties = [];
      });
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _matchedSpecialties = _allSpecialties.where((s) => 
        s.name.toLowerCase().contains(q) || 
        (s.overview?.toLowerCase().contains(q) ?? false)
      ).toList();

      _matchedDoctors = _allDoctors.where((doc) {
        final matchesName = doc.fullName.toLowerCase().contains(q);
        final matchesDegree = doc.degree?.toLowerCase().contains(q) ?? false;
        final matchesPosition = doc.position?.toLowerCase().contains(q) ?? false;
        
        // Search in doctor's specialties too
        final docSpecialties = _allSpecialties.where((s) => doc.specialtyIds.contains(s.id));
        final matchesSpecialty = docSpecialties.any((s) => s.name.toLowerCase().contains(q));

        return matchesName || matchesDegree || matchesPosition || matchesSpecialty;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: widget.initialQuery.isEmpty,
            onChanged: _performSearch,
            decoration: const InputDecoration(
              hintText: 'Tìm bác sĩ, chuyên khoa...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _searchCtrl.text.isEmpty
          ? _buildEmptyState()
          : _matchedDoctors.isEmpty && _matchedSpecialties.isEmpty
            ? const Center(child: Text('Không tìm thấy kết quả nào'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_matchedSpecialties.isNotEmpty) ...[
                      const Text('Chuyên khoa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._matchedSpecialties.map((s) => _buildSpecialtyTile(s)),
                      const SizedBox(height: 24),
                    ],
                    if (_matchedDoctors.isNotEmpty) ...[
                      const Text('Bác sĩ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._matchedDoctors.map((doc) => DoctorCard(
                        doctor: doc,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doc))
                        ),
                      )),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nhập từ khóa để tìm kiếm', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSpecialtyTile(Specialty s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF38A3A5).withOpacity(0.1),
          backgroundImage: s.image != null ? NetworkImage(s.image!) : null,
          child: s.image == null ? const Icon(Icons.medical_services, color: Color(0xFF38A3A5)) : null,
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Chuyên khoa y tế'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SpecialtyDetailScreen(specialty: s))
        ),
      ),
    );
  }
}
