package com.medbook.appointment.dto.request;

import jakarta.validation.constraints.NotBlank;
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
public class CreateExamPackageRequest {
    
    @NotBlank(message = "CODE_BLANK")
    String code;
    
    @NotBlank(message = "NAME_BLANK")
    String name;
    
    String description;
    
    Integer estimatedTotalMinutes;
    
    String status;
}
