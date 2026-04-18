package com.medbook.doctor.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.medbook.doctor.dto.request.DoctorScheduleBlockRequest;
import com.medbook.doctor.dto.request.DoctorScheduleCreateRequest;
import com.medbook.doctor.dto.request.DoctorScheduleReserveRequest;
import com.medbook.doctor.dto.response.DoctorScheduleResponse;
import com.medbook.doctor.entity.DoctorSchedule;
import com.medbook.doctor.entity.enums.DoctorScheduleStatus;
import com.medbook.doctor.exception.AppException;
import com.medbook.doctor.exception.ErrorCode;
import com.medbook.doctor.mapper.DoctorScheduleMapper;
import com.medbook.doctor.repository.DoctorRepository;
import com.medbook.doctor.repository.DoctorScheduleRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
@Transactional(readOnly = true)
public class DoctorScheduleService {

    DoctorScheduleRepository doctorScheduleRepository;
    DoctorRepository doctorRepository;
    DoctorScheduleMapper doctorScheduleMapper;

    @Transactional
    public DoctorScheduleResponse createSchedule(String doctorId, DoctorScheduleCreateRequest request) {
        ensureDoctorExists(doctorId);
        validateTimeRange(request.getStartTime(), request.getEndTime());

        boolean overlapped = doctorScheduleRepository.existsByDoctorIdAndStartTimeLessThanAndEndTimeGreaterThan(
                doctorId,
                request.getEndTime(),
                request.getStartTime());
        if (overlapped) {
            throw new AppException(ErrorCode.DOCTOR_SCHEDULE_OVERLAPPED);
        }

        DoctorSchedule doctorSchedule = doctorScheduleMapper.toDoctorSchedule(request);
        doctorSchedule.setDoctorId(doctorId);
        doctorSchedule.setStatus(DoctorScheduleStatus.AVAILABLE);

        doctorSchedule = doctorScheduleRepository.save(doctorSchedule);
        return doctorScheduleMapper.toDoctorScheduleResponse(doctorSchedule);
    }

    public List<DoctorScheduleResponse> getSchedulesByDoctor(String doctorId) {
        ensureDoctorExists(doctorId);
        return doctorScheduleRepository.findByDoctorIdOrderByStartTimeAsc(doctorId)
                .stream()
                .map(doctorScheduleMapper::toDoctorScheduleResponse)
                .toList();
    }

    public List<DoctorScheduleResponse> getAvailableSchedules(String doctorId, LocalDate date, Long facilityId) {
        ensureDoctorExists(doctorId);
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.plusDays(1).atStartOfDay().minusNanos(1);

        List<DoctorSchedule> schedules = facilityId == null
                ? doctorScheduleRepository.findByDoctorIdAndStatusAndStartTimeBetweenOrderByStartTimeAsc(
                        doctorId, DoctorScheduleStatus.AVAILABLE, startOfDay, endOfDay)
                : doctorScheduleRepository.findByDoctorIdAndFacilityIdAndStatusAndStartTimeBetweenOrderByStartTimeAsc(
                        doctorId, facilityId, DoctorScheduleStatus.AVAILABLE, startOfDay, endOfDay);

        return schedules.stream()
                .map(doctorScheduleMapper::toDoctorScheduleResponse)
                .toList();
    }

    public DoctorScheduleResponse getSchedule(Long scheduleId) {
        return doctorScheduleMapper.toDoctorScheduleResponse(getScheduleEntity(scheduleId));
    }

    @Transactional
    public DoctorScheduleResponse updateSchedule(Long scheduleId, DoctorScheduleCreateRequest request) {
        DoctorSchedule doctorSchedule = getScheduleEntityForUpdate(scheduleId);
        validateMutableSchedule(doctorSchedule, ErrorCode.DOCTOR_SCHEDULE_CANNOT_UPDATE);
        validateTimeRange(request.getStartTime(), request.getEndTime());

        boolean overlapped = doctorScheduleRepository.existsByDoctorIdAndIdNotAndStartTimeLessThanAndEndTimeGreaterThan(
                doctorSchedule.getDoctorId(),
                scheduleId,
                request.getEndTime(),
                request.getStartTime());
        if (overlapped) {
            throw new AppException(ErrorCode.DOCTOR_SCHEDULE_OVERLAPPED);
        }

        doctorSchedule.setFacilityId(request.getFacilityId());
        doctorSchedule.setStartTime(request.getStartTime());
        doctorSchedule.setEndTime(request.getEndTime());
        doctorSchedule.setNotes(request.getNotes());

        doctorSchedule = doctorScheduleRepository.save(doctorSchedule);
        return doctorScheduleMapper.toDoctorScheduleResponse(doctorSchedule);
    }

    @Transactional
    public void deleteSchedule(Long scheduleId) {
        DoctorSchedule doctorSchedule = getScheduleEntityForUpdate(scheduleId);
        validateMutableSchedule(doctorSchedule, ErrorCode.DOCTOR_SCHEDULE_CANNOT_DELETE);
        doctorScheduleRepository.delete(doctorSchedule);
    }

    @Transactional
    public DoctorScheduleResponse reserveSchedule(Long scheduleId, DoctorScheduleReserveRequest request) {
        DoctorSchedule doctorSchedule = getScheduleEntityForUpdate(scheduleId);
        if (doctorSchedule.getStatus() != DoctorScheduleStatus.AVAILABLE) {
            throw new AppException(ErrorCode.DOCTOR_SCHEDULE_ALREADY_RESERVED);
        }

        doctorSchedule.setStatus(DoctorScheduleStatus.RESERVED);
        doctorSchedule.setAppointmentId(request.getAppointmentId());
        doctorSchedule = doctorScheduleRepository.save(doctorSchedule);
        return doctorScheduleMapper.toDoctorScheduleResponse(doctorSchedule);
    }

    @Transactional
    public DoctorScheduleResponse releaseSchedule(Long scheduleId) {
        return releaseSchedule(scheduleId, null);
    }

    @Transactional
    public DoctorScheduleResponse releaseSchedule(Long scheduleId, String appointmentId) {
        DoctorSchedule doctorSchedule = getScheduleEntityForUpdate(scheduleId);
        if (doctorSchedule.getStatus() != DoctorScheduleStatus.RESERVED) {
            throw new AppException(ErrorCode.DOCTOR_SCHEDULE_NOT_RESERVED);
        }

        if (appointmentId != null && !appointmentId.equals(doctorSchedule.getAppointmentId())) {
            throw new AppException(ErrorCode.DOCTOR_SCHEDULE_APPOINTMENT_MISMATCH);
        }

        doctorSchedule.setStatus(DoctorScheduleStatus.AVAILABLE);
        doctorSchedule.setAppointmentId(null);
        doctorSchedule = doctorScheduleRepository.save(doctorSchedule);
        return doctorScheduleMapper.toDoctorScheduleResponse(doctorSchedule);
    }

    @Transactional
    public DoctorScheduleResponse blockSchedule(Long scheduleId, DoctorScheduleBlockRequest request) {
        DoctorSchedule doctorSchedule = getScheduleEntityForUpdate(scheduleId);
        if (doctorSchedule.getStatus() == DoctorScheduleStatus.RESERVED) {
            throw new AppException(ErrorCode.DOCTOR_SCHEDULE_CANNOT_BLOCK);
        }

        doctorSchedule.setStatus(DoctorScheduleStatus.BLOCKED);
        doctorSchedule.setNotes(request.getReason());
        doctorSchedule = doctorScheduleRepository.save(doctorSchedule);
        return doctorScheduleMapper.toDoctorScheduleResponse(doctorSchedule);
    }

    private void ensureDoctorExists(String doctorId) {
        if (!doctorRepository.existsById(doctorId)) {
            throw new AppException(ErrorCode.DOCTOR_NOT_EXISTED);
        }
    }

    private DoctorSchedule getScheduleEntity(Long scheduleId) {
        return doctorScheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new AppException(ErrorCode.DOCTOR_SCHEDULE_NOT_EXISTED));
    }

    private DoctorSchedule getScheduleEntityForUpdate(Long scheduleId) {
        return doctorScheduleRepository.findByIdWithLock(scheduleId)
                .orElseThrow(() -> new AppException(ErrorCode.DOCTOR_SCHEDULE_NOT_EXISTED));
    }

    private void validateMutableSchedule(DoctorSchedule doctorSchedule, ErrorCode errorCode) {
        if (doctorSchedule.getStatus() == DoctorScheduleStatus.RESERVED) {
            throw new AppException(errorCode);
        }
    }

    private void validateTimeRange(java.time.LocalDateTime startTime, java.time.LocalDateTime endTime) {
        if (!startTime.isBefore(endTime)) {
            throw new AppException(ErrorCode.DOCTOR_SCHEDULE_INVALID_TIME_RANGE);
        }
    }
}
