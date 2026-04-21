const logger = require('../utils/logger');

async function publishOfflineNotification(payload) {
  logger.info('offline_notification_skipped', {
    ...payload,
    delivery: 'local-noop',
  });
  return false;
}

module.exports = {
  publishOfflineNotification,
};
