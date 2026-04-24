const { getAiSuggestion } = require('../services/service.ai');
const logger = require('../utils/logger');

/**
 * POST /chat/ai/suggest
 * Body: { message: "triệu chứng của bệnh nhân" }
 */
async function suggestSpecialty(req, res, next) {
  try {
    const { message } = req.body;
    const correlationId = req.correlationId;
    const userId = req.userId;

    if (!message || !String(message).trim()) {
      return res.status(400).json({
        status: 400,
        message: 'message is required',
        code: 'MESSAGE_REQUIRED',
      });
    }

    logger.info('ai_suggest_request', {
      correlationId,
      userId,
      messageLength: String(message).length,
    });

    const result = await getAiSuggestion({
      userMessage: String(message).trim(),
      correlationId,
    });

    res.status(200).json({
      status: 200,
      message: 'AI suggestion generated successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = { suggestSpecialty };
