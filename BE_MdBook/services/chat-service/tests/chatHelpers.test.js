const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildParticipantPairKey,
  isPatientDoctorPair,
  normalizeRoles,
} = require('../utils/chatHelpers');

test('buildParticipantPairKey sorts ids deterministically', () => {
  assert.equal(buildParticipantPairKey('b-user', 'a-user'), 'a-user:b-user');
});

test('isPatientDoctorPair only allows patient-doctor combinations', () => {
  assert.equal(
    isPatientDoctorPair(['ROLE_PATIENT'], ['ROLE_DOCTOR']),
    true
  );
  assert.equal(
    isPatientDoctorPair(['ROLE_DOCTOR'], ['ROLE_DOCTOR']),
    false
  );
  assert.equal(
    isPatientDoctorPair(['ROLE_PATIENT'], ['ROLE_PATIENT']),
    false
  );
});

test('normalizeRoles merges custom and realm roles with ROLE prefix', () => {
  const roles = normalizeRoles({
    roles: ['patient'],
    realm_access: { roles: ['doctor'] },
  });

  assert.deepEqual(roles.sort(), ['ROLE_DOCTOR', 'ROLE_PATIENT']);
});
