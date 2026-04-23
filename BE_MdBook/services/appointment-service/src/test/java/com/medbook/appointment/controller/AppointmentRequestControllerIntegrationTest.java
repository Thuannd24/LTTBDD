package com.medbook.appointment.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.appointment.configuration.CustomJwtDecoder;
import com.medbook.appointment.configuration.SecurityConfig;
import com.medbook.appointment.dto.request.AppointmentRequestConfirmRequest;
import com.medbook.appointment.dto.request.AppointmentRequestCreateRequest;
import com.medbook.appointment.dto.request.AppointmentRequestRejectRequest;
import com.medbook.appointment.dto.response.AppointmentRequestResponse;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.exception.AppointmentRequestNotFoundException;
import com.medbook.appointment.exception.GlobalExceptionHandler;
import com.medbook.appointment.service.AppointmentRequestService;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest({AppointmentRequestController.class, AppointmentRequestAdminController.class})
@Import({SecurityConfig.class, GlobalExceptionHandler.class})
class AppointmentRequestControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AppointmentRequestService appointmentRequestService;

    @MockBean
    private CustomJwtDecoder customJwtDecoder;

    private AppointmentRequestCreateRequest createRequest;

    @BeforeEach
    void setUp() {
        createRequest = AppointmentRequestCreateRequest.builder()
                .packageId("pkg-001")
                .doctorId("doctor-123")
                .doctorScheduleId(1L)
                .note("Need morning slot")
                .build();
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void createAppointmentRequest_success() throws Exception {
        when(appointmentRequestService.createRequest(any(), eq("user-123"))).thenReturn(
                AppointmentRequestResponse.builder()
                        .id("req-001")
                        .patientUserId("user-123")
                        .status("PENDING_ASSIGNMENT")
                        .build());

        mockMvc.perform(post("/appointment-requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest))
                        .with(csrf()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.result.id").value("req-001"))
                .andExpect(jsonPath("$.result.status").value("PENDING_ASSIGNMENT"));
    }

    @Test
    void createAppointmentRequest_unauthenticated() throws Exception {
        mockMvc.perform(post("/appointment-requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest))
                        .with(csrf()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getMyRequests_success() throws Exception {
        when(appointmentRequestService.getMyRequests(eq("user-123"), any())).thenReturn(new PageImpl<>(List.of(
                AppointmentRequestResponse.builder().id("req-001").patientUserId("user-123").build()
        )));

        mockMvc.perform(get("/appointment-requests/my").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.totalElements").value(1));
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getRequest_successForOwner() throws Exception {
        when(appointmentRequestService.getRequest("req-001")).thenReturn(AppointmentRequestResponse.builder()
                .id("req-001")
                .patientUserId("user-123")
                .status("PENDING_ASSIGNMENT")
                .build());

        mockMvc.perform(get("/appointment-requests/req-001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value("req-001"));
    }

    @Test
    @WithMockUser(username = "other-user", roles = "USER")
    void getRequest_forbiddenForOtherPatient() throws Exception {
        when(appointmentRequestService.getRequest("req-001")).thenReturn(AppointmentRequestResponse.builder()
                .id("req-001")
                .patientUserId("user-123")
                .status("PENDING_ASSIGNMENT")
                .build());

        mockMvc.perform(get("/appointment-requests/req-001"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "doctor-1", roles = "DOCTOR")
    void getPendingRequests_success() throws Exception {
        when(appointmentRequestService.getPendingRequests(any())).thenReturn(new PageImpl<>(List.of(
                AppointmentRequestResponse.builder().id("req-001").status("PENDING_ASSIGNMENT").build()
        )));

        mockMvc.perform(get("/appointment-requests/pending").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.totalElements").value(1));
    }

    @Test
    @WithMockUser(username = "staff-1", roles = "USER")
    void getPendingRequests_forbidden() throws Exception {
        mockMvc.perform(get("/appointment-requests/pending").param("page", "0").param("size", "10"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "doctor-1", roles = "DOCTOR")
    void confirmRequest_success() throws Exception {
        AppointmentRequestConfirmRequest confirmRequest = AppointmentRequestConfirmRequest.builder()
                .facilityId("facility-001")
                .roomSlotId(10L)
                .equipmentSlotId(20L)
                .build();

        when(appointmentRequestService.confirmRequest(eq("req-001"), any(), eq("doctor-1"))).thenReturn(
                AppointmentResponse.builder()
                        .id("apt-001")
                        .patientUserId("user-123")
                        .status("CONFIRMED")
                        .build());

        mockMvc.perform(post("/appointment-requests/req-001/confirm")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(confirmRequest))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value("apt-001"))
                .andExpect(jsonPath("$.result.status").value("CONFIRMED"));
    }

    @Test
    @WithMockUser(username = "admin-1", roles = "ADMIN")
    void rejectRequest_success() throws Exception {
        AppointmentRequestRejectRequest rejectRequest = AppointmentRequestRejectRequest.builder()
                .reason("No room available")
                .build();

        when(appointmentRequestService.rejectRequest(eq("req-001"), any(), eq("admin-1"))).thenReturn(
                AppointmentRequestResponse.builder()
                        .id("req-001")
                        .status("REJECTED")
                        .rejectionReason("No room available")
                        .build());

        mockMvc.perform(post("/appointment-requests/req-001/reject")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(rejectRequest))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.status").value("REJECTED"))
                .andExpect(jsonPath("$.result.rejectionReason").value("No room available"));
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getRequest_notFound() throws Exception {
        when(appointmentRequestService.getRequest("missing"))
                .thenThrow(new AppointmentRequestNotFoundException("Appointment request not found: missing"));

        mockMvc.perform(get("/appointment-requests/missing"))
                .andExpect(status().isNotFound());
    }
}
