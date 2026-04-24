package com.medbook.appointment.repository;

import com.medbook.appointment.entity.Appointment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, String> {
    Page<Appointment> findByPatientUserId(String patientUserId, Pageable pageable);
    Page<Appointment> findByDoctorId(String doctorId, Pageable pageable);
    List<Appointment> findByStatusAndAppointmentDate(Appointment.AppointmentStatus status, LocalDate appointmentDate);
}
