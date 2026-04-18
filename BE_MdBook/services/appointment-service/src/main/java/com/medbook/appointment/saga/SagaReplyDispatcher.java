package com.medbook.appointment.saga;

import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.repository.AppointmentRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SagaReplyDispatcher {

    AppointmentRepository appointmentRepository;
    AppointmentBookingSaga appointmentBookingSaga;
    AppointmentCancelSaga appointmentCancelSaga;

    public void dispatch(SagaReply reply) {
        switch (reply.getEventType()) {
            case DOCTOR_RESERVED,
                 DOCTOR_RESERVE_FAILED,
                 ROOM_SLOT_RESERVED,
                 ROOM_SLOT_RESERVE_FAILED,
                 EQUIPMENT_SLOT_RESERVED,
                 EQUIPMENT_SLOT_RESERVE_FAILED -> appointmentBookingSaga.handleReply(reply);
            case DOCTOR_RELEASED,
                 DOCTOR_RELEASE_FAILED,
                 ROOM_SLOT_RELEASED,
                 ROOM_SLOT_RELEASE_FAILED,
                 EQUIPMENT_SLOT_RELEASED,
                 EQUIPMENT_SLOT_RELEASE_FAILED -> routeReleaseReply(reply);
            default -> throw new IllegalArgumentException("Unsupported reply event type: " + reply.getEventType());
        }
    }

    private void routeReleaseReply(SagaReply reply) {
        Appointment appointment = appointmentRepository.findById(reply.getAppointmentId())
                .orElseThrow(() -> new IllegalArgumentException("Appointment not found for reply: " + reply.getAppointmentId()));
        if (appointment.getStatus() == Appointment.AppointmentStatus.CANCELLATION_PENDING) {
            appointmentCancelSaga.handleReply(reply);
            return;
        }
        appointmentBookingSaga.handleReply(reply);
    }
}
