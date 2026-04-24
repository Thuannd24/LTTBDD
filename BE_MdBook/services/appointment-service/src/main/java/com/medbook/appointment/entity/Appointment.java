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
import java.time.LocalDate;
import java.time.LocalTime;
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
    String patientUserId;
    
    @Column(nullable = false, length = 50)
    String doctorId;
    
    @Column(nullable = false)
    Long doctorScheduleId;

    Long roomSlotId;

    LocalDate appointmentDate;

    LocalTime startTime;

    @Column(nullable = false, length = 50)
    String facilityId;
    
    @Column(nullable = false, length = 50)
    String packageId;
    
    @Column(nullable = false, length = 30)
    @Enumerated(EnumType.STRING)
    AppointmentStatus status;
    
    @Column(columnDefinition = "TEXT")
    String note;
    
    @Column(columnDefinition = "TEXT")
    String cancelReason;
    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(nullable = false)
    LocalDateTime updatedAt;
    
    public enum AppointmentStatus {
        CONFIRMED,
        CANCELLED,
        COMPLETED
    }

    @PrePersist
    private void ensureId() {
        if (id == null || id.isBlank()) {
            id = UUID.randomUUID().toString();
        }
    }
}
