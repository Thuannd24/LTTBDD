-- File: scripts/db/init-appointment.sql
-- Script tự động khởi tạo dữ liệu gói khám cho appointment_db

CREATE TABLE IF NOT EXISTS exam_packages (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    estimated_total_minutes INTEGER,
    specialty_id VARCHAR(36),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exam_package_steps (
    id VARCHAR(36) PRIMARY KEY,
    package_id VARCHAR(36) REFERENCES exam_packages(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    step_order INTEGER,
    estimated_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

DELETE FROM exam_package_steps;
DELETE FROM exam_packages;

INSERT INTO exam_packages (id, code, name, description, status, estimated_total_minutes, specialty_id)
VALUES 
('pkg-001', 'PKG-BASIC', 'Gói khám cơ bản', 'Khám tổng quát, đo huyết áp, kiểm tra chỉ số BMI.', 'ACTIVE', 30, 'spec-011'),
('pkg-002', 'PKG-STANDARD', 'Gói khám tiêu chuẩn', 'Khám tổng quát + Xét nghiệm máu cơ bản + Siêu âm bụng.', 'ACTIVE', 60, 'spec-011'),
('pkg-003', 'PKG-PREMIUM', 'Gói khám toàn diện', 'Khám tổng quát + X-quang + Điện tâm đồ + Xét nghiệm chuyên sâu.', 'ACTIVE', 120, 'spec-011'),
('pkg-004', 'PKG-CARDIO', 'Gói khám tim mạch', 'Chuyên sâu về tim: Siêu âm tim, Đo điện tim, Xét nghiệm mỡ máu.', 'ACTIVE', 90, 'spec-001'),
('pkg-005', 'PKG-DIABETES', 'Gói khám nội tiết', 'Kiểm tra đường huyết, HbA1c, tư vấn chế độ ăn uống.', 'ACTIVE', 75, 'spec-012'),
('pkg-006', 'PKG-WOMENS', 'Gói khám phụ khoa', 'Khám phụ khoa định kỳ, tầm soát ung thư cổ tử cung.', 'ACTIVE', 60, 'spec-005'),
('pkg-007', 'PKG-CHILD', 'Gói khám nhi khoa', 'Theo dõi phát triển thể chất và tiêm chủng cho trẻ.', 'ACTIVE', 45, 'spec-002'),
('pkg-008', 'PKG-DENTAL', 'Gói khám răng miệng', 'Kiểm tra sâu răng, lấy cao răng, tư vấn nha khoa.', 'ACTIVE', 45, 'spec-009')
ON CONFLICT (code) DO UPDATE SET specialty_id = EXCLUDED.specialty_id;

INSERT INTO exam_package_steps (id, package_id, name, description, step_order, estimated_minutes)
VALUES 
('step-001', 'pkg-001', 'Tiếp nhận', 'Lấy thông tin và số thứ tự', 1, 5),
('step-002', 'pkg-001', 'Đo chỉ số sinh tồn', 'Đo huyết áp, cân nặng, chiều cao', 2, 10),
('step-003', 'pkg-001', 'Khám lâm sàng', 'Bác sĩ tư vấn trực tiếp', 3, 15)
ON CONFLICT (id) DO NOTHING;
