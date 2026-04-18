package com.medbook.appointment.repository;

import com.medbook.appointment.entity.AppointmentSaga;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AppointmentSagaRepository extends JpaRepository<AppointmentSaga, String> {
    Optional<AppointmentSaga> findByAppointmentId(String appointmentId);
    Optional<AppointmentSaga> findBySagaId(String sagaId);
}
