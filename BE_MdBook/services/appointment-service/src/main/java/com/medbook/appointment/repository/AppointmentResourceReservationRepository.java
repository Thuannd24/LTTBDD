package com.medbook.appointment.repository;

import com.medbook.appointment.entity.AppointmentResourceReservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AppointmentResourceReservationRepository extends JpaRepository<AppointmentResourceReservation, String> {
    List<AppointmentResourceReservation> findByAppointmentId(String appointmentId);
    Optional<AppointmentResourceReservation> findByAppointmentIdAndTargetTypeAndSlotId(
            String appointmentId,
            AppointmentResourceReservation.ResourceTargetType targetType,
            String slotId);
}
