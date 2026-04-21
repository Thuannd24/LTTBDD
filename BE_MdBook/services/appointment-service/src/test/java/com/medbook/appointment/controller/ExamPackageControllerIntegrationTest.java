package com.medbook.appointment.controller;

import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.configuration.CustomJwtDecoder;
import com.medbook.appointment.configuration.SecurityConfig;
import com.medbook.appointment.exception.GlobalExceptionHandler;
import com.medbook.appointment.entity.ExamPackage;
import com.medbook.appointment.service.ExamPackageService;
import com.medbook.appointment.service.ExamPackageStepService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ExamPackageController.class)
@Import({SecurityConfig.class, GlobalExceptionHandler.class})
class ExamPackageControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ExamPackageService packageService;

    @MockBean
    private ExamPackageStepService stepService;

    @MockBean
    private CustomJwtDecoder customJwtDecoder;

    private ExamPackageResponse testPackageResponse;

    @BeforeEach
    void setUp() {
        testPackageResponse = ExamPackageResponse.builder()
                .id("pkg-1")
                .code("GENERAL_CHECKUP")
                .name("General Checkup")
                .description("Full body checkup")
                .status(ExamPackage.PackageStatus.ACTIVE.name())
                .estimatedTotalMinutes(60)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    @Test
    void getAllPackages_success() throws Exception {
        Page<ExamPackageResponse> packagePage = new PageImpl<>(List.of(testPackageResponse));
        when(packageService.getAllPackages(any())).thenReturn(packagePage);

        mockMvc.perform(get("/exam-packages").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.content[0].id").value("pkg-1"))
                .andExpect(jsonPath("$.result.content[0].code").value("GENERAL_CHECKUP"));
    }

    @Test
    void getPackageById_success() throws Exception {
        when(packageService.getPackageById("pkg-1")).thenReturn(testPackageResponse);

        mockMvc.perform(get("/exam-packages/{id}", "pkg-1").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.id").value("pkg-1"))
                .andExpect(jsonPath("$.result.code").value("GENERAL_CHECKUP"));
    }

    @Test
    void getPackageById_notFound() throws Exception {
        when(packageService.getPackageById("unknown")).thenThrow(new RuntimeException("Package không tồn tại: unknown"));

        mockMvc.perform(get("/exam-packages/{id}", "unknown").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().is5xxServerError());
    }

    @Test
    void getPackageSteps_success() throws Exception {
        when(stepService.getStepsByPackageId("pkg-1")).thenReturn(List.of(ExamPackageStepResponse.builder()
                .id("step-1")
                .packageId("pkg-1")
                .stepName("Step 1")
                .build()));

        mockMvc.perform(get("/exam-packages/{id}/steps", "pkg-1").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result[0].id").value("step-1"));
    }
}
