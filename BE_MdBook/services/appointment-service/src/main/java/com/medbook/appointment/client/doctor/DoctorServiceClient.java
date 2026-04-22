package com.medbook.appointment.client.doctor;

import com.medbook.appointment.client.model.DoctorInfo;
import com.medbook.appointment.client.model.DoctorScheduleInfo;
import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.exception.DoctorNotFoundException;
import com.medbook.appointment.exception.DoctorScheduleNotFoundException;
import com.medbook.appointment.exception.ServiceCommunicationException;
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
                    "Doctor not found: " + doctorId);
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
            throw new ServiceCommunicationException("Error calling doctor-service", ex);
        }
    }

    public DoctorScheduleInfo getDoctorScheduleById(String scheduleId, String doctorId) {
        try {
            DoctorScheduleDetailsResponse response = requireResult(
                    doctorServiceFeignClient.getSchedule(scheduleId),
                    "Schedule not found: " + scheduleId);
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
            throw new ServiceCommunicationException("Error calling doctor-service", ex);
        }
    }

    public void reserveSchedule(Long scheduleId, String appointmentId) {
        try {
            requireResult(
                    doctorServiceFeignClient.reserveSchedule(scheduleId,
                            new AppointmentReferenceRequest(appointmentId)),
                    "Failed to reserve schedule: " + scheduleId);
        } catch (FeignException.NotFound ex) {
            throw new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
        } catch (FeignException ex) {
            throw new ServiceCommunicationException("Error reserving doctor schedule", ex);
        }
    }

    public void releaseSchedule(Long scheduleId, String appointmentId) {
        try {
            requireResult(
                    doctorServiceFeignClient.releaseSchedule(scheduleId,
                            new AppointmentReferenceRequest(appointmentId)),
                    "Failed to release schedule: " + scheduleId);
        } catch (FeignException.NotFound ex) {
            throw new DoctorScheduleNotFoundException("Doctor schedule not found: " + scheduleId);
        } catch (FeignException ex) {
            throw new ServiceCommunicationException("Error releasing doctor schedule", ex);
        }
    }

    private <T> T requireResult(ApiResponse<T> response, String message) {
        if (response == null || response.getResult() == null) {
            throw new ServiceCommunicationException(message);
        }
        return response.getResult();
    }
}
