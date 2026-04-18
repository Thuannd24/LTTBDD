const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    conversation_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true,
    },
    sender_id: { type: String, required: true, index: true },
    recipient_id: { type: String, required: true, index: true },
    content: { type: String, required: true, trim: true },
    content_type: {
      type: String,
      enum: ['TEXT'],
      default: 'TEXT',
    },
    status: {
      type: String,
      enum: ['SENT', 'DELIVERED', 'READ'],
      default: 'SENT',
      index: true,
    },
    created_at: { type: Date, default: Date.now, index: true },
  },
  {
    versionKey: false,
  }
);

messageSchema.index({ conversation_id: 1, created_at: -1 });

module.exports = mongoose.model('Message', messageSchema, 'messages');
