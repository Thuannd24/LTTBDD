package com.medbook.appointment.repository;

import com.medbook.appointment.entity.ExamPackageStep;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExamPackageStepRepository extends JpaRepository<ExamPackageStep, String> {
    List<ExamPackageStep> findByPackageIdOrderByStepOrder(String packageId);
    void deleteByPackageId(String packageId);
}
