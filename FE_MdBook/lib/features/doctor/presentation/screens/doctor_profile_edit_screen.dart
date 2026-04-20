import 'package:flutter/material.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileEditScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final DoctorService _doctorService = DoctorService();
  final SpecialtyService _specialtyService = SpecialtyService();

  bool _loading = true;
  DoctorProfile? _profile;
  List<Specialty> _specialties = [];
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _degreeCtrl;
  late TextEditingController _positionCtrl;
  late TextEditingController _workLocationCtrl;
  late TextEditingController _biographyCtrl;
  late TextEditingController _experienceCtrl;
  late TextEditingController _hourlyRateCtrl;
  late TextEditingController _servicesCtrl;
  late TextEditingController _qualificationCtrl;

  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final specResult = await _specialtyService.fetchAll();
      _specialties = specResult;

      try {
        final profileResult = await _doctorService.getByUserId(widget.doctorId);
        _profile = profileResult;
        _isNew = false;
      } catch (e) {
        debugPrint('Profile not found, creating a new local instance: $e');
        _profile = DoctorProfile(
          id: '',
          userId: widget.doctorId,
          specialtyIds: [],
          status: 'PENDING',
        );
        _isNew = true;
      }

      _degreeCtrl = TextEditingController(text: _profile?.degree ?? '');
      _positionCtrl = TextEditingController(text: _profile?.position ?? '');
      _workLocationCtrl = TextEditingController(text: _profile?.workLocation ?? '');
      _biographyCtrl = TextEditingController(text: _profile?.biography ?? '');
      _experienceCtrl = TextEditingController(text: _profile?.experienceYears.toString() ?? '0');
      _hourlyRateCtrl = TextEditingController(text: _profile?.hourlyRate?.toString() ?? '0');
      _servicesCtrl = TextEditingController(text: _profile?.services ?? '');
      _qualificationCtrl = TextEditingController(text: _profile?.qualification ?? '');

    } catch (e) {
      debugPrint('Load doctor data error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tải dữ liệu')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final payload = {
      'userId': widget.doctorId,
      'specialtyIds': _profile!.specialtyIds,
      'experienceYears': int.tryParse(_experienceCtrl.text) ?? 0,
      'hourlyRate': double.tryParse(_hourlyRateCtrl.text) ?? 0.0,
      'degree': _degreeCtrl.text,
      'position': _positionCtrl.text,
      'workLocation': _workLocationCtrl.text,
      'biography': _biographyCtrl.text,
      'qualification': _qualificationCtrl.text,
      'services': _servicesCtrl.text,
      'status': _profile!.status ?? 'PENDING',
    };

    try {
      if (_isNew) {
        await _doctorService.create(payload);
      } else {
        await _doctorService.update(_profile!.id, payload);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu hồ sơ thành công')));
      _loadAll(); // Reload to get the generated ID
    } catch (e) {
      debugPrint('Save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu hồ sơ thất bại')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_profile == null) return const Center(child: Text('Đã xảy ra lỗi khởi tạo'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isNew ? 'Khởi tạo hồ sơ bác sĩ' : 'Hồ sơ chuyên môn', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_isNew ? 'Chào mừng! Hãy hoàn tất hồ sơ để bắt đầu hành nghề.' : 'Cập nhật thông tin để bệnh nhân hiểu rõ hơn về bạn', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(child: _buildTextField(_degreeCtrl, 'Học hàm / Bằng cấp', Icons.school_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_experienceCtrl, 'Năm kinh nghiệm', Icons.history_rounded, isNumber: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField(_positionCtrl, 'Chức vụ hiện tại', Icons.work_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_hourlyRateCtrl, 'Giá khám / giờ (VND)', Icons.payments_rounded, isNumber: true)),
              ],
            ),
            _buildTextField(_workLocationCtrl, 'Nơi công tác', Icons.location_on_rounded),
            _buildTextField(_biographyCtrl, 'Tiểu sử / Giới thiệu bản thân', Icons.person_search_rounded, maxLines: 3),
            _buildTextField(_servicesCtrl, 'Các dịch vụ cung cấp', Icons.medical_information_rounded, maxLines: 2),
            _buildTextField(_qualificationCtrl, 'Chứng chỉ / Chuyên môn', Icons.verified_rounded, maxLines: 2),
            
            const SizedBox(height: 24),
            const Text('Chuyên khoa đảm nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _specialties.map((s) {
                  final selected = _profile!.specialtyIds.contains(s.id);
                  return FilterChip(
                    label: Text(s.name),
                    selected: selected,
                    selectedColor: const Color(0xFF38A3A5).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF38A3A5),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _profile!.specialtyIds.add(s.id);
                        } else {
                          _profile!.specialtyIds.remove(s.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(_isNew ? 'LƯU HỒ SƠ MỚI' : 'CẬP NHẬT HỒ SƠ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF38A3A5), size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38A3A5), width: 2)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập thông tin' : null,
          ),
        ],
      ),
    );
  }
}
