const { v4: uuid } = require('uuid');

class ApiError extends Error {
  constructor(statusCode, code, message, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

// Matches the spec: { "error": { "code", "message", "details", "traceId" } }
function errorBody(err) {
  return {
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: err.message || 'Something went wrong',
      details: err.details || null,
      traceId: uuid(),
    },
  };
}

module.exports = { ApiError, errorBody };
