package com.hospital.moblie.model;
import com.hospital.moblie.exception.BadRequestException;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
@Table(name = "users") 
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private String createdAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserStatus status;

    @Column(nullable = false)   
    private String name;
    @Column(nullable = false)
    private String email;
    @Column(nullable = false)
    private String password;
    public String getPassword() {
        return password;
    }
    public void setPassword(String password) {
        this.password = password;
    }
    public Role getRole() {
        return role;
    }
    public void setRole(Role role) {
        this.role = role;
    }
    public Long getId() {
        return id;
    }   
    public void setId(Long id) {
        this.id = id;
    }   
    public String getCreatedAt() {
        return createdAt;
    }   
    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
    public UserStatus getStatus() {
        return status;
    }
    public void setStatus(UserStatus status) {
        this.status = status;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }
    public User() {
    }
    public User(String name, String email, Role role, String createdAt) {
        this.name = name;
        this.email = email;
        this.status = UserStatus.PENDING;
        this.role = role;
        this.createdAt = createdAt;
    }
    public void activate() {
        if (this.status == UserStatus.ACTIVE) {
            throw new BadRequestException("User is already active.");
        }
        this.status = UserStatus.ACTIVE;
    }

    public void lock() {
        if (this.status == UserStatus.LOCKED) {
            throw new BadRequestException("User is already locked.");
        }
        this.status = UserStatus.LOCKED;
    }
}