package com.medbook.appointment.entity;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ExamPackageStepTest {
    
    @Test
    void testExamPackageStepCreation() {
        ExamPackageStep step = ExamPackageStep.builder()
                .id("step-001")
                .packageId("pkg-001")
                .stepOrder(1)
                .stepName("Ultrasound")
                .allowedSpecialtyIds(List.of("CARDIO", "RADIOLOGY"))
                .requiredRoomCategory("ULTRASOUND_ROOM")
                .requiredEquipmentType("ULTRASOUND_MACHINE")
                .equipmentRequired(true)
                .estimatedMinutes(20)
                .note("Siêu âm tim")
                .build();
        
        assertNotNull(step);
        assertEquals("step-001", step.getId());
        assertEquals("pkg-001", step.getPackageId());
        assertEquals(1, step.getStepOrder());
        assertEquals("Ultrasound", step.getStepName());
        assertTrue(step.getEquipmentRequired());
        assertEquals(2, step.getAllowedSpecialtyIds().size());
    }
}
