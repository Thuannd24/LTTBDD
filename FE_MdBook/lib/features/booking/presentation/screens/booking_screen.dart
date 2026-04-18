import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import 'checkout_screen.dart';
import 'doctor_list_screen.dart';
import 'specialty_list_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _selectedGender = 'Nam';
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
          'Đặt lịch hẹn',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người đặt lịch
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin người đặt lịch',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInputRow(Icons.edit_outlined, 'Nguyễn Đình Thuân'),
                  _buildInputRow(Icons.cake_outlined, '23/01/2004'),
                  _buildInputRow(Icons.phone_outlined, '0389468847'),
                  
                  const SizedBox(height: 20),
                  const Text.rich(
                    TextSpan(
                      text: 'Giới tính',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      children: [
                        TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildGenderBtn('Nam', Icons.male),
                      const SizedBox(width: 16),
                      _buildGenderBtn('Nữ', Icons.female),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

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
                    value: _selectedSpecialty ?? 'Chọn chuyên khoa',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SpecialtyListScreen()),
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
                    value: _selectedDoctor != null ? _selectedDoctor!['name'] : 'Chọn bác sĩ',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DoctorListScreen()),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _selectedDoctor = result;
                          _selectedSpecialty = result['specialty'];
                        });
                      }
                    },
                  ),

                  if (_selectedDoctor != null) ...[
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
                            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_selectedDoctor!['price']),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ]
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

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // Lý do khám
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text('Lý do khám', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('0/120', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.edit, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Vui lòng mô tả rõ triệu chứng của bạn và nhu cầu thăm khám.',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                  },
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

  Widget _buildInputRow(IconData icon, String text) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 12),
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildGenderBtn(String label, IconData icon) {
    bool isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF38A3A5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[200]!),
          ),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: isSelected ? Colors.white : Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
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
    String month = 'Thg ${date.month}';
    String day = date.day.toString();

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
                Text(month, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(day, style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
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
    String month = 'Thg ${_selectedCustomDate.month}';
    String day = _selectedCustomDate.day.toString();

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
                    Text(month, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(day, style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
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
