package com.medbook.doctor.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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

@ExtendWith(MockitoExtension.class)
@DisplayName("DoctorScheduleService Unit Tests")
class DoctorScheduleServiceTest {

    @Mock
    DoctorScheduleRepository doctorScheduleRepository;

    @Mock
    DoctorRepository doctorRepository;

    @Mock
    DoctorScheduleMapper doctorScheduleMapper;

    @InjectMocks
    DoctorScheduleService doctorScheduleService;

    @Test
    @DisplayName("createSchedule saves available schedule when doctor exists and time range is valid")
    void createScheduleSuccess() {
        DoctorScheduleCreateRequest request = createRequest(
                3L,
                LocalDateTime.of(2026, 4, 7, 8, 0),
                LocalDateTime.of(2026, 4, 7, 10, 0),
                "Morning shift");
        DoctorSchedule mapped = DoctorSchedule.builder().facilityId(3L).startTime(request.getStartTime())
                .endTime(request.getEndTime()).notes(request.getNotes()).build();
        DoctorSchedule saved = buildSchedule(10L, DoctorScheduleStatus.AVAILABLE);
        saved.setNotes("Morning shift");
        DoctorScheduleResponse response = buildResponse(10L, DoctorScheduleStatus.AVAILABLE);
        response.setNotes("Morning shift");

        when(doctorRepository.existsById("doctor-1")).thenReturn(true);
        when(doctorScheduleRepository.existsByDoctorIdAndStartTimeLessThanAndEndTimeGreaterThan(
                "doctor-1", request.getEndTime(), request.getStartTime())).thenReturn(false);
        when(doctorScheduleMapper.toDoctorSchedule(request)).thenReturn(mapped);
        when(doctorScheduleRepository.save(mapped)).thenReturn(saved);
        when(doctorScheduleMapper.toDoctorScheduleResponse(saved)).thenReturn(response);

        DoctorScheduleResponse result = doctorScheduleService.createSchedule("doctor-1", request);

        assertThat(result.getId()).isEqualTo(10L);
        assertThat(mapped.getDoctorId()).isEqualTo("doctor-1");
        assertThat(mapped.getStatus()).isEqualTo(DoctorScheduleStatus.AVAILABLE);
    }

    @Test
    @DisplayName("getAvailableSchedules filters by date and facility when facility is provided")
    void getAvailableSchedulesWithFacility() {
        DoctorSchedule schedule = buildSchedule(19L, DoctorScheduleStatus.AVAILABLE);
        DoctorScheduleResponse response = buildResponse(19L, DoctorScheduleStatus.AVAILABLE);
        LocalDate date = LocalDate.of(2026, 4, 7);

        when(doctorRepository.existsById("doctor-1")).thenReturn(true);
        when(doctorScheduleRepository.findByDoctorIdAndFacilityIdAndStatusAndStartTimeBetweenOrderByStartTimeAsc(
                "doctor-1",
                3L,
                DoctorScheduleStatus.AVAILABLE,
                date.atStartOfDay(),
                date.plusDays(1).atStartOfDay().minusNanos(1)))
                .thenReturn(List.of(schedule));
        when(doctorScheduleMapper.toDoctorScheduleResponse(schedule)).thenReturn(response);

        List<DoctorScheduleResponse> result = doctorScheduleService.getAvailableSchedules("doctor-1", date, 3L);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().getId()).isEqualTo(19L);
    }

    @Test
    @DisplayName("getAvailableSchedules filters by date when facility is not provided")
    void getAvailableSchedulesWithoutFacility() {
        DoctorSchedule schedule = buildSchedule(20L, DoctorScheduleStatus.AVAILABLE);
        DoctorScheduleResponse response = buildResponse(20L, DoctorScheduleStatus.AVAILABLE);
        LocalDate date = LocalDate.of(2026, 4, 7);

        when(doctorRepository.existsById("doctor-1")).thenReturn(true);
        when(doctorScheduleRepository.findByDoctorIdAndStatusAndStartTimeBetweenOrderByStartTimeAsc(
                "doctor-1",
                DoctorScheduleStatus.AVAILABLE,
                date.atStartOfDay(),
                date.plusDays(1).atStartOfDay().minusNanos(1)))
                .thenReturn(List.of(schedule));
        when(doctorScheduleMapper.toDoctorScheduleResponse(schedule)).thenReturn(response);

        List<DoctorScheduleResponse> result = doctorScheduleService.getAvailableSchedules("doctor-1", date, null);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().getId()).isEqualTo(20L);
    }

    @Test
    @DisplayName("updateSchedule rejects reserved schedule")
    void updateScheduleRejectsReserved() {
        DoctorSchedule reserved = buildSchedule(11L, DoctorScheduleStatus.RESERVED);
        DoctorScheduleCreateRequest request = createRequest(
                5L,
                LocalDateTime.of(2026, 4, 8, 9, 0),
                LocalDateTime.of(2026, 4, 8, 11, 0),
                "Updated");

        when(doctorScheduleRepository.findByIdWithLock(11L)).thenReturn(Optional.of(reserved));

        assertThatThrownBy(() -> doctorScheduleService.updateSchedule(11L, request))
                .isInstanceOf(AppException.class)
                .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.DOCTOR_SCHEDULE_CANNOT_UPDATE));
    }

    @Test
    @DisplayName("updateSchedule rejects overlap with another schedule")
    void updateScheduleRejectsOverlap() {
        DoctorSchedule available = buildSchedule(12L, DoctorScheduleStatus.AVAILABLE);
        DoctorScheduleCreateRequest request = createRequest(
                5L,
                LocalDateTime.of(2026, 4, 8, 9, 0),
                LocalDateTime.of(2026, 4, 8, 11, 0),
                "Updated");

        when(doctorScheduleRepository.findByIdWithLock(12L)).thenReturn(Optional.of(available));
        when(doctorScheduleRepository.existsByDoctorIdAndIdNotAndStartTimeLessThanAndEndTimeGreaterThan(
                "doctor-1", 12L, request.getEndTime(), request.getStartTime())).thenReturn(true);

        assertThatThrownBy(() -> doctorScheduleService.updateSchedule(12L, request))
                .isInstanceOf(AppException.class)
                .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.DOCTOR_SCHEDULE_OVERLAPPED));
    }

    @Test
    @DisplayName("updateSchedule updates mutable fields for available schedule")
    void updateScheduleSuccess() {
        DoctorSchedule available = buildSchedule(13L, DoctorScheduleStatus.AVAILABLE);
        DoctorScheduleResponse response = buildResponse(13L, DoctorScheduleStatus.AVAILABLE);
        DoctorScheduleCreateRequest request = createRequest(
                7L,
                LocalDateTime.of(2026, 4, 9, 13, 0),
                LocalDateTime.of(2026, 4, 9, 15, 0),
                "Afternoon shift");

        when(doctorScheduleRepository.findByIdWithLock(13L)).thenReturn(Optional.of(available));
        when(doctorScheduleRepository.existsByDoctorIdAndIdNotAndStartTimeLessThanAndEndTimeGreaterThan(
                "doctor-1", 13L, request.getEndTime(), request.getStartTime())).thenReturn(false);
        when(doctorScheduleRepository.save(available)).thenReturn(available);
        when(doctorScheduleMapper.toDoctorScheduleResponse(available)).thenReturn(response);

        DoctorScheduleResponse result = doctorScheduleService.updateSchedule(13L, request);

        assertThat(result.getId()).isEqualTo(13L);
        assertThat(available.getFacilityId()).isEqualTo(7L);
        assertThat(available.getStartTime()).isEqualTo(request.getStartTime());
        assertThat(available.getEndTime()).isEqualTo(request.getEndTime());
        assertThat(available.getNotes()).isEqualTo("Afternoon shift");
    }

    @Test
    @DisplayName("deleteSchedule rejects reserved schedule")
    void deleteScheduleRejectsReserved() {
        DoctorSchedule reserved = buildSchedule(14L, DoctorScheduleStatus.RESERVED);
        when(doctorScheduleRepository.findByIdWithLock(14L)).thenReturn(Optional.of(reserved));

        assertThatThrownBy(() -> doctorScheduleService.deleteSchedule(14L))
                .isInstanceOf(AppException.class)
                .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.DOCTOR_SCHEDULE_CANNOT_DELETE));

        verify(doctorScheduleRepository, never()).delete(any());
    }

    @Test
    @DisplayName("deleteSchedule deletes available schedule")
    void deleteScheduleSuccess() {
        DoctorSchedule available = buildSchedule(15L, DoctorScheduleStatus.AVAILABLE);
        when(doctorScheduleRepository.findByIdWithLock(15L)).thenReturn(Optional.of(available));

        doctorScheduleService.deleteSchedule(15L);

        verify(doctorScheduleRepository).delete(available);
    }

    @Test
    @DisplayName("reserveSchedule marks available schedule as reserved")
    void reserveScheduleSuccess() {
        DoctorSchedule available = buildSchedule(16L, DoctorScheduleStatus.AVAILABLE);
        DoctorScheduleReserveRequest request = DoctorScheduleReserveRequest.builder().appointmentId("apt-77").build();
        DoctorScheduleResponse response = buildResponse(16L, DoctorScheduleStatus.RESERVED);
        response.setAppointmentId("apt-77");

        when(doctorScheduleRepository.findByIdWithLock(16L)).thenReturn(Optional.of(available));
        when(doctorScheduleRepository.save(available)).thenReturn(available);
        when(doctorScheduleMapper.toDoctorScheduleResponse(available)).thenReturn(response);

        DoctorScheduleResponse result = doctorScheduleService.reserveSchedule(16L, request);

        assertThat(result.getStatus()).isEqualTo(DoctorScheduleStatus.RESERVED);
        assertThat(available.getStatus()).isEqualTo(DoctorScheduleStatus.RESERVED);
        assertThat(available.getAppointmentId()).isEqualTo("apt-77");
    }

    @Test
    @DisplayName("releaseSchedule rejects non-reserved schedule")
    void releaseScheduleRejectsNonReserved() {
        DoctorSchedule blocked = buildSchedule(17L, DoctorScheduleStatus.BLOCKED);
        when(doctorScheduleRepository.findByIdWithLock(17L)).thenReturn(Optional.of(blocked));

        assertThatThrownBy(() -> doctorScheduleService.releaseSchedule(17L))
                .isInstanceOf(AppException.class)
                .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.DOCTOR_SCHEDULE_NOT_RESERVED));
    }

    @Test
    @DisplayName("releaseSchedule rejects appointment mismatch")
    void releaseScheduleRejectsAppointmentMismatch() {
        DoctorSchedule reserved = buildSchedule(21L, DoctorScheduleStatus.RESERVED);
        reserved.setAppointmentId("apt-123");
        when(doctorScheduleRepository.findByIdWithLock(21L)).thenReturn(Optional.of(reserved));

        assertThatThrownBy(() -> doctorScheduleService.releaseSchedule(21L, "apt-999"))
                .isInstanceOf(AppException.class)
                .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.DOCTOR_SCHEDULE_APPOINTMENT_MISMATCH));
    }

    @Test
    @DisplayName("blockSchedule rejects reserved schedule")
    void blockScheduleRejectsReserved() {
        DoctorSchedule reserved = buildSchedule(18L, DoctorScheduleStatus.RESERVED);
        when(doctorScheduleRepository.findByIdWithLock(18L)).thenReturn(Optional.of(reserved));

        assertThatThrownBy(() -> doctorScheduleService.blockSchedule(
                18L, DoctorScheduleBlockRequest.builder().reason("Doctor busy").build()))
                .isInstanceOf(AppException.class)
                .satisfies(ex -> assertThat(((AppException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.DOCTOR_SCHEDULE_CANNOT_BLOCK));
    }

    private DoctorSchedule buildSchedule(Long id, DoctorScheduleStatus status) {
        return DoctorSchedule.builder()
                .id(id)
                .doctorId("doctor-1")
                .facilityId(3L)
                .startTime(LocalDateTime.of(2026, 4, 7, 8, 0))
                .endTime(LocalDateTime.of(2026, 4, 7, 10, 0))
                .status(status)
                .notes("Initial")
                .build();
    }

    private DoctorScheduleResponse buildResponse(Long id, DoctorScheduleStatus status) {
        return DoctorScheduleResponse.builder()
                .id(id)
                .doctorId("doctor-1")
                .facilityId(3L)
                .startTime(LocalDateTime.of(2026, 4, 7, 8, 0))
                .endTime(LocalDateTime.of(2026, 4, 7, 10, 0))
                .status(status)
                .build();
    }

    private DoctorScheduleCreateRequest createRequest(
            Long facilityId,
            LocalDateTime startTime,
            LocalDateTime endTime,
            String notes) {
        return DoctorScheduleCreateRequest.builder()
                .facilityId(facilityId)
                .startTime(startTime)
                .endTime(endTime)
                .notes(notes)
                .build();
    }
}
