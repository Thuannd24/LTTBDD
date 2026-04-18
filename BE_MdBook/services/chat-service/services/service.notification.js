const amqp = require('amqplib');
const config = require('../utils/appConfig');
const logger = require('../utils/logger');

let connectionPromise = null;
let channelPromise = null;

async function getChannel() {
  if (!config.rabbitmq.url) {
    return null;
  }

  if (!connectionPromise) {
    connectionPromise = amqp.connect(config.rabbitmq.url).catch((error) => {
      connectionPromise = null;
      channelPromise = null;
      throw error;
    });
  }

  if (!channelPromise) {
    channelPromise = connectionPromise.then(async (connection) => {
      connection.on('close', () => {
        connectionPromise = null;
        channelPromise = null;
      });
      connection.on('error', () => {
        connectionPromise = null;
        channelPromise = null;
      });
      const channel = await connection.createChannel();
      await channel.assertQueue(config.rabbitmq.queue, { durable: true });
      return channel;
    }).catch((error) => {
      channelPromise = null;
      throw error;
    });
  }

  return channelPromise;
}

async function publishOfflineNotification(payload) {
  const channel = await getChannel();
  if (!channel) {
    logger.warn('rabbitmq_not_configured', payload);
    return false;
  }

  const buffer = Buffer.from(JSON.stringify(payload));
  channel.sendToQueue(config.rabbitmq.queue, buffer, { persistent: true });
  logger.info('offline_notification_published', payload);
  return true;
}

module.exports = {
  publishOfflineNotification,
};
