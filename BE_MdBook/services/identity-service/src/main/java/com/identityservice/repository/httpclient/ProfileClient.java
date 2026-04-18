package com.identityservice.repository.httpclient;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import com.identityservice.configuration.AuthenticationRequestInterceptor;
import com.identityservice.dto.ApiResponse;
import com.identityservice.dto.request.ProfileCreationRequest;

@FeignClient(
        name = "profile-service",
        url = "${app.services.profile}",
        configuration = AuthenticationRequestInterceptor.class)
public interface ProfileClient {
    // Calls internal profile creation endpoint (permitAll in profile-service)
    @PostMapping(value = "/internal/users")
    ApiResponse<Object> createProfile(@RequestBody ProfileCreationRequest request);
}
