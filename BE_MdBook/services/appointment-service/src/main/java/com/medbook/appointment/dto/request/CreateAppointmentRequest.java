package com.medbook.appointment.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class CreateAppointmentRequest {

    @NotBlank(message = "PACKAGE_ID_BLANK")
    String packageId;

    String packageStepId;

    @NotBlank(message = "DOCTOR_ID_BLANK")
    String doctorId;

    @NotNull(message = "DOCTOR_SCHEDULE_ID_NULL")
    Long doctorScheduleId;

    @NotNull(message = "ROOM_SLOT_ID_NULL")
    Long roomSlotId;

    Long equipmentSlotId;

    String note;

    String facilityId;
}
