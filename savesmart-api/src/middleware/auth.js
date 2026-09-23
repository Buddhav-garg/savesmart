const jwt = require('jsonwebtoken');
const { ApiError } = require('../utils/apiError');

const JWT_SECRET = process.env.JWT_SECRET || 'savesmart-dev-secret-change-me';

function signToken(userId) {
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: '12h' });
}

// Authorization: Bearer <token>; a missing/invalid/expired token -> 401
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return next(new ApiError(401, 'UNAUTHENTICATED', 'Sign in again.'));
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.userId = payload.sub;
    next();
  } catch (e) {
    next(new ApiError(401, 'UNAUTHENTICATED', 'Sign in again.'));
  }
}

module.exports = { requireAuth, signToken, JWT_SECRET };
