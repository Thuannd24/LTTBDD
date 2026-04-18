package com.medbook.slotservice.configuration;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * Lớp cấu hình JpaAuditingConfig.
 * 
 * Mục đích: Kích hoạt tính năng JPA Auditing của Spring Data JPA.
 * Tính năng này cho phép hệ thống tự động lưu lại dấu vết thời gian (@CreatedDate, @LastModifiedDate)
 * vào các bản ghi Entity mỗi khi có thao tác Insert hoặc Update xuống DataBase.
 * Giúp lập trình viên không phải viết code cập nhật thời gian thủ công.
 */
@Configuration
// Bật tính năng 'Lắng nghe' của Spring Data JPA.
// Tính năng này giúp tự động điền ngày giờ vào các cột @CreatedDate và @LastModifiedDate 
// mỗi khi bạn gọi lệnh save() xuống database mà không cần gán bằng tay (entity.setCreatedAt(...)).
@EnableJpaAuditing
public class JpaAuditingConfig {
}
