package com.hospital.moblie.security;
import java.util.Collection;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import com.hospital.moblie.model.UserStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UserDetailsImpl implements UserDetails {
    private static final Logger log =
            LoggerFactory.getLogger(UserDetailsImpl.class);
   private Long id;
    private String password;
    private String username;
    private UserStatus status;
    private Collection<? extends GrantedAuthority> authorities;

    public UserDetailsImpl(Long id, String password, String username, UserStatus status, Collection<? extends GrantedAuthority> authorities) {
        this.id = id;
        this.password = password;
        this.username = username;
        this.status = status;
        this.authorities = authorities;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return this.status != UserStatus.LOCKED;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return this.status == UserStatus.ACTIVE;
    }

    public Long getId() {
        return id;
    }
}
