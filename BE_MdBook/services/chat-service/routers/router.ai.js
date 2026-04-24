const express = require('express');
const authMiddleware = require('../middleware');
const controller = require('../controllers/controller.ai');

const router = express.Router();

// POST /chat/ai/suggest — yêu cầu đăng nhập
router.post('/suggest', authMiddleware, controller.suggestSpecialty);

module.exports = router;
