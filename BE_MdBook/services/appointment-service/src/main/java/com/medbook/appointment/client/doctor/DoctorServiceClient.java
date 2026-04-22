package com.medbook.appointment.client.doctor;

import com.medbook.appointment.client.model.DoctorInfo;
import com.medbook.appointment.client.model.DoctorScheduleInfo;
import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.exception.DoctorNotFoundException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.exception.GrpcCommunicationException;
import com.medbook.appointment.exception.GrpcPermissionDeniedException;
import com.medbook.appointment.exception.GrpcUnauthenticatedException;
import feign.FeignException;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Component;

@Component
public class DoctorServiceClient {

    private final DoctorServiceFeignClient doctorServiceFeignClient;

    public DoctorServiceClient(DoctorServiceFeignClient doctorServiceFeignClient) {
        this.doctorServiceFeignClient = doctorServiceFeignClient;
    }

    public DoctorInfo getDoctorById(String doctorId) {
        try {
            DoctorDetailsResponse response = requireResult(
                    doctorServiceFeignClient.getDoctor(doctorId),
                    "Doctor-service returned an empty response for doctor: " + doctorId);
            List<String> specialtyIds = response.specialtyIds() == null
                    ? List.of()
                    : response.specialtyIds().stream().sorted(Comparator.naturalOrder()).toList();
            return new DoctorInfo(
                    response.id(),
                    response.userId(),
                    specialtyIds.isEmpty() ? "" : specialtyIds.getFirst(),
                    specialtyIds,
                    "ACTIVE".equalsIgnoreCase(response.status()));
        } catch (FeignException.NotFound ex) {
            throw new DoctorNotFoundException("Doctor not found: " + doctorId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "doctor-service");
        }
    }

    public DoctorScheduleInfo getDoctorScheduleById(String scheduleId, String doctorId) {
        try {
            DoctorScheduleDetailsResponse response = requireResult(
                    doctorServiceFeignClient.getSchedule(scheduleId),
                    "Doctor-service returned an empty response for schedule: " + scheduleId);
            if (!Objects.equals(response.doctorId(), doctorId)) {
                throw new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
            }
            return new DoctorScheduleInfo(
                    String.valueOf(response.id()),
                    response.doctorId(),
                    response.startTime().toLocalDate().toString(),
                    response.startTime().toLocalTime().toString(),
                    response.endTime().toLocalTime().toString(),
                    "AVAILABLE".equalsIgnoreCase(response.status()));
        } catch (DoctorScheduleNotFoundException ex) {
            throw ex;
        } catch (FeignException.NotFound ex) {
            throw new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "doctor-service");
        }
    }

    public void reserveSchedule(Long scheduleId, String appointmentId) {
        try {
            requireResult(
                    doctorServiceFeignClient.reserveSchedule(scheduleId,
                            new AppointmentReferenceRequest(appointmentId)),
                    "Doctor-service failed to reserve schedule: " + scheduleId);
        } catch (FeignException.NotFound ex) {
            throw new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "doctor-service");
        }
    }

    public void releaseSchedule(Long scheduleId, String appointmentId) {
        try {
            requireResult(
                    doctorServiceFeignClient.releaseSchedule(scheduleId,
                            new AppointmentReferenceRequest(appointmentId)),
                    "Doctor-service failed to release schedule: " + scheduleId);
        } catch (FeignException.NotFound ex) {
            throw new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
        } catch (FeignException ex) {
            throw mapFeignException(ex, "doctor-service");
        }
    }

    private <T> T requireResult(ApiResponse<T> response, String message) {
        if (response == null || response.getResult() == null) {
            throw new GrpcCommunicationException(message);
        }
        return response.getResult();
    }

    private RuntimeException mapFeignException(FeignException ex, String serviceName) {
        return switch (ex.status()) {
            case 401 -> new GrpcUnauthenticatedException("Unauthenticated when calling " + serviceName, ex);
            case 403 -> new GrpcPermissionDeniedException("Permission denied when calling " + serviceName, ex);
            case 400 -> new GrpcCommunicationException("Invalid request when calling " + serviceName, ex);
            case 503 -> new GrpcCommunicationException(serviceName + " unavailable", ex);
            default -> new GrpcCommunicationException("Error calling " + serviceName, ex);
        };
    }
}
