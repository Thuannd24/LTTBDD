import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';

class AiSuggestion {
  final Specialty specialty;
  final List<DoctorProfile> doctors;
  final String reasoning;
  final String aiMessage;
  final String urgency; // 'low' | 'medium' | 'high'

  AiSuggestion({
    required this.specialty,
    required this.doctors,
    required this.reasoning,
    required this.aiMessage,
    required this.urgency,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    final specialtyJson = json['specialty'] as Map<String, dynamic>? ?? {};
    final doctorsJson = json['doctors'] as List<dynamic>? ?? [];

    final suggestedSpecialty = Specialty.fromJson(specialtyJson);
    final allDoctors = doctorsJson
        .map((d) => DoctorProfile.fromJson(d as Map<String, dynamic>))
        .toList();

    // Lọc bác sĩ để chỉ hiện những người thuộc đúng chuyên khoa gợi ý
    List<DoctorProfile> filteredDoctors = [];
    if (suggestedSpecialty.id.isNotEmpty) {
      filteredDoctors = allDoctors.where((doc) {
        return doc.specialtyIds.contains(suggestedSpecialty.id);
      }).toList();
    }

    return AiSuggestion(
      specialty: suggestedSpecialty,
      doctors: filteredDoctors,
      reasoning: json['reasoning'] as String? ?? '',
      aiMessage: json['aiMessage'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'medium',
    );
  }
}
