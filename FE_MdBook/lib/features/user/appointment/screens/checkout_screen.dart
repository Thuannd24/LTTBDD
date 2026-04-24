import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/doctor_schedule_model.dart';
import 'package:tbdd/core/models/exam_package_model.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:tbdd/features/user/appointment/data/appointment_service.dart';
import 'package:tbdd/features/user/appointment/screens/booking_success_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final UserProfile? patient;
  final DoctorProfile doctor;
  final ExamPackageModel packageData;
  final DoctorScheduleModel selectedSchedule;
  final String? reason;

  const CheckoutScreen({
    super.key,
    this.patient,
    required this.doctor,
    required this.packageData,
    required this.selectedSchedule,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('HH:mm, dd/MM/yyyy').format(selectedSchedule.startTime);

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
                  _buildInfoRow('Gói khám', packageData.name),
                  _buildInfoRow('Mã gói', packageData.code),
                  const Divider(thickness: 1, color: Color(0xFFF5F5F5)),
                  _buildSectionHeader(Icons.person_outline, 'Khách hàng'),
                  _buildInfoRow('Khách hàng', patient?.fullName ?? patient?.username ?? 'Người dùng'),
                  _buildInfoRow('Email', patient?.email ?? 'Chưa có email'),
                  _buildInfoRow('Lý do khám', (reason?.trim().isNotEmpty ?? false) ? reason!.trim() : 'Khám định kỳ'),
                  const Divider(thickness: 1, color: Color(0xFFF5F5F5)),
                  _buildSectionHeader(Icons.medical_information_outlined, 'Bác sĩ'),
                  _buildInfoRow('Bác sĩ', doctor.fullName),
                  _buildInfoRow('Thời gian', start),
                  _buildInfoRow('Trạng thái lịch', selectedSchedule.status),
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
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final appointmentService = AppointmentService();
                    final response = await appointmentService.createAppointmentRequest(
                      doctorId: doctor.id,
                      packageId: packageData.id,
                      doctorScheduleId: selectedSchedule.id,
                      roomSlotId: selectedSchedule.roomSlotId,
                      note: reason,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingSuccessScreen(
                            doctor: doctor,
                            packageData: packageData,
                            selectedSchedule: selectedSchedule,
                            requestId: response['result']?['id'] as String?,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không thể gửi yêu cầu đặt lịch: $e')),
                      );
                    }
                  }
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38A3A5)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
