import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/appointment_request_model.dart';
import 'package:tbdd/core/models/exam_package_model.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/features/user/appointment/data/appointment_service.dart';
import 'package:tbdd/features/user/appointment/data/exam_package_service.dart';
import 'package:tbdd/features/user/appointment/screens/booking_screen.dart';
import 'package:tbdd/features/user/appointment/screens/patient_medical_record_view_screen.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:tbdd/core/utils/notification_manager.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final ExamPackageService _examPackageService = ExamPackageService();

  late TabController _tabController;

  List<AppointmentRequestModel> _requests = [];
  Map<String, DoctorProfile> _doctorById = {};
  Map<String, ExamPackageModel> _packageById = {};
  bool _loading = true;

  static const _teal = Color(0xFF38A3A5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _appointmentService.getMyAppointmentRequests(),
        _doctorService.fetchAll(),
        _examPackageService.fetchAll(),
      ]);

      final doctors = results[1] as List<DoctorProfile>;
      final packages = results[2] as List<ExamPackageModel>;

      if (!mounted) return;

      setState(() {
        _requests = results[0] as List<AppointmentRequestModel>;
        _doctorById = {for (final d in doctors) d.id: d};
        _packageById = {for (final p in packages) p.id: p};
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppointmentRequestModel> get _pendingRequests => _requests
      .where((r) =>
          r.status == 'PENDING_ASSIGNMENT')
      .toList();

  List<AppointmentRequestModel> get _confirmedRequests => _requests
      .where((r) => r.status == 'CONFIRMED')
      .toList();

  List<AppointmentRequestModel> get _pastRequests => _requests
      .where((r) =>
          r.status == 'REJECTED' ||
          r.status == 'CANCELLED' ||
          r.status == 'COMPLETED')
      .toList();

  Future<void> _cancelRequest(AppointmentRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lịch hẹn?'),
        content: const Text('Bạn có chắc muốn hủy lịch hẹn này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy lịch',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      if (request.status == 'CONFIRMED' && request.appointmentId != null) {
        await _appointmentService.cancelAppointment(
          appointmentId: request.appointmentId!,
          reason: 'Bệnh nhân yêu cầu hủy lịch',
        );
      } else {
        await _appointmentService.cancelAppointmentRequest(request.id);
      }
      if (!mounted) return;
      
      final doc = _doctorById[request.doctorId];
      String displayDocName = doc?.fullName ?? 'Bác sĩ';
      if (doc != null) {
        final profile = await AuthService().getUserInfo(doc.userId);
        if (profile != null) {
          displayDocName = '${profile.firstName ?? ""} ${profile.lastName ?? ""}'.trim();
          if (displayDocName.isEmpty) displayDocName = profile.username;
        }
      }
      
      NotificationManager.instance.addNotification(
        title: 'Đã hủy lịch hẹn',
        body: 'Lịch hẹn với bác sĩ $displayDocName vào ngày ${DateFormat('dd/MM/yyyy').format(request.createdAt ?? DateTime.now())} đã được hủy.',
        type: 'cancel',
      );
      NotificationManager.instance.showPopup(
        context,
        title: 'Đã hủy lịch hẹn',
        body: 'Lịch hẹn với bác sĩ $displayDocName đã được hủy thành công.',
        type: 'cancel',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã hủy lịch hẹn'), backgroundColor: Colors.orange),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 150,
            backgroundColor: _teal,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Lịch hẹn của tôi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                ).then((_) => _loadData()),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C8385), Color(0xFF57BBBF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.calendar_month, 
                        size: 150, 
                        color: Colors.white.withOpacity(0.1)
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _teal,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelColor: _teal,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Sắp tới'),
                    Tab(text: 'Đang chờ'),
                    Tab(text: 'Lịch sử'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_pendingRequests, showCancel: true),
                  _buildList(_confirmedRequests,
                      showCancel: true, showMedicalRecord: true),
                  _buildList(_pastRequests, showMedicalRecord: true),
                ],
              ),
      ),
    );
  }

  Widget _buildList(
    List<AppointmentRequestModel> list, {
    bool showCancel = false,
    bool showMedicalRecord = false,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Không có lịch hẹn nào',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            if (showCancel) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                ).then((_) => _loadData()),
                icon: const Icon(Icons.add),
                label: const Text('Đặt lịch ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) => _buildCard(
          list[i],
          showCancel: showCancel,
          showMedicalRecord: showMedicalRecord,
        ),
      ),
    );
  }

  Widget _buildCard(
    AppointmentRequestModel request, {
    bool showCancel = false,
    bool showMedicalRecord = false,
  }) {
    final doctor = _doctorById[request.doctorId];
    final pkg = _packageById[request.packageId];

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (request.status) {
      case 'PENDING_ASSIGNMENT':
        statusColor = Colors.orange;
        statusLabel = 'Chờ xác nhận';
        statusIcon = Icons.schedule;
        break;
      case 'CONFIRMED':
        statusColor = _teal;
        statusLabel = 'Đã xác nhận';
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusLabel = 'Đã từ chối';
        statusIcon = Icons.cancel;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusLabel = 'Đã hủy';
        statusIcon = Icons.cancel;
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusLabel = 'Đã khám xong';
        statusIcon = Icons.task_alt;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = request.status;
        statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header with Gradient based on status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.8),
                    statusColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const Spacer(),
                  if (request.createdAt != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(request.createdAt!),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor & Package Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.local_hospital, color: _teal, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FutureBuilder<UserProfile?>(
                          future: doctor != null ? AuthService().getUserInfo(doctor.userId) : Future.value(null),
                          builder: (context, snapshot) {
                            String name = doctor?.fullName ?? "Đang cập nhật";
                            if (snapshot.hasData && snapshot.data != null) {
                              final profile = snapshot.data!;
                              name = '${profile.firstName ?? ""} ${profile.lastName ?? ""}'.trim();
                              if (name.isEmpty) name = profile.username;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkg?.name ?? 'Gói khám dịch vụ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1E293B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bác sĩ: $name',
                                  style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Info Details Grid/List
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (doctor?.position != null)
                          _infoRow(Icons.work_outline, 'Chuyên khoa', doctor!.position!),
                        if (request.note != null && request.note!.isNotEmpty)
                          _infoRow(Icons.chat_bubble_outline, 'Ghi chú', request.note!),
                        if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty)
                          _infoRow(Icons.error_outline, 'Lý do từ chối', request.rejectionReason!, textColor: Colors.red),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  if (showCancel && (request.status == 'PENDING_ASSIGNMENT' || request.status == 'CONFIRMED')) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _cancelRequest(request),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              side: BorderSide(color: Colors.red.shade100),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Hủy lịch hẹn', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (showMedicalRecord && request.status == 'COMPLETED' && request.appointmentId != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientMedicalRecordViewScreen(
                              appointmentId: request.appointmentId!,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Xem kết quả khám bệnh', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: _teal.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text('$label: ',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13, 
                    color: textColor ?? Colors.black87,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}
