package com.medbook.profile.dto.response;

import java.time.Instant;
import java.time.LocalDate;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UserProfileResponse {

    String id;
    String userId;
    String username;
    String email;
    String firstName;
    String lastName;
    String fullName;
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
    String medicalHistory;
    String allergies;
    String aiSummary;
    Boolean active;
    Instant createdAt;
    Instant updatedAt;
}
