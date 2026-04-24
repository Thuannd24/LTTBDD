import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/features/user/appointment/data/appointment_service.dart';

/// Màn hình xem kết quả khám - Bệnh nhân chỉ đọc, không sửa được
class PatientMedicalRecordViewScreen extends StatefulWidget {
  final String appointmentId;

  const PatientMedicalRecordViewScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<PatientMedicalRecordViewScreen> createState() =>
      _PatientMedicalRecordViewScreenState();
}

class _PatientMedicalRecordViewScreenState
    extends State<PatientMedicalRecordViewScreen> {
  final AppointmentService _service = AppointmentService();

  Map<String, dynamic>? _record;
  bool _loading = true;
  String? _error;

  static const _teal = Color(0xFF38A3A5);

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    try {
      final record = await _service
          .getMedicalRecordByAppointment(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _record = record;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null
              ? _buildError()
              : _record == null
                  ? _buildEmpty()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error ?? 'Đã xảy ra lỗi',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined,
              size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Bác sĩ chưa nhập kết quả khám',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Vui lòng liên hệ phòng khám để biết thêm thông tin',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final r = _record!;

    DateTime? followUp;
    if (r['followUpDate'] != null) {
      followUp = DateTime.tryParse(r['followUpDate'].toString());
    }
    DateTime? createdAt;
    if (r['createdAt'] != null) {
      createdAt = DateTime.tryParse(r['createdAt'].toString());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner ngày khám
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C8385), Color(0xFF57BBBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_information,
                    color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kết quả khám bệnh',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      if (createdAt != null)
                        Text(
                          'Ngày khám: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                // Chỉ xem, không sửa
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Chỉ xem',
                          style:
                              TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Smart AI Summary
          if (_hasValue(r['aiSummary']))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _teal.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: _teal, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Tóm tắt y tế thông minh (AI)',
                        style: TextStyle(
                            color: _teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    r['aiSummary'],
                    style: const TextStyle(
                        color: Colors.black87,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_hasValue(r['symptoms']))
            _buildSection(
              icon: Icons.sick_outlined,
              title: 'Triệu chứng',
              content: r['symptoms'],
            ),
          if (_hasValue(r['diagnosis']))
            _buildSection(
              icon: Icons.medical_information_outlined,
              title: 'Chẩn đoán',
              content: r['diagnosis'],
              highlight: true,
            ),
          if (_hasValue(r['prescription']))
            _buildSection(
              icon: Icons.medication_outlined,
              title: 'Đơn thuốc / Chỉ định',
              content: r['prescription'],
            ),
          if (_hasValue(r['notes']))
            _buildSection(
              icon: Icons.notes_outlined,
              title: 'Lời dặn / Hướng dẫn',
              content: r['notes'],
            ),
          if (followUp != null)
            _buildSection(
              icon: Icons.event_outlined,
              title: 'Ngày tái khám',
              content: DateFormat('dd/MM/yyyy').format(followUp),
              highlight: true,
            ),
          const SizedBox(height: 16),
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Kết quả khám chỉ mang tính chất tham khảo. Vui lòng liên hệ bác sĩ để được tư vấn thêm.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required dynamic content,
    bool highlight = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? _teal.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: _teal.withOpacity(0.2))
            : null,
        boxShadow: highlight
            ? null
            : [
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
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content?.toString() ?? '-',
            style: const TextStyle(
                fontSize: 15, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  bool _hasValue(dynamic v) => v != null && v.toString().isNotEmpty;
}
