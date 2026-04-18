package com.medbook.doctor.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.medbook.doctor.entity.DoctorSchedule;
import com.medbook.doctor.entity.enums.DoctorScheduleStatus;

@Repository
public interface DoctorScheduleRepository extends JpaRepository<DoctorSchedule, Long> {

    List<DoctorSchedule> findByDoctorIdOrderByStartTimeAsc(String doctorId);

    List<DoctorSchedule> findByDoctorIdAndStatusAndStartTimeBetweenOrderByStartTimeAsc(
            String doctorId,
            DoctorScheduleStatus status,
            LocalDateTime startTime,
            LocalDateTime endTime);

    List<DoctorSchedule> findByDoctorIdAndFacilityIdAndStatusAndStartTimeBetweenOrderByStartTimeAsc(
            String doctorId,
            Long facilityId,
            DoctorScheduleStatus status,
            LocalDateTime startTime,
            LocalDateTime endTime);

    boolean existsByDoctorIdAndStartTimeLessThanAndEndTimeGreaterThan(
            String doctorId,
            LocalDateTime endTime,
            LocalDateTime startTime);

    boolean existsByDoctorIdAndIdNotAndStartTimeLessThanAndEndTimeGreaterThan(
            String doctorId,
            Long id,
            LocalDateTime endTime,
            LocalDateTime startTime);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT ds FROM DoctorSchedule ds WHERE ds.id = :scheduleId")
    Optional<DoctorSchedule> findByIdWithLock(@Param("scheduleId") Long scheduleId);
}
    
