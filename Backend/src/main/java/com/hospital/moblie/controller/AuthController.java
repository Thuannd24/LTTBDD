package com.hospital.moblie.controller;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import com.hospital.moblie.dto.AuthRequest;
import com.hospital.moblie.dto.AuthResponse;
import com.hospital.moblie.security.JwtUtil;
import com.hospital.moblie.security.UserDetailsImpl;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import com.hospital.moblie.service.UserService;
import jakarta.validation.Valid;
import org.springframework.security.core.AuthenticationException;
import com.hospital.moblie.exception.BadRequestException;
import com.hospital.moblie.dto.ApiResponse;

@RestController
@RequestMapping("api/auth")
public class AuthController {
    private UserService userService;
    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    public AuthController(
        AuthenticationManager authenticationManager,
        JwtUtil jwtUtil,
        UserService userService
    ) {
        this.authenticationManager = authenticationManager;
        this.jwtUtil = jwtUtil;
        this.userService = userService;
    }
    @PostMapping("/login")
    @ResponseStatus(HttpStatus.OK)
    public ApiResponse<AuthResponse> login(@Valid @RequestBody AuthRequest authRequest) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                    authRequest.getEmail(),
                    authRequest.getPassword()
                )
            );

            UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
            String jwt = jwtUtil.generateToken(userDetails);

            return new ApiResponse<>("success", "Login successful", new AuthResponse(jwt));
        } catch (AuthenticationException ex) {
            throw new BadRequestException("Invalid username or password");
        }
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Void> createUser(@Valid @RequestBody AuthRequest authRequest) {
        userService.registerUser(authRequest);
        return new ApiResponse<>("success", "User registered successfully", null);
    }
}