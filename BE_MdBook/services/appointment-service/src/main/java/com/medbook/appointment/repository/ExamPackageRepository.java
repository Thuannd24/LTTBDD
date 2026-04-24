package com.medbook.appointment.repository;

import com.medbook.appointment.entity.ExamPackage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ExamPackageRepository extends JpaRepository<ExamPackage, String> {
    Optional<ExamPackage> findByCode(String code);
    Page<ExamPackage> findBySpecialtyId(String specialtyId, Pageable pageable);
}
