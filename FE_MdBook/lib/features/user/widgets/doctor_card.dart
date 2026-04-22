import 'package:flutter/material.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';

class DoctorCard extends StatelessWidget {
  final DoctorProfile doctor;
  final VoidCallback? onTap;

  const DoctorCard({super.key, required this.doctor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: FutureBuilder<UserProfile?>(
          future: AuthService().getUserInfo(doctor.userId),
          builder: (context, snapshot) {
            String name = doctor.fullName;
            String? avatarUrl = doctor.avatar;
            
            if (snapshot.hasData && snapshot.data != null) {
              final profile = snapshot.data!;
              name = '${profile.firstName ?? ""} ${profile.lastName ?? ""}'.trim();
              if (name.isEmpty) name = profile.username;
              avatarUrl = profile.avatar;
            }

            return Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : const NetworkImage('https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg'),
                      fit: BoxFit.cover
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.degree ?? 'Bác sĩ',
                        style: const TextStyle(color: Color(0xFF38A3A5), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${doctor.degree != null ? '${doctor.degree}. ' : ''}$name',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3142)),
                      ),
                      Text(
                        doctor.position ?? 'Chuyên gia y tế',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kinh nghiệm: ${doctor.experienceYears} năm',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}
