const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

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

module.exports = router;
