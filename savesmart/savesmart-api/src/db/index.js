const path = require('path');
const Database = require('better-sqlite3');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', '..', 'savesmart.db');
const db = new Database(DB_PATH);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  phone TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  pin TEXT NOT NULL,              -- demo only: 4-digit PIN, never do this in production
  is_senior_citizen INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS accounts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  balance_paise INTEGER NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'INR'
);

CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  icon TEXT NOT NULL DEFAULT 'savings',
  target_paise INTEGER NOT NULL,
  saved_paise INTEGER NOT NULL DEFAULT 0,
  target_date TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',   -- active | reached | archived
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS goal_contributions (
  id TEXT PRIMARY KEY,
  goal_id TEXT NOT NULL REFERENCES goals(id),
  amount_paise INTEGER NOT NULL,
  idempotency_key TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE(goal_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS auto_save_rules (
  id TEXT PRIMARY KEY,
  goal_id TEXT NOT NULL REFERENCES goals(id),
  type TEXT NOT NULL,              -- round_up | fixed_weekly | fixed_monthly | salary_day_percent
  amount_paise INTEGER,
  percent REAL,
  schedule TEXT,                   -- e.g. weekday/day-of-month
  paused INTEGER NOT NULL DEFAULT 0,
  paused_since TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS rate_cards (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,              -- FD | RD
  min_tenure_days INTEGER NOT NULL,
  max_tenure_days INTEGER NOT NULL,
  rate_pct REAL NOT NULL,
  senior_bonus_pct REAL NOT NULL DEFAULT 0.5
);

CREATE TABLE IF NOT EXISTS deposits (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  kind TEXT NOT NULL,              -- FD | RD
  principal_paise INTEGER NOT NULL,
  installment_paise INTEGER,       -- RD only
  debit_date INTEGER,              -- RD only, 1-28
  rate_pct REAL NOT NULL,
  start_date TEXT NOT NULL,
  tenure_days INTEGER NOT NULL,
  maturity_date TEXT NOT NULL,
  maturity_paise INTEGER NOT NULL,
  payout TEXT NOT NULL DEFAULT 'on_maturity', -- on_maturity | monthly | quarterly
  renewal TEXT NOT NULL DEFAULT 'none',       -- none | principal | principal_and_interest
  status TEXT NOT NULL DEFAULT 'active',      -- active | withdrawn | matured
  idempotency_key TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS nominees (
  id TEXT PRIMARY KEY,
  deposit_id TEXT REFERENCES deposits(id),
  goal_id TEXT REFERENCES goals(id),
  name TEXT NOT NULL,
  relation TEXT NOT NULL,
  share_pct REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS account_nominees (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relation TEXT NOT NULL,
  share_pct REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS withdrawal_quotes (
  id TEXT PRIMARY KEY,
  deposit_id TEXT NOT NULL REFERENCES deposits(id),
  payable_paise INTEGER NOT NULL,
  penalty_paise INTEGER NOT NULL,
  expires_at TEXT NOT NULL,
  used INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

-- generic idempotency ledger: same Idempotency-Key + route -> same stored response
CREATE TABLE IF NOT EXISTS idempotency_keys (
  key TEXT NOT NULL,
  route TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  response_body TEXT NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (key, route)
);
`);

module.exports = db;
