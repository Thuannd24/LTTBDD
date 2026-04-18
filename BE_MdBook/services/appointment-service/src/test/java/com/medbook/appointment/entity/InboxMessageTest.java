package com.medbook.appointment.entity;

import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class InboxMessageTest {
    
    @Test
    void testInboxMessageCreation() {
        Map<String, Object> payload = new HashMap<>();
        payload.put("status", "SUCCESS");
        payload.put("appointmentId", "apt-001");
        
        InboxMessage msg = InboxMessage.builder()
                .id("inbox-001")
                .messageId("msg-from-doctor-12345")
                .eventType("DOCTOR_RESERVED")
                .payload(payload)
                .processed(false)
                .build();
        
        assertNotNull(msg);
        assertEquals("msg-from-doctor-12345", msg.getMessageId());
        assertEquals("DOCTOR_RESERVED", msg.getEventType());
        assertFalse(msg.getProcessed());
    }
}
