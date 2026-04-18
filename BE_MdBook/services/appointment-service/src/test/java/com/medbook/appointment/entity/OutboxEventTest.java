package com.medbook.appointment.entity;

import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class OutboxEventTest {
    
    @Test
    void testOutboxEventCreation() {
        Map<String, Object> payload = new HashMap<>();
        payload.put("appointmentId", "apt-001");
        payload.put("doctorId", "doc-456");
        
        OutboxEvent event = OutboxEvent.builder()
                .id("outbox-001")
                .aggregateId("apt-001")
                .eventType("DOCTOR_RESERVE")
                .payload(payload)
                .published(false)
                .build();
        
        assertNotNull(event);
        assertEquals("DOCTOR_RESERVE", event.getEventType());
        assertFalse(event.getPublished());
        assertEquals("apt-001", event.getPayload().get("appointmentId"));
    }
}
