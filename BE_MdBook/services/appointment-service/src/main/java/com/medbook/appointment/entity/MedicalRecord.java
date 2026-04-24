package com.medbook.appointment.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "medical_records")
@EntityListeners(AuditingEntityListener.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class MedicalRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;

    @Column(nullable = false, unique = true, length = 50)
    String appointmentId;

    @Column(nullable = false, length = 50)
    String patientUserId;

    @Column(nullable = false, length = 50)
    String doctorId;

    // Kết quả chẩn đoán chính
    @Column(columnDefinition = "TEXT")
    String diagnosis;

    // Triệu chứng được mô tả
    @Column(columnDefinition = "TEXT")
    String symptoms;

    // Đơn thuốc (dạng text hoặc JSON)
    @Column(columnDefinition = "TEXT")
    String prescription;

    // Hướng dẫn / lời khuyên
    @Column(columnDefinition = "TEXT")
    String notes;

    // Lịch tái khám (nếu có)
    LocalDateTime followUpDate;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    LocalDateTime updatedAt;

    @PrePersist
    private void ensureId() {
        if (id == null || id.isBlank()) {
            id = UUID.randomUUID().toString();
        }
    }
}
