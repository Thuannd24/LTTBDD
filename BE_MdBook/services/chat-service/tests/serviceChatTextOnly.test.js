const test = require('node:test');
const assert = require('node:assert/strict');

const { ensureTextOnlyContentType } = require('../utils/chatHelpers');

test('ensureTextOnlyContentType accepts TEXT by default', () => {
  assert.equal(ensureTextOnlyContentType(), 'TEXT');
  assert.equal(ensureTextOnlyContentType('text'), 'TEXT');
});

test('ensureTextOnlyContentType rejects non-text content types', () => {
  assert.throws(
    () => ensureTextOnlyContentType('IMAGE'),
    (error) => error.code === 'CONTENT_TYPE_INVALID'
  );
});
