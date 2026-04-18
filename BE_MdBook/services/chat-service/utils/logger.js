const { serviceName } = require('./appConfig');

function log(level, message, meta = {}) {
  const payload = {
    timestamp: new Date().toISOString(),
    service: serviceName,
    level,
    message,
    ...meta,
  };

  if (level === 'error') {
    console.error(JSON.stringify(payload));
    return;
  }

  console.log(JSON.stringify(payload));
}

module.exports = {
  info: (message, meta) => log('info', message, meta),
  warn: (message, meta) => log('warn', message, meta),
  error: (message, meta) => log('error', message, meta),
};
