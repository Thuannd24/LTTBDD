import 'package:flutter/material.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  final String userId;
  final String? doctorId;
  final Future<void> Function()? onSaved;

  const DoctorProfileEditScreen({
    super.key,
    required this.userId,
    this.doctorId,
    this.onSaved,
  });

  @override
  State<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final DoctorService _doctorService = DoctorService();
  final SpecialtyService _specialtyService = SpecialtyService();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _isNew = false;
  bool _loadedFromLegacyPlaceholder = false;

  DoctorProfile? _profile;
  List<Specialty> _specialties = [];

  TextEditingController? _degreeCtrl;
  TextEditingController? _positionCtrl;
  TextEditingController? _workLocationCtrl;
  TextEditingController? _biographyCtrl;
  TextEditingController? _experienceCtrl;
  TextEditingController? _hourlyRateCtrl;
  TextEditingController? _servicesCtrl;
  TextEditingController? _qualificationCtrl;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didUpdateWidget(covariant DoctorProfileEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.doctorId != widget.doctorId) {
      _loadAll();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _degreeCtrl?.dispose();
    _positionCtrl?.dispose();
    _workLocationCtrl?.dispose();
    _biographyCtrl?.dispose();
    _experienceCtrl?.dispose();
    _hourlyRateCtrl?.dispose();
    _servicesCtrl?.dispose();
    _qualificationCtrl?.dispose();
  }

  void _bindControllers() {
    _disposeControllers();
    _degreeCtrl = TextEditingController(text: _profile?.degree ?? '');
    _positionCtrl = TextEditingController(text: _profile?.position ?? '');
    _workLocationCtrl = TextEditingController(text: _profile?.workLocation ?? '');
    _biographyCtrl = TextEditingController(text: _profile?.biography ?? '');
    _experienceCtrl = TextEditingController(text: (_profile?.experienceYears ?? 0).toString());
    _hourlyRateCtrl = TextEditingController(text: (_profile?.hourlyRate ?? 0).toString());
    _servicesCtrl = TextEditingController(text: _profile?.services ?? '');
    _qualificationCtrl = TextEditingController(text: _profile?.qualification ?? '');
  }

  Future<void> _loadAll() async {
    if (!mounted) {
      return;
    }

    setState(() => _loading = true);

    try {
      _specialties = await _specialtyService.fetchAll();
      _profile = await _resolveProfile();
      _bindControllers();
    } catch (e) {
      debugPrint('Load doctor data error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khong the tai du lieu ho so bac si')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<DoctorProfile> _resolveProfile() async {
    if (widget.userId.isEmpty) {
      _isNew = true;
      _loadedFromLegacyPlaceholder = false;
      return DoctorProfile(
        id: widget.doctorId ?? '',
        userId: '',
        specialtyIds: [],
        status: 'PENDING',
      );
    }

    try {
      final profile = await _doctorService.getByUserId(widget.userId);
      _isNew = false;
      _loadedFromLegacyPlaceholder = false;
      return profile;
    } catch (_) {
      if (widget.doctorId != null && widget.doctorId!.isNotEmpty && widget.doctorId != 'doctor_id') {
        try {
          final profile = await _doctorService.getById(widget.doctorId!);
          _isNew = false;
          _loadedFromLegacyPlaceholder = false;
          return profile;
        } catch (_) {
          // Fall through to legacy recovery/new creation.
        }
      }

      try {
        final allDoctors = await _doctorService.fetchAll();
        final legacyMatches = allDoctors.where((doctor) => doctor.userId == 'doctor_id').toList();
        if (legacyMatches.length == 1) {
          final legacy = legacyMatches.first;
          _isNew = false;
          _loadedFromLegacyPlaceholder = true;
          return DoctorProfile(
            id: legacy.id,
            userId: widget.userId,
            specialtyIds: List<String>.from(legacy.specialtyIds),
            experienceYears: legacy.experienceYears,
            hourlyRate: legacy.hourlyRate,
            degree: legacy.degree,
            position: legacy.position,
            workLocation: legacy.workLocation,
            biography: legacy.biography,
            services: legacy.services,
            qualification: legacy.qualification,
            status: legacy.status,
            firstName: legacy.firstName,
            lastName: legacy.lastName,
            avatar: legacy.avatar,
            createdAt: legacy.createdAt,
            updatedAt: legacy.updatedAt,
          );
        }
      } catch (_) {
        // Ignore legacy lookup failure and create a new local profile.
      }

      _isNew = true;
      _loadedFromLegacyPlaceholder = false;
      return DoctorProfile(
        id: widget.doctorId ?? '',
        userId: widget.userId,
        specialtyIds: [],
        status: 'PENDING',
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _profile == null) {
      return;
    }

    final payload = {
      'userId': widget.userId,
      'specialtyIds': _profile!.specialtyIds,
      'experienceYears': int.tryParse(_experienceCtrl!.text) ?? 0,
      'hourlyRate': double.tryParse(_hourlyRateCtrl!.text) ?? 0.0,
      'degree': _degreeCtrl!.text.trim(),
      'position': _positionCtrl!.text.trim(),
      'workLocation': _workLocationCtrl!.text.trim(),
      'biography': _biographyCtrl!.text.trim(),
      'qualification': _qualificationCtrl!.text.trim(),
      'services': _servicesCtrl!.text.trim(),
      'status': _profile!.status ?? 'PENDING',
    };

    try {
      if (_isNew || _profile!.id.isEmpty) {
        await _doctorService.create(payload);
      } else {
        await _doctorService.update(_profile!.id, payload);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _loadedFromLegacyPlaceholder
                ? 'Da lien ket lai ho so bac si voi tai khoan hien tai'
                : 'Luu ho so bac si thanh cong',
          ),
        ),
      );
      await _loadAll();
      await widget.onSaved?.call();
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Luu ho so bac si that bai')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(child: Text('Da xay ra loi khoi tao ho so'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadedFromLegacyPlaceholder)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD591)),
                ),
                child: const Text(
                  'Phat hien ho so cu dang gan sai tai khoan. Bam luu mot lan de lien ket lai dung tai khoan hien tai.',
                  style: TextStyle(color: Color(0xFF8C6D1F), fontWeight: FontWeight.w600),
                ),
              ),
            Text(
              _isNew ? 'Khoi tao ho so bac si' : 'Ho so chuyen mon',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _isNew
                  ? 'Hoan tat thong tin de mo khoa lich lam viec va cho benh nhan dat lich.'
                  : 'Cap nhat thong tin de benh nhan hieu ro hon ve ban.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _degreeCtrl!,
                    'Hoc ham / Bang cap',
                    Icons.school_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    _experienceCtrl!,
                    'Nam kinh nghiem',
                    Icons.history_rounded,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _positionCtrl!,
                    'Chuc vu hien tai',
                    Icons.work_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    _hourlyRateCtrl!,
                    'Gia kham / gio (VND)',
                    Icons.payments_rounded,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            _buildTextField(_workLocationCtrl!, 'Noi cong tac', Icons.location_on_rounded),
            _buildTextField(_biographyCtrl!, 'Gioi thieu ban than', Icons.person_search_rounded, maxLines: 3),
            _buildTextField(_servicesCtrl!, 'Dich vu cung cap', Icons.medical_information_rounded, maxLines: 2),
            _buildTextField(_qualificationCtrl!, 'Chung chi / Chuyen mon', Icons.verified_rounded, maxLines: 2),
            const SizedBox(height: 24),
            const Text(
              'Chuyen khoa dam nhan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                children: _specialties.map((specialty) {
                  final selected = _profile!.specialtyIds.contains(specialty.id);
                  return FilterChip(
                    label: Text(specialty.name),
                    selected: selected,
                    selectedColor: const Color(0xFF38A3A5).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF38A3A5),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _profile!.specialtyIds.add(specialty.id);
                        } else {
                          _profile!.specialtyIds.remove(specialty.id);
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
                child: Text(
                  _isNew ? 'Luu ho so moi' : 'Cap nhat ho so',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF38A3A5), size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF38A3A5), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Vui long nhap thong tin' : null,
          ),
        ],
      ),
    );
  }
}
