package com.medbook.appointment.service;

import com.medbook.appointment.dto.request.CreateMedicalRecordRequest;
import com.medbook.appointment.dto.response.MedicalRecordResponse;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.entity.MedicalRecord;
import com.medbook.appointment.exception.AppointmentNotFoundException;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.repository.MedicalRecordRepository;
import com.medbook.appointment.client.doctor.DoctorServiceClient;
import com.medbook.appointment.client.model.DoctorInfo;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional
@Slf4j
public class MedicalRecordService {

    MedicalRecordRepository medicalRecordRepository;
    AppointmentRepository appointmentRepository;
    DoctorServiceClient doctorServiceClient;
    AIService aiService;

    public MedicalRecordResponse createRecord(
            String appointmentId,
            CreateMedicalRecordRequest request,
            String authUserId) {

        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Appointment not found: " + appointmentId));

        if (appointment.getStatus() != Appointment.AppointmentStatus.COMPLETED) {
            throw new AppointmentValidationException("Medical records can only be created for COMPLETED appointments");
        }

        // Ánh xạ Auth User ID sang Doctor Profile ID
        DoctorInfo doctorInfo = doctorServiceClient.getDoctorByUserId(authUserId);
        String doctorProfileId = doctorInfo.id();

        if (!appointment.getDoctorId().equals(doctorProfileId)) {
            throw new AppointmentValidationException("Only the treating doctor can create medical records");
        }

        // Nếu đã có hồ sơ thì cập nhật
        MedicalRecord record = medicalRecordRepository.findByAppointmentId(appointmentId)
                .orElse(MedicalRecord.builder()
                        .appointmentId(appointmentId)
                        .patientUserId(appointment.getPatientUserId())
                        .doctorId(doctorProfileId)
                        .build());

        record.setDiagnosis(request.getDiagnosis());
        record.setSymptoms(request.getSymptoms());
        record.setPrescription(request.getPrescription());
        record.setNotes(request.getNotes());
        record.setFollowUpDate(request.getFollowUpDate());

        // Tự động tạo tóm tắt AI
        try {
            String aiSummary = aiService.generateMedicalSummary(
                record.getSymptoms(), 
                record.getDiagnosis(), 
                record.getPrescription(), 
                record.getNotes()
            );
            record.setAiSummary(aiSummary);
        } catch (Exception e) {
            log.error("Failed to generate AI summary: {}", e.getMessage());
            record.setAiSummary("Bác sĩ đã ghi nhận kết quả khám. Bạn vui lòng xem chi tiết chẩn đoán và đơn thuốc bên trên.");
        }

        MedicalRecord saved = medicalRecordRepository.save(record);
        log.info("Medical record saved: {} for appointment: {}", saved.getId(), appointmentId);
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public MedicalRecordResponse getByAppointmentId(String appointmentId, String requestingUserId) {
        MedicalRecord record = medicalRecordRepository.findByAppointmentId(appointmentId)
                .orElseThrow(() -> new AppointmentNotFoundException("Medical record not found for appointment: " + appointmentId));

        // Chỉ bệnh nhân hoặc bác sĩ liên quan mới được xem
        boolean isPatient = record.getPatientUserId().equals(requestingUserId);
        boolean isDoctor = false;
        try {
            DoctorInfo doctorInfo = doctorServiceClient.getDoctorByUserId(requestingUserId);
            if (record.getDoctorId().equals(doctorInfo.id())) {
                isDoctor = true;
            }
        } catch (Exception e) {
            // Not a doctor or service error
        }

        if (!isPatient && !isDoctor) {
            throw new AppointmentValidationException("Access denied to this medical record");
        }

        return toResponse(record);
    }

    @Transactional(readOnly = true)
    public List<MedicalRecordResponse> getMyRecords(String patientUserId) {
        return medicalRecordRepository.findByPatientUserIdOrderByCreatedAtDesc(patientUserId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MedicalRecordResponse> getDoctorRecords(String authUserId) {
        try {
            DoctorInfo doctorInfo = doctorServiceClient.getDoctorByUserId(authUserId);
            return medicalRecordRepository.findByDoctorIdOrderByCreatedAtDesc(doctorInfo.id())
                    .stream().map(this::toResponse).collect(Collectors.toList());
        } catch (Exception e) {
            return List.of();
        }
    }

    private MedicalRecordResponse toResponse(MedicalRecord r) {
        return MedicalRecordResponse.builder()
                .id(r.getId())
                .appointmentId(r.getAppointmentId())
                .patientUserId(r.getPatientUserId())
                .doctorId(r.getDoctorId())
                .diagnosis(r.getDiagnosis())
                .symptoms(r.getSymptoms())
                .prescription(r.getPrescription())
                .notes(r.getNotes())
                .aiSummary(r.getAiSummary())
                .followUpDate(r.getFollowUpDate())
                .createdAt(r.getCreatedAt())
                .updatedAt(r.getUpdatedAt())
                .build();
    }
}
