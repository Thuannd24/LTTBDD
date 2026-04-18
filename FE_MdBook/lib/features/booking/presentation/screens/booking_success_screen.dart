import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart';
import '../../../appointments/presentation/screens/appointment_list_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? doctorData;
  final DateTime? selectedDate;
  final String? selectedTime;

  const BookingSuccessScreen({
    super.key,
    this.doctorData,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = selectedDate != null 
        ? DateFormat('dd/MM/yyyy').format(selectedDate!) 
        : '28/03/2026';
    String doctorName = doctorData?['name'] ?? 'Trịnh Ngọc Phát';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A4A7C), size: 28),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'ĐẶT LỊCH THÀNH CÔNG',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Lịch hẹn với bác sĩ $doctorName vào lúc ${selectedTime ?? '10:40'} ngày $formattedDate của quý khách đã tự động xác nhận. Vui lòng kiểm tra thông tin lịch hẹn tại phần XEM LỊCH HẸN.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Illustration placeholder
            Container(
              height: 350,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage('https://img.freepik.com/free-vector/doctors-nurses-concept-illustration_114360-1515.jpg'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // This is a mock. In a real app we'd navigate to the Appointments tab.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  // Trigger navigation to AppointmentList tab via some state management if needed
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'XEM LỊCH HẸN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
