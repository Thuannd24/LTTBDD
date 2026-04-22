import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';
import 'package:tbdd/core/models/exam_package_model.dart';

class BookingSuccessScreen extends StatelessWidget {
  final DoctorProfile doctor;
  final ExamPackageModel packageData;
  final DoctorScheduleModel selectedSchedule;
  final String? requestId;

  const BookingSuccessScreen({
    super.key,
    required this.doctor,
    required this.packageData,
    required this.selectedSchedule,
    this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(selectedSchedule.startTime);

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
              'GỬI YÊU CẦU THÀNH CÔNG',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Yêu cầu đặt lịch cho gói ${packageData.name} với bác sĩ ${doctor.fullName} vào $formattedDate đã được gửi. Bệnh viện sẽ xác nhận sau khi phân bổ phòng và thiết bị.',
              style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (requestId != null) ...[
              const SizedBox(height: 12),
              Text(
                'Mã yêu cầu: $requestId',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF38A3A5)),
              ),
            ],
            const Spacer(),
            Container(
              height: 300,
              decoration: const BoxDecoration(
                image: DecorationImage(
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
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
