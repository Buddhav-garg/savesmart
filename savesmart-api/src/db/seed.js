const { v4: uuid } = require('uuid');
const db = require('./index');

function seed() {
  const now = new Date().toISOString();

  const existingUser = db.prepare('SELECT id FROM users WHERE phone = ?').get('9999999999');
  let userId;

  if (!existingUser) {
    userId = uuid();
    db.prepare(
      `INSERT INTO users (id, phone, name, pin, is_senior_citizen, created_at)
       VALUES (?, ?, ?, ?, ?, ?)`
    ).run(userId, '9999999999', 'Neha Sharma', '1234', 0, now);

    db.prepare(
      `INSERT INTO accounts (id, user_id, balance_paise, currency) VALUES (?, ?, ?, ?)`
    ).run(uuid(), userId, 25000000, 'INR'); // ₹2,50,000 demo balance

    console.log('Seeded demo user: phone 9999999999, PIN 1234, userId', userId);
  } else {
    userId = existingUser.id;
    console.log('Demo user already exists:', userId);
  }

  const rateCount = db.prepare('SELECT COUNT(*) AS c FROM rate_cards').get().c;
  if (rateCount === 0) {
    const rates = [
      // kind, minDays, maxDays, ratePct
      ['FD', 7, 45, 4.5],
      ['FD', 46, 90, 5.0],
      ['FD', 91, 180, 5.5],
      ['FD', 181, 364, 6.25],
      ['FD', 365, 729, 6.75],
      ['FD', 730, 1825, 7.0],
      ['FD', 1826, 3650, 7.1],
      ['RD', 182, 364, 6.0],
      ['RD', 365, 729, 6.5],
      ['RD', 730, 1825, 6.75],
      ['RD', 1826, 3650, 6.85],
    ];
    const stmt = db.prepare(
      `INSERT INTO rate_cards (id, kind, min_tenure_days, max_tenure_days, rate_pct, senior_bonus_pct)
       VALUES (?, ?, ?, ?, ?, 0.5)`
    );
    const insertMany = db.transaction((rows) => {
      for (const r of rows) stmt.run(uuid(), ...r);
    });
    insertMany(rates);
    console.log('Seeded rate cards.');
  }

  // one sample goal so GET /goals returns something on a fresh clone
  const goalCount = db.prepare('SELECT COUNT(*) AS c FROM goals WHERE user_id = ?').get(userId).c;
  if (goalCount === 0) {
    const goalId = uuid();
    db.prepare(
      `INSERT INTO goals (id, user_id, name, icon, target_paise, saved_paise, target_date, status, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'active', ?, ?)`
    ).run(goalId, userId, 'New Bike', 'two_wheeler', 8000000, 1500000, '2027-06-01', now, now);
    console.log('Seeded sample goal:', goalId);
  }

  return userId;
}

if (require.main === module) {
  const id = seed();
  console.log('Done. Demo userId =', id);
  process.exit(0);
}

module.exports = seed;
