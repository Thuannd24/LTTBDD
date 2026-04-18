package com.medbook.appointment.entity;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class AppointmentSagaTest {
    
    @Test
    void testAppointmentSagaCreation() {
        AppointmentSaga saga = AppointmentSaga.builder()
                .id("saga-log-001")
                .appointmentId("apt-001")
                .sagaId("saga-001")
                .status(AppointmentSaga.SagaStatus.IN_PROGRESS)
                .compensationIndex(0)
                .build();
        
        assertNotNull(saga);
        assertEquals("saga-001", saga.getSagaId());
        assertEquals(AppointmentSaga.SagaStatus.IN_PROGRESS, saga.getStatus());
        assertEquals(0, saga.getCompensationIndex());
    }
    
    @Test
    void testSagaStatusEnum() {
        assertNotNull(AppointmentSaga.SagaStatus.COMPLETED);
        assertNotNull(AppointmentSaga.SagaStatus.COMPENSATING);
        assertNotNull(AppointmentSaga.SagaStatus.COMPENSATED);
    }
}
