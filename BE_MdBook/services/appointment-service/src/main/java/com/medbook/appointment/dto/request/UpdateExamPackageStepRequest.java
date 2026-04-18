package com.medbook.appointment.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UpdateExamPackageStepRequest {
    
    @NotBlank(message = "STEP_NAME_BLANK")
    String stepName;
    
    Integer stepOrder;
    
    List<String> allowedSpecialtyIds;
    
    String requiredRoomCategory;
    
    String requiredEquipmentType;
    
    Boolean equipmentRequired;
    
    Integer estimatedMinutes;
    
    String note;
}
