import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/appointment_request_model.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/exam_package_model.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/features/user/appointment/data/appointment_service.dart';
import 'package:tbdd/features/user/appointment/data/exam_package_service.dart';
import 'package:tbdd/features/user/appointment/screens/booking_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final ExamPackageService _examPackageService = ExamPackageService();

  List<AppointmentRequestModel> _requests = [];
  Map<String, DoctorProfile> _doctorById = {};
  Map<String, ExamPackageModel> _packageById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _appointmentService.getMyAppointmentRequests(),
        _doctorService.fetchAll(),
        _examPackageService.fetchAll(),
      ]);

      final doctors = results[1] as List<DoctorProfile>;
      final packages = results[2] as List<ExamPackageModel>;

      if (!mounted) {
        return;
      }

      setState(() {
        _requests = results[0] as List<AppointmentRequestModel>;
        _doctorById = {for (final doctor in doctors) doctor.id: doctor};
        _packageById = {for (final pkg in packages) pkg.id: pkg};
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancelConfirmedAppointment(AppointmentRequestModel request) async {
    if (request.appointmentId == null) {
      return;
    }

    try {
      await _appointmentService.cancelAppointment(
        appointmentId: request.appointmentId!,
        reason: 'Bệnh nhân yêu cầu hủy lịch',
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy lịch hẹn')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể hủy lịch: $e')),
        );
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING_ASSIGNMENT':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'REJECTED':
        return 'Đã từ chối';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING_ASSIGNMENT':
        return Colors.orange;
      case 'CONFIRMED':
        return const Color(0xFF38A3A5);
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF38A3A5), Color(0xFF80CBC4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch hẹn',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BookingScreen()),
                        ).then((_) => _loadData());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Color(0xFF38A3A5), size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _requests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _requests.length,
                            itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Center(
          child: Text(
            'Hiện tại bạn chưa có yêu cầu đặt lịch nào',
            style: TextStyle(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 160,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingScreen()),
                ).then((_) => _loadData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A3A5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: const Text('ĐẶT HẸN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(AppointmentRequestModel request) {
    final doctor = _doctorById[request.doctorId];
    final packageData = _packageById[request.packageId];
    final createdAt = request.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    packageData?.name ?? request.packageId,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(request.status),
                    style: TextStyle(color: _statusColor(request.status), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Bác sĩ: ${doctor?.fullName ?? request.doctorId}'),
            Text('Schedule ID: ${request.doctorScheduleId}'),
            if (createdAt != null) Text('Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}'),
            if (request.note != null && request.note!.isNotEmpty) Text('Ghi chú: ${request.note}'),
            if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty)
              Text(
                'Lý do từ chối: ${request.rejectionReason}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            if (request.appointmentId != null) Text('Mã lịch hẹn: ${request.appointmentId}'),
            const SizedBox(height: 16),
            if (request.status == 'CONFIRMED' && request.appointmentId != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelConfirmedAppointment(request),
                  child: const Text('Hủy lịch'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
