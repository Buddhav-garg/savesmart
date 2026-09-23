const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const seed = require('./db/seed');
const authRoutes = require('./routes/auth');
const goalsRoutes = require('./routes/goals');
const depositsRoutes = require('./routes/deposits');
const accountRoutes = require('./routes/account');
const { errorBody, ApiError } = require('./utils/apiError');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

/**
 * Chaos middleware (opt-in): simulates slow network / server errors so the
 * Flutter app's loading/error/empty states can be tested, per the baseline NFRs.
 * Toggle with header  X-Chaos: slow | error | none   or query ?chaos=slow|error
 */
app.use((req, res, next) => {
  const chaos = req.headers['x-chaos'] || req.query.chaos;
  if (chaos === 'slow') {
    return setTimeout(next, 3000);
  }
  if (chaos === 'error') {
    return res.status(500).json(errorBody(new ApiError(500, 'SIMULATED_ERROR', 'Simulated server error.')));
  }
  next();
});

app.get('/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

app.use('/auth', authRoutes);
app.use('/account', accountRoutes);
app.use('/goals', goalsRoutes);
app.use('/deposits', depositsRoutes);

// 404 fallback
app.use((req, res) => {
  res.status(404).json(errorBody(new ApiError(404, 'NOT_FOUND', 'Route not found.')));
});

// Central error handler — every thrown ApiError lands here
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  const status = err.statusCode || 500;
  if (status >= 500) {
    console.error(err);
  }
  res.status(status).json(errorBody(err));
});

seed(); // idempotent: safe to run on every boot

app.listen(PORT, () => {
  console.log(`SaveSmart API listening on http://localhost:${PORT}`);
  console.log(`Demo login -> POST /auth/login { "phone": "9999999999", "pin": "1234" }`);
});
