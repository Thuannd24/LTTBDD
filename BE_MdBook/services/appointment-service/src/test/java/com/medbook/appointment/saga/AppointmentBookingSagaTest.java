package com.medbook.appointment.saga;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.medbook.appointment.dto.request.CreateAppointmentRequest;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.entity.AppointmentPackageContext;
import com.medbook.appointment.entity.AppointmentSaga;
import com.medbook.appointment.repository.AppointmentPackageContextRepository;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.repository.AppointmentResourceReservationRepository;
import com.medbook.appointment.repository.AppointmentSagaRepository;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AppointmentBookingSagaTest {

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private AppointmentSagaRepository appointmentSagaRepository;

    @Mock
    private AppointmentPackageContextRepository appointmentPackageContextRepository;

    @Mock
    private AppointmentResourceReservationRepository reservationRepository;

    @Mock
    private OutboxEventService outboxEventService;

    private AppointmentBookingSaga bookingSaga;

    @BeforeEach
    void setUp() {
        bookingSaga = new AppointmentBookingSaga(
                appointmentRepository,
                appointmentSagaRepository,
                appointmentPackageContextRepository,
                reservationRepository,
                outboxEventService);
    }

    @Test
    void startBooking_persistsSagaContextAndDoctorReserveCommand() {
        Appointment appointment = appointment();
        CreateAppointmentRequest request = CreateAppointmentRequest.builder()
                .roomSlotId(22L)
                .equipmentSlotId(33L)
                .build();
        when(appointmentSagaRepository.findBySagaId("saga-1")).thenReturn(Optional.empty());
        when(appointmentPackageContextRepository.findByAppointmentId("apt-1")).thenReturn(Optional.empty());
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(invocation -> invocation.getArgument(0));

        bookingSaga.startBooking(appointment, request);

        ArgumentCaptor<AppointmentSaga> sagaCaptor = ArgumentCaptor.forClass(AppointmentSaga.class);
        verify(appointmentSagaRepository).save(sagaCaptor.capture());
        assertThat(sagaCaptor.getValue().getStatus()).isEqualTo(AppointmentSaga.SagaStatus.IN_PROGRESS);
        assertThat(sagaCaptor.getValue().getCompensationIndex()).isEqualTo(0);

        ArgumentCaptor<AppointmentPackageContext> contextCaptor = ArgumentCaptor.forClass(AppointmentPackageContext.class);
        verify(appointmentPackageContextRepository).save(contextCaptor.capture());
        assertThat(contextCaptor.getValue().getValidationContext()).isEqualTo(Map.of(
                "roomSlotId", 22L,
                "equipmentSlotId", 33L));

        ArgumentCaptor<SagaCommand> commandCaptor = ArgumentCaptor.forClass(SagaCommand.class);
        verify(outboxEventService).enqueue(eq("apt-1"), eq(SagaEventType.DOCTOR_RESERVE_COMMAND), commandCaptor.capture());
        assertThat(commandCaptor.getValue().getDoctorId()).isEqualTo("doctor-1");
        assertThat(commandCaptor.getValue().getDoctorScheduleId()).isEqualTo(11L);
    }

    @Test
    void handleRoomReserved_withoutEquipment_completesBooking() {
        Appointment appointment = appointment();
        AppointmentSaga saga = AppointmentSaga.builder()
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .status(AppointmentSaga.SagaStatus.IN_PROGRESS)
                .compensationIndex(1)
                .build();
        when(appointmentRepository.findById("apt-1")).thenReturn(Optional.of(appointment));
        when(appointmentSagaRepository.findBySagaId("saga-1")).thenReturn(Optional.of(saga));
        when(appointmentPackageContextRepository.findByAppointmentId("apt-1")).thenReturn(Optional.of(
                AppointmentPackageContext.builder()
                        .appointmentId("apt-1")
                        .packageStepId("step-1")
                        .validationContext(Map.of("roomSlotId", 22L))
                        .build()));

        bookingSaga.handleReply(SagaReply.builder()
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .eventType(SagaEventType.ROOM_SLOT_RESERVED)
                .roomSlotId(22L)
                .build());

        ArgumentCaptor<Appointment> appointmentCaptor = ArgumentCaptor.forClass(Appointment.class);
        verify(appointmentRepository, org.mockito.Mockito.atLeastOnce()).save(appointmentCaptor.capture());
        assertThat(appointmentCaptor.getAllValues().getLast().getStatus()).isEqualTo(Appointment.AppointmentStatus.CONFIRMED);

        ArgumentCaptor<SagaCommand> commandCaptor = ArgumentCaptor.forClass(SagaCommand.class);
        verify(outboxEventService).enqueue(eq("apt-1"), eq(SagaEventType.APPOINTMENT_BOOKED), commandCaptor.capture());
        assertThat(commandCaptor.getValue().getEventType()).isEqualTo(SagaEventType.APPOINTMENT_BOOKED);
    }

    @Test
    void handleRoomReserveFailed_marksBookingFailedAndStartsCompensation() {
        Appointment appointment = appointment();
        AppointmentSaga saga = AppointmentSaga.builder()
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .status(AppointmentSaga.SagaStatus.IN_PROGRESS)
                .compensationIndex(1)
                .build();
        when(appointmentRepository.findById("apt-1")).thenReturn(Optional.of(appointment));
        when(appointmentSagaRepository.findBySagaId("saga-1")).thenReturn(Optional.of(saga));

        bookingSaga.handleReply(SagaReply.builder()
                .appointmentId("apt-1")
                .sagaId("saga-1")
                .eventType(SagaEventType.ROOM_SLOT_RESERVE_FAILED)
                .errorCode("ROOM_UNAVAILABLE")
                .errorMessage("Room slot not available")
                .build());

        assertThat(appointment.getStatus()).isEqualTo(Appointment.AppointmentStatus.BOOKING_FAILED);
        assertThat(saga.getStatus()).isEqualTo(AppointmentSaga.SagaStatus.COMPENSATING);

        ArgumentCaptor<SagaCommand> commandCaptor = ArgumentCaptor.forClass(SagaCommand.class);
        verify(outboxEventService).enqueue(eq("apt-1"), eq(SagaEventType.DOCTOR_RELEASE_COMMAND), commandCaptor.capture());
        assertThat(commandCaptor.getValue().getDoctorScheduleId()).isEqualTo(11L);
    }

    private Appointment appointment() {
        return Appointment.builder()
                .id("apt-1")
                .sagaId("saga-1")
                .patientUserId("user-1")
                .doctorId("doctor-1")
                .doctorScheduleId(11L)
                .facilityId("facility-1")
                .packageId("pkg-1")
                .packageStepId("step-1")
                .status(Appointment.AppointmentStatus.BOOKING_PENDING)
                .build();
    }
}
