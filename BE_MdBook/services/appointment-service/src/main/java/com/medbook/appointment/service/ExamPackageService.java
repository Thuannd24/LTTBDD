package com.medbook.appointment.service;

import com.medbook.appointment.dto.request.ExamPackageRequest;
import com.medbook.appointment.dto.response.ExamPackageResponse;
import com.medbook.appointment.entity.ExamPackage;
import com.medbook.appointment.mapper.ExamPackageMapper;
import com.medbook.appointment.repository.ExamPackageRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Transactional(readOnly = true)
public class ExamPackageService {
    
    ExamPackageRepository repository;
    ExamPackageMapper mapper;
    
    /**
     * Lấy danh sách tất cả packages với phân trang
     */
    public Page<ExamPackageResponse> getAllPackages(Pageable pageable) {
        return repository.findAll(pageable)
                .map(mapper::toResponse);
    }
    
    /**
     * Lấy chi tiết 1 package
     */
    public ExamPackageResponse getPackageById(String id) {
        return repository.findById(id)
                .map(mapper::toResponse)
                .orElseThrow(() -> new RuntimeException("Package không tồn tại: " + id));
    }
    
    /**
     * Tạo package mới
     */
    @Transactional
    public ExamPackageResponse createPackage(ExamPackageRequest request) {
        // Kiểm tra code không trùng
        if (repository.findByCode(request.getCode()).isPresent()) {
            throw new RuntimeException("Package với code '" + request.getCode() + "' đã tồn tại");
        }
        
        ExamPackage entity = mapper.toEntity(request);
        entity.setStatus(ExamPackage.PackageStatus.ACTIVE);
        
        ExamPackage saved = repository.save(entity);
        return mapper.toResponse(saved);
    }
    
    /**
     * Cập nhật package
     */
    @Transactional
    public ExamPackageResponse updatePackage(String id, ExamPackageRequest request) {
        ExamPackage entity = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Package không tồn tại: " + id));
        
        mapper.updateEntity(entity, request);
        ExamPackage updated = repository.save(entity);
        return mapper.toResponse(updated);
    }
    
    /**
     * Xóa package
     */
    @Transactional
    public void deletePackage(String id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Package không tồn tại: " + id);
        }
        repository.deleteById(id);
    }
    
}
