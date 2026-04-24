package com.medbook.appointment.service.command;

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
public class CreateAppointmentCommand {

    String packageId;
    String doctorId;
    Long doctorScheduleId;
    Long roomSlotId;

    String note;
    String facilityId;
}
