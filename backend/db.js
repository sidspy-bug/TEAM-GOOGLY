const Database = require("better-sqlite3");
const path = require("path");

const dbPath = path.join(__dirname, "shop.db");
const db = new Database(dbPath);

// Enable WAL mode for better concurrent read performance
db.pragma("journal_mode = WAL");
db.pragma("foreign_keys = ON");

/* =====================
   SCHEMA CREATION
===================== */

db.exec(`
  -- User settings (onboarding, shop name, avatar, etc.)
  CREATE TABLE IF NOT EXISTS user_settings (
    uid TEXT PRIMARY KEY,
    shop_name TEXT DEFAULT 'My Shop',
    avatar_index INTEGER DEFAULT -1,
    onboarded INTEGER DEFAULT 0,
    language TEXT DEFAULT 'en',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  -- Products catalog
  CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    cost_price REAL NOT NULL CHECK(cost_price > 0),
    selling_price REAL NOT NULL CHECK(selling_price > 0),
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  -- Inventory stock levels
  CREATE TABLE IF NOT EXISTS inventory (
    product_id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    current_stock INTEGER DEFAULT 0,
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  );

  -- Sales transactions
  CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    product_id INTEGER NOT NULL,
    units_sold INTEGER NOT NULL CHECK(units_sold > 0),
    transaction_mode TEXT DEFAULT 'Cash',
    revenue REAL NOT NULL,
    profit REAL NOT NULL,
    transaction_date TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  );

  -- Purchase history (Restocks)
  CREATE TABLE IF NOT EXISTS purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    product_id INTEGER NOT NULL,
    units_purchased INTEGER NOT NULL CHECK(units_purchased > 0),
    cost_price REAL NOT NULL,
    gst REAL DEFAULT 0,
    purchase_date TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  );

  -- Indexes for faster queries
  CREATE INDEX IF NOT EXISTS idx_products_user ON products(user_id);
  CREATE INDEX IF NOT EXISTS idx_inventory_user ON inventory(user_id);
  CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
  CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date);
  CREATE INDEX IF NOT EXISTS idx_purchases_user ON purchases(user_id);
  CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases(purchase_date);
`);

console.log("✅ SQLite database initialized at:", dbPath);

// Migration: add language column to existing databases that predate this field
try {
  db.exec(`ALTER TABLE user_settings ADD COLUMN language TEXT DEFAULT 'en'`);
} catch (err) {
  // Ignore "duplicate column" errors; log anything unexpected
  if (!err.message || !err.message.includes('duplicate column')) {
    console.warn('Migration warning (language column):', err.message);
  }
}

module.exports = db;
