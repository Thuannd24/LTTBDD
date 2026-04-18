const express = require('express');
const http = require('http');
const cors = require('cors');
const morgan = require('morgan');
const { Server } = require('socket.io');

const config = require('./utils/appConfig');
const logger = require('./utils/logger');
const { correlationMiddleware } = require('./utils/correlation');
const chatRouter = require('./routers/router.chat');

require('./database');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  path: config.socketPath,
  cors: {
    origin: config.corsOrigins.includes('*') ? true : config.corsOrigins,
    methods: ['GET', 'POST'],
  },
});

app.set('io', io);

// CORS is handled globally at the Gateway level, do not inject local rules

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(correlationMiddleware);
app.use(
  morgan((tokens, req, res) =>
    JSON.stringify({
      method: tokens.method(req, res),
      path: tokens.url(req, res),
      status: Number(tokens.status(req, res)),
      responseTimeMs: Number(tokens['response-time'](req, res)),
      contentLength: tokens.res(req, res, 'content-length'),
      correlationId: req.correlationId,
      userId: req.userId || null,
    })
  )
);

app.use('/chat', chatRouter);

app.use((req, res, next) => {
  res.status(404).json({
    status: 0,
    message: 'Route not found',
    correlationId: req.correlationId,
  });
});

app.use((error, req, res, next) => {
  logger.error('request_failed', {
    correlationId: req?.correlationId,
    userId: req?.userId,
    path: req?.originalUrl,
    error: error.message,
    code: error.code,
  });

  res.status(error.status || 500).json({
    status: 0,
    message: error.message || 'Internal server error',
    code: error.code || 'INTERNAL_ERROR',
    correlationId: req?.correlationId,
  });
});

require('./socket')(io);

server.listen(config.port, config.host, () => {
  logger.info('server_started', {
    host: config.host,
    port: config.port,
    httpPath: '/chat',
    socketPath: config.socketPath,
  });
});
