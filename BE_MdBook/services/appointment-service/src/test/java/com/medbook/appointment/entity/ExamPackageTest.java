package com.medbook.appointment.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ExamPackageTest {
    
    @Test
    void testExamPackageCreation() {
        ExamPackage pkg = ExamPackage.builder()
                .id("pkg-001")
                .code("GC001")
                .name("General Checkup")
                .description("Khám tổng quát")
                .status(ExamPackage.PackageStatus.ACTIVE)
                .estimatedTotalMinutes(60)
                .build();
        
        assertNotNull(pkg);
        assertEquals("pkg-001", pkg.getId());
        assertEquals("GC001", pkg.getCode());
        assertEquals("General Checkup", pkg.getName());
        assertEquals(ExamPackage.PackageStatus.ACTIVE, pkg.getStatus());
    }
}
