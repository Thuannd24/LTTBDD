package com.medbook.appointment.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.medbook.appointment.client.doctor.DoctorServiceClient;
import com.medbook.appointment.client.model.DoctorInfo;
import com.medbook.appointment.client.model.DoctorScheduleInfo;
import com.medbook.appointment.client.model.EquipmentInfo;
import com.medbook.appointment.client.model.RoomInfo;
import com.medbook.appointment.client.model.SlotInfo;
import com.medbook.appointment.client.slot.SlotServiceClient;
import com.medbook.appointment.dto.request.CancelAppointmentRequest;
import com.medbook.appointment.dto.request.CreateAppointmentRequest;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.dto.response.CreateAppointmentResponse;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.exception.AppointmentNotFoundException;
import com.medbook.appointment.exception.AppointmentValidationException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.mapper.AppointmentMapper;
import com.medbook.appointment.repository.AppointmentRepository;
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

    private CreateAppointmentRequest validRequest;
    private Appointment testAppointment;
    private AppointmentResponse testResponse;
    private AppointmentStatusResponse testStatusResponse;
    private String currentUserId;

    @BeforeEach
    void setUp() {
        currentUserId = "user-123";

        validRequest = CreateAppointmentRequest.builder()
                .packageId("pkg-001")
                .packageStepId("step-001")
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
                .packageStepId("step-001")
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
    void createAppointment_success() {
        mockSuccessfulValidation();
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(invocation -> {
            Appointment appointment = invocation.getArgument(0);
            if (appointment.getId() == null) {
                appointment.setId("apt-001");
            }
            return appointment;
        });
        CreateAppointmentResponse response = appointmentService.createAppointment(validRequest, currentUserId);

        assertThat(response.getAppointmentId()).isNotBlank();
        assertThat(response.getStatus()).isEqualTo("CONFIRMED");
        verify(doctorServiceClient).reserveSchedule(1L, response.getAppointmentId());
        verify(slotServiceClient).reserveSlot(2L, response.getAppointmentId());
        verify(slotServiceClient).reserveSlot(3L, response.getAppointmentId());
    }

    @Test
    void createAppointment_rejectsWhenDoctorInactive() {
        mockSuccessfulValidation();
        when(doctorServiceClient.getDoctorById("doctor-123")).thenReturn(new DoctorInfo(
                "doctor-123",
                "Doctor A",
                "specialty-1",
                List.of("specialty-1"),
                false
        ));

        assertThatThrownBy(() -> appointmentService.createAppointment(validRequest, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("inactive");
    }

    @Test
    void createAppointment_rejectsWhenScheduleUnavailable() {
        mockSuccessfulValidation();
        when(doctorServiceClient.getDoctorScheduleById("1", "doctor-123")).thenReturn(new DoctorScheduleInfo(
                "1",
                "doctor-123",
                "2026-04-07",
                "08:00",
                "09:00",
                false
        ));

        assertThatThrownBy(() -> appointmentService.createAppointment(validRequest, currentUserId))
                .isInstanceOf(DoctorScheduleNotFoundException.class)
                .hasMessageContaining("not available");
    }

    @Test
    void createAppointment_rejectsWhenRoomSlotUnavailable() {
        mockSuccessfulValidation();
        doThrow(new RuntimeException("Room slot is not available"))
                .when(slotServiceClient).reserveSlot(eq(2L), anyString());

        assertThatThrownBy(() -> appointmentService.createAppointment(validRequest, currentUserId))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Room slot is not available");
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

        lenient().when(slotServiceClient.getSlotById("2")).thenReturn(new SlotInfo(
                "2",
                "ROOM",
                "room-001",
                "2026-04-07",
                "08:00",
                "09:00",
                true
        ));

        lenient().when(slotServiceClient.getRoomById("room-001")).thenReturn(new RoomInfo(
                "room-001",
                "Lab Room 1",
                "LAB_ROOM",
                true
        ));

        lenient().when(slotServiceClient.getSlotById("3")).thenReturn(new SlotInfo(
                "3",
                "EQUIPMENT",
                "equipment-001",
                "2026-04-07",
                "08:00",
                "09:00",
                true
        ));

        lenient().when(slotServiceClient.getEquipmentById("equipment-001")).thenReturn(new EquipmentInfo(
                "equipment-001",
                "XRay Machine",
                "XRAY_MACHINE",
                true
        ));
    }
}
