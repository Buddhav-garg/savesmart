const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../db');
const { ApiError } = require('../utils/apiError');
const { signToken } = require('../middleware/auth');

const router = express.Router();

// POST /auth/login  { phone, pin }  -> demo login, no real OTP/SMS
router.post('/login', (req, res, next) => {
  try {
    const { phone, pin } = req.body || {};
    if (!phone || !pin) {
      throw new ApiError(422, 'VALIDATION_ERROR', 'phone and pin are required.');
    }

    const user = db.prepare('SELECT * FROM users WHERE phone = ?').get(phone);
    if (!user || user.pin !== pin) {
      throw new ApiError(401, 'INVALID_CREDENTIALS', 'Phone or PIN is incorrect.');
    }

    const token = signToken(user.id);
    res.json({
      token,
      user: { id: user.id, name: user.name, phone: user.phone },
    });
  } catch (e) {
    next(e);
  }
});

// POST /auth/register  { phone, name, pin } -> creates a demo user + account
router.post('/register', (req, res, next) => {
  try {
    const { phone, name, pin } = req.body || {};
    if (!phone || !name || !pin) {
      throw new ApiError(422, 'VALIDATION_ERROR', 'phone, name and pin are required.');
    }
    const existing = db.prepare('SELECT id FROM users WHERE phone = ?').get(phone);
    if (existing) {
      throw new ApiError(409, 'USER_EXISTS', 'An account with this phone number already exists.');
    }

    const userId = uuid();
    const now = new Date().toISOString();
    db.prepare(
      `INSERT INTO users (id, phone, name, pin, is_senior_citizen, created_at)
       VALUES (?, ?, ?, ?, 0, ?)`
    ).run(userId, phone, name, pin, now);
    db.prepare(`INSERT INTO accounts (id, user_id, balance_paise, currency) VALUES (?, ?, 0, 'INR')`).run(
      uuid(),
      userId
    );

    const token = signToken(userId);
    res.status(201).json({ token, user: { id: userId, name, phone } });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
