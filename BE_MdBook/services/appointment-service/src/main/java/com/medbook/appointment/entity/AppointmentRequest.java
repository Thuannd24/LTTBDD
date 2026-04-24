package com.medbook.appointment.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(name = "appointment_requests")
@EntityListeners(AuditingEntityListener.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AppointmentRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;

    @Column(nullable = false, length = 50)
    String patientUserId;

    @Column(nullable = false, length = 50)
    String doctorId;

    @Column(nullable = false)
    Long doctorScheduleId;

    @Column(nullable = false, length = 50)
    String packageId;

    @Column(length = 50)
    String facilityId;

    Long roomSlotId;


    @Column(nullable = false, length = 30)
    @Enumerated(EnumType.STRING)
    RequestStatus status;

    @Column(columnDefinition = "TEXT")
    String note;

    @Column(length = 50)
    String appointmentId;

    @Column(length = 50)
    String processedBy;

    LocalDateTime processedAt;

    @Column(columnDefinition = "TEXT")
    String rejectionReason;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    LocalDateTime updatedAt;

    public enum RequestStatus {
        PENDING_ASSIGNMENT,
        CONFIRMED,
        REJECTED,
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
