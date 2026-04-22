package com.medbook.profile.entity;

import java.time.Instant;
import java.time.LocalDate;

import jakarta.persistence.*;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "user_profiles")
@EntityListeners(AuditingEntityListener.class)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    String id;

    @Column(nullable = false, unique = true)
    String userId;

    String username;
    String email;
    String firstName;
    String lastName;
    String phone;
    String avatar;
    String gender;
    LocalDate dob;
    String address;
    String city;
    String district;
    String ward;
    String emergencyContactName;
    String emergencyContactPhone;
    String insuranceNumber;
    String bloodType;
    Double weight;
    Double height;
    @Column(columnDefinition = "TEXT")
    String medicalHistory;
    @Column(columnDefinition = "TEXT")
    String allergies;
    @Column(columnDefinition = "TEXT")
    String aiSummary;

    @Builder.Default
    Boolean active = true;

    @CreatedDate
    @Column(updatable = false)
    Instant createdAt;

    @LastModifiedDate
    Instant updatedAt;
}
