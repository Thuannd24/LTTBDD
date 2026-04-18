package com.medbook.appointment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medbook.appointment.configuration.CustomJwtDecoder;
import com.medbook.appointment.configuration.SecurityConfig;
import com.medbook.appointment.dto.request.ExamPackageRequest;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.entity.ExamPackage;
import com.medbook.appointment.exception.GlobalExceptionHandler;
import com.medbook.appointment.grpc.context.JwtContextFilter;
import com.medbook.appointment.service.ExamPackageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ExamPackageAdminController.class)
@Import({SecurityConfig.class, GlobalExceptionHandler.class, JwtContextFilter.class})
class ExamPackageAdminControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ExamPackageService packageService;

    @MockBean
    private CustomJwtDecoder customJwtDecoder;

    private ExamPackageRequest request;
    private ExamPackageResponse testPackageResponse;

    @BeforeEach
    void setUp() {
        request = ExamPackageRequest.builder()
                .code("NEW_PACKAGE")
                .name("New Package")
                .description("New package description")
                .estimatedTotalMinutes(45)
                .build();

        testPackageResponse = ExamPackageResponse.builder()
                .id("pkg-1")
                .code("NEW_PACKAGE")
                .name("Updated Package")
                .description("New package description")
                .status(ExamPackage.PackageStatus.INACTIVE.name())
                .estimatedTotalMinutes(90)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void createPackage_success() throws Exception {
        when(packageService.createPackage(any())).thenReturn(testPackageResponse);

        mockMvc.perform(post("/admin/exam-packages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value("pkg-1"))
                .andExpect(jsonPath("$.result.code").value("NEW_PACKAGE"));
    }

    @Test
    @WithMockUser(roles = "USER")
    void createPackage_forbidden() throws Exception {
        mockMvc.perform(post("/admin/exam-packages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    void createPackage_unauthenticated() throws Exception {
        mockMvc.perform(post("/admin/exam-packages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void updatePackage_success() throws Exception {
        when(packageService.updatePackage(eq("pkg-1"), any())).thenReturn(testPackageResponse);

        mockMvc.perform(put("/admin/exam-packages/{id}", "pkg-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value("pkg-1"));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void deletePackage_success() throws Exception {
        doNothing().when(packageService).deletePackage("pkg-1");

        mockMvc.perform(delete("/admin/exam-packages/{id}", "pkg-1")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "USER")
    void deletePackage_forbidden() throws Exception {
        mockMvc.perform(delete("/admin/exam-packages/{id}", "pkg-1")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }
}
