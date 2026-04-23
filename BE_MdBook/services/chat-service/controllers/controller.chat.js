const {
  createOrGetConversation,
  listUserConversations,
} = require('../services/service.chat');
const logger = require('../utils/logger');

/**
 * Health check endpoint
 */
async function health(req, res) {
  res.status(200).json({
    status: 'ok',
    service: 'chat-service',
    timestamp: new Date().toISOString(),
  });
}

/**
 * Get all conversations for the current user
 */
async function getConversations(req, res, next) {
  try {
    const userId = req.userId;
    const correlationId = req.correlationId;

    logger.info('conversation_list_requested', {
      correlationId,
      userId,
    });

    const conversations = await listUserConversations({
      userId,
      userRoles: req.roles || [],
      correlationId,
    });

    res.status(200).json({
      status: 200,
      message: 'Conversations retrieved successfully',
      data: conversations,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Create a new conversation
 */
async function createConversation(req, res, next) {
  try {
    const userId = req.userId;
    const { targetUserId } = req.body;
    const correlationId = req.correlationId;

    if (!targetUserId) {
      return res.status(400).json({
        status: 400,
        message: 'targetUserId is required',
      });
    }

    logger.info('conversation_create_requested', {
      correlationId,
      userId,
      targetUserId,
    });

    const conversation = await createOrGetConversation({
      currentUserId: userId,
      currentUserRoles: req.roles || [],
      targetUserId: otherUserId,
      correlationId,
    });

    res.status(201).json({
      status: 201,
      message: 'Conversation created successfully',
      data: conversation,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get messages for a conversation
 */


/**
 * Send a message
 */


module.exports = {
  health,
  getConversations,
  createConversation,
};
