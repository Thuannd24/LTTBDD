const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const http = require("http");
const cors = require("cors");

const app = express();
const upload = multer({ storage: multer.memoryStorage() }); // lưu vào RAM

// Cấu hình CORS


// Tạo thư mục lưu ảnh nếu chưa có
const savePath = path.join(__dirname, 'uploads');
if (!fs.existsSync(savePath)) {
    fs.mkdirSync(savePath, { recursive: true });
}

// Route test upload
app.post('/upload', upload.single('avatar'), (req, res) => {
    console.log('📥 req.body:', req.body); // text fields
    console.log('📁 req.file:', req.file); // file info

    // Nếu có file thì lưu
    if (req.file) {
        const extension = req.file.originalname.split('.').pop();
        const filename = `${Date.now()}.${extension}`;
        const fullPath = path.join(savePath, filename);
        fs.writeFileSync(fullPath, req.file.buffer);

        return res.json({
            message: 'Upload thành công!',
            filePath: `/uploads/${filename}`,
            fullName: req.body.FullName,
        });
    }

    return res.status(400).json({ message: 'Không có file được upload.' });
});

app.listen(3000, () => {
    console.log('🚀 Test upload server chạy tại http://localhost:3000/upload');
});
