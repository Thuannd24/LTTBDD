/**
 * Comprehensive E2E Test Script for MedBook Chat Service
 * Tests: Health Check, REST API Auth, Socket.IO Connection, RabbitMQ Queue
 */
const http = require('http');
const { io } = require('socket.io-client');

const BASE_URL = 'http://localhost:5006';
const RESULTS = [];

function log(testName, passed, detail) {
  const icon = passed ? '✅' : '❌';
  RESULTS.push({ testName, passed, detail });
  console.log(`${icon} [${testName}] ${detail}`);
}

// ──── Test 1: Health Check ────
function testHealth() {
  return new Promise((resolve) => {
    const req = http.get(`${BASE_URL}/chat/health`, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const data = JSON.parse(body);
          log('Health Check', data.status === 'ok', `Status: ${res.statusCode}, Body: ${body}`);
        } catch (e) {
          log('Health Check', false, `Parse error: ${e.message}, Raw: ${body}`);
        }
        resolve();
      });
    });
    req.on('error', (e) => {
      log('Health Check', false, `Connection error: ${e.message}`);
      resolve();
    });
    req.setTimeout(5000, () => {
      log('Health Check', false, 'Timeout after 5s');
      req.destroy();
      resolve();
    });
  });
}

// ──── Test 2: REST API requires auth ────
function testRestAuthRequired() {
  return new Promise((resolve) => {
    const req = http.get(`${BASE_URL}/chat/conversations`, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        const passed = res.statusCode === 401;
        log('REST Auth Guard', passed, `GET /chat/conversations without token => Status ${res.statusCode}`);
        resolve();
      });
    });
    req.on('error', (e) => {
      log('REST Auth Guard', false, `Connection error: ${e.message}`);
      resolve();
    });
    req.setTimeout(5000, () => {
      log('REST Auth Guard', false, 'Timeout');
      req.destroy();
      resolve();
    });
  });
}

// ──── Test 3: 404 for unknown routes ────
function testNotFound() {
  return new Promise((resolve) => {
    const req = http.get(`${BASE_URL}/chat/nonexistent`, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        const passed = res.statusCode === 404;
        log('404 Unknown Route', passed, `GET /chat/nonexistent => Status ${res.statusCode}`);
        resolve();
      });
    });
    req.on('error', (e) => {
      log('404 Unknown Route', false, `Error: ${e.message}`);
      resolve();
    });
    req.setTimeout(5000, () => {
      log('404 Unknown Route', false, 'Timeout');
      req.destroy();
      resolve();
    });
  });
}

// ──── Test 4: Socket.IO rejects without token ────
function testSocketNoToken() {
  return new Promise((resolve) => {
    const socket = io(BASE_URL, {
      path: '/chat/socket.io',
      autoConnect: true,
      reconnection: false,
      timeout: 5000,
    });

    const timer = setTimeout(() => {
      log('Socket Auth Reject', false, 'Timeout - no response in 5s');
      socket.close();
      resolve();
    }, 5000);

    socket.on('connect', () => {
      clearTimeout(timer);
      log('Socket Auth Reject', false, 'Unexpectedly connected WITHOUT a token');
      socket.close();
      resolve();
    });

    socket.on('connect_error', (err) => {
      clearTimeout(timer);
      log('Socket Auth Reject', true, `Correctly rejected: "${err.message}"`);
      socket.close();
      resolve();
    });
  });
}

// ──── Test 5: Socket.IO rejects invalid token ────
function testSocketBadToken() {
  return new Promise((resolve) => {
    const socket = io(BASE_URL, {
      path: '/chat',
      autoConnect: true,
      reconnection: false,
      timeout: 5000,
      auth: {
        token: 'Bearer INVALID_TOKEN_12345'
      }
    });

    const timer = setTimeout(() => {
      log('Socket Bad Token', false, 'Timeout - no response in 5s');
      socket.close();
      resolve();
    }, 5000);

    socket.on('connect', () => {
      clearTimeout(timer);
      log('Socket Bad Token', false, 'Unexpectedly connected with INVALID token');
      socket.close();
      resolve();
    });

    socket.on('connect_error', (err) => {
      clearTimeout(timer);
      log('Socket Bad Token', true, `Correctly rejected invalid token: "${err.message}"`);
      socket.close();
      resolve();
    });
  });
}

// ──── Test 6: MongoDB connection (via docker logs) ────
function testMongoConnection() {
  return new Promise((resolve) => {
    const { exec } = require('child_process');
    exec('docker logs mid-project-528840900-chat-service-1 2>&1', (error, stdout) => {
      const connected = stdout.includes('mongodb_connected');
      log('MongoDB Connection', connected, connected ? 'Log confirms mongodb_connected' : 'No mongodb_connected in logs');
      resolve();
    });
  });
}

// ──── Test 7: RabbitMQ queue existence ────
function testRabbitMQ() {
  return new Promise((resolve) => {
    const options = {
      hostname: 'localhost',
      port: 15672,
      path: '/api/queues/%2f/notification-delivery',
      auth: 'guest:guest',
      timeout: 5000,
    };
    const req = http.get(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const data = JSON.parse(body);
            log('RabbitMQ Queue', true, `Queue "notification-delivery" exists, messages: ${data.messages || 0}`);
          } catch (e) {
            log('RabbitMQ Queue', true, 'Queue exists (parse issue)');
          }
        } else if (res.statusCode === 404) {
          log('RabbitMQ Queue', false, 'Queue "notification-delivery" not found - chat-service may not have connected yet');
        } else {
          log('RabbitMQ Queue', false, `Unexpected status: ${res.statusCode}`);
        }
        resolve();
      });
    });
    req.on('error', (e) => {
      log('RabbitMQ Queue', false, `Cannot reach RabbitMQ Management: ${e.message}`);
      resolve();
    });
    req.setTimeout(5000, () => {
      log('RabbitMQ Queue', false, 'Timeout connecting to RabbitMQ');
      req.destroy();
      resolve();
    });
  });
}

// ──── Run all tests ────
(async () => {
  console.log('\n🏥 MedBook Chat Service — Comprehensive E2E Test Suite\n');
  console.log('=' .repeat(60));

  await testHealth();
  await testRestAuthRequired();
  await testNotFound();
  await testSocketNoToken();
  await testSocketBadToken();
  await testMongoConnection();
  await testRabbitMQ();

  console.log('\n' + '='.repeat(60));
  const passed = RESULTS.filter(r => r.passed).length;
  const failed = RESULTS.filter(r => !r.passed).length;
  console.log(`\n📊 Results: ${passed} passed, ${failed} failed out of ${RESULTS.length} tests\n`);

  if (failed > 0) {
    console.log('❌ FAILED tests:');
    RESULTS.filter(r => !r.passed).forEach(r => console.log(`   - ${r.testName}: ${r.detail}`));
  }

  process.exit(failed > 0 ? 1 : 0);
})();
