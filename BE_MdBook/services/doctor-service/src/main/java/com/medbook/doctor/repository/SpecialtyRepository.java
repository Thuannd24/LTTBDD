package com.medbook.doctor.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.medbook.doctor.entity.Specialty;

@Repository
public interface SpecialtyRepository extends JpaRepository<Specialty, String> {
    boolean existsByName(String name);

    boolean existsByNameAndIdNot(String name, String id);
}
