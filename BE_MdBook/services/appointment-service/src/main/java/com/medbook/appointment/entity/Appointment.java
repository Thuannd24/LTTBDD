package com.medbook.appointment.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "appointments")
@EntityListeners(AuditingEntityListener.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Appointment {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;
    
    @Column(nullable = false, length = 50)
    String sagaId;
    
    @Column(nullable = false, length = 50)
    String patientUserId;
    
    @Column(nullable = false, length = 50)
    String doctorId;
    
    @Column(nullable = false)
    Long doctorScheduleId;
    
    @Column(nullable = false, length = 50)
    String facilityId;
    
    @Column(nullable = false, length = 50)
    String packageId;
    
    @Column(nullable = false, length = 50)
    String packageStepId;
    
    @Column(nullable = false, length = 30)
    @Enumerated(EnumType.STRING)
    AppointmentStatus status;
    
    @Column(columnDefinition = "TEXT")
    String note;
    
    @Column(columnDefinition = "TEXT")
    String cancelReason;
    
    @Column(length = 100)
    String failureCode;
    
    @Column(columnDefinition = "TEXT")
    String failureMessage;
    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(nullable = false)
    LocalDateTime updatedAt;
    
    public enum AppointmentStatus {
        BOOKING_PENDING,
        CONFIRMED,
        BOOKING_FAILED,
        CANCELLATION_PENDING,
        CANCELLED,
        CANCELLATION_FAILED
    }

    @PrePersist
    private void ensureSagaId() {
        if (sagaId == null || sagaId.isBlank()) {
            sagaId = UUID.randomUUID().toString();
        }
    }
}
