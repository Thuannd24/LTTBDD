package com.medbook.appointment.service;

import com.medbook.appointment.dto.request.ExamPackageStepRequest;
import com.medbook.appointment.dto.response.ExamPackageStepResponse;
import com.medbook.appointment.entity.ExamPackageStep;
import com.medbook.appointment.mapper.ExamPackageStepMapper;
import com.medbook.appointment.repository.ExamPackageRepository;
import com.medbook.appointment.repository.ExamPackageStepRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional(readOnly = true)
public class ExamPackageStepService {
    
    ExamPackageStepRepository repository;
    ExamPackageRepository packageRepository;
    ExamPackageStepMapper mapper;
    
    /**
     * Lấy danh sách steps của 1 package
     */
    public List<ExamPackageStepResponse> getStepsByPackageId(String packageId) {
        // Verify package exists
        if (!packageRepository.existsById(packageId)) {
            throw new RuntimeException("Package không tồn tại: " + packageId);
        }
        
        return repository.findByPackageIdOrderByStepOrder(packageId)
                .stream()
                .map(mapper::toResponse)
                .toList();
    }
    
    /**
     * Lấy chi tiết 1 step
     */
    public ExamPackageStepResponse getStepById(String stepId) {
        return repository.findById(stepId)
                .map(mapper::toResponse)
                .orElseThrow(() -> new RuntimeException("Step không tồn tại: " + stepId));
    }
    
    /**
     * Tạo step mới cho package
     */
    @Transactional
    public ExamPackageStepResponse createStep(String packageId, ExamPackageStepRequest request) {
        // Verify package exists
        if (!packageRepository.existsById(packageId)) {
            throw new RuntimeException("Package không tồn tại: " + packageId);
        }
        
        ExamPackageStep entity = mapper.toEntity(request);
        entity.setPackageId(packageId);
        
        ExamPackageStep saved = repository.save(entity);
        return mapper.toResponse(saved);
    }
    
    /**
     * Cập nhật step
     */
    @Transactional
    public ExamPackageStepResponse updateStep(String packageId, String stepId, ExamPackageStepRequest request) {
        ExamPackageStep entity = repository.findById(stepId)
                .orElseThrow(() -> new RuntimeException("Step không tồn tại: " + stepId));
        
        // Verify step belongs to package
        if (!entity.getPackageId().equals(packageId)) {
            throw new RuntimeException("Step không thuộc package: " + packageId);
        }
        
        mapper.updateEntity(entity, request);
        ExamPackageStep updated = repository.save(entity);
        return mapper.toResponse(updated);
    }
    
    /**
     * Xóa step
     */
    @Transactional
    public void deleteStep(String packageId, String stepId) {
        ExamPackageStep entity = repository.findById(stepId)
                .orElseThrow(() -> new RuntimeException("Step không tồn tại: " + stepId));
        
        // Verify step belongs to package
        if (!entity.getPackageId().equals(packageId)) {
            throw new RuntimeException("Step không thuộc package: " + packageId);
        }
        
        repository.deleteById(stepId);
    }
    @Transactional
    public void deleteStepsByPackageId(String packageId) {
        repository.deleteByPackageId(packageId);
    }
}
