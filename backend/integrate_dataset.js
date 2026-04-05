/**
 * integrate_dataset.js — Loads generated_dataset.json into shop.db
 *
 * Steps:
 *   1. Delete all existing data for the target UID
 *   2. Insert new products (upsert by ID)
 *   3. Insert transactions and purchases
 *   4. Rebuild inventory from net purchases - sales
 *
 * Run: node integrate_dataset.js
 */

const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const TARGET_UID = 'rXLAE0lyv8Z5v8EwdBdBi1t0kcz2';
const db = new Database(path.join(__dirname, 'shop.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = OFF'); // Temporarily off for clean wipe

const dataPath = path.join(__dirname, 'generated_dataset.json');
const dataset = JSON.parse(fs.readFileSync(dataPath, 'utf-8'));

console.log(`\n📦 Loading dataset: ${dataset.transactions.length} transactions, ${dataset.purchases.length} purchases, ${dataset.products.length} products`);

// ── STEP 0: BEFORE COUNTS ────────────────────────────────────────────────
const beforeProducts = db.prepare('SELECT COUNT(*) AS c FROM products WHERE user_id = ?').get(TARGET_UID);
const beforeTx = db.prepare('SELECT COUNT(*) AS c FROM transactions WHERE user_id = ?').get(TARGET_UID);
const beforePur = db.prepare('SELECT COUNT(*) AS c FROM purchases WHERE user_id = ?').get(TARGET_UID);
const beforeInv = db.prepare('SELECT COUNT(*) AS c FROM inventory WHERE user_id = ?').get(TARGET_UID);

console.log(`\n📊 BEFORE:`);
console.log(`  Products: ${beforeProducts.c}, Transactions: ${beforeTx.c}, Purchases: ${beforePur.c}, Inventory: ${beforeInv.c}`);

// ── STEP 1: WIPE EXISTING DATA FOR THIS UID ──────────────────────────────
const wipe = db.transaction(() => {
  db.prepare('DELETE FROM transactions WHERE user_id = ?').run(TARGET_UID);
  db.prepare('DELETE FROM purchases WHERE user_id = ?').run(TARGET_UID);
  db.prepare('DELETE FROM inventory WHERE user_id = ?').run(TARGET_UID);
  db.prepare('DELETE FROM products WHERE user_id = ?').run(TARGET_UID);
});
wipe();
console.log('🗑️  Wiped existing data for UID');

// ── STEP 2: INSERT PRODUCTS ──────────────────────────────────────────────
const insertProduct = db.prepare(`
  INSERT INTO products (id, user_id, product_name, category, cost_price, selling_price, created_at)
  VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
`);

const insertProducts = db.transaction(() => {
  for (const p of dataset.products) {
    insertProduct.run(p.id, TARGET_UID, p.product_name, p.category, p.cost_price, p.selling_price);
  }
});
insertProducts();
console.log(`✅ Inserted ${dataset.products.length} products`);

// ── STEP 3: INSERT PURCHASES ─────────────────────────────────────────────
const insertPurchase = db.prepare(`
  INSERT INTO purchases (user_id, product_id, units_purchased, cost_price, gst, purchase_date)
  VALUES (?, ?, ?, ?, ?, ?)
`);

const insertPurchases = db.transaction(() => {
  for (const pur of dataset.purchases) {
    insertPurchase.run(
      TARGET_UID,
      pur.product_id,
      pur.units_purchased,
      pur.cost_price,
      pur.gst,
      pur.purchase_date
    );
  }
});
insertPurchases();
console.log(`✅ Inserted ${dataset.purchases.length} purchases`);

// ── STEP 4: INSERT TRANSACTIONS ──────────────────────────────────────────
const insertTransaction = db.prepare(`
  INSERT INTO transactions (user_id, product_id, units_sold, transaction_mode, revenue, profit, transaction_date)
  VALUES (?, ?, ?, ?, ?, ?, ?)
`);

const insertTransactions = db.transaction(() => {
  for (const tx of dataset.transactions) {
    insertTransaction.run(
      TARGET_UID,
      tx.product_id,
      tx.units_sold,
      tx.transaction_mode,
      tx.revenue,
      tx.profit,
      tx.transaction_date
    );
  }
});
insertTransactions();
console.log(`✅ Inserted ${dataset.transactions.length} transactions`);

// ── STEP 5: REBUILD INVENTORY ────────────────────────────────────────────
// net stock = total purchased - total sold
const insertInventory = db.prepare(`
  INSERT INTO inventory (product_id, user_id, current_stock, updated_at)
  VALUES (?, ?, ?, datetime('now'))
`);

const rebuildInventory = db.transaction(() => {
  for (const p of dataset.products) {
    const purchased = db.prepare(
      'SELECT COALESCE(SUM(units_purchased), 0) AS total FROM purchases WHERE user_id = ? AND product_id = ?'
    ).get(TARGET_UID, p.id);

    const sold = db.prepare(
      'SELECT COALESCE(SUM(units_sold), 0) AS total FROM transactions WHERE user_id = ? AND product_id = ?'
    ).get(TARGET_UID, p.id);

    const currentStock = Math.max(0, purchased.total - sold.total);
    insertInventory.run(p.id, TARGET_UID, currentStock);
  }
});
rebuildInventory();
console.log(`✅ Rebuilt inventory for ${dataset.products.length} products`);

// ── STEP 6: VERIFY ───────────────────────────────────────────────────────
db.pragma('foreign_keys = ON');

const afterProducts = db.prepare('SELECT COUNT(*) AS c FROM products WHERE user_id = ?').get(TARGET_UID);
const afterTx = db.prepare('SELECT COUNT(*) AS c FROM transactions WHERE user_id = ?').get(TARGET_UID);
const afterPur = db.prepare('SELECT COUNT(*) AS c FROM purchases WHERE user_id = ?').get(TARGET_UID);
const afterInv = db.prepare('SELECT COUNT(*) AS c FROM inventory WHERE user_id = ?').get(TARGET_UID);
const totalRev = db.prepare('SELECT COALESCE(SUM(revenue), 0) AS total FROM transactions WHERE user_id = ?').get(TARGET_UID);
const totalProfit = db.prepare('SELECT COALESCE(SUM(profit), 0) AS total FROM transactions WHERE user_id = ?').get(TARGET_UID);
const lowStock = db.prepare('SELECT COUNT(*) AS c FROM inventory WHERE user_id = ? AND current_stock < 5').get(TARGET_UID);

console.log(`\n📊 AFTER:`);
console.log(`  Products:     ${afterProducts.c}`);
console.log(`  Transactions: ${afterTx.c}`);
console.log(`  Purchases:    ${afterPur.c}`);
console.log(`  Inventory:    ${afterInv.c}`);
console.log(`  Total Revenue: ₹${totalRev.total.toLocaleString()}`);
console.log(`  Total Profit:  ₹${totalProfit.total.toLocaleString()}`);
console.log(`  Low Stock Items: ${lowStock.c}`);

// Cross-check
const expectedRev = dataset.overall_metrics.total_revenue;
const match = Math.abs(totalRev.total - expectedRev) < 1;
console.log(`\n🔍 Revenue cross-check: DB=₹${totalRev.total.toFixed(0)} vs Dataset=₹${expectedRev} ${match ? '✅' : '❌'}`);

console.log('\n🎉 Integration complete! Restart the backend server to see changes.');
db.close();
