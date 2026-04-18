const { verifyAccessToken } = require('../services/service.keycloak');

module.exports = async function authMiddleware(req, res, next) {
  try {
    const authorization = req.headers.authorization || '';
    const token = authorization.replace(/^Bearer\s+/i, '').trim();
    const authContext = await verifyAccessToken(token, req.correlationId);
    req.auth = authContext;
    req.userId = authContext.userId;
    next();
  } catch (error) {
    next(error);
  }
};
