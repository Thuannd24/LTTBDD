package com.medbook.appointment.saga;

import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.entity.AppointmentResourceReservation;
import com.medbook.appointment.entity.AppointmentSaga;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.repository.AppointmentResourceReservationRepository;
import com.medbook.appointment.repository.AppointmentSagaRepository;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class AppointmentCancelSaga {

    AppointmentRepository appointmentRepository;
    AppointmentSagaRepository appointmentSagaRepository;
    AppointmentResourceReservationRepository reservationRepository;
    OutboxEventService outboxEventService;

    @Transactional
    public Appointment startCancellation(Appointment appointment, String reason) {
        if (appointment.getStatus() != Appointment.AppointmentStatus.CONFIRMED) {
            throw new AppointmentValidationException("Only confirmed appointments can be cancelled");
        }

        appointment.setStatus(Appointment.AppointmentStatus.CANCELLATION_PENDING);
        appointment.setCancelReason(reason);
        appointment.setFailureCode(null);
        appointment.setFailureMessage(null);
        appointmentRepository.save(appointment);

        AppointmentSaga saga = appointmentSagaRepository.findBySagaId(appointment.getSagaId())
                .orElse(AppointmentSaga.builder()
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .build());
        saga.setStatus(AppointmentSaga.SagaStatus.IN_PROGRESS);
        saga.setCompensationIndex(countReservedResources(appointment.getId()));
        appointmentSagaRepository.save(saga);

        enqueueNextRelease(appointment);
        log.info("Cancellation saga started for appointment {} with saga {}", appointment.getId(), appointment.getSagaId());
        return appointment;
    }

    @Transactional
    public void handleReply(SagaReply reply) {
        Appointment appointment = getAppointment(reply.getAppointmentId());
        AppointmentSaga saga = getSaga(reply.getSagaId());

        switch (reply.getEventType()) {
            case EQUIPMENT_SLOT_RELEASED ->
                    handleReleased(appointment, saga, AppointmentResourceReservation.ResourceTargetType.EQUIPMENT, reply.getEquipmentSlotId());
            case ROOM_SLOT_RELEASED ->
                    handleReleased(appointment, saga, AppointmentResourceReservation.ResourceTargetType.ROOM, reply.getRoomSlotId());
            case DOCTOR_RELEASED ->
                    handleReleased(appointment, saga, AppointmentResourceReservation.ResourceTargetType.DOCTOR, appointment.getDoctorScheduleId());
            case EQUIPMENT_SLOT_RELEASE_FAILED, ROOM_SLOT_RELEASE_FAILED, DOCTOR_RELEASE_FAILED ->
                    handleReleaseFailure(appointment, saga, reply);
            default -> throw new IllegalArgumentException("Unsupported cancellation reply: " + reply.getEventType());
        }
    }

    private void handleReleased(
            Appointment appointment,
            AppointmentSaga saga,
            AppointmentResourceReservation.ResourceTargetType targetType,
            Long slotId) {
        if (slotId != null) {
            reservationRepository.findByAppointmentIdAndTargetTypeAndSlotId(
                            appointment.getId(),
                            targetType,
                            String.valueOf(slotId))
                    .ifPresent(reservation -> {
                        reservation.setStatus(AppointmentResourceReservation.ReservationStatus.RELEASED);
                        reservationRepository.save(reservation);
                    });
        }

        List<AppointmentResourceReservation> remaining = findReservedResources(appointment.getId());
        if (remaining.isEmpty()) {
            finalizeCancellation(appointment, saga);
            return;
        }

        saga.setCompensationIndex(remaining.size());
        appointmentSagaRepository.save(saga);
        enqueueReleaseForReservation(appointment, remaining.getFirst());
    }

    private void handleReleaseFailure(Appointment appointment, AppointmentSaga saga, SagaReply reply) {
        appointment.setStatus(Appointment.AppointmentStatus.CANCELLATION_FAILED);
        appointment.setFailureCode(reply.getErrorCode());
        appointment.setFailureMessage(reply.getErrorMessage());
        appointmentRepository.save(appointment);
        saga.setStatus(AppointmentSaga.SagaStatus.FAILED);
        appointmentSagaRepository.save(saga);
    }

    private void enqueueNextRelease(Appointment appointment) {
        List<AppointmentResourceReservation> reservations = findReservedResources(appointment.getId());
        if (reservations.isEmpty()) {
            finalizeCancellation(appointment, getSaga(appointment.getSagaId()));
            return;
        }

        enqueueReleaseForReservation(appointment, reservations.getFirst());
    }

    private void enqueueReleaseForReservation(Appointment appointment, AppointmentResourceReservation reservation) {
        SagaEventType eventType = switch (reservation.getTargetType()) {
            case EQUIPMENT -> SagaEventType.EQUIPMENT_SLOT_RELEASE_COMMAND;
            case ROOM -> SagaEventType.ROOM_SLOT_RELEASE_COMMAND;
            case DOCTOR -> SagaEventType.DOCTOR_RELEASE_COMMAND;
        };

        SagaCommand.SagaCommandBuilder builder = SagaCommand.builder()
                .messageId(UUID.randomUUID().toString())
                .appointmentId(appointment.getId())
                .sagaId(appointment.getSagaId())
                .eventType(eventType);

        switch (reservation.getTargetType()) {
            case EQUIPMENT -> builder.equipmentSlotId(Long.valueOf(reservation.getSlotId()));
            case ROOM -> builder.roomSlotId(Long.valueOf(reservation.getSlotId()));
            case DOCTOR -> builder.doctorId(appointment.getDoctorId()).doctorScheduleId(Long.valueOf(reservation.getSlotId()));
        }

        outboxEventService.enqueue(appointment.getId(), eventType, builder.build());
    }

    private List<AppointmentResourceReservation> findReservedResources(String appointmentId) {
        return reservationRepository.findByAppointmentId(appointmentId).stream()
                .filter(reservation -> reservation.getStatus() == AppointmentResourceReservation.ReservationStatus.RESERVED)
                .sorted(Comparator.comparingInt(this::releasePriority))
                .toList();
    }

    private int releasePriority(AppointmentResourceReservation reservation) {
        return switch (reservation.getTargetType()) {
            case EQUIPMENT -> 0;
            case ROOM -> 1;
            case DOCTOR -> 2;
        };
    }

    private int countReservedResources(String appointmentId) {
        return findReservedResources(appointmentId).size();
    }

    private void finalizeCancellation(Appointment appointment, AppointmentSaga saga) {
        appointment.setStatus(Appointment.AppointmentStatus.CANCELLED);
        appointmentRepository.save(appointment);

        saga.setStatus(AppointmentSaga.SagaStatus.COMPLETED);
        saga.setCompensationIndex(0);
        appointmentSagaRepository.save(saga);

        outboxEventService.enqueue(
                appointment.getId(),
                SagaEventType.APPOINTMENT_CANCELLED,
                SagaCommand.builder()
                        .messageId(UUID.randomUUID().toString())
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .eventType(SagaEventType.APPOINTMENT_CANCELLED)
                        .patientUserId(appointment.getPatientUserId())
                        .doctorId(appointment.getDoctorId())
                        .doctorScheduleId(appointment.getDoctorScheduleId())
                        .facilityId(appointment.getFacilityId())
                        .build());
    }

    private Appointment getAppointment(String appointmentId) {
        return appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new IllegalArgumentException("Appointment not found for saga: " + appointmentId));
    }

    private AppointmentSaga getSaga(String sagaId) {
        return appointmentSagaRepository.findBySagaId(sagaId)
                .orElseThrow(() -> new IllegalArgumentException("Saga not found: " + sagaId));
    }
}
