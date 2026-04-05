/**
 * normalize.js — One-time script to reduce inflated inventory and
 * purchase data for a specific UID by 10x.
 *
 * Affected tables:
 *   inventory  → current_stock  / 10   (rounded down, min 0)
 *   purchases  → units_purchased / 10  (rounded down, min 1)
 *   transactions → units_sold / 10     (rounded down, min 1)
 *                  revenue / 10
 *                  profit  / 10
 *
 * Run once:  node normalize.js
 */

const Database = require('better-sqlite3');
const path = require('path');

const TARGET_UID = 'rXLAE0lyv8Z5v8EwdBdBi1t0kcz2';
const DIVISOR = 10;

const db = new Database(path.join(__dirname, 'shop.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// ── Before counts ──────────────────────────────────────────────────────────
const beforeInv = db.prepare(
  'SELECT COUNT(*) AS c, SUM(current_stock) AS total FROM inventory WHERE user_id = ?'
).get(TARGET_UID);

const beforePur = db.prepare(
  'SELECT COUNT(*) AS c, SUM(units_purchased) AS total FROM purchases WHERE user_id = ?'
).get(TARGET_UID);

const beforeTx = db.prepare(
  'SELECT COUNT(*) AS c, SUM(units_sold) AS totalUnits, SUM(revenue) AS totalRev FROM transactions WHERE user_id = ?'
).get(TARGET_UID);

console.log('\n📊 BEFORE normalization:');
console.log(`  inventory  → rows: ${beforeInv.c}, total stock: ${beforeInv.total}`);
console.log(`  purchases  → rows: ${beforePur.c}, total units: ${beforePur.total}`);
console.log(`  transactions → rows: ${beforeTx.c}, units: ${beforeTx.totalUnits}, revenue: ₹${Number(beforeTx.totalRev).toFixed(0)}`);

// ── Run in one atomic transaction ──────────────────────────────────────────
const normalize = db.transaction(() => {
  // 1. Inventory — divide stock by 10, floor, min 0
  db.prepare(`
    UPDATE inventory
    SET current_stock = MAX(0, CAST(current_stock / ? AS INTEGER)),
        updated_at    = datetime('now')
    WHERE user_id = ?
  `).run(DIVISOR, TARGET_UID);

  // 2. Purchases — divide units by 10, ceil to min 1
  db.prepare(`
    UPDATE purchases
    SET units_purchased = MAX(1, CAST(units_purchased / ? AS INTEGER))
    WHERE user_id = ?
  `).run(DIVISOR, TARGET_UID);

  // 3. Transactions — divide units_sold, revenue, profit by 10
  db.prepare(`
    UPDATE transactions
    SET units_sold = MAX(1, CAST(units_sold / ? AS INTEGER)),
        revenue    = ROUND(revenue / ?, 2),
        profit     = ROUND(profit  / ?, 2)
    WHERE user_id = ?
  `).run(DIVISOR, DIVISOR, DIVISOR, TARGET_UID);
});

normalize();

// ── After counts ───────────────────────────────────────────────────────────
const afterInv = db.prepare(
  'SELECT COUNT(*) AS c, SUM(current_stock) AS total FROM inventory WHERE user_id = ?'
).get(TARGET_UID);

const afterPur = db.prepare(
  'SELECT COUNT(*) AS c, SUM(units_purchased) AS total FROM purchases WHERE user_id = ?'
).get(TARGET_UID);

const afterTx = db.prepare(
  'SELECT COUNT(*) AS c, SUM(units_sold) AS totalUnits, SUM(revenue) AS totalRev FROM transactions WHERE user_id = ?'
).get(TARGET_UID);

console.log('\n✅ AFTER normalization:');
console.log(`  inventory  → rows: ${afterInv.c}, total stock: ${afterInv.total}`);
console.log(`  purchases  → rows: ${afterPur.c}, total units: ${afterPur.total}`);
console.log(`  transactions → rows: ${afterTx.c}, units: ${afterTx.totalUnits}, revenue: ₹${Number(afterTx.totalRev).toFixed(0)}`);

console.log('\n🎉 Normalization complete. Restart the backend server to reflect changes.');
db.close();
