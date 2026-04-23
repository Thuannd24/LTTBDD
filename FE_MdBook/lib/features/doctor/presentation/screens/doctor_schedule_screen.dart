import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';
import 'package:tbdd/features/doctor/data/doctor_schedule_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  final String doctorId;
  final bool isDoctorProfileLoading;
  final VoidCallback? onOpenProfile;

  const DoctorScheduleScreen({
    super.key,
    required this.doctorId,
    this.isDoctorProfileLoading = false,
    this.onOpenProfile,
  });

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final DoctorScheduleService _doctorScheduleService = DoctorScheduleService();

  List<DoctorScheduleModel> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DoctorScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doctorId != widget.doctorId) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.doctorId.isEmpty || widget.doctorId == 'doctor_id') {
      if (mounted) {
        setState(() {
          _schedules = [];
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final list = await _doctorScheduleService.getSchedulesByDoctor(widget.doctorId);
      if (!mounted) {
        return;
      }

      setState(() {
        _schedules = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Khong the tai lich lam viec: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showAddSlotDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);
    final notesController = TextEditingController();
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Them lich lam viec'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngay kham'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gio bat dau'),
                    trailing: Text(startTime.format(dialogContext)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setDialogState(() => startTime = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gio ket thuc'),
                    trailing: Text(endTime.format(dialogContext)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setDialogState(() => endTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Huy'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final startDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        startTime.hour,
                        startTime.minute,
                      );
                      final endDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        endTime.hour,
                        endTime.minute,
                      );

                      if (!startDateTime.isBefore(endDateTime)) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Gio bat dau phai som hon gio ket thuc'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => submitting = true);

                      try {
                        await _doctorScheduleService.createSchedule(
                          doctorId: widget.doctorId,
                          startTime: startDateTime,
                          endTime: endDateTime,
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        );

                        if (!mounted) {
                          return;
                        }

                        navigator.pop();
                        await _load();
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Tao lich lam viec thanh cong')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Khong the tao lich lam viec: $e')),
                          );
                        }
                        setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tao'),
            ),
          ],
        ),
      ),
    );

    notesController.dispose();
  }

  String _formatSchedule(DoctorScheduleModel schedule) {
    final date = DateFormat('dd/MM/yyyy').format(schedule.startTime);
    final timeRange = '${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)}';
    return '$date, $timeRange';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return const Color(0xFF2E7D32);
      case 'RESERVED':
        return const Color(0xFFEF6C00);
      case 'BLOCKED':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.doctorId == 'doctor_id'
          ? null
          : FloatingActionButton(
              onPressed: _showAddSlotDialog,
              backgroundColor: const Color(0xFF38A3A5),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lich lam viec',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Them cac khung gio cu the de benh nhan co the dat lich.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  if (widget.doctorId != 'doctor_id')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: _showAddSlotDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38A3A5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Them lich lam viec'),
                      ),
                    ),
                  Expanded(
                    child: widget.isDoctorProfileLoading
                        ? const Center(child: CircularProgressIndicator())
                        : widget.doctorId == 'doctor_id'
                            ? Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.assignment_ind_outlined,
                                            size: 48,
                                            color: Color(0xFF38A3A5),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Tai khoan nay chua co ho so bac si duoc lien ket.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Hay cap nhat ho so chuyen mon truoc, sau do quay lai de tao lich lam viec.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton(
                                            onPressed: widget.onOpenProfile,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF38A3A5),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Mo ho so chuyen mon'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : _schedules.isEmpty
                                ? const Center(child: Text('Chua co lich lam viec nao'))
                                : RefreshIndicator(
                                    onRefresh: _load,
                                    child: ListView.builder(
                                      itemCount: _schedules.length,
                                      itemBuilder: (context, index) {
                                        final schedule = _schedules[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            leading: const CircleAvatar(
                                              backgroundColor: Color(0xFF38A3A5),
                                              child: Icon(
                                                Icons.calendar_month,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              _formatSchedule(schedule),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              schedule.notes?.isNotEmpty == true
                                                  ? schedule.notes!
                                                  : 'Co so ${schedule.facilityId ?? 1}',
                                            ),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _statusColor(schedule.status).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                schedule.status,
                                                style: TextStyle(
                                                  color: _statusColor(schedule.status),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
    );
  }
}
