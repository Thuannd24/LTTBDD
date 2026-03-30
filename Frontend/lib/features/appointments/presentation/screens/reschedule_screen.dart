import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../booking/presentation/screens/doctor_list_screen.dart';
import '../../../booking/presentation/screens/specialty_list_screen.dart';

class RescheduleScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const RescheduleScreen({super.key, required this.appointment});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  int _selectedDateIndex = 0;
  DateTime _selectedCustomDate = DateTime.now();
  String? _selectedSlot;
  
  Map<String, dynamic>? _selectedDoctor;
  String? _selectedSpecialty;

  final List<String> _morningSlots = ['08:00', '08:30', '09:00', '09:30', '10:00', '10:30'];
  final List<String> _afternoonSlots = ['13:30', '14:00', '14:30', '15:00', '15:30', '16:00'];

  List<DateTime> get _defaultDates {
    DateTime now = DateTime.now();
    return [
      now,
      now.add(const Duration(days: 1)),
      now.add(const Duration(days: 2)),
    ];
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedCustomDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF38A3A5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedCustomDate = picked;
        _selectedDateIndex = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Yêu cầu đổi lịch',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin lịch hẹn đã đặt (Mới thêm)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin lịch hẹn đã đặt',
                    style: TextStyle(
                      color: Color(0xFF38A3A5),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAppointmentDetailRow('Bệnh viện', widget.appointment['hospital']),
                  _buildAppointmentDetailRow('Chuyên khoa', widget.appointment['type']),
                  _buildAppointmentDetailRow('Bác sĩ', widget.appointment['doctor'].replaceAll('BS. ', '')),
                  _buildAppointmentDetailRow(
                    'Thời gian đặt khám', 
                    '${widget.appointment['time']}, ${widget.appointment['date']}/${widget.appointment['month_year']}'
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1, color: Color(0xFFEEEEEE)),

            // Thông tin đặt hẹn
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Thông tin đặt hẹn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Chọn Chuyên khoa
                  _buildSelectionTile(
                    icon: Icons.category_outlined,
                    label: 'Chuyên khoa',
                    value: _selectedSpecialty ?? 'Thần kinh',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SpecialtyListScreen()),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _selectedDoctor = result;
                          _selectedSpecialty = result['specialty'];
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Chọn Bác sĩ
                  _buildSelectionTile(
                    icon: Icons.person_outline,
                    label: 'Bác sĩ',
                    value: _selectedDoctor != null ? _selectedDoctor!['name'] : 'BS. Alan Cooper',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DoctorListScreen()),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _selectedDoctor = result;
                          _selectedSpecialty = result['specialty'];
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, color: Color(0xFF38A3A5), size: 20),
                        const SizedBox(width: 12),
                        const Text('Giá khám: ', style: TextStyle(color: Colors.grey)),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_selectedDoctor?['price'] ?? 600000),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // Lịch hẹn
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Lịch hẹn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(
                      text: 'Ngày khám mong muốn',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      children: [
                        TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateItem(0, _defaultDates[0], 'Hôm nay'),
                      _buildDateItem(1, _defaultDates[1], 'Ngày mai'),
                      _buildDateItem(2, _defaultDates[2], 'Ngày kia'),
                      _buildDateOther(context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Giờ khám mong muốn',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sáng', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  _buildTimeGrid(_morningSlots),
                  const SizedBox(height: 16),
                  const Text('Chiều', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  _buildTimeGrid(_afternoonSlots),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yêu cầu đổi lịch đã được gửi thành công')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2DFDB),
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

  Widget _buildAppointmentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF444444),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 22),
            const SizedBox(width: 12),
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeGrid(List<String> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        bool isSelected = _selectedSlot == slots[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slots[index]),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF38A3A5) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                slots[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateItem(int index, DateTime date, String label) {
    bool isSelected = _selectedDateIndex == index;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedDateIndex = index),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF38A3A5) : Colors.transparent, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Thg ${date.month}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('${date.day}', style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDateOther(BuildContext context) {
    bool isSelected = _selectedDateIndex == 3;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF38A3A5) : Colors.transparent, width: 2),
            ),
            child: isSelected 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Thg ${_selectedCustomDate.month}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('${_selectedCustomDate.day}', style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                )
              : const Icon(Icons.add, color: Colors.grey, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(isSelected ? 'Ngày đã chọn' : 'Ngày khác', style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey, fontSize: 12)),
      ],
    );
  }
}
