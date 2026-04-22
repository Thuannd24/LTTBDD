import 'package:flutter/material.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/core/constants/app_strings.dart';
import 'package:tbdd/features/user/appointment/screens/specialty_detail_screen.dart';

class SpecialtyListScreen extends StatefulWidget {
  final bool isGeneralView;
  const SpecialtyListScreen({super.key, this.isGeneralView = false});

  @override
  State<SpecialtyListScreen> createState() => _SpecialtyListScreenState();
}

class _SpecialtyListScreenState extends State<SpecialtyListScreen> {
  final SpecialtyService _specialtyService = SpecialtyService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Specialty> _allSpecialties = [];
  List<Specialty> _filteredSpecialties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final list = await _specialtyService.fetchAll();
      setState(() {
        _allSpecialties = list;
        _filteredSpecialties = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(String q) {
    setState(() {
      _filteredSpecialties = _allSpecialties.where((s) => s.name.toLowerCase().contains(q.toLowerCase())).toList();
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
        title: const Text('Danh sách chuyên khoa'),
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
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchSpecialtyHint,
                  icon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_filteredSpecialties.isEmpty)
            const Expanded(child: Center(child: Text('Không tìm thấy chuyên khoa nào')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSpecialties.length,
                itemBuilder: (context, index) {
                  final s = _filteredSpecialties[index];
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
                          color: const Color(0xFF38A3A5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: Color(0xFF38A3A5)),
                      ),
                      title: Text(
                        s.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))
                      ),
                      subtitle: const Text('Bác sĩ chuyên khoa'),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        if (widget.isGeneralView) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpecialtyDetailScreen(specialty: s),
                            ),
                          );
                        } else {
                          Navigator.pop(context, s);
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
