package com.hospital.moblie.service.impl;
import java.util.List;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.hospital.moblie.dto.AuthRequest;
import com.hospital.moblie.dto.UserDTO;
import com.hospital.moblie.exception.BadRequestException;
import com.hospital.moblie.exception.ResourceNotFoundException;
import com.hospital.moblie.mapper.UserMapper;
import com.hospital.moblie.model.Role;
import com.hospital.moblie.model.User;
import com.hospital.moblie.model.UserStatus;
import com.hospital.moblie.repository.UserRepository;
import com.hospital.moblie.service.UserService;
@Service
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserServiceImpl(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @CacheEvict(value = {"users", "usersByRole"}, allEntries = true)
    public void registerUser(AuthRequest authRequest) {
        if (userRepository.existsByEmail(authRequest.getEmail())) {
            throw new BadRequestException("User with email: " + authRequest.getEmail() + " already exists.");
        }
        User user = UserMapper.AuthtoEntity(authRequest);
        user.setStatus(UserStatus.PENDING);
        user.setRole(Role.USER);
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        User usersave = userRepository.save(user);
    }


    @Override
    @Cacheable(value = "users")
    public List<UserDTO> getAll() {
        return userRepository.findAll().stream().map(UserMapper::toDTO).toList();
    }

    @Override
    @Cacheable(value = "usersByRole", key = "#role")
    public List<UserDTO> getByRole(Role role) {
        return userRepository.findByRole(role).stream()
                .map(UserMapper::toDTO)
                .toList();
    }

    public void addMail(String email, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User with id: " + userId + " not found."));
        if (user.getEmail() != null) {
            throw new BadRequestException("User with email: " + email + " already exists.");
        }
    }

    @Override
    public void checkUser(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User with id: " + userId + " not found.");
        }
    }

    @Override
    @CacheEvict(value = {"users", "usersByRole"}, allEntries = true)
    public void activateUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User with id: " + userId + " not found."));
        user.activate();
        userRepository.save(user);
    }
}
