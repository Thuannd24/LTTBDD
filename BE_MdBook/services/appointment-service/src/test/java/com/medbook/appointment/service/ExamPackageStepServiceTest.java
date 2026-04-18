package com.medbook.appointment.service;

import com.medbook.appointment.dto.request.ExamPackageStepRequest;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.entity.ExamPackageStep;
import com.medbook.appointment.mapper.ExamPackageStepMapper;
import com.medbook.appointment.repository.ExamPackageRepository;
import com.medbook.appointment.repository.ExamPackageStepRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExamPackageStepServiceTest {

    @Mock
    private ExamPackageStepRepository repository;

    @Mock
    private ExamPackageRepository packageRepository;

    @Mock
    private ExamPackageStepMapper mapper;

    @InjectMocks
    private ExamPackageStepService service;

    private ExamPackageStep testStep;
    private ExamPackageStepResponse testStepResponse;

    @BeforeEach
    void setUp() {
        testStep = ExamPackageStep.builder()
                .id("step-1")
                .packageId("pkg-1")
                .stepOrder(1)
                .stepName("Ultrasound")
                .allowedSpecialtyIds(Arrays.asList("spec-1", "spec-2"))
                .requiredRoomCategory("ULTRASOUND_ROOM")
                .requiredEquipmentType("ULTRASOUND_MACHINE")
                .equipmentRequired(true)
                .estimatedMinutes(30)
                .note("Standard ultrasound scan")
                .build();

        testStepResponse = ExamPackageStepResponse.builder()
                .id("step-1")
                .packageId("pkg-1")
                .stepOrder(1)
                .stepName("Ultrasound")
                .allowedSpecialtyIds(Arrays.asList("spec-1", "spec-2"))
                .requiredRoomCategory("ULTRASOUND_ROOM")
                .requiredEquipmentType("ULTRASOUND_MACHINE")
                .equipmentRequired(true)
                .estimatedMinutes(30)
                .note("Standard ultrasound scan")
                .build();
    }

    @Test
    void getStepsByPackageId_success() {
        when(packageRepository.existsById("pkg-1")).thenReturn(true);
        when(repository.findByPackageIdOrderByStepOrder("pkg-1")).thenReturn(List.of(testStep));
        when(mapper.toResponse(testStep)).thenReturn(testStepResponse);

        List<ExamPackageStepResponse> result = service.getStepsByPackageId("pkg-1");

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("step-1", result.get(0).getId());
    }

    @Test
    void getStepsByPackageId_packageNotFound() {
        when(packageRepository.existsById("unknown-pkg")).thenReturn(false);

        assertThrows(RuntimeException.class, () -> service.getStepsByPackageId("unknown-pkg"));
    }

    @Test
    void getStepById_success() {
        when(repository.findById("step-1")).thenReturn(Optional.of(testStep));
        when(mapper.toResponse(testStep)).thenReturn(testStepResponse);

        ExamPackageStepResponse result = service.getStepById("step-1");

        assertNotNull(result);
        assertEquals("step-1", result.getId());
    }

    @Test
    void getStepById_notFound() {
        when(repository.findById("unknown-step")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> service.getStepById("unknown-step"));
    }

    @Test
    void createStep_success() {
        ExamPackageStepRequest request = ExamPackageStepRequest.builder()
                .stepOrder(1)
                .stepName("New Step")
                .equipmentRequired(true)
                .estimatedMinutes(30)
                .build();

        when(packageRepository.existsById("pkg-1")).thenReturn(true);
        when(mapper.toEntity(request)).thenReturn(testStep);
        when(repository.save(any())).thenReturn(testStep);
        when(mapper.toResponse(testStep)).thenReturn(testStepResponse);

        ExamPackageStepResponse result = service.createStep("pkg-1", request);

        assertNotNull(result);
        assertEquals("step-1", result.getId());
    }

    @Test
    void createStep_packageNotFound() {
        ExamPackageStepRequest request = ExamPackageStepRequest.builder()
                .stepOrder(1)
                .stepName("New Step")
                .equipmentRequired(true)
                .estimatedMinutes(30)
                .build();

        when(packageRepository.existsById("unknown-pkg")).thenReturn(false);

        assertThrows(RuntimeException.class, () -> service.createStep("unknown-pkg", request));
    }

    @Test
    void updateStep_success() {
        ExamPackageStepRequest request = ExamPackageStepRequest.builder()
                .stepName("Updated Step Name")
                .estimatedMinutes(45)
                .build();

        when(repository.findById("step-1")).thenReturn(Optional.of(testStep));
        when(repository.save(any())).thenReturn(testStep);
        when(mapper.toResponse(testStep)).thenReturn(testStepResponse);

        ExamPackageStepResponse result = service.updateStep("pkg-1", "step-1", request);

        assertNotNull(result);
        verify(mapper, times(1)).updateEntity(testStep, request);
        verify(repository, times(1)).save(testStep);
    }

    @Test
    void updateStep_stepNotFound() {
        ExamPackageStepRequest request = ExamPackageStepRequest.builder()
                .stepName("Updated")
                .build();

        when(repository.findById("unknown-step")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> service.updateStep("pkg-1", "unknown-step", request));
    }

    @Test
    void updateStep_wrongPackage() {
        ExamPackageStep wrongStep = ExamPackageStep.builder()
                .id("step-1")
                .packageId("pkg-999")
                .build();

        ExamPackageStepRequest request = ExamPackageStepRequest.builder()
                .stepName("Updated")
                .build();

        when(repository.findById("step-1")).thenReturn(Optional.of(wrongStep));

        assertThrows(RuntimeException.class, () -> service.updateStep("pkg-1", "step-1", request));
    }

    @Test
    void deleteStep_success() {
        when(repository.findById("step-1")).thenReturn(Optional.of(testStep));

        service.deleteStep("pkg-1", "step-1");

        verify(repository, times(1)).deleteById("step-1");
    }

    @Test
    void deleteStep_stepNotFound() {
        when(repository.findById("unknown-step")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> service.deleteStep("pkg-1", "unknown-step"));
    }
}
