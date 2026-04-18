package com.medbook.doctor.grpc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.medbook.doctor.dto.response.DoctorResponse;
import com.medbook.doctor.dto.response.DoctorScheduleResponse;
import com.medbook.doctor.entity.enums.DoctorScheduleStatus;
import com.medbook.doctor.exception.AppException;
import com.medbook.doctor.exception.ErrorCode;
import com.medbook.doctor.service.DoctorScheduleService;
import com.medbook.doctor.service.DoctorService;
import com.medbook.grpc.doctor.GetDoctorByIdRequest;
import com.medbook.grpc.doctor.GetDoctorScheduleByIdRequest;
import com.medbook.grpc.doctor.ReleaseDoctorScheduleRequest;
import com.medbook.grpc.doctor.ReserveDoctorScheduleRequest;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.StreamObserver;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DoctorGrpcServiceTest {

    @Mock
    private DoctorService doctorService;

    @Mock
    private DoctorScheduleService doctorScheduleService;

    private DoctorGrpcService doctorGrpcService;

    @BeforeEach
    void setUp() {
        doctorGrpcService = new DoctorGrpcService(doctorService, doctorScheduleService);
    }

    @Test
    void getDoctorById_mapsActiveAndSortedSpecialties() {
        when(doctorService.getDoctor("doctor-1")).thenReturn(DoctorResponse.builder()
                .id("doctor-1")
                .userId("user-1")
                .specialtyIds(new LinkedHashSet<>(Set.of("specialty-b", "specialty-a")))
                .status("ACTIVE")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build());

        TestObserver<com.medbook.grpc.doctor.DoctorResponse> observer = new TestObserver<>();
        doctorGrpcService.getDoctorById(GetDoctorByIdRequest.newBuilder().setDoctorId("doctor-1").build(), observer);

        assertThat(observer.response.getId()).isEqualTo("doctor-1");
        assertThat(observer.response.getAllowedSpecialtyIdsList()).containsExactly("specialty-a", "specialty-b");
        assertThat(observer.response.getSpecialtyId()).isEqualTo("specialty-a");
        assertThat(observer.response.getActive()).isTrue();
    }

    @Test
    void getDoctorScheduleById_rejectsWrongDoctor() {
        when(doctorScheduleService.getSchedule(10L)).thenReturn(scheduleResponse("doctor-1", DoctorScheduleStatus.AVAILABLE));

        TestObserver<com.medbook.grpc.doctor.DoctorScheduleResponse> observer = new TestObserver<>();
        doctorGrpcService.getDoctorScheduleById(GetDoctorScheduleByIdRequest.newBuilder()
                .setScheduleId("10")
                .setDoctorId("doctor-2")
                .build(), observer);

        assertThat(statusCode(observer.error)).isEqualTo(Status.Code.INVALID_ARGUMENT);
    }

    @Test
    void reserveDoctorSchedule_returnsReservedSchedule() {
        when(doctorScheduleService.getSchedule(10L)).thenReturn(scheduleResponse("doctor-1", DoctorScheduleStatus.AVAILABLE));
        when(doctorScheduleService.reserveSchedule(org.mockito.ArgumentMatchers.eq(10L), org.mockito.ArgumentMatchers.any()))
                .thenReturn(scheduleResponse("doctor-1", DoctorScheduleStatus.RESERVED));

        TestObserver<com.medbook.grpc.doctor.DoctorScheduleResponse> observer = new TestObserver<>();
        doctorGrpcService.reserveDoctorSchedule(ReserveDoctorScheduleRequest.newBuilder()
                .setScheduleId("10")
                .setDoctorId("doctor-1")
                .setAppointmentId("apt-1")
                .build(), observer);

        assertThat(observer.response.getAvailable()).isFalse();
    }

    @Test
    void releaseDoctorSchedule_mapsAppException() {
        when(doctorScheduleService.releaseSchedule(10L, "apt-2"))
                .thenThrow(new AppException(ErrorCode.DOCTOR_SCHEDULE_APPOINTMENT_MISMATCH));

        TestObserver<com.medbook.grpc.doctor.DoctorScheduleResponse> observer = new TestObserver<>();
        doctorGrpcService.releaseDoctorSchedule(ReleaseDoctorScheduleRequest.newBuilder()
                .setScheduleId("10")
                .setAppointmentId("apt-2")
                .build(), observer);

        assertThat(statusCode(observer.error)).isEqualTo(Status.Code.INVALID_ARGUMENT);
    }

    private DoctorScheduleResponse scheduleResponse(String doctorId, DoctorScheduleStatus status) {
        return DoctorScheduleResponse.builder()
                .id(10L)
                .doctorId(doctorId)
                .facilityId(1L)
                .startTime(LocalDateTime.of(2026, 4, 10, 8, 0))
                .endTime(LocalDateTime.of(2026, 4, 10, 9, 0))
                .status(status)
                .build();
    }

    private Status.Code statusCode(Throwable throwable) {
        return ((StatusRuntimeException) throwable).getStatus().getCode();
    }

    private static class TestObserver<T> implements StreamObserver<T> {
        private T response;
        private Throwable error;

        @Override
        public void onNext(T value) {
            this.response = value;
        }

        @Override
        public void onError(Throwable t) {
            this.error = t;
        }

        @Override
        public void onCompleted() {
        }
    }
}
