package com.medbook.appointment.client.profile;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class InternalUserProfileResponse {
    String id;
    String userId;
    String username;
    String firstName;
    String lastName;
    String avatar;
    String fcmToken;
}
