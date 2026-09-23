# SaveSmart API

A local REST API for the **SaveSmart** Flutter capstone project (goal-based savings,
recurring and fixed deposits). Built with **Node.js + Express + SQLite** (via
`better-sqlite3`) so it runs entirely on your machine — no cloud account needed.

Implements the exact contract from the problem statement: money as integer paise,
ISO-8601 UTC timestamps, `{ error: { code, message, details, traceId } }` error shape,
`Idempotency-Key` on every mutating call, and cursor paging (`{ items, nextCursor }`).

## 1. Setup

```bash
cd savesmart-api
npm install
npm start
```

The server starts on **http://localhost:4000** and seeds a demo user on first run:

```
phone: 9999999999
pin:   1234
```

A SQLite file `savesmart.db` is created next to `package.json`. Delete it any time to
reset all data — it will reseed automatically on next boot.

### Running on a physical phone / emulator
- **Android emulator:** use `http://10.0.2.2:4000` as the base URL (this maps to your
  machine's localhost).
- **iOS simulator:** `http://localhost:4000` works directly.
- **Physical device:** use your machine's LAN IP, e.g. `http://192.168.1.23:4000`, and
  make sure your phone is on the same Wi-Fi network as your computer.

## 2. Authentication

```
POST /auth/login      { phone, pin }        -> { token, user }
POST /auth/register   { phone, name, pin }  -> { token, user }
```

Send the token on every other call: `Authorization: Bearer <token>`.
A missing or invalid token returns `401 UNAUTHENTICATED`.

## 3. Endpoints (matches the project's API contract table)

| Method | Path | Purpose | Notable errors |
|---|---|---|---|
| GET/POST | `/goals` | List (paged) / create a goal | 422 |
| GET | `/goals/:id` | Goal detail | 404 |
| POST | `/goals/:id/contributions` | Add money (**Idempotency-Key** required) | 422 `INSUFFICIENT_FUNDS` |
| PUT | `/goals/:id/rules` | Add an auto-save rule (max 3/goal) | 422 |
| PATCH | `/goals/:id/rules/:ruleId` | Pause/resume a rule | 404 |
| GET | `/deposits/rates` | Rate card, optionally filtered by `?kind=&tenureDays=` | — |
| POST | `/deposits` | Book FD/RD (**Idempotency-Key** required) | 422 |
| GET | `/deposits` | Portfolio, sortable via `?sort=maturityDate\|principal&order=asc\|desc` | — |
| GET | `/deposits/:id` | Deposit detail | 404 |
| POST | `/deposits/:id/withdrawal-quote` | Premature withdrawal quote (10 min expiry) | 409 |
| POST | `/deposits/:id/withdraw` | Confirm withdrawal with `{ quoteId }` | 410 `QUOTE_EXPIRED` |
| GET | `/account` | Savings account balance | — |

## 4. Idempotency

Every mutating call above that moves money or creates a record **requires** an
`Idempotency-Key` header (any unique string, e.g. a UUID you generate once per
confirmation screen tap). Retrying the exact same key + route always returns the
original stored response — money is never moved twice. This is enforced server-side
in `src/middleware/idempotency.js`, backed by a SQLite table, so it survives restarts.

```bash
curl -X POST http://localhost:4000/goals/GOAL_ID/contributions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"amountPaise": 50000}'
```

## 5. Chaos switches (for testing loading/error/empty states)

Per the baseline NFRs, every screen must handle slow networks and server errors.
Trigger these on any request:

```bash
curl "http://localhost:4000/goals?chaos=slow"    # adds a 3s delay
curl "http://localhost:4000/goals?chaos=error"   # forces a 500
```

Or with a header: `-H "X-Chaos: slow"` / `-H "X-Chaos: error"`.

## 6. Financial maths

`src/utils/depositMath.js` is pure, dependency-free, and directly testable —
mirror its FD/RD formulas in your Flutter `DepositMath` class so client-side
estimates always match the server (per NFR: "rates always from the server,
never hard-coded").

- **FD:** quarterly-compounded, `A = P × (1 + r/4/100) ^ (4 × years)`
- **RD:** monthly instalments compounded quarterly at the applicable rate

## 7. Project structure

```
savesmart-api/
├── src/
│   ├── server.js              Express app, chaos middleware, error handler
│   ├── db/
│   │   ├── index.js           SQLite connection + schema (CREATE TABLE ...)
│   │   └── seed.js            Demo user, account, rate cards, sample goal
│   ├── middleware/
│   │   ├── auth.js            JWT sign + requireAuth
│   │   └── idempotency.js     Idempotency-Key enforcement
│   ├── routes/
│   │   ├── auth.js            /auth/login, /auth/register
│   │   ├── account.js         /account
│   │   ├── goals.js           /goals/**
│   │   └── deposits.js        /deposits/**
│   └── utils/
│       ├── apiError.js        ApiError class + { error: {...} } envelope
│       └── depositMath.js     FD/RD maturity formulas + rate lookup
└── savesmart.db                created on first run (gitignore this)
```
