package com.medbook.appointment.saga;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.entity.AppointmentResourceReservation;
import com.medbook.appointment.entity.AppointmentSaga;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.repository.AppointmentResourceReservationRepository;
import com.medbook.appointment.repository.AppointmentSagaRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AppointmentCancelSagaTest {

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private AppointmentSagaRepository appointmentSagaRepository;

    @Mock
    private AppointmentResourceReservationRepository reservationRepository;

    @Mock
    private OutboxEventService outboxEventService;

    private AppointmentCancelSaga cancelSaga;

    @BeforeEach
    void setUp() {
        cancelSaga = new AppointmentCancelSaga(
                appointmentRepository,
                appointmentSagaRepository,
                reservationRepository,
                outboxEventService);
    }

    @Test
    void startCancellation_rejectsNonConfirmedAppointment() {
        Appointment appointment = appointment(Appointment.AppointmentStatus.BOOKING_PENDING);

        assertThatThrownBy(() -> cancelSaga.startCancellation(appointment, "Need to reschedule"))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("confirmed");
    }

    @Test
    void startCancellation_enqueuesEquipmentReleaseFirst() {
        Appointment appointment = appointment(Appointment.AppointmentStatus.CONFIRMED);
        AppointmentSaga saga = AppointmentSaga.builder()
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .status(AppointmentSaga.SagaStatus.COMPLETED)
                .compensationIndex(3)
                .build();
        when(appointmentSagaRepository.findBySagaId("saga-1")).thenReturn(Optional.of(saga));
        when(reservationRepository.findByAppointmentId("apt-1")).thenReturn(List.of(
                reservation(AppointmentResourceReservation.ResourceTargetType.DOCTOR, "11"),
                reservation(AppointmentResourceReservation.ResourceTargetType.ROOM, "22"),
                reservation(AppointmentResourceReservation.ResourceTargetType.EQUIPMENT, "33")));

        Appointment updated = cancelSaga.startCancellation(appointment, "Need to reschedule");

        assertThat(updated.getStatus()).isEqualTo(Appointment.AppointmentStatus.CANCELLATION_PENDING);
        ArgumentCaptor<SagaCommand> commandCaptor = ArgumentCaptor.forClass(SagaCommand.class);
        verify(outboxEventService).enqueue(eq("apt-1"), eq(SagaEventType.EQUIPMENT_SLOT_RELEASE_COMMAND), commandCaptor.capture());
        assertThat(commandCaptor.getValue().getEquipmentSlotId()).isEqualTo(33L);
    }

    @Test
    void handleDoctorReleased_finalizesCancellation() {
        Appointment appointment = appointment(Appointment.AppointmentStatus.CANCELLATION_PENDING);
        AppointmentSaga saga = AppointmentSaga.builder()
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .status(AppointmentSaga.SagaStatus.IN_PROGRESS)
                .compensationIndex(1)
                .build();
        AppointmentResourceReservation doctorReservation = reservation(AppointmentResourceReservation.ResourceTargetType.DOCTOR, "11");

        when(appointmentRepository.findById("apt-1")).thenReturn(Optional.of(appointment));
        when(appointmentSagaRepository.findBySagaId("saga-1")).thenReturn(Optional.of(saga));
        when(reservationRepository.findByAppointmentIdAndTargetTypeAndSlotId(
                "apt-1",
                AppointmentResourceReservation.ResourceTargetType.DOCTOR,
                "11")).thenReturn(Optional.of(doctorReservation));
        when(reservationRepository.findByAppointmentId("apt-1")).thenReturn(List.of());

        cancelSaga.handleReply(SagaReply.builder()
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .eventType(SagaEventType.DOCTOR_RELEASED)
                .build());

        assertThat(appointment.getStatus()).isEqualTo(Appointment.AppointmentStatus.CANCELLED);
        assertThat(saga.getStatus()).isEqualTo(AppointmentSaga.SagaStatus.COMPLETED);
        verify(outboxEventService).enqueue(eq("apt-1"), eq(SagaEventType.APPOINTMENT_CANCELLED), any(SagaCommand.class));
    }

    private Appointment appointment(Appointment.AppointmentStatus status) {
        return Appointment.builder()
                .id("apt-1")
                .sagaId("saga-1")
                .patientUserId("user-1")
                .doctorId("doctor-1")
                .doctorScheduleId(11L)
                .facilityId("facility-1")
                .packageId("pkg-1")
                .packageStepId("step-1")
                .status(status)
                .build();
    }

    private AppointmentResourceReservation reservation(
            AppointmentResourceReservation.ResourceTargetType targetType,
            String slotId) {
        return AppointmentResourceReservation.builder()
                .appointmentId("apt-1")
                .targetType(targetType)
                .slotId(slotId)
                .targetId(slotId)
                .status(AppointmentResourceReservation.ReservationStatus.RESERVED)
                .build();
    }
}
