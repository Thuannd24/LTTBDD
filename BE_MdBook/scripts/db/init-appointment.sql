-- Tự động tạo bảng nếu chưa có (để tránh lỗi khi Spring Boot chưa khởi động)
CREATE TABLE IF NOT EXISTS exam_packages (
    id VARCHAR(255) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    estimated_total_minutes INTEGER DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exam_package_steps (
    id VARCHAR(255) PRIMARY KEY,
    package_id VARCHAR(255) REFERENCES exam_packages(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    step_order INTEGER NOT NULL,
    estimated_minutes INTEGER DEFAULT 15,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Chèn dữ liệu Gói khám
INSERT INTO exam_packages (id, code, name, description, status, estimated_total_minutes)
VALUES 
('pkg-001', 'PKG-BASIC', 'Gói khám cơ bản', 'Khám tổng quát, đo huyết áp, kiểm tra chỉ số BMI.', 'ACTIVE', 30),
('pkg-002', 'PKG-STANDARD', 'Gói khám tiêu chuẩn', 'Khám tổng quát + Xét nghiệm máu cơ bản + Siêu âm bụng.', 'ACTIVE', 60),
('pkg-003', 'PKG-PREMIUM', 'Gói khám toàn diện', 'Khám tổng quát + X-quang + Điện tâm đồ + Xét nghiệm chuyên sâu.', 'ACTIVE', 120),
('pkg-004', 'PKG-CARDIO', 'Gói khám tim mạch', 'Chuyên sâu về tim: Siêu âm tim, Đo điện tim, Xét nghiệm mỡ máu.', 'ACTIVE', 90),
('pkg-005', 'PKG-DIABETES', 'Gói khám tiểu đường', 'Kiểm tra đường huyết, HbA1c, tư vấn chế độ ăn uống.', 'ACTIVE', 75),
('pkg-006', 'PKG-WOMENS', 'Gói khám phụ khoa', 'Khám phụ khoa định kỳ, tầm soát ung thư cổ tử cung.', 'ACTIVE', 60),
('pkg-007', 'PKG-CHILD', 'Gói khám nhi khoa', 'Theo dõi phát triển thể chất và tiêm chủng cho trẻ.', 'ACTIVE', 45),
('pkg-008', 'PKG-DENTAL', 'Gói khám răng miệng', 'Kiểm tra sâu răng, lấy cao răng, tư vấn nha khoa.', 'ACTIVE', 45)
ON CONFLICT (code) DO NOTHING;

-- Chèn dữ liệu các bước khám cho Gói cơ bản (ví dụ)
INSERT INTO exam_package_steps (id, package_id, name, description, step_order, estimated_minutes)
VALUES 
('step-001', 'pkg-001', 'Tiếp nhận', 'Lấy thông tin và số thứ tự', 1, 5),
('step-002', 'pkg-001', 'Đo chỉ số sinh tồn', 'Đo huyết áp, cân nặng, chiều cao', 2, 10),
('step-003', 'pkg-001', 'Khám lâm sàng', 'Bác sĩ tư vấn trực tiếp', 3, 15)
ON CONFLICT (id) DO NOTHING;
