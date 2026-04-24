package com.medbook.profile.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.medbook.profile.dto.request.CreateInternalProfileRequest;
import com.medbook.profile.dto.request.UpdateMyProfileRequest;
import com.medbook.profile.dto.response.InternalUserProfileResponse;
import com.medbook.profile.dto.response.ProfileExistenceResponse;
import com.medbook.profile.dto.response.UserProfileResponse;
import com.medbook.profile.entity.UserProfile;
import com.medbook.profile.exception.AppException;
import com.medbook.profile.exception.ErrorCode;
import com.medbook.profile.mapper.UserProfileMapper;
import com.medbook.profile.repository.UserProfileRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class UserProfileServiceImpl implements UserProfileService {

    UserProfileRepository userProfileRepository;
    UserProfileMapper userProfileMapper;
    UploadService uploadService;
    AIService aiService;

    @Override
    public UserProfileResponse getMyProfile(String userId) {
        UserProfile profile = userProfileRepository
                .findByUserId(userId)
                .orElseGet(() -> {
                    UserProfile newProfile = UserProfile.builder()
                            .userId(userId)
                            .build();
                    return userProfileRepository.save(newProfile);
                });
        return userProfileMapper.toUserProfileResponse(profile);
    }

    @Override
    @Transactional
    public UserProfileResponse updateMyProfile(String userId, UpdateMyProfileRequest request) {
        UserProfile profile = userProfileRepository
                .findByUserId(userId)
                .orElseGet(() -> UserProfile.builder()
                        .userId(userId)
                        .build());

        userProfileMapper.updateUserProfile(profile, request);

        // Generate AI summary if there's medical history or allergies
        if (request.getMedicalHistory() != null || request.getAllergies() != null) {
            String summary = aiService.generateSummary(profile.getMedicalHistory(), profile.getAllergies());
            profile.setAiSummary(summary);
        }

        profile = userProfileRepository.save(profile);
        return userProfileMapper.toUserProfileResponse(profile);
    }

    @Override
    @Transactional
    public UserProfileResponse updateMyAvatar(String userId, org.springframework.web.multipart.MultipartFile file) {
        UserProfile profile = userProfileRepository
                .findByUserId(userId)
                .orElseGet(() -> UserProfile.builder()
                        .userId(userId)
                        .build());

        try {
            String imageUrl = uploadService.uploadImage(file, "medbook/avatars");
            profile.setAvatar(imageUrl);
            profile = userProfileRepository.save(profile);
        } catch (java.io.IOException e) {
            throw new AppException(ErrorCode.UNCATEGORIZED_EXCEPTION);
        }

        return userProfileMapper.toUserProfileResponse(profile);
    }

    @Override
    public UserProfileResponse getProfileByUserId(String userId) {
        UserProfile profile = userProfileRepository
                .findByUserId(userId)
                .orElseThrow(() -> new AppException(ErrorCode.PROFILE_NOT_FOUND));
        return userProfileMapper.toUserProfileResponse(profile);
    }

    @Override
    @Transactional
    public InternalUserProfileResponse createInternalProfile(CreateInternalProfileRequest request) {
        if (userProfileRepository.existsByUserId(request.getUserId())) {
            throw new AppException(ErrorCode.PROFILE_ALREADY_EXISTS);
        }

        UserProfile profile = userProfileMapper.toUserProfile(request);
        profile = userProfileRepository.save(profile);
        log.info("Created profile for userId: {}", request.getUserId());
        return userProfileMapper.toInternalUserProfileResponse(profile);
    }

    @Override
    public InternalUserProfileResponse getInternalProfile(String userId) {
        UserProfile profile = userProfileRepository
                .findByUserId(userId)
                .orElseThrow(() -> new AppException(ErrorCode.PROFILE_NOT_FOUND));
        return userProfileMapper.toInternalUserProfileResponse(profile);
    }

    @Override
    public ProfileExistenceResponse checkProfileExists(String userId) {
        boolean exists = userProfileRepository.existsByUserId(userId);
        return ProfileExistenceResponse.builder()
                .exists(exists)
                .userId(userId)
                .build();
    }

    @Override
    @Transactional
    public UserProfileResponse generateAiSummary(String userId) {
        UserProfile profile = userProfileRepository
                .findByUserId(userId)
                .orElseThrow(() -> new AppException(ErrorCode.PROFILE_NOT_FOUND));

        String summary = aiService.generateSummary(profile.getMedicalHistory(), profile.getAllergies());
        profile.setAiSummary(summary);
        
        return userProfileMapper.toUserProfileResponse(userProfileRepository.save(profile));
    }

    @Override
    @Transactional
    public void updateFcmToken(String userId, com.medbook.profile.dto.request.UpdateFcmTokenRequest request) {
        UserProfile profile = userProfileRepository
                .findByUserId(userId)
                .orElseGet(() -> UserProfile.builder()
                        .userId(userId)
                        .build());
        profile.setFcmToken(request.getFcmToken());
        userProfileRepository.save(profile);
    }
}
