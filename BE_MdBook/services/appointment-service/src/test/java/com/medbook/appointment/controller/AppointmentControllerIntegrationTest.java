package com.medbook.appointment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.appointment.configuration.CustomJwtDecoder;
import com.medbook.appointment.configuration.SecurityConfig;
import com.medbook.appointment.dto.request.CancelAppointmentRequest;
import com.medbook.appointment.dto.response.AppointmentResponse;
import com.medbook.appointment.dto.response.AppointmentStatusResponse;
import com.medbook.appointment.exception.AppointmentAccessDeniedException;
import com.medbook.appointment.exception.AppointmentNotFoundException;
import com.medbook.appointment.exception.GlobalExceptionHandler;
import com.medbook.appointment.service.AppointmentService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AppointmentController.class)
@Import({SecurityConfig.class, GlobalExceptionHandler.class})
class AppointmentControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AppointmentService appointmentService;

    @MockBean
    private CustomJwtDecoder customJwtDecoder;

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getAppointment_success() throws Exception {
        when(appointmentService.getAppointment("apt-001")).thenReturn(AppointmentResponse.builder()
                .id("apt-001")
                .patientUserId("user-123")
                .doctorId("doctor-456")
                .status("CONFIRMED")
                .build());

        mockMvc.perform(get("/appointments/apt-001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value("apt-001"))
                .andExpect(jsonPath("$.result.patientUserId").value("user-123"));
    }

    @Test
    @WithMockUser(username = "admin-001", roles = "ADMIN")
    void getAppointment_allowsAdmin() throws Exception {
        when(appointmentService.getAppointment("apt-001")).thenReturn(AppointmentResponse.builder()
                .id("apt-001")
                .patientUserId("user-123")
                .doctorId("doctor-456")
                .status("CONFIRMED")
                .build());

        mockMvc.perform(get("/appointments/apt-001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value("apt-001"));
    }

    @Test
    @WithMockUser(username = "other-user", roles = "USER")
    void getAppointment_forbiddenForDifferentUser() throws Exception {
        when(appointmentService.getAppointment("apt-001")).thenReturn(AppointmentResponse.builder()
                .id("apt-001")
                .patientUserId("user-123")
                .doctorId("doctor-456")
                .status("CONFIRMED")
                .build());

        mockMvc.perform(get("/appointments/apt-001"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getAppointment_notFound() throws Exception {
        when(appointmentService.getAppointment("missing")).thenThrow(new AppointmentNotFoundException("Appointment not found: missing"));

        mockMvc.perform(get("/appointments/missing"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getAppointmentStatus_success() throws Exception {
        when(appointmentService.getAppointment("apt-002")).thenReturn(AppointmentResponse.builder()
                .id("apt-002")
                .patientUserId("user-123")
                .build());
        when(appointmentService.getAppointmentStatus("apt-002")).thenReturn(AppointmentStatusResponse.builder()
                .status("CONFIRMED")
                .build());

        mockMvc.perform(get("/appointments/apt-002/status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.status").value("CONFIRMED"));
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getMyAppointments_success() throws Exception {
        when(appointmentService.getMyAppointments(eq("user-123"), any())).thenReturn(new PageImpl<>(List.of(
                AppointmentResponse.builder().id("apt-001").patientUserId("user-123").build(),
                AppointmentResponse.builder().id("apt-002").patientUserId("user-123").build()
        )));

        mockMvc.perform(get("/appointments/my").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.totalElements").value(2));
    }

    @Test
    @WithMockUser(username = "doctor-456", roles = "DOCTOR")
    void getDoctorAppointments_success() throws Exception {
        when(appointmentService.getDoctorAppointments(eq("doctor-456"), any())).thenReturn(new PageImpl<>(List.of(
                AppointmentResponse.builder().id("apt-001").doctorId("doctor-456").build()
        )));

        mockMvc.perform(get("/appointments/doctor/doctor-456").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.totalElements").value(1))
                .andExpect(jsonPath("$.result.content[0].doctorId").value("doctor-456"));
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void getDoctorAppointments_forbidden() throws Exception {
        mockMvc.perform(get("/appointments/doctor/doctor-456").param("page", "0").param("size", "10"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void cancelAppointment_success() throws Exception {
        CancelAppointmentRequest cancelRequest = CancelAppointmentRequest.builder()
                .reason("Need to reschedule")
                .build();

        when(appointmentService.cancelAppointment(eq("apt-001"), any(), eq("user-123"))).thenReturn(AppointmentResponse.builder()
                .id("apt-001")
                .status("CANCELLED")
                .cancelReason("Need to reschedule")
                .build());

        mockMvc.perform(post("/appointments/apt-001/cancel")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cancelRequest))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.status").value("CANCELLED"))
                .andExpect(jsonPath("$.result.cancelReason").value("Need to reschedule"));
    }

    @Test
    void cancelAppointment_unauthenticated() throws Exception {
        CancelAppointmentRequest cancelRequest = CancelAppointmentRequest.builder()
                .reason("Need to reschedule")
                .build();

        mockMvc.perform(post("/appointments/apt-001/cancel")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cancelRequest))
                        .with(csrf()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void cancelAppointment_forbidden() throws Exception {
        CancelAppointmentRequest cancelRequest = CancelAppointmentRequest.builder()
                .reason("Need to reschedule")
                .build();

        when(appointmentService.cancelAppointment(eq("apt-001"), any(), eq("user-123")))
                .thenThrow(new AppointmentAccessDeniedException("Unauthorized to cancel this appointment"));

        mockMvc.perform(post("/appointments/apt-001/cancel")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cancelRequest))
                        .with(csrf()))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "doctor-456", roles = "DOCTOR")
    void completeAppointment_success() throws Exception {
        when(appointmentService.completeAppointment("apt-001")).thenReturn(AppointmentResponse.builder()
                .id("apt-001")
                .status("COMPLETED")
                .build());

        mockMvc.perform(post("/appointments/apt-001/complete")
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.status").value("COMPLETED"));
    }

    @Test
    @WithMockUser(username = "user-123", roles = "USER")
    void completeAppointment_forbidden() throws Exception {
        mockMvc.perform(post("/appointments/apt-001/complete")
                        .with(csrf()))
                .andExpect(status().isForbidden());
    }
}
