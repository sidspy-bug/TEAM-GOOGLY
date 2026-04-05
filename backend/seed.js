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

const uids = db.prepare("SELECT uid FROM user_settings").all().map(r => r.uid);
if (uids.length === 0) uids.push("seed-user");

console.log(`🌱 Seeding data for UIDs: ${uids.join(", ")}`);

for (const uid of uids) {
  // Force clear existing data for this user to ensure a fresh demo state
  db.prepare("DELETE FROM transactions WHERE user_id = ?").run(uid);
  db.prepare("DELETE FROM inventory WHERE user_id = ?").run(uid);
  db.prepare("DELETE FROM products WHERE user_id = ?").run(uid);
  console.log(`🧹 Cleared existing data for UID: ${uid}`);

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
  "INSERT INTO products (user_id, product_name, category, cost_price, selling_price, created_at) VALUES (?, ?, ?, ?, ?, ?)"
);
const insertInventory = db.prepare(
  "INSERT OR REPLACE INTO inventory (product_id, user_id, current_stock, updated_at) VALUES (?, ?, ?, ?)"
);

const productIds = [];

const seedProducts = db.transaction(() => {
  for (const p of products) {
    const daysAgo = Math.floor(Math.random() * 90); // Scatter purchase events over 90 days
    const date = new Date();
    date.setDate(date.getDate() - daysAgo);
    date.setHours(Math.floor(Math.random() * 12) + 8);
    const dateStr = date.toISOString().replace("T", " ").slice(0, 19);

    const result = insertProduct.run(uid, p.name, p.category, p.cost, p.sell, dateStr);
    const id = result.lastInsertRowid;
    productIds.push(id);
    insertInventory.run(id, uid, 0, dateStr); // Start at 0!
  }
});

seedProducts();
console.log(`✅ Inserted ${products.length} products`);

const insertTxn = db.prepare(
  "INSERT INTO transactions (user_id, product_id, units_sold, transaction_mode, revenue, profit, transaction_date) VALUES (?, ?, ?, ?, ?, ?, ?)"
);
const insertPurchase = db.prepare(
  "INSERT INTO purchases (user_id, product_id, units_purchased, cost_price, gst, purchase_date) VALUES (?, ?, ?, ?, ?, ?)"
);
const addStock = db.prepare(
  "UPDATE inventory SET current_stock = current_stock + ?, updated_at = datetime('now') WHERE product_id = ?"
);
const decrementStock = db.prepare(
  "UPDATE inventory SET current_stock = MAX(current_stock - ?, 0), updated_at = datetime('now') WHERE product_id = ?"
);

let txnCounter = 0;
let purchaseCounter = 0;

const seedEvents = db.transaction(() => {
  const currentStocks = new Array(products.length).fill(0);

  // Loop precisely from 90 days ago (-90) up to today (0)
  for (let daysAgo = 90; daysAgo >= 0; daysAgo--) {
    const date = new Date();
    date.setDate(date.getDate() - daysAgo);
    
    // 1. Restock Check: Buy Inventory if Low!
    for (let i = 0; i < products.length; i++) {
       // More aggressive restocking: if stock < 20 or 30% chance of random restock
       if (currentStocks[i] < 20 || Math.random() < 0.05) {
          const refillQty = Math.floor(Math.random() * 100) + 50; // buy 50-150 units
          const gst = (products[i].cost * 0.05).toFixed(2); // 5% GST example
          
          date.setHours(9); // 9am morning restocks
          const pDateStr = date.toISOString().replace("T", " ").slice(0, 19);

          insertPurchase.run(uid, productIds[i], refillQty, products[i].cost, gst, pDateStr);
          addStock.run(refillQty, productIds[i]);
          currentStocks[i] += refillQty;
          purchaseCounter++;
       }
    }

    // 2. Generate random sales (1 to 8 txns per day for more activity)
    const txnsToday = Math.floor(Math.random() * 8) + 1; 
    for (let i = 0; i < txnsToday; i++) {
      let pIdx = Math.floor(Math.random() * products.length);
      // Bias towards first few products (top sellers)
      if (Math.random() > 0.4) pIdx = Math.floor(Math.random() * 5); 
      
      const units = Math.floor(Math.random() * 5) + 1;
      if (currentStocks[pIdx] >= units) {
         const product = products[pIdx];
         const mode = ["UPI", "Cash", "Card"][Math.floor(Math.random() * 3)];
         const revenue = units * product.sell;
         const profit = units * (product.sell - product.cost);

         date.setHours(Math.floor(Math.random() * 10) + 10); // 10am-8pm window
         const tDateStr = date.toISOString().replace("T", " ").slice(0, 19);

         insertTxn.run(uid, productIds[pIdx], units, mode, revenue, profit, tDateStr);
         decrementStock.run(units, productIds[pIdx]);
         currentStocks[pIdx] -= units;
         txnCounter++;
      }
    }
  }
});

seedEvents();
console.log(`✅ Inserted ${purchaseCounter} explicit historical Purchases natively supporting ${txnCounter} Sales`);

// Ensure user_settings row exists
  const userRow = db.prepare("SELECT uid FROM user_settings WHERE uid = ?").get(uid);
  if (!userRow) {
    db.prepare(
      "INSERT INTO user_settings (uid, shop_name, onboarded) VALUES (?, 'Seed Demo Shop', 1)"
    ).run(uid);
    console.log(`✅ Created user_settings for ${uid}`);
  }
} // Close for-of loop

console.log("🎉 All seeds complete!");
