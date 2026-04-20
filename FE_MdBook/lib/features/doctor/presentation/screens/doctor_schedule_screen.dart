import 'package:flutter/material.dart';
import '../../data/slot_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  final String doctorId;
  const DoctorScheduleScreen({super.key, required this.doctorId});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final SlotService _slotService = SlotService();
  List<dynamic> _configs = [];
  bool _loading = true;

  final List<String> _days = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _slotService.getScheduleConfigs(targetId: widget.doctorId);
      setState(() => _configs = list);
    } catch (e) {
      debugPrint('Load configs error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAddSlotDialog() {
    String selectedDay = 'MONDAY';
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    int duration = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm ca rảnh định kỳ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setDialogState(() => selectedDay = v!),
                decoration: const InputDecoration(labelText: 'Thứ trong tuần'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Giờ bắt đầu'),
                trailing: Text(startTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: startTime);
                  if (picked != null) setDialogState(() => startTime = picked);
                },
              ),
              ListTile(
                title: const Text('Giờ kết thúc'),
                trailing: Text(endTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: endTime);
                  if (picked != null) setDialogState(() => endTime = picked);
                },
              ),
              const SizedBox(height: 16),
              const Text('Thời gian mỗi ca (phút):'),
              Slider(
                value: duration.toDouble(),
                min: 15,
                max: 120,
                divisions: 7,
                label: '$duration',
                onChanged: (v) => setDialogState(() => duration = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                  final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
                  
                  await _slotService.createRecurringSlot(
                    targetId: widget.doctorId,
                    dayOfWeek: selectedDay,
                    startTime: startStr,
                    endTime: endStr,
                    slotDurationMinutes: duration,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _load();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotDialog,
        backgroundColor: const Color(0xFF38A3A5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cấu hình lịch khám định kỳ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Hệ thống sẽ tự động tạo ca rảnh dựa trên cấu hình này', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                Expanded(
                  child: _configs.isEmpty 
                    ? const Center(child: Text('Chưa có cấu hình lịch nào'))
                    : ListView.builder(
                        itemCount: _configs.length,
                        itemBuilder: (context, index) {
                          final config = _configs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF38A3A5),
                                child: Icon(Icons.calendar_month, color: Colors.white, size: 20),
                              ),
                              title: Text(config['dayOfWeek'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${config['startTime']} - ${config['endTime']} (${config['slotDurationMinutes']} phút/ca)'),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {}), // Implement delete if needed
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
}
