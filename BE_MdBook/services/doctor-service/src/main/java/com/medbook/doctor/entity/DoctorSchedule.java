package com.medbook.doctor.entity;

import java.time.LocalDateTime;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import com.medbook.doctor.entity.enums.DoctorScheduleStatus;

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
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Entity
@Table(
        name = "doctor_schedules",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_doctor_schedule_doctor_facility_time",
                columnNames = {"doctor_id", "facility_id", "start_time", "end_time"}),
        indexes = {
                @Index(name = "idx_doctor_schedule_doctor_time", columnList = "doctor_id, start_time"),
                @Index(name = "idx_doctor_schedule_doctor_status", columnList = "doctor_id, status"),
                @Index(name = "idx_doctor_schedule_facility_time", columnList = "facility_id, start_time")
        })
@EntityListeners(AuditingEntityListener.class)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DoctorSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(name = "doctor_id", nullable = false, length = 64)
    String doctorId;

    @Column(name = "facility_id", nullable = false)
    Long facilityId;

    @Column(name = "start_time", nullable = false)
    LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    LocalDateTime endTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    DoctorScheduleStatus status = DoctorScheduleStatus.AVAILABLE;

    @Column(name = "appointment_id", length = 64)
    String appointmentId;

    @Column(name = "notes", length = 255)
    String notes;

    @Column(name = "room_slot_id")
    Long roomSlotId;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    LocalDateTime updatedAt;
}
