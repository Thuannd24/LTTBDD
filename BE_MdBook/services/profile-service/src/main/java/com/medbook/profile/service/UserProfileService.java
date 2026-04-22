package com.medbook.profile.service;

import com.medbook.profile.dto.request.CreateInternalProfileRequest;
import com.medbook.profile.dto.request.UpdateMyProfileRequest;
import com.medbook.profile.dto.response.InternalUserProfileResponse;
import com.medbook.profile.dto.response.ProfileExistenceResponse;
import com.medbook.profile.dto.response.UserProfileResponse;

public interface UserProfileService {

    UserProfileResponse getMyProfile(String userId);

    UserProfileResponse updateMyProfile(String userId, UpdateMyProfileRequest request);

    UserProfileResponse getProfileByUserId(String userId);

    InternalUserProfileResponse createInternalProfile(CreateInternalProfileRequest request);

    InternalUserProfileResponse getInternalProfile(String userId);

    UserProfileResponse updateMyAvatar(String userId, org.springframework.web.multipart.MultipartFile file);

    ProfileExistenceResponse checkProfileExists(String userId);

    UserProfileResponse generateAiSummary(String userId);
}
