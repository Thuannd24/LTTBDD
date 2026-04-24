import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/appointment_request_model.dart';
import 'package:tbdd/features/user/appointment/data/appointment_service.dart';

import 'package:tbdd/features/chat/data/profile_service.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';
import 'package:tbdd/features/doctor/data/doctor_schedule_service.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  final String doctorId;
  const DoctorAppointmentScreen({super.key, required this.doctorId});

  @override
  State<DoctorAppointmentScreen> createState() =>
      _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _service = AppointmentService();
  late TabController _tabController;

  List<AppointmentRequestModel> _pending = [];
  List<Map<String, dynamic>> _confirmed = [];
  Map<int, DoctorScheduleModel> _scheduleMap = {};
  Map<String, ChatUserProfile> _patientMap = {};
  bool _loading = true;

  static const _teal = Color(0xFF38A3A5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DoctorAppointmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doctorId != widget.doctorId &&
        widget.doctorId != 'doctor_id') {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.doctorId == 'doctor_id') return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getPendingRequests(),
        _service.getDoctorAppointments(widget.doctorId),
      ]);
      
      final allPending = results[0] as List<AppointmentRequestModel>;
      final pending = allPending.where((p) => p.doctorId == widget.doctorId).toList();
      final confirmed = results[1] as List<Map<String, dynamic>>;
      
      final schedules = await DoctorScheduleService().getSchedulesByDoctor(widget.doctorId);
      final Map<int, DoctorScheduleModel> sMap = {
        for (final s in schedules) s.id: s
      };

      final Set<String> patientIds = {};
      for (final p in pending) {
        patientIds.add(p.patientUserId);
      }
      for (final c in confirmed) {
        if (c['patientUserId'] != null) patientIds.add(c['patientUserId'].toString());
      }

      final Map<String, ChatUserProfile> pMap = {};
      await Future.wait(patientIds.map((id) async {
        try {
          final profile = await ProfileService.instance.getProfile(id, roleHint: 'PATIENT');
          pMap[id] = profile;
        } catch (_) {}
      }));

      if (!mounted) return;
      setState(() {
        _pending = pending;
        _confirmed = confirmed;
        _scheduleMap = sMap;
        _patientMap = pMap;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading doctor appointments: $e\n$st');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận yêu cầu'),
        content: const Text('Bạn có chắc chắn muốn xác nhận lịch hẹn này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await _service.confirmAppointmentRequest(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Đã xác nhận lịch hẹn'),
            backgroundColor: _teal),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(String requestId) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lý do từ chối'),
        content: TextField(
          controller: reasonCtrl,
          decoration:
              const InputDecoration(hintText: 'Nhập lý do từ chối...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () =>
                Navigator.pop(ctx, reasonCtrl.text.trim()),
            child: const Text('Từ chối',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await _service.rejectAppointmentRequest(requestId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã từ chối yêu cầu'),
            backgroundColor: Colors.orange),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _teal,
                      labelColor: _teal,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(
                          text:
                              'Chờ xác nhận${_pending.isEmpty ? "" : " (${_pending.length})"}',
                        ),
                        const Tab(text: 'Đã xác nhận'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        RefreshIndicator(
                          onRefresh: _loadData,
                          color: _teal,
                          child: _pending.isEmpty
                              ? _emptyState('Không có yêu cầu chờ xác nhận',
                                  Icons.check_circle_outline)
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _pending.length,
                                  itemBuilder: (ctx, i) =>
                                      _buildPendingCard(_pending[i]),
                                ),
                        ),
                        RefreshIndicator(
                          onRefresh: _loadData,
                          color: _teal,
                          child: _confirmed.isEmpty
                              ? _emptyState('Không có lịch hẹn đã xác nhận',
                                  Icons.calendar_today_outlined)
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _confirmed.length,
                                  itemBuilder: (ctx, i) =>
                                      _buildConfirmedCard(_confirmed[i]),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPatientDetails(String patientUserId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(
        color: _teal,
      )),
    );

    try {
      final profile = await ProfileService.instance
          .getProfile(patientUserId, roleHint: 'PATIENT');
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _teal.withOpacity(0.1),
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person, color: _teal, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            profile.phone ?? 'Chưa cập nhật số điện thoại',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildDetailSection(
                    Icons.history_edu, 'Tiền sử bệnh lý', profile.medicalHistory ?? 'Chưa có thông tin'),
                const SizedBox(height: 16),
                _buildDetailSection(
                    Icons.warning_amber_rounded, 'Dị ứng', profile.allergies ?? 'Không có thông tin'),
                const SizedBox(height: 32),
                const Text(
                  'Lịch sử khám tại đây',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tính năng đang phát triển - Bác sĩ có thể xem các Medical Records cũ tại đây.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Đóng', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải thông tin bệnh nhân: $e')));
      }
    }
  }

  Widget _buildDetailSection(IconData icon, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: _teal),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!)),
          child: Text(content,
              style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildPendingCard(AppointmentRequestModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () => _showPatientDetails(req.patientUserId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: _teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _patientMap[req.patientUserId]?.displayName ?? 'Đang tải...',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                        if (req.createdAt != null)
                          Text(
                            _scheduleMap[req.doctorScheduleId] != null
                                ? DateFormat('dd/MM/yyyy HH:mm')
                                    .format(_scheduleMap[req.doctorScheduleId]!.startTime)
                                : DateFormat('dd/MM/yyyy HH:mm').format(req.createdAt!),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Chờ xác nhận',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              if (req.note != null && req.note!.isNotEmpty)
                _infoRow(
                    Icons.note_outlined, 'Lý do khám', req.note!),
              _infoRow(Icons.person_outline, 'Bệnh nhân', 
                  _patientMap[req.patientUserId]?.displayName ?? 'Đang tải...'),
              if (_patientMap[req.patientUserId]?.phone != null)
                _infoRow(Icons.phone_outlined, 'Số điện thoại', _patientMap[req.patientUserId]!.phone!),
              _infoRow(Icons.medical_services_outlined, 'Mã gói khám',
                  req.packageId),
              _infoRow(Icons.schedule_outlined, 'Giờ khám',
                  _scheduleMap[req.doctorScheduleId] != null
                      ? '${DateFormat('HH:mm').format(_scheduleMap[req.doctorScheduleId]!.startTime)} - ${DateFormat('HH:mm').format(_scheduleMap[req.doctorScheduleId]!.endTime)}'
                      : req.doctorScheduleId.toString()),
              const SizedBox(height: 14),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(req.id),
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.red),
                      label: const Text('Từ chối',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirm(req.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Nhấn để xem chi tiết bệnh nhân',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedCard(Map<String, dynamic> appt) {
    final status = appt['status']?.toString() ?? '';
    final statusLabel =
        status == 'COMPLETED' ? 'Đã khám xong' : 'Đã xác nhận';
    final statusColor =
        status == 'COMPLETED' ? Colors.green : _teal;

    final doctorScheduleId = (appt['doctorScheduleId'] as num?)?.toInt() ?? 0;
    final patientId = appt['patientUserId']?.toString() ?? '';
    final schedule = _scheduleMap[doctorScheduleId];
    final patient = _patientMap[patientId];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () => _showPatientDetails(patientId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch hẹn #${appt['id']?.toString().substring(0, 8) ?? '-'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(Icons.person_outline, 'Bệnh nhân',
                  patient?.displayName ?? 'Đang tải...'),
              if (patient?.phone != null)
                _infoRow(Icons.phone_outlined, 'Số điện thoại', patient!.phone!),
              _infoRow(Icons.schedule_outlined, 'Giờ khám',
                  schedule != null
                      ? '${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)} (${DateFormat('dd/MM/yyyy').format(schedule.startTime)})'
                      : doctorScheduleId.toString()),
              if (status == 'CONFIRMED') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompleteDialog(
                        appt['id']?.toString() ?? ''),
                    icon: const Icon(Icons.task_alt, size: 16),
                    label: const Text('Xác nhận đã khám xong'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else if (status == 'COMPLETED') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalRecordFormScreen(
                            appointmentId:
                                appt['id']?.toString() ?? ''),
                      ),
                    ),
                    icon: const Icon(Icons.note_add_outlined,
                        color: _teal),
                    label: const Text('Thêm / Xem kết quả khám',
                        style: TextStyle(color: _teal)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _teal),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCompleteDialog(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text(
            'Bạn có chắc bệnh nhân đã được khám xong? Sau khi xác nhận, bạn có thể nhập kết quả khám.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.completeAppointment(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Đã đánh dấu khám xong!'),
            backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text('$label: ',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text,
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Màn hình nhập kết quả khám ───────────────────────────────────────────────

class MedicalRecordFormScreen extends StatefulWidget {
  final String appointmentId;
  const MedicalRecordFormScreen({super.key, required this.appointmentId});

  @override
  State<MedicalRecordFormScreen> createState() =>
      _MedicalRecordFormScreenState();
}

class _MedicalRecordFormScreenState extends State<MedicalRecordFormScreen> {
  final AppointmentService _service = AppointmentService();
  final _formKey = GlobalKey<FormState>();

  final _diagnosisCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _prescriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _followUpDate;
  bool _loading = false;
  bool _loadingExisting = true;

  static const _teal = Color(0xFF38A3A5);

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final record = await _service
          .getMedicalRecordByAppointment(widget.appointmentId);
      if (record != null && mounted) {
        _diagnosisCtrl.text = record['diagnosis'] ?? '';
        _symptomsCtrl.text = record['symptoms'] ?? '';
        _prescriptionCtrl.text = record['prescription'] ?? '';
        _notesCtrl.text = record['notes'] ?? '';
        if (record['followUpDate'] != null) {
          _followUpDate =
              DateTime.tryParse(record['followUpDate'].toString());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingExisting = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.createMedicalRecord(widget.appointmentId, {
        'diagnosis': _diagnosisCtrl.text.trim(),
        'symptoms': _symptomsCtrl.text.trim(),
        'prescription': _prescriptionCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'followUpDate': _followUpDate?.toIso8601String(),
      });
      

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Đã lưu kết quả khám và hoàn tất lịch hẹn'),
            backgroundColor: _teal),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Kết quả khám bệnh',
            style: TextStyle(color: Colors.white)),
        backgroundColor: _teal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loadingExisting
          ? const Center(
              child: CircularProgressIndicator(color: _teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCard(
                      icon: Icons.sick_outlined,
                      title: 'Triệu chứng',
                      child: TextFormField(
                        controller: _symptomsCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Mô tả triệu chứng của bệnh nhân...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.medical_information_outlined,
                      title: 'Chẩn đoán *',
                      child: TextFormField(
                        controller: _diagnosisCtrl,
                        maxLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập chẩn đoán'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'Nhập chẩn đoán bệnh...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.medication_outlined,
                      title: 'Đơn thuốc / Chỉ định',
                      child: TextFormField(
                        controller: _prescriptionCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Thuốc, liều dùng, thời gian điều trị...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.notes_outlined,
                      title: 'Lời dặn / Hướng dẫn',
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Chế độ ăn uống, nghỉ ngơi...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.event_outlined,
                      title: 'Ngày tái khám',
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _followUpDate ??
                                DateTime.now()
                                    .add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _followUpDate = picked);
                          }
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Text(
                                _followUpDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_followUpDate!)
                                    : 'Chưa đặt ngày tái khám',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _followUpDate != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.calendar_today_outlined,
                                  color: _teal),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'LƯU KẾT QUẢ KHÁM',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _teal),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}
