package com.medbook.appointment.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "appointment_sagas")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AppointmentSaga {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;
    
    @Column(nullable = false, length = 50)
    String appointmentId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "appointmentId", insertable = false, updatable = false)
    Appointment appointment;
    
    @Column(nullable = false, length = 50)
    String sagaId;
    
    @Column(nullable = false, length = 30)
    @Enumerated(EnumType.STRING)
    SagaStatus status;
    
    @Column(nullable = false)
    Integer compensationIndex;
    
    public enum SagaStatus {
        IN_PROGRESS,
        COMPLETED,
        FAILED,
        COMPENSATING,
        COMPENSATED
    }
}
