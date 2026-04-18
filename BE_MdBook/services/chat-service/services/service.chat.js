const { models } = require('../database');
const { getUserProfile } = require('./service.profile');
const { assertPatientDoctorRelationship } = require('./service.appointment');
const { publishOfflineNotification } = require('./service.notification');
const {
  buildParticipantPairKey,
  ensureTextOnlyContentType,
  getOtherParticipant,
  inferConversationPartnerRole,
  isPatientDoctorPair,
} = require('../utils/chatHelpers');
const { httpError } = require('../utils/httpError');
const logger = require('../utils/logger');

function normalizeContentType(value) {
  try {
    return ensureTextOnlyContentType(value);
  } catch (error) {
    throw httpError(error.status || 400, error.message, {
      code: error.code || 'CONTENT_TYPE_INVALID',
    });
  }
}

function normalizeMessageDocument(document) {
  return {
    id: String(document._id),
    conversationId: String(document.conversation_id),
    senderId: document.sender_id,
    recipientId: document.recipient_id,
    content: document.content,
    contentType: document.content_type,
    status: document.status,
    createdAt: document.created_at,
  };
}

async function ensureConversationMember(conversationId, userId) {
  const conversation = await models.Conversation.findById(conversationId);
  if (!conversation) {
    throw httpError(404, 'Conversation not found', {
      code: 'CONVERSATION_NOT_FOUND',
    });
  }

  if (!conversation.participant_ids.includes(String(userId))) {
    throw httpError(403, 'You are not allowed to access this conversation', {
      code: 'CONVERSATION_FORBIDDEN',
    });
  }

  return conversation;
}

function mapConversationSummary(conversation, currentUserId, otherProfile) {
  return {
    id: String(conversation._id),
    participantIds: conversation.participant_ids,
    otherParticipant: {
      userId: otherProfile.userId,
      role: otherProfile.role,
      displayName: otherProfile.displayName,
      avatarUrl: otherProfile.avatarUrl,
    },
    lastMessage: conversation.last_message
      ? {
          id: conversation.last_message.message_id
            ? String(conversation.last_message.message_id)
            : null,
          senderId: conversation.last_message.sender_id,
          content: conversation.last_message.content,
          contentType: conversation.last_message.content_type,
          status: conversation.last_message.status,
          createdAt: conversation.last_message.created_at,
        }
      : null,
    updatedAt: conversation.updated_at,
  };
}

async function buildConversationSummary(
  conversation,
  currentUserId,
  currentUserRoles,
  correlationId
) {
  const otherUserId = getOtherParticipant(
    conversation.participant_ids,
    currentUserId
  );
  const cachedProfile =
    conversation.participant_profiles.find(
      (profile) => profile.user_id === otherUserId
    ) || {};

  const otherProfile = await getUserProfile(otherUserId, {
    preferredRole:
      cachedProfile.role || inferConversationPartnerRole(currentUserRoles),
    correlationId,
  });

  return mapConversationSummary(conversation, currentUserId, {
    userId: otherUserId,
    role: otherProfile.role || cachedProfile.role || null,
    displayName: otherProfile.displayName || cachedProfile.display_name || null,
    avatarUrl: otherProfile.avatarUrl || cachedProfile.avatar_url || null,
  });
}

async function createOrGetConversation({
  currentUserId,
  currentUserRoles,
  targetUserId,
  correlationId,
}) {
  if (!targetUserId || String(targetUserId) === String(currentUserId)) {
    throw httpError(400, 'targetUserId is invalid', {
      code: 'TARGET_USER_INVALID',
    });
  }

  const targetRoleHint = inferConversationPartnerRole(currentUserRoles);
  const [currentProfile, targetProfile] = await Promise.all([
    getUserProfile(currentUserId, {
      preferredRole: currentUserRoles[0],
      correlationId,
    }),
    getUserProfile(targetUserId, {
      preferredRole: targetRoleHint,
      correlationId,
    }),
  ]);

  // NOTE: In production this MUST enforce patient-doctor pairing.
  // For dev/demo, the check is relaxed to allow any pair of users.
  const enforceRolePair = process.env.ENFORCE_ROLE_PAIR === 'true';
  if (
    enforceRolePair &&
    (!targetProfile.raw ||
      !targetProfile.role ||
      !isPatientDoctorPair(currentUserRoles, [targetProfile.role]))
  ) {
    throw httpError(403, 'Only patient-doctor conversations are allowed', {
      code: 'ROLE_PAIR_NOT_ALLOWED',
    });
  }

  // Skip appointment relationship enforcement in dev (profile-service may not be running)
  if (process.env.ENFORCE_ROLE_PAIR === 'true') {
    if (currentUserRoles.includes('ROLE_PATIENT')) {
      await assertPatientDoctorRelationship({
        patientId: currentUserId,
        doctorId: targetUserId,
        correlationId,
      });
    } else if (currentUserRoles.includes('ROLE_DOCTOR')) {
      await assertPatientDoctorRelationship({
        patientId: targetUserId,
        doctorId: currentUserId,
        correlationId,
      });
    }
  }

  const participantIds = [String(currentUserId), String(targetUserId)].sort();
  const participantPairKey = buildParticipantPairKey(
    currentUserId,
    targetUserId
  );

  const conversation = await models.Conversation.findOneAndUpdate(
    { participant_pair_key: participantPairKey },
    {
      $setOnInsert: {
        participant_ids: participantIds,
        participant_pair_key: participantPairKey,
        participant_profiles: [
          {
            user_id: String(currentUserId),
            role: currentProfile.role || currentUserRoles[0] || null,
            display_name: currentProfile.displayName,
            avatar_url: currentProfile.avatarUrl,
            cached_at: new Date(),
          },
          {
            user_id: String(targetUserId),
            role: targetProfile.role,
            display_name: targetProfile.displayName,
            avatar_url: targetProfile.avatarUrl,
            cached_at: new Date(),
          },
        ],
        updated_at: new Date(),
        created_at: new Date(),
      },
    },
    {
      upsert: true,
      new: true,
    }
  );

  logger.info('conversation_ready', {
    correlationId,
    conversationId: String(conversation._id),
    userId: currentUserId,
    targetUserId,
  });

  return buildConversationSummary(
    conversation,
    currentUserId,
    currentUserRoles,
    correlationId
  );
}

async function listUserConversations({ userId, userRoles, correlationId }) {
  const conversations = await models.Conversation.find({
    participant_ids: String(userId),
  }).sort({ updated_at: -1 });

  return Promise.all(
    conversations.map((conversation) =>
      buildConversationSummary(conversation, userId, userRoles, correlationId)
    )
  );
}

async function markConversationRead({
  conversationId,
  currentUserId,
  correlationId,
  messageId,
}) {
  await ensureConversationMember(conversationId, currentUserId);

  const filter = {
    conversation_id: conversationId,
    recipient_id: String(currentUserId),
    status: { $in: ['SENT', 'DELIVERED'] },
  };
  if (messageId) {
    filter._id = messageId;
  }

  const messages = await models.Message.find(filter);
  if (messages.length === 0) {
    return [];
  }

  const ids = messages.map((message) => message._id);
  await models.Message.updateMany(
    { _id: { $in: ids } },
    { $set: { status: 'READ' } }
  );

  const latestMessage = messages[messages.length - 1];
  await models.Conversation.updateOne(
    {
      _id: conversationId,
      'last_message.message_id': latestMessage._id,
      'last_message.status': { $in: ['SENT', 'DELIVERED'] },
    },
    { $set: { 'last_message.status': 'READ' } }
  );

  logger.info('messages_read', {
    correlationId,
    conversationId,
    userId: currentUserId,
    count: ids.length,
  });

  return messages.map((message) => ({
    messageId: String(message._id),
    conversationId: String(message.conversation_id),
    senderId: message.sender_id,
    recipientId: message.recipient_id,
    status: 'READ',
  }));
}

async function getConversationMessages({
  conversationId,
  currentUserId,
  before,
  limit = 30,
  markAsRead = true,
  correlationId,
}) {
  await ensureConversationMember(conversationId, currentUserId);

  const query = { conversation_id: conversationId };
  if (before) {
    query.created_at = { $lt: new Date(before) };
  }

  const safeLimit = Math.min(Math.max(Number(limit) || 30, 1), 100);
  const messages = await models.Message.find(query)
    .sort({ created_at: -1 })
    .limit(safeLimit);

  const normalized = messages.reverse().map(normalizeMessageDocument);

  if (markAsRead) {
    await markConversationRead({
      conversationId,
      currentUserId,
      correlationId,
    });
  }

  return normalized;
}

async function updateConversationLastMessage(conversationId, message) {
  await models.Conversation.updateOne(
    { _id: conversationId },
    {
      $set: {
        last_message: {
          message_id: message._id,
          sender_id: message.sender_id,
          content: message.content,
          content_type: message.content_type,
          status: message.status,
          created_at: message.created_at,
        },
        updated_at: message.created_at,
      },
    }
  );
}

async function sendMessage({
  conversationId,
  senderId,
  senderRoles,
  content,
  contentType,
  correlationId,
  isRecipientOnline,
  isRecipientOnlineResolver,
}) {
  const normalizedContent = String(content || '').trim();
  if (!normalizedContent) {
    throw httpError(400, 'Message content is required', {
      code: 'MESSAGE_CONTENT_REQUIRED',
    });
  }

  const conversation = await ensureConversationMember(conversationId, senderId);
  const recipientId = getOtherParticipant(conversation.participant_ids, senderId);
  if (!recipientId) {
    throw httpError(500, 'Conversation recipient not found', {
      code: 'RECIPIENT_NOT_FOUND',
    });
  }

  const normalizedType = normalizeContentType(contentType);
  const recipientOnline =
    typeof isRecipientOnlineResolver === 'function'
      ? Boolean(isRecipientOnlineResolver(recipientId))
      : Boolean(isRecipientOnline);

  const message = await models.Message.create({
    conversation_id: conversation._id,
    sender_id: String(senderId),
    recipient_id: String(recipientId),
    content: normalizedContent,
    content_type: normalizedType,
    status: recipientOnline ? 'DELIVERED' : 'SENT',
    created_at: new Date(),
  });

  await updateConversationLastMessage(conversation._id, message);
  const payload = normalizeMessageDocument(message);

  if (!recipientOnline) {
    const senderProfile = await getUserProfile(senderId, {
      preferredRole: senderRoles[0],
      correlationId,
    });

    await publishOfflineNotification({
      type: 'CHAT_MESSAGE_OFFLINE',
      conversationId: payload.conversationId,
      senderId: payload.senderId,
      recipientId: payload.recipientId,
      messagePreview: payload.content,
      correlationId,
      createdAt: payload.createdAt,
      senderDisplayName: senderProfile.displayName,
    });
  }

  logger.info('message_created', {
    correlationId,
    conversationId,
    userId: senderId,
    recipientId,
    status: payload.status,
  });

  return payload;
}

async function markConversationDelivered({
  conversationId,
  currentUserId,
  correlationId,
  messageId,
}) {
  await ensureConversationMember(conversationId, currentUserId);

  const filter = {
    conversation_id: conversationId,
    recipient_id: String(currentUserId),
    status: 'SENT',
  };
  if (messageId) {
    filter._id = messageId;
  }

  const messages = await models.Message.find(filter);
  if (messages.length === 0) {
    return [];
  }

  const ids = messages.map((message) => message._id);
  await models.Message.updateMany(
    { _id: { $in: ids } },
    { $set: { status: 'DELIVERED' } }
  );

  const latestMessage = messages[messages.length - 1];
  await models.Conversation.updateOne(
    {
      _id: conversationId,
      'last_message.message_id': latestMessage._id,
      'last_message.status': 'SENT',
    },
    { $set: { 'last_message.status': 'DELIVERED' } }
  );

  logger.info('messages_delivered', {
    correlationId,
    conversationId,
    userId: currentUserId,
    count: ids.length,
  });

  return messages.map((message) => ({
    messageId: String(message._id),
    conversationId: String(message.conversation_id),
    senderId: message.sender_id,
    recipientId: message.recipient_id,
    status: 'DELIVERED',
  }));
}

module.exports = {
  createOrGetConversation,
  listUserConversations,
  getConversationMessages,
  sendMessage,
  markConversationDelivered,
  markConversationRead,
  ensureConversationMember,
};
