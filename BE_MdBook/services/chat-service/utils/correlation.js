const { randomUUID } = require('crypto');

function resolveCorrelationId(value) {
  return value || randomUUID();
}

function correlationMiddleware(req, res, next) {
  const correlationId = resolveCorrelationId(req.headers['x-correlation-id']);
  req.correlationId = correlationId;
  res.setHeader('x-correlation-id', correlationId);
  next();
}

module.exports = {
  correlationMiddleware,
  resolveCorrelationId,
};
