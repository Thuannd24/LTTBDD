# Plan 2: Public APIs - Package Management

## Phạm vi
Triển khai các endpoint để tạo, đọc, quản lý ExamPackage và ExamPackageStep.

## Tasks
### 2.1 Tạo ExamPackageController
- Endpoint: `GET /exam-packages`
  - Trả về danh sách tất cả packages (pagination)
  - Response: `List<ExamPackageDTO>`
  
- Endpoint: `GET /exam-packages/{id}`
  - Trả về chi tiết 1 package
  - Response: `ExamPackageDTO`
  
- Endpoint: `GET /exam-packages/{id}/steps`
  - Trả về danh sách steps của package
  - Response: `List<ExamPackageStepDTO>`

### 2.2 Tạo ExamPackageAdminController (ADMIN only)
- Endpoint: `POST /admin/exam-packages` (ADMIN)
  - Tạo package mới
  - Request: `CreateExamPackageRequest`
  - Response: `ExamPackageDTO`

- Endpoint: `PUT /admin/exam-packages/{id}` (ADMIN)
  - Update package
  - Request: `UpdateExamPackageRequest`
  - Response: `ExamPackageDTO`

- Endpoint: `DELETE /admin/exam-packages/{id}` (ADMIN)
  - Xóa package

### 2.3 Tạo ExamPackageStepAdminController (ADMIN only)
- Endpoint: `POST /admin/exam-packages/{packageId}/steps` (ADMIN)
  - Thêm step vào package
  - Request: `CreateExamPackageStepRequest`
  - Response: `ExamPackageStepDTO`

- Endpoint: `PUT /admin/exam-packages/{packageId}/steps/{stepId}` (ADMIN)
  - Update step
  - Request: `UpdateExamPackageStepRequest`
  - Response: `ExamPackageStepDTO`

- Endpoint: `DELETE /admin/exam-packages/{packageId}/steps/{stepId}` (ADMIN)
  - Xóa step

### 2.4 Tạo DTOs & Mappers
- DTOs: `ExamPackageDTO`, `ExamPackageStepDTO`, `CreateExamPackageRequest`, `UpdateExamPackageRequest`, etc.
- Mappers: `ExamPackageMapper`, `ExamPackageStepMapper`

### 2.5 Tạo Services
- `ExamPackageService` - Business logic (CRUD, query)
- `ExamPackageStepService` - Business logic cho steps

### 2.6 Add Security/Auth
- Package CRUD phải có @PreAuthorize("hasRole('ADMIN')")
- Package query (GET) không cần auth hoặc tất cả user access được

## Acceptance Criteria
- [ ] 6 endpoint hoạt động (3 public + 3 admin CRUD)
- [ ] AuthN/AuthZ hoạt động đúng (ADMIN vs USER)
- [ ] DTOs/Mappers đầy đủ
- [ ] Unit tests cho services (happy path + edge case)
- [ ] Integration tests cho controllers
- [ ] OpenAPI spec được cập nhật

## Estimate
**3-4 giờ** (controllers, services, DTOs, tests, OpenAPI)
