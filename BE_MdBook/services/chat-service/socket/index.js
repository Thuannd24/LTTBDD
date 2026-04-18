
const presence = require('./State/OnlineUsers');
const { verifyAccessToken } = require('../services/service.keycloak');
const {
  listUserConversations,
  getConversationMessages,
  sendMessage,
  markConversationDelivered,
  markConversationRead,
} = require('../services/service.chat');
const { resolveCorrelationId } = require('../utils/correlation');
const logger = require('../utils/logger');

function emitReadReceipts(io, receipts) {
  receipts.forEach((receipt) => {
    io.to(`user:${receipt.senderId}`).emit('message:read', receipt);
  });
}

function emitDeliveredReceipts(io, receipts) {
  receipts.forEach((receipt) => {
    io.to(`user:${receipt.senderId}`).emit('message:delivered', receipt);
  });
}

module.exports = function registerSocket(io) {
  io.use(async (socket, next) => {
    try {
      const correlationId = resolveCorrelationId(
        socket.handshake.headers['x-correlation-id']
      );
      const rawToken =
        socket.handshake.auth?.token ||
        socket.handshake.query?.token ||
        socket.handshake.headers?.authorization ||
        '';
      const token = String(rawToken).replace(/^Bearer\s+/i, '').trim();
      const authContext = await verifyAccessToken(token, correlationId);

      socket.correlationId = correlationId;
      socket.auth = authContext;
      socket.userId = authContext.userId;
      next();
    } catch (error) {
      next(error);
    }
  });

  io.on('connection', (socket) => {
    presence.setOnline(socket.userId, socket.id);
    socket.join(`user:${socket.userId}`);

    logger.info('socket_connected', {
      correlationId: socket.correlationId,
      userId: socket.userId,
      socketId: socket.id,
      onlineUsers: presence.listUserIds(),
    });

    socket.on('conversation:list', async () => {
      try {
        const conversations = await listUserConversations({
          userId: socket.userId,
          userRoles: socket.auth.roles,
          correlationId: socket.correlationId,
        });
        socket.emit('conversation:list', conversations);
      } catch (error) {
        socket.emit('chat:error', { message: error.message });
      }
    });

    socket.on('conversation:join', async ({ conversationId }) => {
      try {
        socket.join(`conversation:${conversationId}`);
        const deliveredReceipts = await markConversationDelivered({
          conversationId,
          currentUserId: socket.userId,
          correlationId: socket.correlationId,
        });
        emitDeliveredReceipts(io, deliveredReceipts);
        const receipts = await markConversationRead({
          conversationId,
          currentUserId: socket.userId,
          correlationId: socket.correlationId,
        });
        emitReadReceipts(io, receipts);
        socket.emit('conversation:joined', { conversationId });
      } catch (error) {
        socket.emit('chat:error', { message: error.message });
      }
    });

    socket.on('message:history', async ({ conversationId, before, limit }) => {
      try {
        const messages = await getConversationMessages({
          conversationId,
          currentUserId: socket.userId,
          before,
          limit,
          markAsRead: false,
          correlationId: socket.correlationId,
        });
        const deliveredReceipts = await markConversationDelivered({
          conversationId,
          currentUserId: socket.userId,
          correlationId: socket.correlationId,
        });
        emitDeliveredReceipts(io, deliveredReceipts);
        const readReceipts = await markConversationRead({
          conversationId,
          currentUserId: socket.userId,
          correlationId: socket.correlationId,
        });
        emitReadReceipts(io, readReceipts);
        socket.emit('message:history', { conversationId, messages });
      } catch (error) {
        socket.emit('chat:error', { message: error.message });
      }
    });

    socket.on('message:send', async ({ conversationId, content, contentType }) => {
      try {
        const message = await sendMessage({
          conversationId,
          senderId: socket.userId,
          senderRoles: socket.auth.roles,
          content,
          contentType,
          correlationId: socket.correlationId,
          isRecipientOnlineResolver: (recipientId) => presence.isOnline(recipientId),
        });

        socket.emit('message:new', message);
        io.to(`user:${message.recipientId}`).emit('message:new', message);

        if (message.status === 'DELIVERED') {
          io.to(`user:${message.senderId}`).emit('message:delivered', {
            messageId: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            recipientId: message.recipientId,
            status: 'DELIVERED',
          });
        }
      } catch (error) {
        logger.error('socket_message_send_failed', { error: error.message, stack: error.stack });
        socket.emit('chat:error', { message: error.message });
      }
    });

    socket.on('message:delivered', async ({ conversationId, messageId }) => {
      try {
        const receipts = await markConversationDelivered({
          conversationId,
          currentUserId: socket.userId,
          messageId,
          correlationId: socket.correlationId,
        });
        emitDeliveredReceipts(io, receipts);
      } catch (error) {
        socket.emit('chat:error', { message: error.message });
      }
    });

    socket.on('message:read', async ({ conversationId, messageId }) => {
      try {
        const receipts = await markConversationRead({
          conversationId,
          currentUserId: socket.userId,
          messageId,
          correlationId: socket.correlationId,
        });
        emitReadReceipts(io, receipts);
      } catch (error) {
        socket.emit('chat:error', { message: error.message });
      }
    });

    socket.on('disconnect', () => {
      presence.setOffline(socket.userId, socket.id);
      logger.info('socket_disconnected', {
        correlationId: socket.correlationId,
        userId: socket.userId,
        socketId: socket.id,
        onlineUsers: presence.listUserIds(),
      });
    });
  });
};
