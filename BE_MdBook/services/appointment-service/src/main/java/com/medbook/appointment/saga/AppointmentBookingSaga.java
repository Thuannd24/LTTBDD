package com.medbook.appointment.saga;

import com.medbook.appointment.dto.request.CreateAppointmentRequest;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.entity.AppointmentPackageContext;
import com.medbook.appointment.entity.AppointmentResourceReservation;
import com.medbook.appointment.entity.AppointmentSaga;
import com.medbook.appointment.repository.AppointmentPackageContextRepository;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.repository.AppointmentResourceReservationRepository;
import com.medbook.appointment.repository.AppointmentSagaRepository;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
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
public class AppointmentBookingSaga {

    static final String ROOM_SLOT_ID_KEY = "roomSlotId";
    static final String EQUIPMENT_SLOT_ID_KEY = "equipmentSlotId";

    AppointmentRepository appointmentRepository;
    AppointmentSagaRepository appointmentSagaRepository;
    AppointmentPackageContextRepository appointmentPackageContextRepository;
    AppointmentResourceReservationRepository reservationRepository;
    OutboxEventService outboxEventService;

    @Transactional
    public void startBooking(Appointment appointment, CreateAppointmentRequest request) {
        AppointmentSaga saga = appointmentSagaRepository.findBySagaId(appointment.getSagaId())
                .orElse(AppointmentSaga.builder()
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .build());
        saga.setStatus(AppointmentSaga.SagaStatus.IN_PROGRESS);
        saga.setCompensationIndex(0);
        appointmentSagaRepository.save(saga);

        savePackageContext(appointment, request);
        clearFailure(appointment);

        outboxEventService.enqueue(
                appointment.getId(),
                SagaEventType.DOCTOR_RESERVE_COMMAND,
                SagaCommand.builder()
                        .messageId(UUID.randomUUID().toString())
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .eventType(SagaEventType.DOCTOR_RESERVE_COMMAND)
                        .patientUserId(appointment.getPatientUserId())
                        .facilityId(appointment.getFacilityId())
                        .doctorId(appointment.getDoctorId())
                        .doctorScheduleId(appointment.getDoctorScheduleId())
                        .build());
        log.info("Booking saga started for appointment {} with saga {}", appointment.getId(), appointment.getSagaId());
    }

    @Transactional
    public void handleReply(SagaReply reply) {
        Appointment appointment = getAppointment(reply.getAppointmentId());
        AppointmentSaga saga = getSaga(reply.getSagaId());

        switch (reply.getEventType()) {
            case DOCTOR_RESERVED -> handleDoctorReserved(appointment, saga);
            case DOCTOR_RESERVE_FAILED -> handleReserveFailure(appointment, saga, reply, false);
            case ROOM_SLOT_RESERVED -> handleRoomReserved(appointment, saga, reply);
            case ROOM_SLOT_RESERVE_FAILED -> handleRoomReserveFailed(appointment, saga, reply);
            case EQUIPMENT_SLOT_RESERVED -> handleEquipmentReserved(appointment, saga, reply);
            case EQUIPMENT_SLOT_RESERVE_FAILED -> handleEquipmentReserveFailed(appointment, saga, reply);
            case ROOM_SLOT_RELEASED, EQUIPMENT_SLOT_RELEASED, DOCTOR_RELEASED ->
                    handleCompensationReleased(appointment, saga, reply);
            case ROOM_SLOT_RELEASE_FAILED, EQUIPMENT_SLOT_RELEASE_FAILED, DOCTOR_RELEASE_FAILED ->
                    handleCompensationFailed(appointment, saga, reply);
            default -> throw new IllegalArgumentException("Unsupported booking reply: " + reply.getEventType());
        }
    }

    private void handleDoctorReserved(Appointment appointment, AppointmentSaga saga) {
        upsertReservation(
                appointment.getId(),
                AppointmentResourceReservation.ResourceTargetType.DOCTOR,
                String.valueOf(appointment.getDoctorScheduleId()),
                appointment.getDoctorId(),
                AppointmentResourceReservation.ReservationStatus.RESERVED);
        saga.setCompensationIndex(1);
        appointmentSagaRepository.save(saga);

        outboxEventService.enqueue(
                appointment.getId(),
                SagaEventType.ROOM_SLOT_RESERVE_COMMAND,
                SagaCommand.builder()
                        .messageId(UUID.randomUUID().toString())
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .eventType(SagaEventType.ROOM_SLOT_RESERVE_COMMAND)
                        .patientUserId(appointment.getPatientUserId())
                        .facilityId(appointment.getFacilityId())
                        .roomSlotId(getContextLong(appointment.getId(), ROOM_SLOT_ID_KEY))
                        .build());
    }

    private void handleRoomReserved(Appointment appointment, AppointmentSaga saga, SagaReply reply) {
        Long roomSlotId = getRequired(reply.getRoomSlotId(), getContextLong(appointment.getId(), ROOM_SLOT_ID_KEY));
        upsertReservation(
                appointment.getId(),
                AppointmentResourceReservation.ResourceTargetType.ROOM,
                String.valueOf(roomSlotId),
                String.valueOf(roomSlotId),
                AppointmentResourceReservation.ReservationStatus.RESERVED);
        saga.setCompensationIndex(2);
        appointmentSagaRepository.save(saga);

        Long equipmentSlotId = getContextLong(appointment.getId(), EQUIPMENT_SLOT_ID_KEY);
        if (equipmentSlotId == null) {
            completeBooking(appointment, saga);
            return;
        }

        outboxEventService.enqueue(
                appointment.getId(),
                SagaEventType.EQUIPMENT_SLOT_RESERVE_COMMAND,
                SagaCommand.builder()
                        .messageId(UUID.randomUUID().toString())
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .eventType(SagaEventType.EQUIPMENT_SLOT_RESERVE_COMMAND)
                        .patientUserId(appointment.getPatientUserId())
                        .facilityId(appointment.getFacilityId())
                        .equipmentSlotId(equipmentSlotId)
                        .build());
    }

    private void handleEquipmentReserved(Appointment appointment, AppointmentSaga saga, SagaReply reply) {
        Long equipmentSlotId = getRequired(reply.getEquipmentSlotId(), getContextLong(appointment.getId(), EQUIPMENT_SLOT_ID_KEY));
        upsertReservation(
                appointment.getId(),
                AppointmentResourceReservation.ResourceTargetType.EQUIPMENT,
                String.valueOf(equipmentSlotId),
                String.valueOf(equipmentSlotId),
                AppointmentResourceReservation.ReservationStatus.RESERVED);
        saga.setCompensationIndex(3);
        appointmentSagaRepository.save(saga);
        completeBooking(appointment, saga);
    }

    private void handleRoomReserveFailed(Appointment appointment, AppointmentSaga saga, SagaReply reply) {
        handleReserveFailure(appointment, saga, reply, true);
        enqueueDoctorRelease(appointment);
    }

    private void handleEquipmentReserveFailed(Appointment appointment, AppointmentSaga saga, SagaReply reply) {
        handleReserveFailure(appointment, saga, reply, true);
        outboxEventService.enqueue(
                appointment.getId(),
                SagaEventType.ROOM_SLOT_RELEASE_COMMAND,
                SagaCommand.builder()
                        .messageId(UUID.randomUUID().toString())
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .eventType(SagaEventType.ROOM_SLOT_RELEASE_COMMAND)
                        .roomSlotId(getContextLong(appointment.getId(), ROOM_SLOT_ID_KEY))
                        .build());
    }

    private void handleReserveFailure(Appointment appointment, AppointmentSaga saga, SagaReply reply, boolean compensating) {
        appointment.setStatus(Appointment.AppointmentStatus.BOOKING_FAILED);
        appointment.setFailureCode(reply.getErrorCode());
        appointment.setFailureMessage(defaultMessage(reply));
        appointmentRepository.save(appointment);
        saga.setStatus(compensating ? AppointmentSaga.SagaStatus.COMPENSATING : AppointmentSaga.SagaStatus.FAILED);
        appointmentSagaRepository.save(saga);
    }

    private void handleCompensationReleased(Appointment appointment, AppointmentSaga saga, SagaReply reply) {
        switch (reply.getEventType()) {
            case EQUIPMENT_SLOT_RELEASED -> {
                updateReservationStatus(
                        appointment.getId(),
                        AppointmentResourceReservation.ResourceTargetType.EQUIPMENT,
                        String.valueOf(getRequired(reply.getEquipmentSlotId(), getContextLong(appointment.getId(), EQUIPMENT_SLOT_ID_KEY))),
                        AppointmentResourceReservation.ReservationStatus.RELEASED);
                outboxEventService.enqueue(
                        appointment.getId(),
                        SagaEventType.ROOM_SLOT_RELEASE_COMMAND,
                        SagaCommand.builder()
                                .messageId(UUID.randomUUID().toString())
                                .appointmentId(appointment.getId())
                                .sagaId(appointment.getSagaId())
                                .eventType(SagaEventType.ROOM_SLOT_RELEASE_COMMAND)
                                .roomSlotId(getContextLong(appointment.getId(), ROOM_SLOT_ID_KEY))
                                .build());
            }
            case ROOM_SLOT_RELEASED -> {
                updateReservationStatus(
                        appointment.getId(),
                        AppointmentResourceReservation.ResourceTargetType.ROOM,
                        String.valueOf(getRequired(reply.getRoomSlotId(), getContextLong(appointment.getId(), ROOM_SLOT_ID_KEY))),
                        AppointmentResourceReservation.ReservationStatus.RELEASED);
                enqueueDoctorRelease(appointment);
            }
            case DOCTOR_RELEASED -> {
                updateReservationStatus(
                        appointment.getId(),
                        AppointmentResourceReservation.ResourceTargetType.DOCTOR,
                        String.valueOf(appointment.getDoctorScheduleId()),
                        AppointmentResourceReservation.ReservationStatus.RELEASED);
                saga.setStatus(AppointmentSaga.SagaStatus.COMPENSATED);
                saga.setCompensationIndex(0);
                appointmentSagaRepository.save(saga);
            }
            default -> throw new IllegalArgumentException("Unsupported compensation release reply: " + reply.getEventType());
        }
    }

    private void handleCompensationFailed(Appointment appointment, AppointmentSaga saga, SagaReply reply) {
        appointment.setFailureCode(reply.getErrorCode());
        appointment.setFailureMessage(defaultMessage(reply));
        appointmentRepository.save(appointment);
        saga.setStatus(AppointmentSaga.SagaStatus.FAILED);
        appointmentSagaRepository.save(saga);
    }

    private void completeBooking(Appointment appointment, AppointmentSaga saga) {
        appointment.setStatus(Appointment.AppointmentStatus.CONFIRMED);
        clearFailure(appointment);
        saga.setStatus(AppointmentSaga.SagaStatus.COMPLETED);
        appointmentRepository.save(appointment);
        appointmentSagaRepository.save(saga);

        outboxEventService.enqueue(
                appointment.getId(),
                SagaEventType.APPOINTMENT_BOOKED,
                SagaCommand.builder()
                        .messageId(UUID.randomUUID().toString())
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .eventType(SagaEventType.APPOINTMENT_BOOKED)
                        .patientUserId(appointment.getPatientUserId())
                        .doctorId(appointment.getDoctorId())
                        .doctorScheduleId(appointment.getDoctorScheduleId())
                        .facilityId(appointment.getFacilityId())
                        .build());
    }

    private void enqueueDoctorRelease(Appointment appointment) {
        outboxEventService.enqueue(
                appointment.getId(),
                SagaEventType.DOCTOR_RELEASE_COMMAND,
                SagaCommand.builder()
                        .messageId(UUID.randomUUID().toString())
                        .appointmentId(appointment.getId())
                        .sagaId(appointment.getSagaId())
                        .eventType(SagaEventType.DOCTOR_RELEASE_COMMAND)
                        .doctorId(appointment.getDoctorId())
                        .doctorScheduleId(appointment.getDoctorScheduleId())
                        .build());
    }

    private void savePackageContext(Appointment appointment, CreateAppointmentRequest request) {
        Map<String, Object> context = new HashMap<>();
        context.put(ROOM_SLOT_ID_KEY, request.getRoomSlotId());
        context.put(EQUIPMENT_SLOT_ID_KEY, request.getEquipmentSlotId());

        AppointmentPackageContext packageContext = appointmentPackageContextRepository.findByAppointmentId(appointment.getId())
                .orElse(AppointmentPackageContext.builder()
                        .appointmentId(appointment.getId())
                        .packageStepId(appointment.getPackageStepId())
                        .build());
        packageContext.setPackageStepId(appointment.getPackageStepId());
        packageContext.setValidationContext(context);
        appointmentPackageContextRepository.save(packageContext);
    }

    private void upsertReservation(
            String appointmentId,
            AppointmentResourceReservation.ResourceTargetType targetType,
            String slotId,
            String targetId,
            AppointmentResourceReservation.ReservationStatus status) {
        AppointmentResourceReservation reservation = reservationRepository
                .findByAppointmentIdAndTargetTypeAndSlotId(appointmentId, targetType, slotId)
                .orElse(AppointmentResourceReservation.builder()
                        .appointmentId(appointmentId)
                        .targetType(targetType)
                        .slotId(slotId)
                        .targetId(targetId)
                        .build());
        reservation.setTargetId(targetId);
        reservation.setStatus(status);
        reservationRepository.save(reservation);
    }

    private void updateReservationStatus(
            String appointmentId,
            AppointmentResourceReservation.ResourceTargetType targetType,
            String slotId,
            AppointmentResourceReservation.ReservationStatus status) {
        reservationRepository.findByAppointmentIdAndTargetTypeAndSlotId(appointmentId, targetType, slotId)
                .ifPresent(reservation -> {
                    reservation.setStatus(status);
                    reservationRepository.save(reservation);
                });
    }

    private Long getContextLong(String appointmentId, String key) {
        return appointmentPackageContextRepository.findByAppointmentId(appointmentId)
                .map(AppointmentPackageContext::getValidationContext)
                .map(context -> context.get(key))
                .map(this::toLong)
                .orElse(null);
    }

    private Long toLong(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        return Long.parseLong(value.toString());
    }

    private Long getRequired(Long replyValue, Long fallbackValue) {
        return replyValue != null ? replyValue : fallbackValue;
    }

    private String defaultMessage(SagaReply reply) {
        return Objects.requireNonNullElse(reply.getErrorMessage(), "Saga step failed");
    }

    private void clearFailure(Appointment appointment) {
        appointment.setFailureCode(null);
        appointment.setFailureMessage(null);
        appointmentRepository.save(appointment);
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
