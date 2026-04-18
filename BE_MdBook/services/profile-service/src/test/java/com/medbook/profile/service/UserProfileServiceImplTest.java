package com.medbook.profile.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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

@ExtendWith(MockitoExtension.class)
class UserProfileServiceImplTest {

    @Mock
    UserProfileRepository userProfileRepository;

    @Mock
    UserProfileMapper userProfileMapper;

    @InjectMocks
    UserProfileServiceImpl userProfileService;

    private UserProfile userProfile;
    private final String TEST_USER_ID = "user-123";

    @BeforeEach
    void setUp() {
        userProfile = UserProfile.builder()
                .id("profile-1")
                .userId(TEST_USER_ID)
                .username("testuser")
                .firstName("John")
                .lastName("Doe")
                .avatar("https://example.com/avatar.jpg")
                .active(true)
                .build();
    }

    @Test
    void createInternalProfile_success() {
        CreateInternalProfileRequest request = CreateInternalProfileRequest.builder()
                .userId(TEST_USER_ID)
                .username("testuser")
                .email("test@example.com")
                .firstName("John")
                .lastName("Doe")
                .build();

        when(userProfileRepository.existsByUserId(TEST_USER_ID)).thenReturn(false);
        when(userProfileMapper.toUserProfile(request)).thenReturn(userProfile);
        when(userProfileRepository.save(userProfile)).thenReturn(userProfile);

        InternalUserProfileResponse expectedResponse = InternalUserProfileResponse.builder()
                .userId(TEST_USER_ID)
                .username("testuser")
                .firstName("John")
                .lastName("Doe")
                .build();
        when(userProfileMapper.toInternalUserProfileResponse(userProfile)).thenReturn(expectedResponse);

        InternalUserProfileResponse result = userProfileService.createInternalProfile(request);

        assertNotNull(result);
        assertEquals(TEST_USER_ID, result.getUserId());
        assertEquals("testuser", result.getUsername());
        verify(userProfileRepository).save(any(UserProfile.class));
    }

    @Test
    void createInternalProfile_duplicateUserId_throwsProfileAlreadyExists() {
        CreateInternalProfileRequest request = CreateInternalProfileRequest.builder()
                .userId(TEST_USER_ID)
                .build();

        when(userProfileRepository.existsByUserId(TEST_USER_ID)).thenReturn(true);

        AppException exception = assertThrows(AppException.class,
                () -> userProfileService.createInternalProfile(request));

        assertEquals(ErrorCode.PROFILE_ALREADY_EXISTS, exception.getErrorCode());
        verify(userProfileRepository, never()).save(any());
    }

    @Test
    void getMyProfile_success() {
        when(userProfileRepository.findByUserId(TEST_USER_ID)).thenReturn(Optional.of(userProfile));

        UserProfileResponse expectedResponse = UserProfileResponse.builder()
                .userId(TEST_USER_ID)
                .username("testuser")
                .firstName("John")
                .lastName("Doe")
                .fullName("John Doe")
                .build();
        when(userProfileMapper.toUserProfileResponse(userProfile)).thenReturn(expectedResponse);

        UserProfileResponse result = userProfileService.getMyProfile(TEST_USER_ID);

        assertNotNull(result);
        assertEquals(TEST_USER_ID, result.getUserId());
        assertEquals("John Doe", result.getFullName());
    }

    @Test
    void getMyProfile_notFound_throwsProfileNotFound() {
        when(userProfileRepository.findByUserId(TEST_USER_ID)).thenReturn(Optional.empty());

        AppException exception = assertThrows(AppException.class,
                () -> userProfileService.getMyProfile(TEST_USER_ID));

        assertEquals(ErrorCode.PROFILE_NOT_FOUND, exception.getErrorCode());
    }

    @Test
    void updateMyProfile_success() {
        UpdateMyProfileRequest request = UpdateMyProfileRequest.builder()
                .firstName("Jane")
                .lastName("Smith")
                .phone("+84901234567")
                .build();

        when(userProfileRepository.findByUserId(TEST_USER_ID)).thenReturn(Optional.of(userProfile));
        when(userProfileRepository.save(userProfile)).thenReturn(userProfile);

        UserProfileResponse expectedResponse = UserProfileResponse.builder()
                .userId(TEST_USER_ID)
                .firstName("Jane")
                .lastName("Smith")
                .fullName("Jane Smith")
                .build();
        when(userProfileMapper.toUserProfileResponse(userProfile)).thenReturn(expectedResponse);

        UserProfileResponse result = userProfileService.updateMyProfile(TEST_USER_ID, request);

        assertNotNull(result);
        assertEquals("Jane Smith", result.getFullName());
        verify(userProfileMapper).updateUserProfile(userProfile, request);
        verify(userProfileRepository).save(userProfile);
    }

    @Test
    void getInternalProfile_success() {
        when(userProfileRepository.findByUserId(TEST_USER_ID)).thenReturn(Optional.of(userProfile));

        InternalUserProfileResponse expectedResponse = InternalUserProfileResponse.builder()
                .userId(TEST_USER_ID)
                .username("testuser")
                .firstName("John")
                .lastName("Doe")
                .avatar("https://example.com/avatar.jpg")
                .build();
        when(userProfileMapper.toInternalUserProfileResponse(userProfile)).thenReturn(expectedResponse);

        InternalUserProfileResponse result = userProfileService.getInternalProfile(TEST_USER_ID);

        assertNotNull(result);
        assertEquals(TEST_USER_ID, result.getUserId());
        assertEquals("testuser", result.getUsername());
        assertEquals("John", result.getFirstName());
        assertEquals("Doe", result.getLastName());
        assertEquals("https://example.com/avatar.jpg", result.getAvatar());
    }

    @Test
    void getInternalProfile_notFound_throwsProfileNotFound() {
        when(userProfileRepository.findByUserId(TEST_USER_ID)).thenReturn(Optional.empty());

        AppException exception = assertThrows(AppException.class,
                () -> userProfileService.getInternalProfile(TEST_USER_ID));

        assertEquals(ErrorCode.PROFILE_NOT_FOUND, exception.getErrorCode());
    }

    @Test
    void checkProfileExists_returnsTrue_whenProfileExists() {
        when(userProfileRepository.existsByUserId(TEST_USER_ID)).thenReturn(true);

        ProfileExistenceResponse result = userProfileService.checkProfileExists(TEST_USER_ID);

        assertTrue(result.isExists());
        assertEquals(TEST_USER_ID, result.getUserId());
    }

    @Test
    void checkProfileExists_returnsFalse_whenProfileNotExists() {
        when(userProfileRepository.existsByUserId(TEST_USER_ID)).thenReturn(false);

        ProfileExistenceResponse result = userProfileService.checkProfileExists(TEST_USER_ID);

        assertFalse(result.isExists());
        assertEquals(TEST_USER_ID, result.getUserId());
    }
}
