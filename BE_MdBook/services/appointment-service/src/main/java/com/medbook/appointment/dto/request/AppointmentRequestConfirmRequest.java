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
public class AppointmentRequestConfirmRequest {

    @NotBlank(message = "FACILITY_ID_BLANK")
    String facilityId;

    @NotNull(message = "ROOM_SLOT_ID_NULL")
    Long roomSlotId;

    Long equipmentSlotId;
}
