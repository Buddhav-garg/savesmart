const db = require('../db');

function daysBetween(d1, d2) {
  return Math.round((new Date(d2) - new Date(d1)) / 86400000);
}

function addDays(dateStr, days) {
  const d = new Date(dateStr);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Find the applicable rate card row for a kind + tenure. */
function findRate(kind, tenureDays) {
  const row = db
    .prepare(
      `SELECT * FROM rate_cards
       WHERE kind = ? AND min_tenure_days <= ? AND max_tenure_days >= ?
       ORDER BY rate_pct DESC LIMIT 1`
    )
    .get(kind, tenureDays, tenureDays);
  return row || null;
}

/**
 * Quarterly-compounded FD maturity, matching the standard bank formula:
 * A = P * (1 + r/4/100) ^ (4 * years), rounded to the nearest paisa.
 * years = tenureDays / 365 (as used across the reference bank calculators).
 */
function fdMaturity(principalPaise, ratePct, tenureDays, isSenior = false) {
  const effectiveRate = ratePct + (isSenior ? 0.5 : 0);
  const years = tenureDays / 365;
  const n = 4; // quarterly
  const amount = principalPaise * Math.pow(1 + effectiveRate / n / 100, n * years);
  return Math.round(amount);
}

/**
 * RD maturity using the standard monthly-compounding RD formula:
 * M = R * [ ( (1+i)^n - 1 ) / (1 - (1+i)^(-1/3)) ], i = r/400 (quarterly rate/4 per compounding quarter,
 * approximated monthly per common bank RD convention), n = number of installments.
 * For simplicity and unit-testability we compute via monthly compounding at rate/12/100 per installment.
 */
function rdMaturity(installmentPaise, ratePct, months, isSenior = false) {
  const effectiveRate = ratePct + (isSenior ? 0.5 : 0);
  const i = effectiveRate / 400; // quarterly rate fraction
  let maturity = 0;
  for (let month = 1; month <= months; month++) {
    const quartersRemaining = (months - month + 1) / 3;
    maturity += installmentPaise * Math.pow(1 + i, quartersRemaining);
  }
  return Math.round(maturity);
}

module.exports = { daysBetween, addDays, findRate, fdMaturity, rdMaturity };
