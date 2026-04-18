package com.medbook.profile.controller;

import jakarta.validation.Valid;

import org.springframework.web.bind.annotation.*;

import com.medbook.profile.dto.ApiResponse;
import com.medbook.profile.dto.request.CreateInternalProfileRequest;
import com.medbook.profile.dto.response.InternalUserProfileResponse;
import com.medbook.profile.dto.response.ProfileExistenceResponse;
import com.medbook.profile.service.UserProfileService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/internal/users")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Internal User Profile", description = "Internal APIs for inter-service communication")
public class InternalUserProfileController {

    UserProfileService userProfileService;

    @GetMapping("/{userId}")
    @Operation(summary = "Get internal profile by userId (used by chat-service)")
    public ApiResponse<InternalUserProfileResponse> getInternalProfile(@PathVariable String userId) {
        return ApiResponse.<InternalUserProfileResponse>builder()
                .result(userProfileService.getInternalProfile(userId))
                .build();
    }

    @PostMapping
    @Operation(summary = "Create profile from internal request (used by identity-service sync)")
    public ApiResponse<InternalUserProfileResponse> createInternalProfile(
            @Valid @RequestBody CreateInternalProfileRequest request) {
        return ApiResponse.<InternalUserProfileResponse>builder()
                .result(userProfileService.createInternalProfile(request))
                .build();
    }

    @GetMapping("/check/{userId}")
    @Operation(summary = "Check if profile exists for userId")
    public ApiResponse<ProfileExistenceResponse> checkProfileExists(@PathVariable String userId) {
        return ApiResponse.<ProfileExistenceResponse>builder()
                .result(userProfileService.checkProfileExists(userId))
                .build();
    }
}
