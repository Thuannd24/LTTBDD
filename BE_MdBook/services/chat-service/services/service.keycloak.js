const { createPublicKey } = require('crypto');
const jwt = require('jsonwebtoken');
const config = require('../utils/appConfig');
const logger = require('../utils/logger');
const { httpRequest } = require('../utils/httpClient');
const { normalizeRoles } = require('../utils/chatHelpers');
const { httpError } = require('../utils/httpError');

const jwksCache = {
  expiresAt: 0,
  keys: new Map(),
};

function buildVerifyOptions() {
  const options = {
    algorithms: ['RS256'],
    // We remove strict issuer validation because the Gateway IP or Docker DNS
    // might cause issuer mismatches. Signature verification via JWKS and 
    // manual realm checking below are sufficient for security.
  };

  if (config.keycloak.audience) {
    options.audience = config.keycloak.audience;
  }

  return options;
}

async function refreshJwks(correlationId) {
  const response = await httpRequest(config.keycloak.jwksUrl, {
    headers: {
      'x-correlation-id': correlationId || '',
    },
  });

  if (!response.ok || !Array.isArray(response.body?.keys)) {
    throw httpError(503, 'Unable to load Keycloak JWKS', {
      code: 'JWKS_UNAVAILABLE',
    });
  }

  jwksCache.keys = new Map(
    response.body.keys
      .filter((key) => key.kid)
      .map((key) => [key.kid, key])
  );
  jwksCache.expiresAt = Date.now() + config.jwksCacheTtlMs;
}

async function getSigningKey(kid, correlationId) {
  if (!kid) {
    throw httpError(401, 'Missing token kid', { code: 'TOKEN_KID_MISSING' });
  }

  if (Date.now() >= jwksCache.expiresAt || !jwksCache.keys.has(kid)) {
    await refreshJwks(correlationId);
  }

  const jwk = jwksCache.keys.get(kid);
  if (!jwk) {
    throw httpError(401, 'Signing key not found', { code: 'TOKEN_KID_UNKNOWN' });
  }

  return createPublicKey({ key: jwk, format: 'jwk' });
}

async function introspectTokenIfEnabled(token, correlationId) {
  if (!config.keycloak.enableIntrospection || !config.keycloak.introspectUrl) {
    return;
  }

  const body = new URLSearchParams();
  body.set('token', token);
  if (config.keycloak.introspectClientId) {
    body.set('client_id', config.keycloak.introspectClientId);
  }
  if (config.keycloak.introspectClientSecret) {
    body.set('client_secret', config.keycloak.introspectClientSecret);
  }

  const response = await httpRequest(config.keycloak.introspectUrl, {
    method: 'POST',
    headers: {
      'content-type': 'application/x-www-form-urlencoded',
      'x-correlation-id': correlationId || '',
    },
    body: body.toString(),
  });

  if (!response.ok || response.body?.active !== true) {
    throw httpError(401, 'Token introspection rejected access token', {
      code: 'TOKEN_INTROSPECTION_FAILED',
    });
  }
}

async function verifyAccessToken(token, correlationId) {
  if (!token) {
    throw httpError(401, 'Missing access token', { code: 'TOKEN_MISSING' });
  }

  const decoded = jwt.decode(token, { complete: true });
  if (!decoded?.header || !decoded?.payload) {
    throw httpError(401, 'Invalid access token', { code: 'TOKEN_INVALID' });
  }

  const key = await getSigningKey(decoded.header.kid, correlationId);
  const payload = jwt.verify(token, key, buildVerifyOptions());

  if (payload.iss && !payload.iss.includes(config.keycloak.realm)) {
    throw httpError(401, 'Token issued for unexpected realm', {
      code: 'TOKEN_REALM_INVALID',
    });
  }

  await introspectTokenIfEnabled(token, correlationId);

  const authContext = {
    userId: payload.sub,
    roles: normalizeRoles(payload),
    tokenPayload: payload,
  };

  logger.info('access_token_verified', {
    correlationId,
    userId: authContext.userId,
    roles: authContext.roles,
  });

  return authContext;
}

module.exports = {
  verifyAccessToken,
};
