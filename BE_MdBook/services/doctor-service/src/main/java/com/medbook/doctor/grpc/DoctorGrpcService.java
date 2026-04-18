package com.medbook.doctor.grpc;

import com.medbook.doctor.dto.request.DoctorScheduleReserveRequest;
import com.medbook.doctor.dto.response.DoctorResponse;
import com.medbook.doctor.dto.response.DoctorScheduleResponse;
import com.medbook.doctor.entity.enums.DoctorScheduleStatus;
import com.medbook.doctor.service.DoctorScheduleService;
import com.medbook.doctor.service.DoctorService;
import com.medbook.grpc.doctor.DoctorServiceGrpc;
import com.medbook.grpc.doctor.GetDoctorByIdRequest;
import com.medbook.grpc.doctor.GetDoctorScheduleByIdRequest;
import com.medbook.grpc.doctor.ReleaseDoctorScheduleRequest;
import com.medbook.grpc.doctor.ReserveDoctorScheduleRequest;
import io.grpc.stub.StreamObserver;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.devh.boot.grpc.server.service.GrpcService;

@GrpcService
@RequiredArgsConstructor
@Slf4j
public class DoctorGrpcService extends DoctorServiceGrpc.DoctorServiceImplBase {

    private final DoctorService doctorService;
    private final DoctorScheduleService doctorScheduleService;

    @Override
    public void getDoctorById(GetDoctorByIdRequest request,
            StreamObserver<com.medbook.grpc.doctor.DoctorResponse> responseObserver) {
        try {
            DoctorResponse response = doctorService.getDoctor(request.getDoctorId());
            List<String> specialtyIds = response.getSpecialtyIds() == null
                    ? List.of()
                    : response.getSpecialtyIds().stream().sorted(Comparator.naturalOrder()).toList();

            responseObserver.onNext(com.medbook.grpc.doctor.DoctorResponse.newBuilder()
                    .setId(response.getId())
                    .setName(response.getUserId() == null ? "" : response.getUserId())
                    .setSpecialtyId(specialtyIds.isEmpty() ? "" : specialtyIds.getFirst())
                    .addAllAllowedSpecialtyIds(specialtyIds)
                    .setActive("ACTIVE".equalsIgnoreCase(response.getStatus()))
                    .build());
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            log.error("gRPC getDoctorById failed for doctorId={}", request.getDoctorId(), throwable);
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    @Override
    public void getDoctorScheduleById(GetDoctorScheduleByIdRequest request,
            StreamObserver<com.medbook.grpc.doctor.DoctorScheduleResponse> responseObserver) {
        try {
            Long scheduleId = parseScheduleId(request.getScheduleId());
            DoctorScheduleResponse response = doctorScheduleService.getSchedule(scheduleId);
            if (!response.getDoctorId().equals(request.getDoctorId())) {
                throw new IllegalArgumentException("Schedule does not belong to the requested doctor");
            }

            responseObserver.onNext(toGrpcScheduleResponse(response));
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            log.error("gRPC getDoctorScheduleById failed for scheduleId={}, doctorId={}",
                    request.getScheduleId(), request.getDoctorId(), throwable);
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    @Override
    public void reserveDoctorSchedule(ReserveDoctorScheduleRequest request,
            StreamObserver<com.medbook.grpc.doctor.DoctorScheduleResponse> responseObserver) {
        try {
            Long scheduleId = parseScheduleId(request.getScheduleId());
            DoctorScheduleResponse schedule = doctorScheduleService.getSchedule(scheduleId);
            if (!schedule.getDoctorId().equals(request.getDoctorId())) {
                throw new IllegalArgumentException("Schedule does not belong to the requested doctor");
            }

            DoctorScheduleResponse response = doctorScheduleService.reserveSchedule(
                    scheduleId,
                    DoctorScheduleReserveRequest.builder()
                            .appointmentId(request.getAppointmentId())
                            .build());
            responseObserver.onNext(toGrpcScheduleResponse(response));
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            log.error("gRPC reserveDoctorSchedule failed for scheduleId={}, doctorId={}, appointmentId={}",
                    request.getScheduleId(), request.getDoctorId(), request.getAppointmentId(), throwable);
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    @Override
    public void releaseDoctorSchedule(ReleaseDoctorScheduleRequest request,
            StreamObserver<com.medbook.grpc.doctor.DoctorScheduleResponse> responseObserver) {
        try {
            Long scheduleId = parseScheduleId(request.getScheduleId());
            DoctorScheduleResponse response = doctorScheduleService.releaseSchedule(scheduleId,
                    request.getAppointmentId());
            responseObserver.onNext(toGrpcScheduleResponse(response));
            responseObserver.onCompleted();
        } catch (Throwable throwable) {
            log.error("gRPC releaseDoctorSchedule failed for scheduleId={}, appointmentId={}",
                    request.getScheduleId(), request.getAppointmentId(), throwable);
            responseObserver.onError(GrpcExceptionMapper.map(throwable).asRuntimeException());
        }
    }

    private Long parseScheduleId(String scheduleId) {
        try {
            return Long.parseLong(scheduleId);
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Invalid schedule id");
        }
    }

    private com.medbook.grpc.doctor.DoctorScheduleResponse toGrpcScheduleResponse(DoctorScheduleResponse response) {
        return com.medbook.grpc.doctor.DoctorScheduleResponse.newBuilder()
                .setId(String.valueOf(response.getId()))
                .setDoctorId(response.getDoctorId())
                .setDate(response.getStartTime().toLocalDate().toString())
                .setStartTime(response.getStartTime().toLocalTime().toString())
                .setEndTime(response.getEndTime().toLocalTime().toString())
                .setAvailable(response.getStatus() == DoctorScheduleStatus.AVAILABLE)
                .build();
    }
}
