package com.medbook.profile.controller;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.medbook.profile.dto.ApiResponse;
import com.medbook.profile.dto.request.UpdateMyProfileRequest;
import com.medbook.profile.dto.response.UserProfileResponse;
import com.medbook.profile.service.UserProfileService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "User Profile", description = "APIs for managing user profiles")
@SecurityRequirement(name = "bearerAuth")
public class UserProfileController {

    UserProfileService userProfileService;

    @GetMapping("/me")
    @Operation(summary = "Get current user profile")
    public ApiResponse<UserProfileResponse> getMyProfile() {
        String userId = getCurrentUserId();
        return ApiResponse.<UserProfileResponse>builder()
                .result(userProfileService.getMyProfile(userId))
                .build();
    }

    @PutMapping("/me")
    @Operation(summary = "Update current user profile")
    public ApiResponse<UserProfileResponse> updateMyProfile(@Valid @RequestBody UpdateMyProfileRequest request) {
        String userId = getCurrentUserId();
        return ApiResponse.<UserProfileResponse>builder()
                .result(userProfileService.updateMyProfile(userId, request))
                .build();
    }

    @PostMapping(value = "/me/avatar", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Update current user avatar")
    public ApiResponse<UserProfileResponse> updateMyAvatar(@RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        String userId = getCurrentUserId();
        return ApiResponse.<UserProfileResponse>builder()
                .result(userProfileService.updateMyAvatar(userId, file))
                .build();
    }

    @GetMapping("/{userId}")
    @Operation(summary = "Get user profile by userId")
    public ApiResponse<UserProfileResponse> getProfileByUserId(@PathVariable String userId) {
        return ApiResponse.<UserProfileResponse>builder()
                .result(userProfileService.getProfileByUserId(userId))
                .build();
    }

    private String getCurrentUserId() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof Jwt jwt) {
            return jwt.getSubject();
        }

        return SecurityContextHolder.getContext().getAuthentication().getName();
    }
}
