const mongoose = require('mongoose');

const cachedParticipantSchema = new mongoose.Schema(
  {
    user_id: { type: String, required: true },
    role: { type: String, default: null },
    display_name: { type: String, default: null },
    avatar_url: { type: String, default: null },
    cached_at: { type: Date, default: Date.now },
  },
  {
    _id: false,
  }
);

const lastMessageSchema = new mongoose.Schema(
  {
    message_id: { type: mongoose.Schema.Types.ObjectId, default: null },
    sender_id: { type: String, default: null },
    content: { type: String, default: null },
    content_type: {
      type: String,
      enum: ['TEXT'],
      default: 'TEXT',
    },
    status: {
      type: String,
      enum: ['SENT', 'DELIVERED', 'READ'],
      default: 'SENT',
    },
    created_at: { type: Date, default: null },
  },
  {
    _id: false,
  }
);

const conversationSchema = new mongoose.Schema(
  {
    participant_ids: {
      type: [String],
      required: true,
      validate: {
        validator(value) {
          return Array.isArray(value) && value.length === 2;
        },
        message: 'conversation must contain exactly two participants',
      },
    },
    participant_pair_key: { type: String, required: true, unique: true },
    participant_profiles: {
      type: [cachedParticipantSchema],
      default: [],
    },
    last_message: { type: lastMessageSchema, default: null },
    updated_at: { type: Date, default: Date.now, index: true },
    created_at: { type: Date, default: Date.now },
  },
  {
    versionKey: false,
  }
);

conversationSchema.index({ updated_at: -1 });
conversationSchema.index({ participant_ids: 1, updated_at: -1 });

module.exports = mongoose.model(
  'Conversation',
  conversationSchema,
  'conversations'
);
