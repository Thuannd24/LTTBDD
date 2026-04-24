import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';
import 'package:tbdd/core/models/exam_package_model.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/features/doctor/data/doctor_schedule_service.dart';
import 'package:tbdd/features/user/appointment/data/exam_package_service.dart';
import 'package:tbdd/features/user/appointment/screens/checkout_screen.dart';
import 'package:tbdd/features/user/appointment/screens/doctor_list_screen.dart';

class BookingScreen extends StatefulWidget {
  final DoctorProfile? initialDoctor;

  const BookingScreen({super.key, this.initialDoctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AuthService _authService = AuthService();
  final ExamPackageService _examPackageService = ExamPackageService();
  final DoctorScheduleService _doctorScheduleService = DoctorScheduleService();
  final TextEditingController _reasonController = TextEditingController();

  UserProfile? _currentUser;
  DoctorProfile? _selectedDoctor;
  ExamPackageModel? _selectedPackage;
  DoctorScheduleModel? _selectedSchedule;
  List<ExamPackageModel> _packages = [];
  List<DoctorScheduleModel> _schedules = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _loadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _selectedDoctor = widget.initialDoctor;
    _loadInitialData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _hydrateSelectedDoctor() async {
    final selectedDoctor = _selectedDoctor;
    if (selectedDoctor == null || selectedDoctor.userId.isEmpty) {
      return;
    }

    final profile = await _authService.getUserInfo(selectedDoctor.userId);
    if (!mounted || _selectedDoctor?.id != selectedDoctor.id || profile == null) {
      return;
    }

    setState(() {
      _selectedDoctor!
        ..firstName = profile.firstName
        ..lastName = profile.lastName
        ..avatar = profile.avatar ?? _selectedDoctor!.avatar;
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _authService.getMyInfo(),
        _examPackageService.fetchAll(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = results[0] as UserProfile?;
        _packages = results[1] as List<ExamPackageModel>;
        if (_packages.isNotEmpty) {
          _selectedPackage = _packages.first;
        }
        _loading = false;
      });

      if (_selectedDoctor != null) {
        await _hydrateSelectedDoctor();
        await _loadSchedules();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadSchedules() async {
    if (_selectedDoctor == null) {
      return;
    }

    setState(() {
      _loadingSchedules = true;
      _selectedSchedule = null;
    });

    try {
      final schedules = await _doctorScheduleService.getAvailableSchedules(
        doctorId: _selectedDoctor!.id,
        date: _selectedDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _schedules = schedules;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _schedules = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSchedules = false);
      }
    }
  }

  Future<void> _pickDoctor() async {
    final doctor = await Navigator.push<DoctorProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorListScreen(selectionMode: true),
      ),
    );

    if (doctor == null) {
      return;
    }

    setState(() {
      _selectedDoctor = doctor;
    });
    await _hydrateSelectedDoctor();
    await _loadSchedules();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
    await _loadSchedules();
  }

  void _continueToCheckout() {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bác sĩ')),
      );
      return;
    }
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn gói khám')),
      );
      return;
    }
    if (_selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khung giờ khám')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          patient: _currentUser,
          doctor: _selectedDoctor!,
          packageData: _selectedPackage!,
          selectedSchedule: _selectedSchedule!,
          reason: _reasonController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFF38A3A5),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Đăng ký lịch khám',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C8385), Color(0xFF57BBBF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF38A3A5),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_currentUser?.fullName ?? _currentUser?.username ?? 'Bệnh nhân', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(_currentUser?.email ?? 'Chưa có email', 
                                  style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(thickness: 1, height: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('1. Chọn bác sĩ & Gói khám',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                  const SizedBox(height: 20),
                  _buildSelectionTile(
                    icon: Icons.person_search_outlined,
                    label: 'Bác sĩ chuyên khoa',
                    value: _selectedDoctor?.fullName ?? 'Nhấn để chọn bác sĩ',
                    onTap: _pickDoctor,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExamPackageModel>(
                    value: _selectedPackage,
                    decoration: InputDecoration(
                      labelText: 'Gói khám dịch vụ',
                      prefixIcon: const Icon(Icons.medical_services_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _packages
                        .map(
                          (pkg) => DropdownMenuItem<ExamPackageModel>(
                            value: pkg,
                            child: Text(pkg.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPackage = value),
                  ),
                  const SizedBox(height: 24),
                  const Text('2. Chọn thời gian khám',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  _buildSelectionTile(
                    icon: Icons.calendar_month_outlined,
                    label: 'Ngày khám',
                    value: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(_selectedDate),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('3. Chọn giờ khám còn trống',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  if (_selectedDoctor == null)
                    _buildEmptyState('Vui lòng chọn bác sĩ để xem lịch')
                  else if (_loadingSchedules)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Color(0xFF38A3A5)),
                    ))
                  else if (_schedules.isEmpty)
                    _buildEmptyState('Rất tiếc, ngày này bác sĩ không có lịch trống')
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _schedules.map((schedule) {
                        final isSelected = _selectedSchedule?.id == schedule.id;
                        final label =
                            '${DateFormat('HH:mm').format(schedule.startTime)}';
                        return ChoiceChip(
                          label: Container(
                            width: 70,
                            alignment: Alignment.center,
                            child: Text(label, style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedSchedule = schedule),
                          selectedColor: const Color(0xFF38A3A5),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF475569)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF38A3A5) : Colors.transparent,
                            ),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const Divider(thickness: 1, height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('4. Lý do thăm khám (không bắt buộc)',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhập triệu chứng hoặc nhu cầu của bạn...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continueToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A3A5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'ĐẶT HẸN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: const Color(0xFFCBD5E1), size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF38A3A5), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}
