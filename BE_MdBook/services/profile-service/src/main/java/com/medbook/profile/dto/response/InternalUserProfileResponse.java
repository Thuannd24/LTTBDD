package com.medbook.profile.dto.response;

import lombok.*;
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
}
