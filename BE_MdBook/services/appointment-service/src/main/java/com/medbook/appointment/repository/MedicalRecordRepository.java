package com.medbook.appointment.repository;

import com.medbook.appointment.entity.MedicalRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MedicalRecordRepository extends JpaRepository<MedicalRecord, String> {

    Optional<MedicalRecord> findByAppointmentId(String appointmentId);

    List<MedicalRecord> findByPatientUserIdOrderByCreatedAtDesc(String patientUserId);

    List<MedicalRecord> findByDoctorIdOrderByCreatedAtDesc(String doctorId);
}
