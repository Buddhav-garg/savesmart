const db = require('../db');
const { ApiError } = require('../utils/apiError');

/**
 * Enforces "same Idempotency-Key -> same response" for mutating calls
 * that move money or create a record, per the API conventions in the spec.
 *
 * Usage: router.post('/path', requireAuth, idempotent, handler)
 * The route's own handler must call `res.locals.storeIdempotent(statusCode, body)`
 * instead of res.json() directly, OR simply use `res.idempotentJson(status, body)`
 * which this middleware attaches to `res`.
 */
function idempotent(req, res, next) {
  const key = req.headers['idempotency-key'];

  if (!key) {
    return next(
      new ApiError(422, 'IDEMPOTENCY_KEY_REQUIRED', 'Idempotency-Key header is required for this call.')
    );
  }

  const route = `${req.method} ${req.baseUrl}${req.route ? req.route.path : req.path}`;

  const existing = db
    .prepare('SELECT status_code, response_body FROM idempotency_keys WHERE key = ? AND route = ?')
    .get(key, route);

  if (existing) {
    return res.status(existing.status_code).json(JSON.parse(existing.response_body));
  }

  res.idempotentJson = (statusCode, body) => {
    db.prepare(
      `INSERT INTO idempotency_keys (key, route, status_code, response_body, created_at)
       VALUES (?, ?, ?, ?, ?)`
    ).run(key, route, statusCode, JSON.stringify(body), new Date().toISOString());
    res.status(statusCode).json(body);
  };

  next();
}

module.exports = { idempotent };
