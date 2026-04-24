package com.medbook.appointment.client.profile;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import com.medbook.appointment.dto.ApiResponse;

@FeignClient(name = "profile-service", url = "${app.services.profile:http://profile-service:5010}")
public interface ProfileServiceClient {

    @GetMapping("/internal/users/{userId}")
    ApiResponse<InternalUserProfileResponse> getInternalProfile(@PathVariable("userId") String userId);
}
