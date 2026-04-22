package com.medbook.profile.dto.request;

import java.time.LocalDate;

import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UpdateMyProfileRequest {

    @Size(max = 100, message = "INVALID_FIRST_NAME")
    String firstName;

    @Size(max = 100, message = "INVALID_LAST_NAME")
    String lastName;

    @Pattern(regexp = "^(\\+?[0-9]{7,15})?$", message = "INVALID_PHONE")
    String phone;

    String avatar;

    String gender;

    @Past(message = "INVALID_DOB")
    LocalDate dob;

    @Size(max = 255, message = "INVALID_ADDRESS")
    String address;

    String city;
    String district;
    String ward;

    String emergencyContactName;

    @Pattern(regexp = "^(\\+?[0-9]{7,15})?$", message = "INVALID_PHONE")
    String emergencyContactPhone;

    @Size(max = 50, message = "INVALID_INSURANCE_NUMBER")
    String insuranceNumber;

    String bloodType;
    Double weight;
    Double height;
    String medicalHistory;
    String allergies;
    String aiSummary;
}
