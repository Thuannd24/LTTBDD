const logger = require('./logger');

async function httpRequest(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();

  let body = null;
  if (text) {
    try {
      body = JSON.parse(text);
    } catch (_) {
      body = text;
    }
  }

  if (!response.ok) {
    logger.warn('upstream_request_failed', {
      url,
      status: response.status,
      body,
    });
  }

  return {
    status: response.status,
    ok: response.ok,
    body,
  };
}

module.exports = { httpRequest };
