package com.medbook.appointment.entity;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class AppointmentTest {
    
    @Test
    void testAppointmentCreation() {
        Appointment apt = Appointment.builder()
                .id("apt-001")
                .sagaId("saga-001")
                .patientUserId("user-123")
                .doctorId("doc-456")
                .doctorScheduleId(101L)
                .facilityId("clinic-1")
                .packageId("pkg-001")
                .packageStepId("step-ultrasound")
                .status(Appointment.AppointmentStatus.BOOKING_PENDING)
                .note("Follow-up visit")
                .build();
        
        assertNotNull(apt);
        assertEquals("apt-001", apt.getId());
        assertEquals("saga-001", apt.getSagaId());
        assertEquals("user-123", apt.getPatientUserId());
        assertEquals(Appointment.AppointmentStatus.BOOKING_PENDING, apt.getStatus());
    }
    
    @Test
    void testAppointmentStatusEnum() {
        assertNotNull(Appointment.AppointmentStatus.CONFIRMED);
        assertNotNull(Appointment.AppointmentStatus.BOOKING_FAILED);
        assertNotNull(Appointment.AppointmentStatus.CANCELLED);
    }
}
