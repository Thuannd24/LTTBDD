-- File: scripts/db/init-doctor.sql
-- Script tự động khởi tạo dữ liệu chuyên khoa cho doctor_db

-- Xóa dữ liệu cũ nếu có (tránh trùng lặp nếu chạy lại)
DELETE FROM specialties;

INSERT INTO specialties (id, name, description, overview, services, technology, image, created_at, updated_at)
VALUES 
-- 1. TIM MẠCH
(gen_random_uuid(), 'Tim Mạch', 'Trung tâm can thiệp và điều trị bệnh lý tim mạch toàn diện.', 
'Trung tâm Tim mạch hiện là một trong số ít các Trung tâm tim mạch có quy mô lớn và uy tín ở Việt Nam, được trang bị các phương tiện hiện đại, tuân thủ các quy trình thăm khám chuyên nghiệp, được cấp chứng chỉ quản lý, chăm sóc bệnh mạch vành và suy tim theo tiêu chuẩn của ACC. Chuyên khoa Tim mạch cung cấp dịch vụ điều trị, chăm sóc bệnh lý tim mạch cho bệnh nhân trong nước và quốc tế theo các tiêu chuẩn quốc tế cao nhất.',
E'Điều trị suy tim chuyên sâu\nĐiều trị sau nhồi máu cơ tim\nĐiều trị tăng huyết áp phức tạp\nĐiều trị các rối loạn nhịp dai dẳng (rung nhĩ, ngoại tâm thu)\nQuản lý bệnh nhân ngoại trú: Các bệnh nhân có tiền sử tăng huyết áp, bệnh mạch vành, nhồi máu cơ tim.', 
E'Máy điện tim kỹ thuật số 12 cần GE\nMáy Holter điện tim 24h và Holter huyết áp 24h\nMáy siêu âm tim 3D, 4D qua thành ngực và thực quản GE ViViD95\nMáy chụp mạch ANGIO 2 bình diện SIEMENS\nMáy siêu âm trong lòng mạch IVUS và FFR', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872147/specialties/mhetrubsjvpplsst2dv4.jpg', NOW(), NOW()),

-- 2. NHI KHOA
(gen_random_uuid(), 'Nhi Khoa', 'Chăm sóc sức khỏe toàn diện cho trẻ em với môi trường thân thiện.', 
'Khoa Nhi là một trong những chuyên khoa mũi nhọn, hội tụ đội ngũ chuyên gia hàng đầu. Với tiêu chuẩn "Bệnh viện khách sạn", khoa Nhi mang đến không gian thăm khám đầy màu sắc, giúp trẻ giảm bớt áp lực tâm lý. Chúng tôi cung cấp các gói khám sức khỏe tổng quát, tư vấn dinh dưỡng và tiêm chủng vắc-xin cho trẻ từ sơ sinh đến tuổi vị thành niên.',
E'Khám và điều trị các bệnh lý hô hấp, tiêu hóa nhi\nTư vấn dinh dưỡng và tăng trưởng chiều cao\nKhám sàng lọc sơ sinh và dị tật bẩm sinh\nDịch vụ tiêm chủng trọn gói\nTâm lý trị liệu cho trẻ em', 
E'Hệ thống xét nghiệm vi sinh tự động hoàn toàn\nMáy thở hiện đại dành riêng cho trẻ sơ sinh\nHệ thống lồng ấp và sưởi ấm trẻ sơ sinh cao cấp\nCông nghệ chẩn đoán hình ảnh liều thấp (Low Dose) an toàn cho trẻ', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872715/specialties/dyydyft7gjrxi9i198x5.jpg', NOW(), NOW()),

-- 3. THẦN KINH
(gen_random_uuid(), 'Thần Kinh', 'Chuyên khoa sâu về não bộ, tủy sống và hệ thần kinh ngoại biên.', 
'Khoa Thần kinh cung cấp các dịch vụ khám, tư vấn và điều trị chuyên sâu các bệnh lý về nội thần kinh. Với đội ngũ bác sĩ là các chuyên gia đầu ngành, chúng tôi cam kết mang lại hiệu quả điều trị tối ưu cho các bệnh nhân mắc bệnh lý phức tạp như đột quỵ, Parkinson, và các rối loạn vận động khác.',
E'Điều trị và dự phòng đột quỵ\nKhám và điều trị đau đầu, mất ngủ mạn tính\nĐiều trị động kinh và các chứng rối loạn lo âu\nPhẫu thuật u não và cột sống\nĐiều trị bệnh Alzheimer và sa sút trí tuệ', 
E'Máy MRI 3.0 Tesla Silent hiện đại nhất thế giới (không tiếng ồn)\nMáy CT Scanner 640 lát cắt chẩn đoán nhanh đột quỵ\nHệ thống điện não đồ (EEG) và điện cơ đồ (EMG) độ phân giải cao\nRobot hỗ trợ phẫu thuật thần kinh chính xác tuyệt đối', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872696/specialties/zbowrq4ex3hrm0hgugcp.jpg', NOW(), NOW()),

-- 4. CƠ XƯƠNG KHỚP
(gen_random_uuid(), 'Cơ Xương Khớp', 'Điều trị các bệnh lý hệ vận động và chấn thương chỉnh hình.', 
'Chuyên khoa Cơ xương khớp tập trung vào việc khôi phục chức năng vận động cho bệnh nhân thông qua các phương pháp can thiệp hiện đại. Chúng tôi tự hào về tỷ lệ thành công cao trong các ca thay khớp háng, khớp gối và phẫu thuật nội soi khớp cột sống.',
E'Thay khớp háng, khớp gối toàn phần\nĐiều trị thoát vị đĩa đệm không phẫu thuật\nPhẫu thuật nội soi tái tạo dây chằng\nĐiều trị loãng xương và thoái hóa khớp\nPhục hồi chức năng sau chấn thương thể thao', 
E'Công nghệ tái tạo mô bằng tế bào gốc\nHệ thống Robot hỗ trợ phẫu thuật xương khớp\nMáy đo loãng xương tia X năng lượng kép (DEXA)\nCông nghệ Plasma điều trị thoát vị đĩa đệm', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872720/specialties/lpawjormuycfuof9y0fb.jpg', NOW(), NOW()),

-- 5. SẢN PHỤ KHOA
(gen_random_uuid(), 'Sản Phụ Khoa', 'Đồng hành cùng phụ nữ trong hành trình làm mẹ và chăm sóc sức khỏe.', 
'Khoa Sản phụ khoa cung cấp dịch vụ chăm sóc toàn diện từ giai đoạn tiền thai kỳ, trong suốt thai kỳ cho đến khi vượt cạn và chăm sóc sau sinh. Chúng tôi chú trọng vào sự an toàn của mẹ và bé với quy trình kiểm soát nhiễm khuẩn và chăm sóc đặc biệt.',
E'Dịch vụ thai sản và sinh con trọn gói\nSàng lọc trước sinh và chẩn đoán dị tật thai nhi\nĐiều trị vô sinh hiếm muộn (IVF/IUI)\nKhám và điều trị các bệnh phụ khoa\nTầm soát ung thư cổ tử cung và ung thư vú', 
E'Máy siêu âm 4D Voluson E10 hàng đầu thế giới\nHệ thống phòng sinh LDR hiện đại (Labor, Delivery, Recovery)\nCông nghệ sàng lọc NIPT độ chính xác 99.9%\nHệ thống nội soi phụ khoa 3D', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872704/specialties/ywmngfmt0nz76yhzwvxl.jpg', NOW(), NOW()),

-- 6. UNG BƯỚU
(gen_random_uuid(), 'Ung Bướu', 'Trung tâm điều trị ung thư theo tiêu chuẩn quốc tế.', 
'Khoa Ung bướu cam kết mang lại hy vọng cho bệnh nhân ung thư thông qua các phác đồ điều trị cá thể hóa. Chúng tôi kết hợp giữa phẫu thuật, hóa trị, xạ trị và các liệu pháp nhắm trúng đích để đạt hiệu quả cao nhất đồng thời giảm tác dụng phụ.',
E'Tầm soát ung thư sớm đa cơ quan\nHóa trị và liệu pháp miễn dịch\nXạ trị gia tốc điều biến liều (IMRT)\nChăm sóc giảm nhẹ cho bệnh nhân giai đoạn cuối\nPhẫu thuật cắt bỏ khối u chuyên sâu', 
E'Máy xạ trị gia tốc TrueBeam thế hệ mới\nCông nghệ PET/CT giúp phát hiện tế bào ung thư siêu nhỏ\nXét nghiệm gen di truyền xác định nguy cơ ung thư\nHệ thống pha thuốc hóa trị tự động bảo vệ an toàn tuyệt đối', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872711/specialties/mczwkpjrljojfdfoxnos.jpg', NOW(), NOW()),

-- 7. TIÊU HÓA
(gen_random_uuid(), 'Tiêu Hóa', 'Chẩn đoán và điều trị bệnh lý dạ dày, đại tràng và gan mật.', 
'Khoa Tiêu hóa là trung tâm hàng đầu về nội soi tiêu hóa, chuyên sâu trong việc tầm soát ung thư dạ dày và đại trực tràng. Quy trình nội soi không đau giúp bệnh nhân cảm thấy thoải mái và an tâm khi thăm khám.',
E'Nội soi dạ dày, đại trực tràng không đau\nTầm soát và điều trị viêm gan B, C\nCắt polyp đại tràng qua nội soi\nĐiều trị trào ngược dạ dày thực quản (GERD)\nTán sỏi mật qua nội soi ngược dòng (ERCP)', 
E'Hệ thống nội soi Olympus HQ190 với công nghệ NBI (nhấn mạnh mạch máu)\nMáy siêu âm đàn hồi mô gan (Fibroscan)\nCông nghệ nội soi viên nang (Capsule Endoscopy)\nHệ thống xét nghiệm hơi thở tìm vi khuẩn HP', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872682/specialties/mj6kxqdajbdzv3l50jsl.jpg', NOW(), NOW()),

-- 8. MẮT (NHÃN KHOA)
(gen_random_uuid(), 'Mắt', 'Chăm sóc thị lực và phẫu thuật khúc xạ công nghệ cao.', 
'Khoa Mắt cung cấp dịch vụ chăm sóc mắt toàn diện cho mọi lứa tuổi. Chúng tôi sở hữu công nghệ phẫu thuật khúc xạ hiện đại nhất, giúp bệnh nhân lấy lại thị lực hoàn hảo mà không cần đeo kính.',
E'Phẫu thuật xóa cận bằng Relex Smile và Lasik\nPhẫu thuật thay thủy tinh thể (Phaco)\nTầm soát và điều trị bệnh võng mạc tiểu đường\nKhám và điều trị cận thị tiến triển ở trẻ em\nĐiều trị đục thủy tinh thể và Glocom', 
E'Máy phẫu thuật VisuMax điều trị cận thị tối tân\nHệ thống chụp cắt lớp võng mạc OCT 3D\nMáy đo khúc xạ tự động thế hệ mới\nCông nghệ kính Ortho-K chỉnh hình giác mạc ban đêm', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872691/specialties/kkygcrcegdtipn4xldv8.jpg', NOW(), NOW()),

-- 9. RĂNG HÀM MẶT
(gen_random_uuid(), 'Răng Hàm Mặt', 'Nha khoa thẩm mỹ và phẫu thuật hàm mặt chuyên sâu.', 
'Khoa Răng Hàm Mặt kết hợp giữa chăm sóc sức khỏe răng miệng và nha khoa thẩm mỹ. Chúng tôi sử dụng các vật liệu cao cấp và công nghệ kỹ thuật số để tạo ra nụ cười rạng rỡ và tự nhiên nhất cho khách hàng.',
E'Cấy ghép răng Implant All-on-4/6\nNiềng răng thẩm mỹ Invisalign (không mắc cài)\nBọc răng sứ thẩm mỹ công nghệ cao\nPhẫu thuật nhổ răng khôn không đau bằng Piezotome\nTẩy trắng răng công nghệ Plasma', 
E'Hệ thống chẩn đoán hình ảnh CT Cone Beam 3D\nCông nghệ thiết kế nụ cười kỹ thuật số (Smile Design)\nMáy phẫu thuật siêu âm Piezotome hạn chế sưng đau\nMáy scan trong miệng iTero Element 5D', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872700/specialties/cpl7qskh3bsfzfjjrzqj.jpg', NOW(), NOW()),

-- 10. DA LIỄU
(gen_random_uuid(), 'Da Liễu', 'Điều trị bệnh lý da liễu và thẩm mỹ da công nghệ cao.', 
'Khoa Da liễu không chỉ điều trị các bệnh lý về da mà còn đi đầu trong lĩnh vực thẩm mỹ nội khoa. Chúng tôi ứng dụng các công nghệ Laser thế hệ mới nhất để trẻ hóa làn da và điều trị các vấn đề về sắc tố da một cách an toàn.',
E'Điều trị mụn trứng cá và sẹo rỗ\nTrẻ hóa da bằng công nghệ HIFU, Thermage\nĐiều trị nám, tàn nhang bằng Laser Picoway\nĐiều trị các bệnh lý da tự miễn (vảy nến, chàm)\nTriệt lông thẩm mỹ và xóa xăm', 
E'Máy Laser Picoway - "Tiêu chuẩn vàng" trong điều trị sắc tố\nCông nghệ nâng cơ Thermage FLX hiện đại nhất\nHệ thống soi da phân tích đa chiều Visia\nCông nghệ Fractional CO2 điều trị sẹo rỗ chuyên sâu', 
'https://res.cloudinary.com/dpusohlya/image/upload/v1776872708/specialties/r9tvgtwrdbmkxulaxbum.jpg', NOW(), NOW());
