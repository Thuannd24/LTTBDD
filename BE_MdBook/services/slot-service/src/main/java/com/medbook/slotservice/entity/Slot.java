package com.medbook.slotservice.entity;

import com.medbook.slotservice.entity.enums.SlotStatus;
import com.medbook.slotservice.entity.enums.SlotTargetType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(
        name = "slots",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_slot_target_start_end",
                columnNames = {"target_type", "target_id", "start_time", "end_time"}),
        indexes = {
            @Index(name = "idx_slot_target_time", columnList = "target_type, target_id, start_time"),
            @Index(name = "idx_slot_facility_status_time", columnList = "facility_id, status, start_time"),
            @Index(name = "idx_slot_status_time", columnList = "status, start_time")
        })
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Slot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false, length = 20)
    private SlotTargetType targetType;

    @Column(name = "target_id", nullable = false, length = 64)
    private String targetId;

    @Column(name = "facility_id", nullable = false)
    private Long facilityId;

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private SlotStatus status = SlotStatus.AVAILABLE;

    @Column(name = "recurring_config_id")
    private Long recurringConfigId;

    @Column(name = "appointment_id", length = 64)
    private String appointmentId;

    @Column(name = "notes", length = 255)
    private String notes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
