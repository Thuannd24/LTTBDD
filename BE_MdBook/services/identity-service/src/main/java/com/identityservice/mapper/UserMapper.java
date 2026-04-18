package com.identityservice.mapper;

import org.keycloak.representations.idm.UserRepresentation;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import com.identityservice.dto.response.UserResponse;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Mapper(componentModel = "spring")
public interface UserMapper {
    @Mapping(target = "roles", ignore = true)
    @Mapping(target = "createdAt", expression = "java(toLocalDateTime(userRepresentation.getCreatedTimestamp()))")
    @Mapping(target = "noPassword", constant = "false")
    UserResponse toUserResponse(UserRepresentation userRepresentation);

    default LocalDateTime toLocalDateTime(Long timestamp) {
        if (timestamp == null) return null;
        return LocalDateTime.ofInstant(Instant.ofEpochMilli(timestamp), ZoneId.systemDefault());
    }
}
