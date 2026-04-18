package com.medbook.appointment.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ExamPackageStepResponse {
    String id;
    String packageId;
    Integer stepOrder;
    String stepName;
    List<String> allowedSpecialtyIds;
    String requiredRoomCategory;
    String requiredEquipmentType;
    Boolean equipmentRequired;
    Integer estimatedMinutes;
    String note;
    LocalDateTime createdAt;
}
