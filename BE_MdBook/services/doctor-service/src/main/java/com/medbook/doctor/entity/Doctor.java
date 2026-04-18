package com.medbook.doctor.entity;

import java.time.Instant;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "doctors")
@EntityListeners(AuditingEntityListener.class)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Doctor {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;

    @Column(nullable = false, unique = true)
    String userId;

    @ElementCollection
    @CollectionTable(name = "doctor_specialties", joinColumns = @JoinColumn(name = "doctor_id"))
    @Column(name = "specialty_id")
    Set<String> specialtyIds;

    int experienceYears;
    double hourlyRate;

    String degree; // VD: Giáo sư, Tiến sĩ, Bác sĩ
    String position; // VD: Phó Chủ tịch Hội đồng chuyên môn
    String workLocation; // VD: Vinmec Times City

    @Column(columnDefinition = "TEXT")
    String biography; // Giới thiệu chi tiết

    @Column(columnDefinition = "TEXT")
    String services; // Các dịch vụ chuyên sâu của bác sĩ

    @Column(columnDefinition = "TEXT")
    String qualification;

    @Builder.Default
    String status = "PENDING"; // PENDING, ACTIVE, INACTIVE

    @CreatedDate
    @Column(updatable = false)
    Instant createdAt;

    @LastModifiedDate
    Instant updatedAt;
}
