package com.hospital.moblie.security;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;

import com.hospital.moblie.model.User;
import com.hospital.moblie.repository.UserRepository;

import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {
    UserRepository userRepository;

    public UserDetailsServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + username));

        return new UserDetailsImpl(
            user.getId(),
            user.getPassword(),
            user.getEmail(),
            user.getStatus(),
            List.of(new SimpleGrantedAuthority(user.getRole().name()))
        );
    }
}
