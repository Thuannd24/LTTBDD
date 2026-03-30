package com.hospital.moblie.mapper;
import java.time.LocalDateTime;

import com.hospital.moblie.dto.AuthRequest;
import com.hospital.moblie.dto.UserDTO;
import com.hospital.moblie.model.User;
public class UserMapper {
       public static UserDTO toDTO(User user) {
        UserDTO userDTO = new UserDTO();
        userDTO.setId(user.getId());
        userDTO.setName(user.getName());
        userDTO.setEmail(user.getEmail());
        userDTO.setRole(user.getRole());
        userDTO.setCreatedAt(user.getCreatedAt());
        userDTO.setStatus(user.getStatus());
        return userDTO;
    }
     public static User toEntity(UserDTO userDTO) {
        User user = new User();
        user.setId(userDTO.getId());
        user.setName(userDTO.getName());
        user.setEmail(userDTO.getEmail());
        user.setStatus(userDTO.getStatus());
        user.setRole(userDTO.getRole());
        user.setCreatedAt(userDTO.getCreatedAt());
        user.setPassword(userDTO. getPassword());
        return user;
 }
 public static User AuthtoEntity(AuthRequest authRequest) {
        User user = new User();
        user.setEmail(authRequest.getEmail());
        user.setPassword(authRequest.getPassword());
        user.setName(authRequest.getUsername());
        user.setCreatedAt(LocalDateTime.now().toString());
        return user;
    }
}
