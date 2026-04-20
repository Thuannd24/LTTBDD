package com.identityservice.service;

import com.identityservice.dto.request.UserCreationRequest;
import com.identityservice.dto.request.ProfileCreationRequest;
import com.identityservice.dto.response.UserResponse;
import com.identityservice.exception.AppException;
import com.identityservice.exception.ErrorCode;
import com.identityservice.mapper.UserMapper;
import com.identityservice.repository.httpclient.ProfileClient;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.RealmResource;
import org.keycloak.admin.client.resource.UsersResource;
import org.keycloak.representations.idm.CredentialRepresentation;
import org.keycloak.representations.idm.RoleRepresentation;
import org.keycloak.representations.idm.UserRepresentation;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import jakarta.ws.rs.core.Response;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Slf4j
public class UserService {

    final Keycloak keycloak;
    final ProfileClient profileClient;
    final UserMapper userMapper;

    @Value("${app.keycloak.realm}")
    String realm;

    public UserResponse createUser(UserCreationRequest request) {
        return createKeycloakUser(request, List.of("USER"));
    }

    @PreAuthorize("hasRole('ADMIN')")
    public UserResponse adminCreateUser(UserCreationRequest request) {
        return createKeycloakUser(request, request.getRoles() != null && !request.getRoles().isEmpty() ? request.getRoles() : List.of("USER"));
    }

    private UserResponse createKeycloakUser(UserCreationRequest request, List<String> roles) {
        RealmResource realmResource = keycloak.realm(realm);
        UsersResource usersResource = realmResource.users();

        UserRepresentation kcUser = new UserRepresentation();
        kcUser.setUsername(request.getUsername());
        kcUser.setEmail(request.getEmail());
        kcUser.setFirstName(request.getFirstName());
        kcUser.setLastName(request.getLastName());
        kcUser.setEnabled(true);
        kcUser.setEmailVerified(true);

        CredentialRepresentation credential = new CredentialRepresentation();
        credential.setType(CredentialRepresentation.PASSWORD);
        credential.setValue(request.getPassword());
        credential.setTemporary(false);

        kcUser.setCredentials(Collections.singletonList(credential));

        Response response = usersResource.create(kcUser);

        if (response.getStatus() == 201 || response.getStatus() == 200) {
            String userId = null;
            if (response.getLocation() != null) {
                String path = response.getLocation().getPath();
                userId = path.substring(path.lastIndexOf('/') + 1);
            } else {
                // Fallback: search user by username to get ID if Location header is missing
                List<UserRepresentation> search = realmResource.users().search(request.getUsername());
                if (!search.isEmpty()) {
                    userId = search.get(0).getId();
                }
            }

            if (userId == null) {
                throw new RuntimeException("User created in Keycloak but failed to retrieve ID");
            }

            try {
                // Assign roles
                for (String roleName : roles) {
                    RoleRepresentation realmRole = realmResource.roles().get(roleName).toRepresentation();
                    usersResource.get(userId).roles().realmLevel().add(Collections.singletonList(realmRole));
                }
            } catch (Exception e) {
                log.error("Warning: Failed to assign role to user. Make sure roles exist in Keycloak.", e);
            }

            // Create profile
            ProfileCreationRequest profileRequest = ProfileCreationRequest.builder()
                    .userId(userId)
                    .username(request.getUsername())
                    .email(request.getEmail())
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .dob(request.getDob())
                    .city(request.getCity())
                    .build();

            profileClient.createProfile(profileRequest);

            // Fetch final user from Keycloak to have full metadata (CreatedAt, etc)
            UserRepresentation createdUser = usersResource.get(userId).toRepresentation();
            UserResponse userResponse = userMapper.toUserResponse(createdUser);
            userResponse.setRoles(roles);

            return userResponse;
        } else if (response.getStatus() == 409) {
            throw new AppException(ErrorCode.USER_EXISTED);
        } else {
            throw new RuntimeException("Failed to create user in Keycloak, status: " + response.getStatus());
        }
    }

    @PreAuthorize("hasRole('ADMIN')")
    public List<UserResponse> getUsers() {
        return keycloak.realm(realm).users().list().stream()
                .map(user -> {
                    UserResponse response = userMapper.toUserResponse(user);
                    // Fetch roles for each user
                    List<String> roles = keycloak.realm(realm).users().get(user.getId()).roles().realmLevel().listAll()
                            .stream().map(RoleRepresentation::getName).collect(Collectors.toList());
                    response.setRoles(roles);
                    return response;
                }).collect(Collectors.toList());
    }

    @PreAuthorize("hasRole('ADMIN')")
    public void deleteUser(String userId) {
        keycloak.realm(realm).users().get(userId).remove();
    }

    @PreAuthorize("hasRole('ADMIN')")
    public void updateUserRoles(String userId, List<String> roles) {
        UsersResource usersResource = keycloak.realm(realm).users();
        
        // Remove all current roles first (Optional, depending on business logic)
        // For simplicity, we add new roles. To replace, we would need to remove old ones.
        
        for (String roleName : roles) {
            RoleRepresentation realmRole = keycloak.realm(realm).roles().get(roleName).toRepresentation();
            usersResource.get(userId).roles().realmLevel().add(Collections.singletonList(realmRole));
        }
    }

    public UserResponse getMyInfo() {
        var context = SecurityContextHolder.getContext();
        String userId = context.getAuthentication().getName();
        log.info("Fetching info for userId: {}", userId);

        try {
            // Get from Keycloak by ID directly
            UserRepresentation user = keycloak.realm(realm).users().get(userId).toRepresentation();
            log.debug("Successfully profile from Keycloak for userId: {}", userId);

            UserResponse userResponse = userMapper.toUserResponse(user);
            
            // Get roles from Keycloak
            List<String> roles = keycloak.realm(realm).users().get(userId).roles().realmLevel().listAll()
                    .stream().map(RoleRepresentation::getName).collect(Collectors.toList());
            userResponse.setRoles(roles);
            log.debug("Successfully fetched roles for userId: {}: {}", userId, roles);

            return userResponse;
        } catch (jakarta.ws.rs.NotFoundException e) {
            log.error("User not found in Keycloak: {}", userId);
            throw new AppException(ErrorCode.USER_NOT_EXISTED);
        } catch (Exception e) {
            log.error("Error fetching user info from Keycloak for userId {}: {}", userId, e.getMessage());
            throw new RuntimeException("Error fetching user info: " + e.getMessage());
        }
    }
}
