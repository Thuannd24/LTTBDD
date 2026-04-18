package com.medbook.doctor.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.stereotype.Repository;

import com.medbook.doctor.entity.Doctor;

@Repository
public interface DoctorRepository extends JpaRepository<Doctor, String> {

    @Override
    @EntityGraph(attributePaths = "specialtyIds")
    Optional<Doctor> findById(String id);

    @Override
    @EntityGraph(attributePaths = "specialtyIds")
    java.util.List<Doctor> findAll();

    @EntityGraph(attributePaths = "specialtyIds")
    Optional<Doctor> findByUserId(String userId);
}
