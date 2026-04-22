package com.medbook.appointment.entity;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class AppointmentResourceReservationTest {
    
    @Test
    void testDoctorReservation() {
        AppointmentResourceReservation res = AppointmentResourceReservation.builder()
                .id("res-001")
                .appointmentId("apt-001")
                .slotId("slot-101")
                .targetType(AppointmentResourceReservation.ResourceTargetType.DOCTOR)
                .targetId("doc-456")
                .status(AppointmentResourceReservation.ReservationStatus.RESERVED)
                .build();
        
        assertNotNull(res);
        assertEquals(AppointmentResourceReservation.ResourceTargetType.DOCTOR, res.getTargetType());
        assertEquals(AppointmentResourceReservation.ReservationStatus.RESERVED, res.getStatus());
    }
    
    @Test
    void testRoomReservation() {
        AppointmentResourceReservation res = AppointmentResourceReservation.builder()
                .id("res-002")
                .appointmentId("apt-001")
                .slotId("slot-202")
                .targetType(AppointmentResourceReservation.ResourceTargetType.ROOM)
                .targetId("room-ultrasound")
                .status(AppointmentResourceReservation.ReservationStatus.RESERVED)
                .build();
        
        assertEquals(AppointmentResourceReservation.ResourceTargetType.ROOM, res.getTargetType());
    }
}
