package com.medbook.appointment.service;

import com.medbook.appointment.dto.request.ExamPackageRequest;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.entity.ExamPackage;
import com.medbook.appointment.mapper.ExamPackageMapper;
import com.medbook.appointment.repository.ExamPackageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

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
class ExamPackageServiceTest {

    @Mock
    private ExamPackageRepository repository;

    @Mock
    private ExamPackageMapper mapper;

    @InjectMocks
    private ExamPackageService service;

    private ExamPackage testPackage;
    private ExamPackageResponse testPackageResponse;

    @BeforeEach
    void setUp() {
        testPackage = ExamPackage.builder()
                .id("pkg-1")
                .code("GENERAL_CHECKUP")
                .name("General Checkup")
                .description("Full body checkup")
                .status(ExamPackage.PackageStatus.ACTIVE)
                .estimatedTotalMinutes(60)
                .build();

        testPackageResponse = ExamPackageResponse.builder()
                .id("pkg-1")
                .code("GENERAL_CHECKUP")
                .name("General Checkup")
                .description("Full body checkup")
                .status(ExamPackage.PackageStatus.ACTIVE.name())
                .estimatedTotalMinutes(60)
                .build();
    }

    @Test
    void getAllPackages_success() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<ExamPackage> packagePage = new PageImpl<>(List.of(testPackage));
        when(repository.findAll(pageable)).thenReturn(packagePage);
        when(mapper.toResponse(testPackage)).thenReturn(testPackageResponse);

        Page<ExamPackageResponse> result = service.getAllPackages(pageable);

        assertNotNull(result);
        assertEquals(1, result.getContent().size());
        assertEquals("pkg-1", result.getContent().get(0).getId());
        verify(repository, times(1)).findAll(pageable);
    }

    @Test
    void getPackageById_success() {
        when(repository.findById("pkg-1")).thenReturn(Optional.of(testPackage));
        when(mapper.toResponse(testPackage)).thenReturn(testPackageResponse);

        ExamPackageResponse result = service.getPackageById("pkg-1");

        assertNotNull(result);
        assertEquals("pkg-1", result.getId());
        assertEquals("GENERAL_CHECKUP", result.getCode());
    }

    @Test
    void getPackageById_notFound() {
        when(repository.findById("unknown-id")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> service.getPackageById("unknown-id"));
    }

    @Test
    void createPackage_success() {
        ExamPackageRequest request = ExamPackageRequest.builder()
                .code("NEW_PACKAGE")
                .name("New Package")
                .description("New package description")
                .estimatedTotalMinutes(45)
                .build();

        when(repository.findByCode("NEW_PACKAGE")).thenReturn(Optional.empty());
        when(mapper.toEntity(request)).thenReturn(testPackage);
        when(repository.save(any())).thenReturn(testPackage);
        when(mapper.toResponse(testPackage)).thenReturn(testPackageResponse);

        ExamPackageResponse result = service.createPackage(request);

        assertNotNull(result);
        assertEquals("pkg-1", result.getId());
        verify(repository, times(1)).save(any());
    }

    @Test
    void createPackage_duplicateCode() {
        ExamPackageRequest request = ExamPackageRequest.builder()
                .code("DUPLICATE_CODE")
                .name("Duplicate")
                .estimatedTotalMinutes(30)
                .build();

        when(repository.findByCode("DUPLICATE_CODE")).thenReturn(Optional.of(testPackage));

        assertThrows(RuntimeException.class, () -> service.createPackage(request));
    }

    @Test
    void updatePackage_success() {
        ExamPackageRequest request = ExamPackageRequest.builder()
                .code("GENERAL_CHECKUP")
                .name("Updated Name")
                .estimatedTotalMinutes(90)
                .build();

        when(repository.findById("pkg-1")).thenReturn(Optional.of(testPackage));
        when(repository.save(any())).thenReturn(testPackage);
        when(mapper.toResponse(testPackage)).thenReturn(testPackageResponse);

        ExamPackageResponse result = service.updatePackage("pkg-1", request);

        assertNotNull(result);
        verify(mapper, times(1)).updateEntity(testPackage, request);
        verify(repository, times(1)).save(testPackage);
    }

    @Test
    void updatePackage_notFound() {
        ExamPackageRequest request = ExamPackageRequest.builder()
                .code("GENERAL_CHECKUP")
                .name("Updated Name")
                .build();

        when(repository.findById("unknown-id")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> service.updatePackage("unknown-id", request));
    }

    @Test
    void deletePackage_success() {
        when(repository.existsById("pkg-1")).thenReturn(true);

        service.deletePackage("pkg-1");

        verify(repository, times(1)).deleteById("pkg-1");
    }

    @Test
    void deletePackage_notFound() {
        when(repository.existsById("unknown-id")).thenReturn(false);

        assertThrows(RuntimeException.class, () -> service.deletePackage("unknown-id"));
    }
}
