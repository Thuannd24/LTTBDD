import 'package:flutter/material.dart';
import 'package:tbdd/features/doctor/data/slot_service.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  final SlotService _slotService = SlotService();

  List<dynamic> _configs = [];
  bool _loadingConfigs = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _loadingConfigs = true);
    try {
      final configs = await _slotService.getScheduleConfigs(
        targetId: '1',
        targetType: 'FACILITY',
        facilityId: 1,
      );
      setState(() {
        _configs = configs;
        _loadingConfigs = false;
      });
    } catch (e) {
      setState(() => _loadingConfigs = false);
    }
  }

  Future<void> _showAddConfigDialog() async {
    String dayOfWeek = 'MONDAY';
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    int duration = 120;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm khung giờ làm việc chung'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: dayOfWeek,
                items: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setDialogState(() => dayOfWeek = v!),
                decoration: const InputDecoration(labelText: 'Thứ trong tuần'),
              ),
              ListTile(
                title: const Text('Giờ bắt đầu'),
                trailing: Text(startTime.format(ctx)),
                onTap: () async {
                  final p = await showTimePicker(context: ctx, initialTime: startTime);
                  if (p != null) setDialogState(() => startTime = p);
                },
              ),
              ListTile(
                title: const Text('Giờ kết thúc'),
                trailing: Text(endTime.format(ctx)),
                onTap: () async {
                  final p = await showTimePicker(context: ctx, initialTime: endTime);
                  if (p != null) setDialogState(() => endTime = p);
                },
              ),
              TextFormField(
                initialValue: '120',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Thời lượng mỗi ca (phút)'),
                onChanged: (v) => duration = int.tryParse(v) ?? 120,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _slotService.createRecurringSlot(
                    targetId: '1',
                    targetType: 'FACILITY',
                    dayOfWeek: dayOfWeek,
                    startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                    endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                    slotDurationMinutes: duration,
                  );
                  Navigator.pop(ctx);
                  _loadConfigs();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cấu hình lịch làm việc',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A4A7C)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddConfigDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm giờ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A3A5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _loadingConfigs
                  ? const Center(child: CircularProgressIndicator())
                  : _configs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Chưa có cấu hình lịch nào.', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _configs.length,
                          itemBuilder: (ctx, i) {
                            final c = _configs[i];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFF38A3A5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.access_time, color: Color(0xFF38A3A5), size: 20),
                                ),
                                title: Text(
                                  '${c['dayOfWeek']} | ${c['startTime']} - ${c['endTime']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Thời lượng: ${c['slotDurationMinutes']} phút/ca'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    // Implement delete
                                  },
                                ),
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
