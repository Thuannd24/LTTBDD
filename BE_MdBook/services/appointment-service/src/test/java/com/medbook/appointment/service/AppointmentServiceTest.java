package com.medbook.appointment.service;

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
import com.medbook.appointment.grpc.client.DoctorGrpcClient;
import com.medbook.appointment.grpc.client.SlotGrpcClient;
import com.medbook.appointment.grpc.model.DoctorInfo;
import com.medbook.appointment.grpc.model.DoctorScheduleInfo;
import com.medbook.appointment.grpc.model.EquipmentInfo;
import com.medbook.appointment.grpc.model.RoomInfo;
import com.medbook.appointment.grpc.model.SlotInfo;
import com.medbook.appointment.mapper.AppointmentMapper;
import com.medbook.appointment.repository.AppointmentRepository;
import com.medbook.appointment.saga.AppointmentBookingSaga;
import com.medbook.appointment.saga.AppointmentCancelSaga;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AppointmentServiceTest {

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private AppointmentMapper appointmentMapper;

    @Mock
    private ExamPackageService examPackageService;

    @Mock
    private ExamPackageStepService examPackageStepService;

    @Mock
    private DoctorGrpcClient doctorGrpcClient;

    @Mock
    private SlotGrpcClient slotGrpcClient;

    @Mock
    private AppointmentBookingSaga appointmentBookingSaga;

    @Mock
    private AppointmentCancelSaga appointmentCancelSaga;

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
                .sagaId("saga-001")
                .patientUserId(currentUserId)
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .facilityId("facility-001")
                .packageId("pkg-001")
                .packageStepId("step-001")
                .status(Appointment.AppointmentStatus.BOOKING_PENDING)
                .note("Test appointment")
                .build();

        testResponse = AppointmentResponse.builder()
                .id("apt-001")
                .sagaId("saga-001")
                .patientUserId(currentUserId)
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .status("BOOKING_PENDING")
                .build();

        testStatusResponse = AppointmentStatusResponse.builder()
                .status("CONFIRMED")
                .build();
    }

    @Test
    void createAppointment_success() {
        mockSuccessfulValidation();
        when(appointmentRepository.save(any(Appointment.class))).thenReturn(testAppointment);

        CreateAppointmentResponse response = appointmentService.createAppointment(validRequest, currentUserId);

        assertThat(response.getAppointmentId()).isEqualTo("apt-001");
        assertThat(response.getSagaId()).isEqualTo("saga-001");
        assertThat(response.getStatus()).isEqualTo("BOOKING_PENDING");
        verify(appointmentRepository, times(1)).save(any(Appointment.class));
        verify(appointmentBookingSaga).startBooking(testAppointment, validRequest);
    }

    @Test
    void createAppointment_rejectsWhenStepDoesNotBelongToPackage() {
        mockSuccessfulValidation();
        when(examPackageStepService.getStepById("step-001")).thenReturn(ExamPackageStepResponse.builder()
                .id("step-001")
                .packageId("pkg-other")
                .allowedSpecialtyIds(List.of("specialty-1"))
                .requiredRoomCategory("LAB_ROOM")
                .requiredEquipmentType("XRAY_MACHINE")
                .equipmentRequired(true)
                .build());

        assertThatThrownBy(() -> appointmentService.createAppointment(validRequest, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("does not belong");
    }

    @Test
    void createAppointment_rejectsWhenDoctorInactive() {
        mockSuccessfulValidation();
        when(doctorGrpcClient.getDoctorById("doctor-123")).thenReturn(new DoctorInfo(
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
        when(doctorGrpcClient.getDoctorScheduleById("1", "doctor-123")).thenReturn(new DoctorScheduleInfo(
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
    void createAppointment_rejectsWhenSpecialtyMismatch() {
        mockSuccessfulValidation();
        when(examPackageStepService.getStepById("step-001")).thenReturn(ExamPackageStepResponse.builder()
                .id("step-001")
                .packageId("pkg-001")
                .allowedSpecialtyIds(List.of("specialty-x"))
                .requiredRoomCategory("LAB_ROOM")
                .requiredEquipmentType("XRAY_MACHINE")
                .equipmentRequired(true)
                .build());

        assertThatThrownBy(() -> appointmentService.createAppointment(validRequest, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("specialty");
    }

    @Test
    void createAppointment_rejectsWhenRoomSlotUnavailable() {
        mockSuccessfulValidation();
        when(slotGrpcClient.getSlotById("2")).thenReturn(new SlotInfo(
                "2",
                "ROOM",
                "room-001",
                "2026-04-07",
                "08:00",
                "09:00",
                false
        ));

        assertThatThrownBy(() -> appointmentService.createAppointment(validRequest, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("Room slot is not available");
    }

    @Test
    void createAppointment_rejectsWhenEquipmentRequiredButMissing() {
        mockSuccessfulValidation();
        CreateAppointmentRequest requestWithoutEquipment = CreateAppointmentRequest.builder()
                .packageId("pkg-001")
                .packageStepId("step-001")
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .roomSlotId(2L)
                .note("Test")
                .facilityId("facility-001")
                .build();

        assertThatThrownBy(() -> appointmentService.createAppointment(requestWithoutEquipment, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("Equipment slot ID is required");
    }

    @Test
    void createAppointment_rejectsWhenEquipmentProvidedButNotRequired() {
        mockSuccessfulValidation();
        when(examPackageStepService.getStepById("step-001")).thenReturn(ExamPackageStepResponse.builder()
                .id("step-001")
                .packageId("pkg-001")
                .allowedSpecialtyIds(List.of("specialty-1"))
                .requiredRoomCategory("LAB_ROOM")
                .equipmentRequired(false)
                .build());

        assertThatThrownBy(() -> appointmentService.createAppointment(validRequest, currentUserId))
                .isInstanceOf(AppointmentValidationException.class)
                .hasMessageContaining("must not be provided");
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
                .sagaId("saga-001")
                .patientUserId("user-123")
                .doctorId("doctor-123")
                .status(Appointment.AppointmentStatus.CONFIRMED)
                .build();

        Appointment cancelledAppointment = Appointment.builder()
                .id("apt-001")
                .sagaId("saga-001")
                .patientUserId("user-123")
                .doctorId("doctor-123")
                .status(Appointment.AppointmentStatus.CANCELLATION_PENDING)
                .cancelReason("Need to reschedule")
                .build();

        when(appointmentRepository.findById("apt-001")).thenReturn(Optional.of(confirmedAppointment));
        when(appointmentCancelSaga.startCancellation(confirmedAppointment, "Need to reschedule")).thenReturn(cancelledAppointment);
        when(appointmentMapper.toResponse(cancelledAppointment)).thenReturn(AppointmentResponse.builder()
                .id("apt-001")
                .status("CANCELLATION_PENDING")
                .cancelReason("Need to reschedule")
                .build());

        AppointmentResponse response = appointmentService.cancelAppointment("apt-001", cancelRequest, currentUserId);

        assertThat(response.getStatus()).isEqualTo("CANCELLATION_PENDING");
        assertThat(response.getCancelReason()).isEqualTo("Need to reschedule");
        verify(appointmentCancelSaga).startCancellation(confirmedAppointment, "Need to reschedule");
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

        lenient().when(examPackageStepService.getStepById("step-001")).thenReturn(ExamPackageStepResponse.builder()
                .id("step-001")
                .packageId("pkg-001")
                .allowedSpecialtyIds(List.of("specialty-1"))
                .requiredRoomCategory("LAB_ROOM")
                .requiredEquipmentType("XRAY_MACHINE")
                .equipmentRequired(true)
                .build());

        lenient().when(doctorGrpcClient.getDoctorById("doctor-123")).thenReturn(new DoctorInfo(
                "doctor-123",
                "Doctor A",
                "specialty-1",
                List.of("specialty-1"),
                true
        ));

        lenient().when(doctorGrpcClient.getDoctorScheduleById("1", "doctor-123")).thenReturn(new DoctorScheduleInfo(
                "1",
                "doctor-123",
                "2026-04-07",
                "08:00",
                "09:00",
                true
        ));

        lenient().when(slotGrpcClient.getSlotById("2")).thenReturn(new SlotInfo(
                "2",
                "ROOM",
                "room-001",
                "2026-04-07",
                "08:00",
                "09:00",
                true
        ));

        lenient().when(slotGrpcClient.getRoomById("room-001")).thenReturn(new RoomInfo(
                "room-001",
                "Lab Room 1",
                "LAB_ROOM",
                true
        ));

        lenient().when(slotGrpcClient.getSlotById("3")).thenReturn(new SlotInfo(
                "3",
                "EQUIPMENT",
                "equipment-001",
                "2026-04-07",
                "08:00",
                "09:00",
                true
        ));

        lenient().when(slotGrpcClient.getEquipmentById("equipment-001")).thenReturn(new EquipmentInfo(
                "equipment-001",
                "XRay Machine",
                "XRAY_MACHINE",
                true
        ));
    }
}
