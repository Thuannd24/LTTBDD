package com.medbook.appointment.repository;

import com.medbook.appointment.entity.AppointmentRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AppointmentRequestRepository extends JpaRepository<AppointmentRequest, String> {
    Page<AppointmentRequest> findByPatientUserIdOrderByCreatedAtDesc(String patientUserId, Pageable pageable);
    Page<AppointmentRequest> findByStatusOrderByCreatedAtAsc(AppointmentRequest.RequestStatus status, Pageable pageable);
}
