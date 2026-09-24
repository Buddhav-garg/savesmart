const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');
const { ApiError } = require('../utils/apiError');

const router = express.Router();
router.use(requireAuth);

// GET /account -> savings account balance, for the Home screen summary
router.get('/', (req, res) => {
  const account = db.prepare('SELECT * FROM accounts WHERE user_id = ?').get(req.userId);
  res.json({
    id: account.id,
    balancePaise: account.balance_paise,
    currency: account.currency,
  });
});

router.get('/nominees', (req, res) => {
  const items = db.prepare(
    'SELECT id, name, relation, share_pct AS sharePct FROM account_nominees WHERE user_id = ? ORDER BY rowid'
  ).all(req.userId);
  res.json({ items });
});

router.put('/nominees', (req, res, next) => {
  try {
    const { items } = req.body || {};
    if (!Array.isArray(items) || items.length === 0) {
      throw new ApiError(422, 'VALIDATION_ERROR', 'Add at least one nominee.');
    }
    const clean = items.map((item) => ({
      name: typeof item.name === 'string' ? item.name.trim() : '',
      relation: typeof item.relation === 'string' ? item.relation.trim() : '',
      sharePct: Number(item.sharePct),
    }));
    if (clean.some((item) => !item.name || !item.relation || !Number.isFinite(item.sharePct) || item.sharePct <= 0 || item.sharePct > 100)) {
      throw new ApiError(422, 'VALIDATION_ERROR', 'Each nominee needs a name, relationship, and share between 0 and 100%.');
    }
    const total = clean.reduce((sum, item) => sum + item.sharePct, 0);
    if (Math.abs(total - 100) > 0.000001) {
      throw new ApiError(422, 'NOMINEE_SHARE_INVALID', 'Nominee shares must add to 100%.');
    }
    const tx = db.transaction(() => {
      db.prepare('DELETE FROM account_nominees WHERE user_id = ?').run(req.userId);
      const insert = db.prepare(
        'INSERT INTO account_nominees (id, user_id, name, relation, share_pct) VALUES (?, ?, ?, ?, ?)'
      );
      clean.forEach((item) => insert.run(uuid(), req.userId, item.name, item.relation, item.sharePct));
    });
    tx();
    const saved = db.prepare(
      'SELECT id, name, relation, share_pct AS sharePct FROM account_nominees WHERE user_id = ? ORDER BY rowid'
    ).all(req.userId);
    res.json({ items: saved });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
