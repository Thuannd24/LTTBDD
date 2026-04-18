function normalizeRole(role) {
  if (!role) {
    return null;
  }

  const value = String(role).toUpperCase();
  return value.startsWith('ROLE_') ? value : `ROLE_${value}`;
}

function ensureTextOnlyContentType(value) {
  const contentType = String(value || 'TEXT').toUpperCase();
  if (contentType !== 'TEXT') {
    const error = new Error('Only text messages are supported in v1');
    error.code = 'CONTENT_TYPE_INVALID';
    error.status = 400;
    throw error;
  }

  return contentType;
}

function normalizeRoles(payload = {}) {
  const roles = new Set();
  const sources = [];

  if (Array.isArray(payload.roles)) {
    sources.push(...payload.roles);
  }

  if (Array.isArray(payload.realm_access?.roles)) {
    sources.push(...payload.realm_access.roles);
  }

  if (Array.isArray(payload.authorities)) {
    sources.push(...payload.authorities);
  }

  sources
    .map(normalizeRole)
    .filter(Boolean)
    .forEach((role) => roles.add(role));

  return Array.from(roles);
}

function buildParticipantPairKey(userIdA, userIdB) {
  return [String(userIdA), String(userIdB)].sort().join(':');
}

function getOtherParticipant(participantIds, currentUserId) {
  return participantIds.find((participantId) => String(participantId) !== String(currentUserId)) || null;
}

function isPatientDoctorPair(sourceRoles, targetRoles) {
  const source = new Set(sourceRoles || []);
  const target = new Set(targetRoles || []);

  return (
    (source.has('ROLE_PATIENT') && target.has('ROLE_DOCTOR')) ||
    (source.has('ROLE_DOCTOR') && target.has('ROLE_PATIENT'))
  );
}

function inferConversationPartnerRole(sourceRoles) {
  const roles = new Set(sourceRoles || []);
  if (roles.has('ROLE_PATIENT')) {
    return 'ROLE_DOCTOR';
  }

  if (roles.has('ROLE_DOCTOR')) {
    return 'ROLE_PATIENT';
  }

  return null;
}

module.exports = {
  ensureTextOnlyContentType,
  normalizeRole,
  normalizeRoles,
  buildParticipantPairKey,
  getOtherParticipant,
  isPatientDoctorPair,
  inferConversationPartnerRole,
};
