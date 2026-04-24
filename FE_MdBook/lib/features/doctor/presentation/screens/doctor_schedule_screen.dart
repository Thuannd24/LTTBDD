import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/api/api_client.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';

import 'package:tbdd/features/doctor/data/doctor_schedule_service.dart';
import 'package:tbdd/features/doctor/data/slot_service.dart';

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
          SnackBar(content: Text('Không thể tải lịch làm việc: $e')),
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
    
    // Services

    
    List<dynamic>? roomSlots;
    Set<dynamic> selectedRoomSlots = {};
    DateTime selectedDate = DateTime.now();
    bool loadingSlots = false;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          
          Future<void> loadSlots() async {
            setDialogState(() => loadingSlots = true);
            try {
              final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
              final resp = await ApiClient().get('/slot/slots/facility/available?facilityId=1&date=$dateStr');
              if (resp.statusCode == 200) {
                final data = jsonDecode(resp.body);
                setDialogState(() {
                  roomSlots = data['result']?['slots'] ?? [];
                  loadingSlots = false;
                });
              } else {
                setDialogState(() {
                  loadingSlots = false;
                  roomSlots ??= [];
                });
              }
            } catch (e) {
              setDialogState(() {
                loadingSlots = false;
                roomSlots ??= [];
              });
            }
          }

          if (roomSlots == null && !loadingSlots) {
            loadSlots();
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Đăng ký lịch làm việc', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A4A7C))),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38A3A5).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF38A3A5)),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null && picked != selectedDate) {
                              setDialogState(() {
                                selectedDate = picked;
                                roomSlots = null;
                                selectedRoomSlots.clear();
                              });
                              loadSlots();
                            }
                          },
                          child: const Text('Đổi ngày'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Chọn các khung giờ (có thể chọn nhiều):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(height: 12),
                  if (loadingSlots)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Color(0xFF38A3A5)),
                    )
                  else if (roomSlots == null || roomSlots!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Không có khung giờ trống nào.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: roomSlots!.length,
                        itemBuilder: (ctx, i) {
                          final s = roomSlots![i];
                          final isSelected = selectedRoomSlots.any((item) => item['id'] == s['id']);
                          final start = DateTime.parse(s['startTime']);
                          final end = DateTime.parse(s['endTime']);
                          return Card(
                            elevation: 0,
                            color: isSelected ? const Color(0xFF38A3A5).withOpacity(0.1) : Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF38A3A5) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              value: isSelected,
                              activeColor: const Color(0xFF38A3A5),
                              title: Text(
                                '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF38A3A5) : Colors.black87,
                                ),
                              ),
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    selectedRoomSlots.add(s);
                                  } else {
                                    selectedRoomSlots.removeWhere((item) => item['id'] == s['id']);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: (submitting || selectedRoomSlots.isEmpty)
                    ? null
                    : () async {
                        setDialogState(() => submitting = true);
                        try {
                          int successCount = 0;
                          for (final slot in selectedRoomSlots) {
                            final start = DateTime.parse(slot['startTime']);
                            final end = DateTime.parse(slot['endTime']);
                            
                            await _doctorScheduleService.createSchedule(
                              doctorId: widget.doctorId,
                              startTime: start,
                              endTime: end,
                              roomSlotId: slot['id'],
                            );
                            successCount++;
                          }

                          navigator.pop();
                          _load();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Đăng ký thành công $successCount khung giờ')),
                          );
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          setDialogState(() => submitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: submitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text('Đăng ký (${selectedRoomSlots.length})'),
              ),
            ],
          );
        },
      ),
    );
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
              heroTag: 'doctor_schedule_fab',
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
                    'Lịch làm việc',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thêm các khung giờ cụ thể để bệnh nhân có thể đặt lịch.',
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
                        label: const Text('Thêm lịch làm việc'),
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
                                            'Tài khoản này chưa có hồ sơ bác sĩ được liên kết.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Hãy cập nhật hồ sơ chuyên môn trước, sau đó quay lại để tạo lịch làm việc.',
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
                                            child: const Text('Mở hồ sơ chuyên môn'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : _schedules.isEmpty
                                ? const Center(child: Text('Chưa có lịch làm việc nào'))
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
                                                  : 'Cơ sở ${schedule.facilityId ?? 1}',
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
