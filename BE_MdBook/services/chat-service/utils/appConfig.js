require('dotenv').config();

function splitCsv(value, fallback = []) {
  if (!value) {
    return fallback;
  }

  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function parseBoolean(value, fallback = false) {
  if (value === undefined) {
    return fallback;
  }

  return ['1', 'true', 'yes', 'on'].includes(String(value).toLowerCase());
}

const keycloakIssuer =
  process.env.KEYCLOAK_ISSUER || 'http://localhost:8181/realms/clinic-realm';

// Accept multiple issuers so that tokens issued via localhost (dev) or
// internal docker hostname (prod) are both valid.
const keycloakIssuers = [keycloakIssuer];
// Always add the localhost variant so frontend dev tokens are accepted
if (!keycloakIssuer.includes('localhost')) {
  keycloakIssuers.push('http://localhost:8181/realms/clinic-realm');
}
// Always add the docker-internal variant
if (!keycloakIssuer.includes('keycloak:8080')) {
  keycloakIssuers.push('http://keycloak:8080/realms/clinic-realm');
}

module.exports = {
  serviceName: process.env.SERVICE_NAME || 'chat-service',
  host: process.env.HOST || '0.0.0.0',
  port: Number(process.env.PORT || 5006),
  mongoUrl:
    process.env.MONGO_URL ||
    `mongodb://${process.env.DB_HOST || '127.0.0.1'}:${process.env.DB_PORT || 27017}/${process.env.DB_NAME || 'chat_db'}`,
  corsOrigins: splitCsv(process.env.CORS_ORIGINS, ['*']),
  socketPath: process.env.SOCKET_PATH || '/chat/socket.io',
  keycloak: {
    issuer: keycloakIssuer,
    issuers: keycloakIssuers,
    jwksUrl:
      process.env.KEYCLOAK_JWKS_URL ||
      `${keycloakIssuer}/protocol/openid-connect/certs`,
    audience: process.env.KEYCLOAK_AUDIENCE || undefined,
    realm: process.env.KEYCLOAK_REALM || 'clinic-realm',
    enableIntrospection: parseBoolean(process.env.ENABLE_IDENTITY_INTROSPECTION, false),
    introspectUrl: process.env.IDENTITY_INTROSPECT_URL || '',
    introspectClientId: process.env.IDENTITY_INTROSPECT_CLIENT_ID || '',
    introspectClientSecret: process.env.IDENTITY_INTROSPECT_CLIENT_SECRET || '',
  },
  integrations: {
    profileBaseUrl: process.env.PROFILE_SERVICE_URL || 'http://localhost:5010',
    patientProfilePathTemplate:
      process.env.PROFILE_PATIENT_PATH_TEMPLATE ||
      '/profile/profiles/patients/by-user/{userId}',
    doctorProfilePathTemplate:
      process.env.PROFILE_DOCTOR_PATH_TEMPLATE ||
      '/profile/profiles/doctors/by-user/{userId}',
    enforceAppointmentRelationship: parseBoolean(
      process.env.ENFORCE_APPOINTMENT_RELATIONSHIP,
      false
    ),
    appointmentRelationshipUrlTemplate:
      process.env.APPOINTMENT_RELATIONSHIP_URL_TEMPLATE || '',
  },
  profileCacheTtlMs: Number(process.env.PROFILE_CACHE_TTL_MS || 300000),
  jwksCacheTtlMs: Number(process.env.JWKS_CACHE_TTL_MS || 3600000),
};
