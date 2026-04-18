package com.identityservice.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.net.URI;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.*;
import org.keycloak.representations.idm.RoleRepresentation;
import org.keycloak.representations.idm.UserRepresentation;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import com.identityservice.dto.request.UserCreationRequest;
import com.identityservice.dto.response.UserResponse;
import com.identityservice.exception.AppException;
import com.identityservice.exception.ErrorCode;
import com.identityservice.mapper.UserMapper;
import com.identityservice.repository.httpclient.ProfileClient;

import jakarta.ws.rs.core.Response;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private Keycloak keycloak;

    @Mock
    private ProfileClient profileClient;

    @Mock
    private UserMapper userMapper;

    @InjectMocks
    private UserService userService;

    private UserCreationRequest request;
    private UserRepresentation userRepresentation;
    private UserResponse userResponse;

    @BeforeEach
    void init() {
        request = UserCreationRequest.builder()
                .username("testuser")
                .password("password123")
                .email("test@example.com")
                .firstName("John")
                .lastName("Doe")
                .dob(LocalDate.of(2000, 1, 1))
                .city("Hanoi")
                .build();

        userRepresentation = new UserRepresentation();
        userRepresentation.setId("123-uuid");
        userRepresentation.setUsername("testuser");
        userRepresentation.setEmail("test@example.com");

        userResponse = UserResponse.builder()
                .id("123-uuid")
                .username("testuser")
                .email("test@example.com")
                .build();
    }

    @Test
    void createUser_success() throws Exception {
        // Arrange
        RealmResource realmResource = mock(RealmResource.class);
        UsersResource usersResource = mock(UsersResource.class);
        RolesResource rolesResource = mock(RolesResource.class);
        RoleResource roleResource = mock(RoleResource.class);
        UserResource userResource = mock(UserResource.class);
        RoleMappingResource roleMappingResource = mock(RoleMappingResource.class);
        RoleScopeResource roleScopeResource = mock(RoleScopeResource.class);

        RoleRepresentation roleRepresentation = new RoleRepresentation();
        roleRepresentation.setName("USER");

        when(keycloak.realm(any())).thenReturn(realmResource);
        when(realmResource.users()).thenReturn(usersResource);
        when(realmResource.roles()).thenReturn(rolesResource);
        when(rolesResource.get("USER")).thenReturn(roleResource);
        when(roleResource.toRepresentation()).thenReturn(roleRepresentation);
        
        Response response = Response.created(new URI("http://localhost:8181/users/123-uuid")).build();
        when(usersResource.create(any())).thenReturn(response);
        
        when(usersResource.get("123-uuid")).thenReturn(userResource);
        when(userResource.toRepresentation()).thenReturn(userRepresentation);
        when(userResource.roles()).thenReturn(roleMappingResource);
        when(roleMappingResource.realmLevel()).thenReturn(roleScopeResource);
        
        when(userMapper.toUserResponse(any())).thenReturn(userResponse);

        // Act
        UserResponse result = userService.createUser(request);

        // Assert
        assertNotNull(result);
        assertEquals("testuser", result.getUsername());
        verify(usersResource).create(any());
        verify(profileClient).createProfile(any());
    }

    @Test
    void createUser_alreadyExisted_fail() {
        // Arrange
        RealmResource realmResource = mock(RealmResource.class);
        UsersResource usersResource = mock(UsersResource.class);
        when(keycloak.realm(any())).thenReturn(realmResource);
        when(realmResource.users()).thenReturn(usersResource);
        
        Response response = Response.status(Response.Status.CONFLICT).build();
        when(usersResource.create(any())).thenReturn(response);

        // Act & Assert
        AppException exception = assertThrows(AppException.class, () -> userService.createUser(request));
        assertEquals(ErrorCode.USER_EXISTED, exception.getErrorCode());
    }

    @Test
    void getMyInfo_success() {
        // Arrange
        SecurityContext securityContext = mock(SecurityContext.class);
        Authentication authentication = mock(Authentication.class);
        SecurityContextHolder.setContext(securityContext);
        
        when(securityContext.getAuthentication()).thenReturn(authentication);
        when(authentication.getName()).thenReturn("123-uuid");

        RealmResource realmResource = mock(RealmResource.class);
        UsersResource usersResource = mock(UsersResource.class);
        UserResource userResource = mock(UserResource.class);
        RoleMappingResource roleMappingResource = mock(RoleMappingResource.class);
        RoleScopeResource roleScopeResource = mock(RoleScopeResource.class);

        when(keycloak.realm(any())).thenReturn(realmResource);
        when(realmResource.users()).thenReturn(usersResource);
        when(usersResource.get("123-uuid")).thenReturn(userResource);
        when(userResource.toRepresentation()).thenReturn(userRepresentation);
        when(userResource.roles()).thenReturn(roleMappingResource);
        when(roleMappingResource.realmLevel()).thenReturn(roleScopeResource);
        when(roleScopeResource.listAll()).thenReturn(Collections.emptyList());
        
        when(userMapper.toUserResponse(any())).thenReturn(userResponse);

        // Act
        UserResponse result = userService.getMyInfo();

        // Assert
        assertNotNull(result);
        assertEquals("123-uuid", result.getId());
        verify(userResource).toRepresentation();
    }

    @Test
    void getUsers_success() {
        // Arrange
        RealmResource realmResource = mock(RealmResource.class);
        UsersResource usersResource = mock(UsersResource.class);
        UserResource userResource = mock(UserResource.class);
        RoleMappingResource roleMappingResource = mock(RoleMappingResource.class);
        RoleScopeResource roleScopeResource = mock(RoleScopeResource.class);

        when(keycloak.realm(any())).thenReturn(realmResource);
        when(realmResource.users()).thenReturn(usersResource);
        when(usersResource.list()).thenReturn(List.of(userRepresentation));
        when(usersResource.get(anyString())).thenReturn(userResource);
        when(userResource.roles()).thenReturn(roleMappingResource);
        when(roleMappingResource.realmLevel()).thenReturn(roleScopeResource);
        when(roleScopeResource.listAll()).thenReturn(Collections.emptyList());

        when(userMapper.toUserResponse(any())).thenReturn(userResponse);

        // Act
        List<UserResponse> result = userService.getUsers();

        // Assert
        assertNotNull(result);
        assertFalse(result.isEmpty());
        assertEquals(1, result.size());
    }
}
