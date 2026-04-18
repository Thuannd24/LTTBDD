package com.medbook.appointment.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ExamPackageRequest {
    @NotBlank(message = "Code không được để trống")
    @Size(max = 50, message = "Code không được vượt quá 50 ký tự")
    String code;
    
    @NotBlank(message = "Name không được để trống")
    @Size(max = 255, message = "Name không được vượt quá 255 ký tự")
    String name;
    
    @Size(max = 1000, message = "Description không được vượt quá 1000 ký tự")
    String description;
    
    @NotNull(message = "Estimated total minutes không được để null")
    @Positive(message = "Estimated total minutes phải lớn hơn 0")
    Integer estimatedTotalMinutes;
    
    String status;
}
