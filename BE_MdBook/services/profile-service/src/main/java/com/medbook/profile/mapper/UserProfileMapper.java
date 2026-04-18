package com.medbook.profile.mapper;

import org.mapstruct.*;

import com.medbook.profile.dto.request.CreateInternalProfileRequest;
import com.medbook.profile.dto.request.UpdateMyProfileRequest;
import com.medbook.profile.dto.response.InternalUserProfileResponse;
import com.medbook.profile.dto.response.UserProfileResponse;
import com.medbook.profile.entity.UserProfile;

@Mapper(componentModel = "spring")
public interface UserProfileMapper {

    UserProfile toUserProfile(CreateInternalProfileRequest request);

    @Mapping(target = "fullName", expression = "java(buildFullName(profile))")
    UserProfileResponse toUserProfileResponse(UserProfile profile);

    InternalUserProfileResponse toInternalUserProfileResponse(UserProfile profile);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateUserProfile(@MappingTarget UserProfile profile, UpdateMyProfileRequest request);

    default String buildFullName(UserProfile profile) {
        if (profile.getFirstName() == null && profile.getLastName() == null) {
            return null;
        }
        String first = profile.getFirstName() != null ? profile.getFirstName() : "";
        String last = profile.getLastName() != null ? profile.getLastName() : "";
        return (first + " " + last).trim();
    }
}
