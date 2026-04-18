const config = require('../utils/appConfig');
const { httpRequest } = require('../utils/httpClient');
const { httpError } = require('../utils/httpError');

function buildRelationshipUrl(patientId, doctorId) {
  return config.integrations.appointmentRelationshipUrlTemplate
    .replace('{patientId}', encodeURIComponent(patientId))
    .replace('{doctorId}', encodeURIComponent(doctorId));
}

async function assertPatientDoctorRelationship({ patientId, doctorId, correlationId }) {
  if (!config.integrations.enforceAppointmentRelationship) {
    return;
  }

  if (!config.integrations.appointmentRelationshipUrlTemplate) {
    throw httpError(500, 'Appointment relationship URL template is not configured');
  }

  const response = await httpRequest(buildRelationshipUrl(patientId, doctorId), {
    headers: {
      'x-correlation-id': correlationId || '',
      accept: 'application/json',
    },
  });

  const allowed =
    response.body?.allowed ??
    response.body?.data?.allowed ??
    response.body?.exists ??
    response.body?.data?.exists ??
    false;

  if (!response.ok || allowed !== true) {
    throw httpError(403, 'Patient-doctor relationship check failed', {
      code: 'RELATIONSHIP_NOT_ALLOWED',
    });
  }
}

module.exports = {
  assertPatientDoctorRelationship,
};
