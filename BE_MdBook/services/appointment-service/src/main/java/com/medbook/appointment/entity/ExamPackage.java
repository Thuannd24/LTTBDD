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

@Entity
@Table(name = "exam_packages")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@EntityListeners(AuditingEntityListener.class)
public class ExamPackage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;
    
    @Column(nullable = false, length = 50)
    String code;
    
    @Column(nullable = false, length = 255)
    String name;
    
    @Column(columnDefinition = "TEXT")
    String description;
    
    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    PackageStatus status;
    
    @Column(nullable = false)
    Integer estimatedTotalMinutes;
    
    @Column(name = "specialty_id")
    String specialtyId;
    
@CreatedDate
    @Column(nullable = false, updatable = false)
    LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    LocalDateTime updatedAt;
    
    public enum PackageStatus {
        ACTIVE, INACTIVE
    }
}
