const express = require('express');
const { v4: uuid } = require('uuid');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');
const { idempotent } = require('../middleware/idempotency');
const { ApiError } = require('../utils/apiError');
const { findRate, fdMaturity, rdMaturity, addDays } = require('../utils/depositMath');

const router = express.Router();
router.use(requireAuth);

function toDepositDto(row) {
  const daysToMaturity = Math.max(
    0,
    Math.round((new Date(row.maturity_date) - new Date()) / 86400000)
  );
  return {
    id: row.id,
    kind: row.kind,
    principalPaise: row.principal_paise,
    installmentPaise: row.installment_paise,
    debitDate: row.debit_date,
    ratePct: row.rate_pct,
    startDate: row.start_date,
    maturityDate: row.maturity_date,
    maturityPaise: row.maturity_paise,
    payout: row.payout,
    renewal: row.renewal,
    status: row.status,
    daysToMaturity,
  };
}

// GET /deposits/rates?kind=FD&tenureDays=365 -> single applicable rate, or full card if no query given
router.get('/rates', (req, res, next) => {
  try {
    const { kind, tenureDays } = req.query;
    if (kind && tenureDays) {
      const rate = findRate(kind, parseInt(tenureDays, 10));
      if (!rate) throw new ApiError(404, 'RATE_NOT_FOUND', 'No rate card entry for this tenure.');
      return res.json({
        kind: rate.kind,
        minTenureDays: rate.min_tenure_days,
        maxTenureDays: rate.max_tenure_days,
        ratePct: rate.rate_pct,
        seniorBonusPct: rate.senior_bonus_pct,
      });
    }
    const all = db.prepare('SELECT * FROM rate_cards ORDER BY kind, min_tenure_days').all();
    res.json({
      items: all.map((r) => ({
        kind: r.kind,
        minTenureDays: r.min_tenure_days,
        maxTenureDays: r.max_tenure_days,
        ratePct: r.rate_pct,
        seniorBonusPct: r.senior_bonus_pct,
      })),
    });
  } catch (e) {
    next(e);
  }
});

// POST /deposits  (Idempotency-Key required) — books an FD or RD
// body: { kind: 'FD'|'RD', principalPaise (FD) | installmentPaise (RD), tenureDays, debitDate? (RD, 1-28),
//         payout, renewal, isSeniorCitizen, nominee?: { name, relation, sharePct } }
router.post('/', idempotent, (req, res, next) => {
  try {
    const {
      kind,
      principalPaise,
      installmentPaise,
      tenureDays,
      debitDate,
      payout = 'on_maturity',
      renewal = 'none',
      isSeniorCitizen = false,
      nominee,
    } = req.body || {};

    if (!['FD', 'RD'].includes(kind)) {
      throw new ApiError(422, 'VALIDATION_ERROR', "kind must be 'FD' or 'RD'.");
    }
    if (!tenureDays || tenureDays < 7) {
      throw new ApiError(422, 'VALIDATION_ERROR', 'tenureDays is required and must be at least 7.');
    }

    const rate = findRate(kind, tenureDays);
    if (!rate) throw new ApiError(422, 'VALIDATION_ERROR', 'No rate available for this tenure.');

    const startDate = new Date().toISOString().slice(0, 10);
    const maturityDate = addDays(startDate, tenureDays);

    let principal, maturityPaise;

    if (kind === 'FD') {
      if (!principalPaise || principalPaise < 100000) {
        // ₹1,000 minimum, expressed in paise
        throw new ApiError(422, 'MIN_AMOUNT', 'Minimum FD booking amount is ₹1,000.');
      }
      principal = principalPaise;
      maturityPaise = fdMaturity(principalPaise, rate.rate_pct, tenureDays, isSeniorCitizen);
    } else {
      if (!installmentPaise || installmentPaise <= 0) {
        throw new ApiError(422, 'VALIDATION_ERROR', 'installmentPaise is required for an RD.');
      }
      if (!debitDate || debitDate < 1 || debitDate > 28) {
        throw new ApiError(422, 'INVALID_DEBIT_DATE', 'Debit date must be between 1 and 28.');
      }
      const months = Math.round(tenureDays / 30);
      principal = installmentPaise * months;
      maturityPaise = rdMaturity(installmentPaise, rate.rate_pct, months, isSeniorCitizen);
    }

    const id = uuid();
    const now = new Date().toISOString();
    const key = req.headers['idempotency-key'];

    db.prepare(
      `INSERT INTO deposits
        (id, user_id, kind, principal_paise, installment_paise, debit_date, rate_pct,
         start_date, tenure_days, maturity_date, maturity_paise, payout, renewal, status,
         idempotency_key, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?)`
    ).run(
      id,
      req.userId,
      kind,
      principal,
      kind === 'RD' ? installmentPaise : null,
      kind === 'RD' ? debitDate : null,
      rate.rate_pct + (isSeniorCitizen ? rate.senior_bonus_pct : 0),
      startDate,
      tenureDays,
      maturityDate,
      maturityPaise,
      payout,
      renewal,
      key,
      now
    );

    if (nominee) {
      const totalShare = nominee.sharePct;
      if (totalShare !== 100) {
        // still book the deposit, but nominee share must total 100% to be saved
        throw new ApiError(422, 'NOMINEE_SHARE_INVALID', 'Nominee shares must add to 100%.');
      }
      db.prepare(
        `INSERT INTO nominees (id, deposit_id, name, relation, share_pct) VALUES (?, ?, ?, ?, ?)`
      ).run(uuid(), id, nominee.name, nominee.relation, nominee.sharePct);
    }

    const row = db.prepare('SELECT * FROM deposits WHERE id = ?').get(id);
    res.idempotentJson(201, toDepositDto(row));
  } catch (e) {
    next(e);
  }
});

// GET /deposits?sort=maturityDate|principal&order=asc|desc&cursor=&limit=
router.get('/', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
  const sortField = { maturityDate: 'maturity_date', principal: 'principal_paise' }[req.query.sort] || 'created_at';
  const order = req.query.order === 'asc' ? 'ASC' : 'DESC';
  const cursor = req.query.cursor || null;

  let rows;
  if (cursor) {
    rows = db
      .prepare(
        `SELECT * FROM deposits WHERE user_id = ? AND created_at < ?
         ORDER BY ${sortField} ${order} LIMIT ?`
      )
      .all(req.userId, cursor, limit + 1);
  } else {
    rows = db
      .prepare(`SELECT * FROM deposits WHERE user_id = ? ORDER BY ${sortField} ${order} LIMIT ?`)
      .all(req.userId, limit + 1);
  }

  const hasMore = rows.length > limit;
  const page = rows.slice(0, limit);
  res.json({
    items: page.map(toDepositDto),
    nextCursor: hasMore ? page[page.length - 1].created_at : null,
  });
});

// GET /deposits/:id
router.get('/:id', (req, res, next) => {
  const row = db.prepare('SELECT * FROM deposits WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
  if (!row) return next(new ApiError(404, 'DEPOSIT_NOT_FOUND', 'Deposit not found.'));
  res.json(toDepositDto(row));
});

// POST /deposits/:id/withdrawal-quote -> premature withdrawal quote, expires in 10 minutes
router.post('/:id/withdrawal-quote', (req, res, next) => {
  try {
    const deposit = db
      .prepare('SELECT * FROM deposits WHERE id = ? AND user_id = ?')
      .get(req.params.id, req.userId);
    if (!deposit) throw new ApiError(404, 'DEPOSIT_NOT_FOUND', 'Deposit not found.');
    if (deposit.status !== 'active') {
      throw new ApiError(409, 'DEPOSIT_NOT_ACTIVE', 'This deposit cannot be withdrawn.');
    }

    // Penalty-adjusted quote: 1% penalty on the rate, prorated for elapsed time.
    const elapsedDays = Math.max(
      1,
      Math.round((Date.now() - new Date(deposit.start_date).getTime()) / 86400000)
    );
    const penaltyRate = 1.0;
    const proratedRate = Math.max(0, deposit.rate_pct - penaltyRate);
    const payable = Math.round(
      deposit.principal_paise * (1 + (proratedRate / 100) * (elapsedDays / 365))
    );
    const penalty = Math.max(0, deposit.maturity_paise - payable);

    const id = uuid();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 10 * 60 * 1000).toISOString();

    db.prepare(
      `INSERT INTO withdrawal_quotes (id, deposit_id, payable_paise, penalty_paise, expires_at, used, created_at)
       VALUES (?, ?, ?, ?, ?, 0, ?)`
    ).run(id, deposit.id, payable, penalty, expiresAt, now.toISOString());

    res.status(201).json({
      quoteId: id,
      depositId: deposit.id,
      payablePaise: payable,
      penaltyPaise: penalty,
      expiresAt,
    });
  } catch (e) {
    next(e);
  }
});

// POST /deposits/:id/withdraw  { quoteId }  -> confirms withdrawal with a live quote
router.post('/:id/withdraw', (req, res, next) => {
  try {
    const deposit = db
      .prepare('SELECT * FROM deposits WHERE id = ? AND user_id = ?')
      .get(req.params.id, req.userId);
    if (!deposit) throw new ApiError(404, 'DEPOSIT_NOT_FOUND', 'Deposit not found.');

    const { quoteId } = req.body || {};
    const quote = db
      .prepare('SELECT * FROM withdrawal_quotes WHERE id = ? AND deposit_id = ?')
      .get(quoteId, deposit.id);
    if (!quote) throw new ApiError(404, 'QUOTE_NOT_FOUND', 'Withdrawal quote not found.');
    if (quote.used) throw new ApiError(410, 'QUOTE_EXPIRED', 'This quote has already been used.');
    if (new Date(quote.expires_at) < new Date()) {
      throw new ApiError(410, 'QUOTE_EXPIRED', 'This quote has expired. Request a new one.');
    }

    const now = new Date().toISOString();
    const tx = db.transaction(() => {
      db.prepare('UPDATE withdrawal_quotes SET used = 1 WHERE id = ?').run(quote.id);
      db.prepare("UPDATE deposits SET status = 'withdrawn' WHERE id = ?").run(deposit.id);
      const account = db.prepare('SELECT * FROM accounts WHERE user_id = ?').get(req.userId);
      db.prepare('UPDATE accounts SET balance_paise = balance_paise + ? WHERE id = ?').run(
        quote.payable_paise,
        account.id
      );
    });
    tx();

    const updated = db.prepare('SELECT * FROM deposits WHERE id = ?').get(deposit.id);
    res.json({ deposit: toDepositDto(updated), creditedPaise: quote.payable_paise });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
