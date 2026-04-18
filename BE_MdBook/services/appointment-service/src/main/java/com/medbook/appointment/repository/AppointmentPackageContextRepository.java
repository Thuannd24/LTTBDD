package com.medbook.appointment.repository;

import com.medbook.appointment.entity.AppointmentPackageContext;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AppointmentPackageContextRepository extends JpaRepository<AppointmentPackageContext, String> {
    Optional<AppointmentPackageContext> findByAppointmentId(String appointmentId);
}
