const express = require('express');
const authMiddleware = require('../middleware');
const controller = require('../controllers/controller.chat');

const router = express.Router();

router.get('/health', controller.health);
router.get('/conversations', authMiddleware, controller.getConversations);
router.post('/conversations', authMiddleware, controller.createConversation);

module.exports = router;
