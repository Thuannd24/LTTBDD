package com.medbook.profile.dto.request;

import jakarta.validation.constraints.NotBlank;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class CreateInternalProfileRequest {

    @NotBlank(message = "USER_ID_REQUIRED")
    String userId;

    String username;
    String email;
    String firstName;
    String lastName;
}
