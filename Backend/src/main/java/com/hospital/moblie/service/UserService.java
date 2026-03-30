package com.hospital.moblie.service;
import com.hospital.moblie.model.User;
import java.util.List;
import com.hospital.moblie.model.Role;
import com.hospital.moblie.dto.AuthRequest;
import com.hospital.moblie.dto.UserDTO;

public interface UserService {
    void registerUser(AuthRequest authRequest);
    List<UserDTO> getAll();
    List<UserDTO> getByRole(Role role);
    void checkUser(Long userId);
    void activateUser(Long userId);
}