const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

const currentDirectory = __dirname;
const parentDirectory = path.resolve(currentDirectory, '..', '..');
const savePathImage = `${parentDirectory}/images`;
const savePathFile = `${parentDirectory}/files`;

module.exports = () => {
  // Upload nhiều ảnh
  router.post('/upload-image', upload.any(), async (req, res) => {
    try {
      const files = req.files || [];
      const savedImages = [];

      for (const file of files) {
        if (!file.mimetype.startsWith('image/')) continue;

        const extension = file.originalname.split('.').pop();
        const fileName = `${uuidv4()}.${extension}`;
        const fullPath = path.join(savePathImage, fileName);

        fs.writeFileSync(fullPath, file.buffer);
          console.log(fileName)
        savedImages.push({
          url: `/images/${fileName}`,
          fileName: file.originalname,
        });
      }

      if (savedImages.length === 0) {
        return res.status(400).json({ status: 0, message: 'Không có file ảnh hợp lệ' });
      }

      return res.status(200).json({ status: 1, data: savedImages });
    } catch (err) {
      return res.status(400).json({ status: 0, message: err.message });
    }
  });

  // Upload nhiều file (loại trừ ảnh)
  router.post('/upload-file', upload.any(), async (req, res) => {
    try {
      const files = req.files || [];
      const savedFiles = [];

      for (const file of files) {
        if (file.mimetype.startsWith('image/')) continue;

        const extension = file.originalname.split('.').pop();
        const fileName = `${uuidv4()}.${extension}`;
        const fullPath = path.join(savePathFile, fileName);

        fs.writeFileSync(fullPath, file.buffer);
        console.log(fileName)
        savedFiles.push({
          url: `/files/${fileName}`,
          fileName: file.originalname,
        });
      }

      if (savedFiles.length === 0) {
        return res.status(400).json({ status: 0, message: 'Không có file hợp lệ' });
      }

      return res.status(200).json({ status: 1, data: savedFiles });
    } catch (err) {
      return res.status(400).json({ status: 0, message: err.message });
    }
  });

  return router;
};
