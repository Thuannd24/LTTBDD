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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "exam_package_steps")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@EntityListeners(AuditingEntityListener.class)
public class ExamPackageStep {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;
    
    @Column(nullable = false, length = 50)
    String packageId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "packageId", insertable = false, updatable = false)
    ExamPackage examPackage;
    
    @Column(nullable = false)
    Integer stepOrder;
    
    @Column(nullable = false, length = 150)
    String stepName;
    
    @Column(columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    List<String> allowedSpecialtyIds;
    
    @Column(length = 50)
    String requiredRoomCategory;
    
    @Column(length = 50)
    String requiredEquipmentType;
    
    @Column(nullable = false)
    Boolean equipmentRequired;
    
    @Column(nullable = false)
    Integer estimatedMinutes;
    
    @Column(columnDefinition = "TEXT")
    String note;
    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    LocalDateTime updatedAt;
}
