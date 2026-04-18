const mongoose = require('mongoose');
const config = require('../utils/appConfig');
const logger = require('../utils/logger');

mongoose.Promise = require('bluebird');

mongoose
  .connect(config.mongoUrl)
  .then(() => {
    logger.info('mongodb_connected', { mongoUrl: config.mongoUrl });
  })
  .catch((error) => {
    logger.error('mongodb_connection_failed', {
      mongoUrl: config.mongoUrl,
      error: error.message,
    });
    process.exit(1);
  });

module.exports = {
  mongoose,
  models: {
    Conversation: require('./schemas/conversation'),
    Message: require('./schemas/message'),
  },
};
