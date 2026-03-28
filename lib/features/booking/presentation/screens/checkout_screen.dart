import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_success_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final Map<String, dynamic>? doctorData;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String? reason;

  const CheckoutScreen({
    super.key,
    this.doctorData,
    this.selectedDate,
    this.selectedTime,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = selectedDate != null 
        ? DateFormat('dd/MM/yyyy').format(selectedDate!) 
        : '28/03/2026';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A4A7C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông tin đặt hẹn',
          style: TextStyle(color: Color(0xFF1A4A7C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.medical_services_outlined, 'Dịch vụ'),
                  _buildInfoRow('Hình thức', 'Khám chuyên khoa tại\nbệnh viện'),
                  
                  const Divider(thickness: 1, color: Color(0xFFF5F5F5)),

                  _buildSectionHeader(Icons.person_outline, 'Khách hàng'),
                  _buildInfoRow('Khách hàng', 'Nguyễn Đình Thuân'),
                  _buildInfoRow('Lý do khám', reason ?? 'Khám định kỳ'),
                  
                  const Divider(thickness: 1, color: Color(0xFFF5F5F5)),

                  _buildSectionHeader(Icons.medical_information_outlined, 'Bác sĩ'),
                  _buildInfoRow('Bác sĩ', doctorData?['name'] ?? 'BS. Trịnh Ngọc Phát'),
                  _buildInfoRow('Thời gian', '${selectedTime ?? '10:00'}, $formattedDate'),
                  _buildInfoRow('Địa điểm', 'BV ĐKQT Vinmec Times\nCity (Hà Nội)'),
                  _buildInfoRow('Chuyên khoa', doctorData?['specialty'] ?? 'Da liễu'),
                  _buildInfoRow(
                    'Phí khám dự kiến', 
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(doctorData?['price'] ?? 690000),
                    isBoldValue: true
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Phí khám tại bệnh viện có thể thay đổi tùy theo dịch vụ sử dụng.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingSuccessScreen(
                        doctorData: doctorData,
                        selectedDate: selectedDate,
                        selectedTime: selectedTime,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'XÁC NHẬN LỊCH HẸN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38A3A5), size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF38A3A5)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
