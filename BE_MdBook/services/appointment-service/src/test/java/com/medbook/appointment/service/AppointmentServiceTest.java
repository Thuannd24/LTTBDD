package com.medbook.appointment.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.medbook.appointment.client.doctor.DoctorServiceClient;
import com.medbook.appointment.client.model.DoctorInfo;
import com.medbook.appointment.client.model.DoctorScheduleInfo;
import com.medbook.appointment.client.slot.SlotServiceClient;
import com.medbook.appointment.dto.request.CancelAppointmentRequest;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.exception.AppointmentNotFoundException;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.mapper.AppointmentMapper;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.service.command.CreateAppointmentCommand;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

@ExtendWith(MockitoExtension.class)
class AppointmentServiceTest {

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private AppointmentMapper appointmentMapper;

    @Mock
    private ExamPackageService examPackageService;

    @Mock
    private DoctorServiceClient doctorServiceClient;

    @Mock
    private SlotServiceClient slotServiceClient;

    @InjectMocks
    private AppointmentService appointmentService;

    private CreateAppointmentCommand validRequest;
    private Appointment testAppointment;
    private AppointmentResponse testResponse;
    private AppointmentStatusResponse testStatusResponse;
    private String currentUserId;

    @BeforeEach
    void setUp() {
        currentUserId = "user-123";

        validRequest = CreateAppointmentCommand.builder()
                .packageId("pkg-001")
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .roomSlotId(2L)
                .equipmentSlotId(3L)
                .note("Test appointment")
                .facilityId("facility-001")
                .build();

        testAppointment = Appointment.builder()
                .id("apt-001")
                .patientUserId(currentUserId)
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .facilityId("facility-001")
                .packageId("pkg-001")
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .note("Test appointment")
                .build();

        testResponse = AppointmentResponse.builder()
                .id("apt-001")
                .patientUserId(currentUserId)
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .status("CONFIRMED")
                .build();

        testStatusResponse = AppointmentStatusResponse.builder()
                .status("CONFIRMED")
                .build();
    }

    @Test
    void createConfirmedAppointment_success() {
        mockSuccessfulValidation();
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(invocation -> {
            Appointment appointment = invocation.getArgument(0);
            if (appointment.getId() == null) {
                appointment.setId("apt-001");
            }
            return appointment;
        });
        when(appointmentMapper.toResponse(any(Appointment.class))).thenReturn(AppointmentResponse.builder()
                .id("apt-001")
                .patientUserId(currentUserId)
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .status("CONFIRMED")
                .build());

        AppointmentResponse response = appointmentService.createConfirmedAppointment(validRequest, currentUserId);

        assertThat(response.getId()).isNotBlank();
        assertThat(response.getStatus()).isEqualTo("CONFIRMED");
        verify(doctorServiceClient).reserveSchedule(eq(1L), anyString());
        verify(slotServiceClient).reserveSlot(eq(2L), anyString());
        verify(slotServiceClient).reserveSlot(eq(3L), anyString());
    }

    @Test
    void createConfirmedAppointment_rejectsWhenDoctorInactive() {
        mockSuccessfulValidation();
        when(doctorServiceClient.getDoctorById("doctor-123")).thenReturn(new DoctorInfo(
                "doctor-123",
                "Doctor A",
                "specialty-1",
                List.of("specialty-1"),
                false
        ));

        assertThatThrownBy(() -> appointmentService.createConfirmedAppointment(validRequest, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("inactive");
    }

    @Test
    void createConfirmedAppointment_rejectsWhenScheduleUnavailable() {
        mockSuccessfulValidation();
        when(doctorServiceClient.getDoctorScheduleById("1", "doctor-123")).thenReturn(new DoctorScheduleInfo(
                "1",
                "doctor-123",
                "2026-04-07",
                "08:00",
                "09:00",
                false
        ));

        assertThatThrownBy(() -> appointmentService.createConfirmedAppointment(validRequest, currentUserId))
                .isInstanceOf(DoctorScheduleNotFoundException.class)
                .hasMessageContaining("not available");
    }

    @Test
    void createConfirmedAppointment_rejectsWhenPackageMissing() {
        mockSuccessfulValidation();
        when(examPackageService.getPackageById("pkg-001"))
                .thenThrow(new RuntimeException("missing package"));

        assertThatThrownBy(() -> appointmentService.createConfirmedAppointment(validRequest, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("Package not found");
    }

    @Test
    void getAppointment_success() {
        when(appointmentRepository.findById("apt-001")).thenReturn(Optional.of(testAppointment));
        when(appointmentMapper.toResponse(testAppointment)).thenReturn(testResponse);

        AppointmentResponse response = appointmentService.getAppointment("apt-001");

        assertThat(response.getId()).isEqualTo("apt-001");
        assertThat(response.getPatientUserId()).isEqualTo("user-123");
    }

    @Test
    void getAppointment_notFound() {
        when(appointmentRepository.findById("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> appointmentService.getAppointment("missing"))
                .isInstanceOf(AppointmentNotFoundException.class);
    }

    @Test
    void getAppointmentStatus_success() {
        when(appointmentRepository.findById("apt-001")).thenReturn(Optional.of(testAppointment));
        when(appointmentMapper.toStatusResponse(testAppointment)).thenReturn(testStatusResponse);

        AppointmentStatusResponse response = appointmentService.getAppointmentStatus("apt-001");

        assertThat(response.getStatus()).isEqualTo("CONFIRMED");
    }

    @Test
    void getMyAppointments_success() {
        Page<Appointment> page = new PageImpl<>(List.of(testAppointment));
        when(appointmentRepository.findByPatientUserId("user-123", PageRequest.of(0, 10))).thenReturn(page);
        when(appointmentMapper.toResponse(testAppointment)).thenReturn(testResponse);

        Page<AppointmentResponse> response = appointmentService.getMyAppointments("user-123", PageRequest.of(0, 10));

        assertThat(response.getTotalElements()).isEqualTo(1);
        assertThat(response.getContent().get(0).getPatientUserId()).isEqualTo("user-123");
    }

    @Test
    void getDoctorAppointments_success() {
        Page<Appointment> page = new PageImpl<>(List.of(testAppointment));
        when(appointmentRepository.findByDoctorId("doctor-123", PageRequest.of(0, 10))).thenReturn(page);
        when(appointmentMapper.toResponse(testAppointment)).thenReturn(testResponse);

        Page<AppointmentResponse> response = appointmentService.getDoctorAppointments("doctor-123", PageRequest.of(0, 10));

        assertThat(response.getTotalElements()).isEqualTo(1);
        assertThat(response.getContent().get(0).getDoctorId()).isEqualTo("doctor-123");
    }

    @Test
    void cancelAppointment_success() {
        CancelAppointmentRequest cancelRequest = CancelAppointmentRequest.builder()
                .reason("Need to reschedule")
                .build();

        Appointment confirmedAppointment = Appointment.builder()
                .id("apt-001")
                .patientUserId("user-123")
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .roomSlotId(2L)
                .equipmentSlotId(3L)
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .build();

        when(appointmentRepository.findById("apt-001")).thenReturn(Optional.of(confirmedAppointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(appointmentMapper.toResponse(any(Appointment.class))).thenAnswer(invocation -> {
            Appointment appointment = invocation.getArgument(0);
            return AppointmentResponse.builder()
                    .id(appointment.getId())
                    .status(appointment.getStatus().name())
                    .cancelReason(appointment.getCancelReason())
                    .build();
        });

        AppointmentResponse response = appointmentService.cancelAppointment("apt-001", cancelRequest, currentUserId);

        assertThat(response.getStatus()).isEqualTo("CANCELLED");
        assertThat(response.getCancelReason()).isEqualTo("Need to reschedule");
        verify(slotServiceClient).releaseSlot(3L, "apt-001");
        verify(slotServiceClient).releaseSlot(2L, "apt-001");
        verify(doctorServiceClient).releaseSchedule(1L, "apt-001");
    }

    @Test
    void cancelAppointment_unauthorized() {
        CancelAppointmentRequest cancelRequest = CancelAppointmentRequest.builder()
                .reason("Need to reschedule")
                .build();

        Appointment otherUserAppointment = Appointment.builder()
                .id("apt-002")
                .patientUserId("other-user")
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .build();

        when(appointmentRepository.findById("apt-002")).thenReturn(Optional.of(otherUserAppointment));

        assertThatThrownBy(() -> appointmentService.cancelAppointment("apt-002", cancelRequest, currentUserId))
                .isInstanceOf(AppointmentAccessDeniedException.class);
    }

    @Test
    void completeAppointment_success() {
        Appointment confirmedAppointment = Appointment.builder()
                .id("apt-003")
                .patientUserId("user-123")
                .doctorId("doctor-123")
                .doctorScheduleId(11L)
                .roomSlotId(12L)
                .equipmentSlotId(13L)
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .build();

        when(appointmentRepository.findById("apt-003")).thenReturn(Optional.of(confirmedAppointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(appointmentMapper.toResponse(any(Appointment.class))).thenAnswer(invocation -> {
            Appointment appointment = invocation.getArgument(0);
            return AppointmentResponse.builder()
                    .id(appointment.getId())
                    .status(appointment.getStatus().name())
                    .cancelReason(appointment.getCancelReason())
                    .build();
        });

        AppointmentResponse response = appointmentService.completeAppointment("apt-003");

        assertThat(response.getStatus()).isEqualTo("COMPLETED");
        assertThat(response.getCancelReason()).isNull();
        verify(slotServiceClient).releaseSlot(13L, "apt-003");
        verify(slotServiceClient).releaseSlot(12L, "apt-003");
        verify(doctorServiceClient).releaseSchedule(11L, "apt-003");
    }

    @Test
    void completeAppointment_rejectsWhenNotConfirmed() {
        Appointment cancelledAppointment = Appointment.builder()
                .id("apt-004")
                .status(Appointment.AppointmentStatus.CANCELLED)
                .build();

        when(appointmentRepository.findById("apt-004")).thenReturn(Optional.of(cancelledAppointment));

        assertThatThrownBy(() -> appointmentService.completeAppointment("apt-004"))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("Only confirmed appointments can be completed");
    }

    private void mockSuccessfulValidation() {
        lenient().when(examPackageService.getPackageById("pkg-001")).thenReturn(ExamPackageResponse.builder()
                .id("pkg-001")
                .code("GENERAL")
                .name("General Package")
                .build());

        lenient().when(doctorServiceClient.getDoctorById("doctor-123")).thenReturn(new DoctorInfo(
                "doctor-123",
                "Doctor A",
                "specialty-1",
                List.of("specialty-1"),
                true
        ));

        lenient().when(doctorServiceClient.getDoctorScheduleById("1", "doctor-123")).thenReturn(new DoctorScheduleInfo(
                "1",
                "doctor-123",
                "2026-04-07",
                "08:00",
                "09:00",
                true
        ));
    }
}
