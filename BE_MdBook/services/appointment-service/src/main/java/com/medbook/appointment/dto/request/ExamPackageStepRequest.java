package com.medbook.appointment.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ExamPackageStepRequest {
    @NotNull(message = "Step order không được để null")
    @Positive(message = "Step order phải lớn hơn 0")
    Integer stepOrder;
    
    @NotBlank(message = "Step name không được để trống")
    @Size(max = 150, message = "Step name không được vượt quá 150 ký tự")
    String stepName;
    
    List<String> allowedSpecialtyIds;
    
    @Size(max = 50, message = "Required room category không được vượt quá 50 ký tự")
    String requiredRoomCategory;
    
    @Size(max = 50, message = "Required equipment type không được vượt quá 50 ký tự")
    String requiredEquipmentType;
    
    @NotNull(message = "Equipment required flag không được để null")
    Boolean equipmentRequired;
    
    @NotNull(message = "Estimated minutes không được để null")
    @Positive(message = "Estimated minutes phải lớn hơn 0")
    Integer estimatedMinutes;
    
    String note;
}
