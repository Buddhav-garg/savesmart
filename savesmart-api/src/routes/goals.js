const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');
const { idempotent } = require('../middleware/idempotency');
const { ApiError } = require('../utils/apiError');

const router = express.Router();
router.use(requireAuth);

function toGoalDto(row) {
  return {
    id: row.id,
    name: row.name,
    icon: row.icon,
    targetPaise: row.target_paise,
    savedPaise: row.saved_paise,
    targetDate: row.target_date,
    status: row.status,
    progressPct: row.target_paise > 0 ? Math.min(100, (row.saved_paise / row.target_paise) * 100) : 0,
    requiredMonthlyPaise: requiredMonthly(row),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function requiredMonthly(row) {
  const remaining = Math.max(0, row.target_paise - row.saved_paise);
  const monthsLeft = Math.max(
    1,
    Math.ceil((new Date(row.target_date) - new Date()) / (1000 * 60 * 60 * 24 * 30))
  );
  return Math.ceil(remaining / monthsLeft);
}

// GET /goals?cursor=&limit=  -> cursor-paged list
router.get('/', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
  const cursor = req.query.cursor || null;

  let rows;
  if (cursor) {
    rows = db
      .prepare(
        `SELECT * FROM goals WHERE user_id = ? AND created_at < ? ORDER BY created_at DESC LIMIT ?`
      )
      .all(req.userId, cursor, limit + 1);
  } else {
    rows = db
      .prepare(`SELECT * FROM goals WHERE user_id = ? ORDER BY created_at DESC LIMIT ?`)
      .all(req.userId, limit + 1);
  }

  const hasMore = rows.length > limit;
  const page = rows.slice(0, limit);
  res.json({
    items: page.map(toGoalDto),
    nextCursor: hasMore ? page[page.length - 1].created_at : null,
  });
});

// POST /goals  { name, icon, targetPaise, targetDate }
router.post('/', (req, res, next) => {
  try {
    const { name, icon, targetPaise, targetDate } = req.body || {};

    if (!name || !targetPaise || targetPaise <= 0 || !targetDate) {
      throw new ApiError(422, 'VALIDATION_ERROR', 'name, targetPaise and targetDate are required.');
    }
    if (new Date(targetDate) < new Date(new Date().toDateString())) {
      throw new ApiError(422, 'TARGET_DATE_IN_PAST', 'Target date cannot be in the past.');
    }

    const id = uuid();
    const now = new Date().toISOString();
    db.prepare(
      `INSERT INTO goals (id, user_id, name, icon, target_paise, saved_paise, target_date, status, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, 0, ?, 'active', ?, ?)`
    ).run(id, req.userId, name, icon || 'savings', targetPaise, targetDate, now, now);

    const row = db.prepare('SELECT * FROM goals WHERE id = ?').get(id);
    res.status(201).json(toGoalDto(row));
  } catch (e) {
    next(e);
  }
});

// GET /goals/:id
router.get('/:id', (req, res, next) => {
  const row = db.prepare('SELECT * FROM goals WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
  if (!row) return next(new ApiError(404, 'GOAL_NOT_FOUND', 'Goal not found.'));
  res.json(toGoalDto(row));
});

// POST /goals/:id/contributions  (Idempotency-Key required)
// Add money to a goal — idempotent: a retry with the same key never moves money twice.
router.post('/:id/contributions', idempotent, (req, res, next) => {
  try {
    const goal = db.prepare('SELECT * FROM goals WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
    if (!goal) throw new ApiError(404, 'GOAL_NOT_FOUND', 'Goal not found.');

    const { amountPaise } = req.body || {};
    if (!amountPaise || amountPaise <= 0) {
      throw new ApiError(422, 'VALIDATION_ERROR', 'amountPaise must be a positive integer.');
    }

    const account = db.prepare('SELECT * FROM accounts WHERE user_id = ?').get(req.userId);
    if (account.balance_paise < amountPaise) {
      throw new ApiError(422, 'INSUFFICIENT_FUNDS', 'Not enough balance in your savings account.');
    }

    const key = req.headers['idempotency-key'];
    const now = new Date().toISOString();

    const tx = db.transaction(() => {
      db.prepare('UPDATE accounts SET balance_paise = balance_paise - ? WHERE id = ?').run(
        amountPaise,
        account.id
      );
      const contributionId = uuid();
      db.prepare(
        `INSERT INTO goal_contributions (id, goal_id, amount_paise, idempotency_key, created_at)
         VALUES (?, ?, ?, ?, ?)`
      ).run(contributionId, goal.id, amountPaise, key, now);

      const newSaved = goal.saved_paise + amountPaise;
      const newStatus = newSaved >= goal.target_paise ? 'reached' : goal.status;
      db.prepare('UPDATE goals SET saved_paise = ?, status = ?, updated_at = ? WHERE id = ?').run(
        newSaved,
        newStatus,
        now,
        goal.id
      );
    });
    tx();

    const updated = db.prepare('SELECT * FROM goals WHERE id = ?').get(goal.id);
    res.idempotentJson(201, toGoalDto(updated));
  } catch (e) {
    next(e);
  }
});

// PUT /goals/:id/rules  { type, amountPaise?, percent?, schedule?, paused? }
// Auto-save rules: max 3 per goal.
router.put('/:id/rules', (req, res, next) => {
  try {
    const goal = db.prepare('SELECT * FROM goals WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
    if (!goal) throw new ApiError(404, 'GOAL_NOT_FOUND', 'Goal not found.');

    const { type, amountPaise, percent, schedule } = req.body || {};
    const validTypes = ['round_up', 'fixed_weekly', 'fixed_monthly', 'salary_day_percent'];
    if (!validTypes.includes(type)) {
      throw new ApiError(422, 'VALIDATION_ERROR', `type must be one of ${validTypes.join(', ')}.`);
    }

    const count = db.prepare('SELECT COUNT(*) AS c FROM auto_save_rules WHERE goal_id = ?').get(goal.id).c;
    if (count >= 3) {
      throw new ApiError(422, 'RULE_LIMIT_EXCEEDED', 'Rules cannot exceed 3 per goal.');
    }

    const id = uuid();
    const now = new Date().toISOString();
    db.prepare(
      `INSERT INTO auto_save_rules (id, goal_id, type, amount_paise, percent, schedule, paused, created_at)
       VALUES (?, ?, ?, ?, ?, ?, 0, ?)`
    ).run(id, goal.id, type, amountPaise || null, percent || null, schedule || null, now);

    const rules = db.prepare('SELECT * FROM auto_save_rules WHERE goal_id = ?').all(goal.id);
    res.json({ items: rules.map(ruleDto) });
  } catch (e) {
    next(e);
  }
});

function ruleDto(r) {
  return {
    id: r.id,
    goalId: r.goal_id,
    type: r.type,
    amountPaise: r.amount_paise,
    percent: r.percent,
    schedule: r.schedule,
    paused: !!r.paused,
    pausedSince: r.paused_since,
  };
}

// PATCH /goals/:id/rules/:ruleId  { paused: true|false }  -- pause/resume a rule
router.patch('/:id/rules/:ruleId', (req, res, next) => {
  try {
    const rule = db
      .prepare('SELECT * FROM auto_save_rules WHERE id = ? AND goal_id = ?')
      .get(req.params.ruleId, req.params.id);
    if (!rule) throw new ApiError(404, 'RULE_NOT_FOUND', 'Auto-save rule not found.');

    const { paused } = req.body || {};
    const now = new Date().toISOString();
    db.prepare('UPDATE auto_save_rules SET paused = ?, paused_since = ? WHERE id = ?').run(
      paused ? 1 : 0,
      paused ? now : null,
      rule.id
    );
    const updated = db.prepare('SELECT * FROM auto_save_rules WHERE id = ?').get(rule.id);
    res.json(ruleDto(updated));
  } catch (e) {
    next(e);
  }
});

module.exports = router;
