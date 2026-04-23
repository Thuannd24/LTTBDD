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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đặt lịch hẹn',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin người đặt lịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person_outline, _currentUser?.fullName ?? _currentUser?.username ?? 'Người dùng'),
                  _buildInfoRow(Icons.email_outlined, _currentUser?.email ?? 'Chưa có email'),
                ],
              ),
            ),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin đặt hẹn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildSelectionTile(
                    icon: Icons.person_outline,
                    label: 'Bác sĩ',
                    value: _selectedDoctor?.fullName ?? 'Chọn bác sĩ',
                    onTap: _pickDoctor,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExamPackageModel>(
                    value: _selectedPackage,
                    decoration: const InputDecoration(
                      labelText: 'Gói khám',
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày khám mong muốn'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Khung giờ bác sĩ còn trống', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_selectedDoctor == null)
                    const Text('Chọn bác sĩ để xem lịch trống')
                  else if (_loadingSchedules)
                    const Center(child: CircularProgressIndicator())
                  else if (_schedules.isEmpty)
                    const Text('Không có lịch trống cho ngày này')
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _schedules.map((schedule) {
                        final isSelected = _selectedSchedule?.id == schedule.id;
                        final label =
                            '${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)}';
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedSchedule = schedule),
                          selectedColor: const Color(0xFF38A3A5),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Lý do khám',
                  hintText: 'Mô tả ngắn triệu chứng hoặc nhu cầu thăm khám',
                  border: OutlineInputBorder(),
                ),
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

  Widget _buildSelectionTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(child: Text(value)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
