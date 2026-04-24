package com.medbook.appointment.service;

import com.medbook.appointment.client.doctor.DoctorServiceClient;
import com.medbook.appointment.client.profile.ProfileServiceClient;
import com.medbook.appointment.client.profile.InternalUserProfileResponse;
import com.medbook.appointment.dto.ApiResponse;
import com.medbook.appointment.entity.Appointment;
import com.medbook.appointment.repository.AppointmentRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Component
@Slf4j
public class AppointmentReminderJob {

    private final AppointmentRepository appointmentRepository;
    private final NotificationService notificationService;
    private final ProfileServiceClient profileServiceClient;
    private final DoctorServiceClient doctorServiceClient;

    public AppointmentReminderJob(AppointmentRepository appointmentRepository,
                                  NotificationService notificationService,
                                  ProfileServiceClient profileServiceClient,
                                  DoctorServiceClient doctorServiceClient) {
        this.appointmentRepository = appointmentRepository;
        this.notificationService = notificationService;
        this.profileServiceClient = profileServiceClient;
        this.doctorServiceClient = doctorServiceClient;
    }

    // Run every day at 8:00 AM
    @Scheduled(cron = "0 0 8 * * *")
    public void sendReminders() {
        log.info("Running daily appointment reminder job");
        LocalDate tomorrow = LocalDate.now().plusDays(1);

        // Sử dụng query trực tiếp thay vì tải toàn bộ appointments vào memory
        List<Appointment> upcomingAppointments = appointmentRepository
                .findByStatusAndAppointmentDate(Appointment.AppointmentStatus.CONFIRMED, tomorrow);

        for (Appointment app : upcomingAppointments) {
            try {
                ApiResponse<InternalUserProfileResponse> response = profileServiceClient.getInternalProfile(app.getPatientUserId());
                if (response.getResult() != null && response.getResult().getFcmToken() != null && !response.getResult().getFcmToken().isBlank()) {
                    var doctorInfo = doctorServiceClient.getDoctorById(app.getDoctorId());
                    String title = "Nhắc nhở lịch khám";
                    String message = String.format(
                            "Bạn có lịch hẹn khám với BS. %s vào ngày mai lúc %s. Vui lòng đến đúng giờ!",
                            doctorInfo.name(),
                            app.getStartTime().format(DateTimeFormatter.ofPattern("HH:mm"))
                    );
                    notificationService.sendPushNotification(response.getResult().getFcmToken(), title, message);
                }
            } catch (Exception e) {
                log.error("Failed to send reminder for appointment {}", app.getId(), e);
            }
        }
    }
}
