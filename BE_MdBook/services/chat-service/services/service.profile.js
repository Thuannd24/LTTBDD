const config = require('../utils/appConfig');
const { httpRequest } = require('../utils/httpClient');
const logger = require('../utils/logger');
const { normalizeRole } = require('../utils/chatHelpers');

const profileCache = new Map();

function buildProfileUrl(baseUrl, template, userId) {
  return `${baseUrl}${template.replace('{userId}', encodeURIComponent(userId))}`;
}

function extractBodyData(body) {
  return body?.data || body?.result || body || null;
}

function readCachedProfile(userId) {
  const cached = profileCache.get(userId);
  if (!cached) {
    return null;
  }

  if (cached.expiresAt < Date.now()) {
    profileCache.delete(userId);
    return null;
  }

  return cached.value;
}

function writeCachedProfile(userId, profile) {
  profileCache.set(userId, {
    value: profile,
    expiresAt: Date.now() + config.profileCacheTtlMs,
  });
}

function normalizeProfile(userId, body, roleHint) {
  const data = extractBodyData(body);
  if (!data) {
    return null;
  }

  const role = normalizeRole(
    data.role ||
      data.userRole ||
      data.type ||
      roleHint
  );

  // Profile service returns firstName + lastName separately (no combined field).
  // Build a combined name as fallback.
  const combinedName =
    (data.firstName || data.lastName)
      ? `${data.firstName || ''} ${data.lastName || ''}`.trim()
      : null;

  return {
    userId,
    role,
    displayName:
      data.displayName ||
      data.fullName ||
      data.name ||
      data.patientName ||
      data.doctorName ||
      combinedName ||
      null,
    avatarUrl: data.avatarUrl || data.avatar || data.photoUrl || null,
    raw: data,
  };
}

async function fetchProfileFromUrl(userId, url, roleHint, correlationId) {
  const response = await httpRequest(url, {
    headers: {
      'x-correlation-id': correlationId || '',
      accept: 'application/json',
    },
  });

  if (!response.ok) {
    return null;
  }

  return normalizeProfile(userId, response.body, roleHint);
}

async function getUserProfile(userId, options = {}) {
  const { preferredRole, correlationId, skipCache = false } = options;

  if (!skipCache) {
    const cached = readCachedProfile(userId);
    if (cached) {
      return cached;
    }
  }

  const roleCandidates = [];
  if (preferredRole === 'ROLE_PATIENT') {
    roleCandidates.push(['ROLE_PATIENT', config.integrations.patientProfilePathTemplate]);
  } else if (preferredRole === 'ROLE_DOCTOR') {
    roleCandidates.push(['ROLE_DOCTOR', config.integrations.doctorProfilePathTemplate]);
  }

  roleCandidates.push(
    ['ROLE_PATIENT', config.integrations.patientProfilePathTemplate],
    ['ROLE_DOCTOR', config.integrations.doctorProfilePathTemplate]
  );

  for (const [roleHint, template] of roleCandidates) {
    const url = buildProfileUrl(
      config.integrations.profileBaseUrl,
      template,
      userId
    );
    const profile = await fetchProfileFromUrl(userId, url, roleHint, correlationId);
    if (profile) {
      // Only cache if we got a real display name; otherwise re-fetch next time
      if (profile.displayName) {
        writeCachedProfile(userId, profile);
      }
      return profile;
    }
  }

  logger.warn('profile_lookup_failed', {
    correlationId,
    userId,
    preferredRole,
  });

  return {
    userId,
    role: normalizeRole(preferredRole),
    displayName: null,
    avatarUrl: null,
    raw: null,
  };
}

module.exports = {
  getUserProfile,
};
