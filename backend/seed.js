#!/usr/bin/env node
/**
 * backend/seed.js — Seed diverse products & transactions into SQLite.
 *
 * Usage:  SEED_UID=<firebase-uid> node backend/seed.js
 *
 * If SEED_UID is not set, it will try to read the first existing UID
 * from the user_settings table. If none exists, it uses "seed-user".
 */

const db = require("./db");

const uid = process.env.SEED_UID
  || (() => {
    const row = db.prepare("SELECT uid FROM user_settings LIMIT 1").get();
    return row ? row.uid : "seed-user";
  })();

console.log(`🌱 Seeding data for UID: ${uid}`);

// Check if products already exist for this user
const existingCount = db.prepare("SELECT COUNT(*) AS count FROM products WHERE user_id = ?").get(uid);
if (existingCount.count > 0) {
  console.log(`⚠️  User already has ${existingCount.count} product(s). Skipping seed to avoid duplicates.`);
  console.log(`   To force re-seed, delete existing data first: DELETE FROM products WHERE user_id = '${uid}';`);
  process.exit(0);
}

// ── Products: 15 diverse items across categories ────────────────────────
const products = [
  // Grocery
  { name: "Tata Salt (1kg)", category: "Grocery", cost: 22, sell: 26, stock: 150 },
  { name: "Sugar (1kg)", category: "Grocery", cost: 38, sell: 48, stock: 120 },
  { name: "Rice (5kg)", category: "Grocery", cost: 245, sell: 310, stock: 40 },
  { name: "Cooking Oil (1L)", category: "Grocery", cost: 140, sell: 180, stock: 4 }, // LOW

  // Dairy
  { name: "Amul Butter (200g)", category: "Dairy", cost: 52, sell: 62, stock: 3 },   // LOW
  { name: "Milk (1L)", category: "Dairy", cost: 26, sell: 32, stock: 30 },

  // Beverages
  { name: "Tea (250g)", category: "Beverages", cost: 85, sell: 110, stock: 80 },
  { name: "Coffee (200g)", category: "Beverages", cost: 120, sell: 165, stock: 25 },
  { name: "Mango Juice (1L)", category: "Beverages", cost: 55, sell: 75, stock: 45 },

  // Snacks
  { name: "Samosa (1pc)", category: "Snacks", cost: 6, sell: 15, stock: 0 },        // OUT
  { name: "Lays Chips", category: "Snacks", cost: 18, sell: 30, stock: 95 },
  { name: "Maggi Noodles", category: "Snacks", cost: 10, sell: 14, stock: 200 },

  // Personal Care
  { name: "Dove Soap", category: "Personal Care", cost: 38, sell: 55, stock: 35 },
  { name: "Head & Shoulders", category: "Personal Care", cost: 175, sell: 240, stock: 2 }, // LOW

  // Stationery
  { name: "Classmate Notebook", category: "Stationery", cost: 28, sell: 45, stock: 65 },
];

const insertProduct = db.prepare(
  "INSERT INTO products (user_id, product_name, category, cost_price, selling_price) VALUES (?, ?, ?, ?, ?)"
);
const insertInventory = db.prepare(
  "INSERT OR REPLACE INTO inventory (product_id, user_id, current_stock) VALUES (?, ?, ?)"
);

const productIds = [];

const seedProducts = db.transaction(() => {
  for (const p of products) {
    const result = insertProduct.run(uid, p.name, p.category, p.cost, p.sell);
    const id = result.lastInsertRowid;
    productIds.push(id);
    insertInventory.run(id, uid, p.stock);
  }
});

seedProducts();
console.log(`✅ Inserted ${products.length} products with inventory`);

// ── Transactions: 25 diverse entries over last 14 days ──────────────────
const modes = ["UPI", "Cash", "Card"];
const txns = [
  // High sellers
  { idx: 0, units: 8, mode: "UPI", daysAgo: 0 },   // Salt
  { idx: 0, units: 5, mode: "Cash", daysAgo: 1 },
  { idx: 1, units: 6, mode: "UPI", daysAgo: 0 },    // Sugar
  { idx: 1, units: 4, mode: "Card", daysAgo: 2 },
  { idx: 2, units: 3, mode: "Cash", daysAgo: 1 },   // Rice
  { idx: 5, units: 10, mode: "UPI", daysAgo: 0 },   // Milk
  { idx: 5, units: 8, mode: "Cash", daysAgo: 1 },
  { idx: 6, units: 5, mode: "UPI", daysAgo: 0 },    // Tea
  { idx: 6, units: 7, mode: "Cash", daysAgo: 3 },
  { idx: 6, units: 4, mode: "UPI", daysAgo: 5 },
  { idx: 7, units: 2, mode: "Card", daysAgo: 1 },   // Coffee
  { idx: 8, units: 3, mode: "UPI", daysAgo: 2 },    // Mango Juice
  { idx: 10, units: 6, mode: "Cash", daysAgo: 0 },   // Chips
  { idx: 10, units: 4, mode: "UPI", daysAgo: 4 },
  { idx: 11, units: 12, mode: "Cash", daysAgo: 0 },  // Maggi
  { idx: 11, units: 8, mode: "UPI", daysAgo: 1 },
  { idx: 11, units: 10, mode: "Cash", daysAgo: 3 },
  { idx: 12, units: 3, mode: "Card", daysAgo: 2 },   // Soap
  { idx: 14, units: 4, mode: "Cash", daysAgo: 1 },   // Notebook
  { idx: 14, units: 2, mode: "UPI", daysAgo: 6 },
  // Low sellers
  { idx: 3, units: 1, mode: "Cash", daysAgo: 5 },   // Cooking Oil
  { idx: 4, units: 1, mode: "UPI", daysAgo: 7 },    // Butter
  { idx: 9, units: 5, mode: "Cash", daysAgo: 0 },   // Samosa (high qty)
  { idx: 13, units: 1, mode: "Card", daysAgo: 10 },  // Shampoo
  { idx: 7, units: 3, mode: "UPI", daysAgo: 8 },    // Coffee again
];

const insertTxn = db.prepare(
  "INSERT INTO transactions (user_id, product_id, units_sold, transaction_mode, revenue, profit, transaction_date) VALUES (?, ?, ?, ?, ?, ?, ?)"
);
const decrementStock = db.prepare(
  "UPDATE inventory SET current_stock = MAX(current_stock - ?, 0), updated_at = datetime('now') WHERE product_id = ?"
);

const seedTxns = db.transaction(() => {
  for (const t of txns) {
    const productId = productIds[t.idx];
    const product = products[t.idx];
    const revenue = t.units * product.sell;
    const profit = t.units * (product.sell - product.cost);
    const date = new Date();
    date.setDate(date.getDate() - t.daysAgo);
    date.setHours(Math.floor(Math.random() * 12) + 8); // 8am-8pm
    const dateStr = date.toISOString().replace("T", " ").slice(0, 19);

    insertTxn.run(uid, productId, t.units, t.mode, revenue, profit, dateStr);
    decrementStock.run(t.units, productId);
  }
});

seedTxns();
console.log(`✅ Inserted ${txns.length} transactions`);

// Ensure user_settings row exists
const userRow = db.prepare("SELECT uid FROM user_settings WHERE uid = ?").get(uid);
if (!userRow) {
  db.prepare(
    "INSERT INTO user_settings (uid, shop_name, onboarded) VALUES (?, 'Seed Demo Shop', 1)"
  ).run(uid);
  console.log(`✅ Created user_settings for ${uid}`);
}

console.log("🎉 Seed complete!");
