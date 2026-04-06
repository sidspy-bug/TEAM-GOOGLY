const express = require("express");
const admin = require("firebase-admin");
const cors = require("cors");
const { createWorker } = require("tesseract.js");

const verifyToken = require("./middleware/auth");
const db = require("./db"); // SQLite database

// Firebase Admin — only for auth token verification
let firebaseInitialized = false;
try {
  const serviceAccount = require("./serviceAccountKey.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  firebaseInitialized = true;
  console.log("✅ Firebase Admin initialized (auth verification enabled)");
} catch (e) {
  console.warn("⚠️  No serviceAccountKey.json found — running without Firebase token verification.");
  console.warn("   Auth endpoints will accept any request. Add the key for production use.");
}

const app = express();

app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));

const axios = require("axios");
const LOW_STOCK_THRESHOLD = 10;

// Ollama config
const OLLAMA_URL = process.env.OLLAMA_URL || "http://localhost:11434";
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || "qwen2.5:7b";

/* =====================
   BASIC ROUTES
===================== */

app.get("/", (req, res) => {
  res.send("Backend connected with SQLite ✅");
});

app.get("/auth/test", verifyToken, (req, res) => {
  res.json({
    message: "User authenticated successfully ✅",
    uid: req.user.uid,
    email: req.user.email,
  });
});

/* =====================
   USER SETTINGS MODULE
===================== */

// Get user settings (onboarding state, shop name, avatar, language)
app.get("/user/settings", verifyToken, (req, res) => {
  const uid = req.user.uid;
  let row = db.prepare("SELECT * FROM user_settings WHERE uid = ?").get(uid);

  if (!row) {
    db.prepare(
      "INSERT INTO user_settings (uid, shop_name, avatar_index, onboarded, language) VALUES (?, 'My Shop', -1, 0, 'en')"
    ).run(uid);
    row = db.prepare("SELECT * FROM user_settings WHERE uid = ?").get(uid);
  }

  res.json({
    shopName: row.shop_name,
    avatarIndex: row.avatar_index,
    onboarded: row.onboarded === 1,
    language: row.language || 'en',
  });
});

// Update user settings
app.put("/user/settings", verifyToken, (req, res) => {
  const uid = req.user.uid;
  const { shopName, avatarIndex, onboarded, language } = req.body;

  const validLanguages = ['en', 'hi', 'ta', 'mr'];

  const existing = db.prepare("SELECT uid FROM user_settings WHERE uid = ?").get(uid);
  if (!existing) {
    db.prepare(
      "INSERT INTO user_settings (uid, shop_name, avatar_index, onboarded, language) VALUES (?, ?, ?, ?, ?)"
    ).run(uid, shopName || "My Shop", avatarIndex ?? -1, onboarded ? 1 : 0, validLanguages.includes(language) ? language : 'en');
  } else {
    const updates = [];
    const params = [];
    if (shopName !== undefined) { updates.push("shop_name = ?"); params.push(shopName); }
    if (avatarIndex !== undefined) { updates.push("avatar_index = ?"); params.push(avatarIndex); }
    if (onboarded !== undefined) { updates.push("onboarded = ?"); params.push(onboarded ? 1 : 0); }
    if (language !== undefined && validLanguages.includes(language)) {
      updates.push("language = ?");
      params.push(language);
    }
    updates.push("updated_at = datetime('now')");
    params.push(uid);
    db.prepare(`UPDATE user_settings SET ${updates.join(", ")} WHERE uid = ?`).run(...params);
  }

  res.json({ message: "Settings updated ✅" });
});

/* =====================
   PRODUCT MODULE
===================== */

// ➕ Add Product
app.post("/products/add", verifyToken, (req, res) => {
  try {
    const { productName, category, costPrice, sellingPrice } = req.body;

    if (!productName || !category) {
      return res.status(400).json({ error: "Product name & category required" });
    }
    if (costPrice <= 0 || sellingPrice <= 0) {
      return res.status(400).json({ error: "Prices must be > 0" });
    }

    const result = db.prepare(
      "INSERT INTO products (user_id, product_name, category, cost_price, selling_price) VALUES (?, ?, ?, ?, ?)"
    ).run(req.user.uid, productName, category, costPrice, sellingPrice);

    res.json({ message: "Product added successfully ✅", id: result.lastInsertRowid });
  } catch (err) {
    console.error("Product add error:", err);
    res.status(500).json({ error: "Product add failed" });
  }
});

// 📋 List Products
app.get("/products/list", verifyToken, (req, res) => {
  const products = db.prepare(
    "SELECT id, product_name AS productName, category, cost_price AS costPrice, selling_price AS sellingPrice, created_at AS createdAt FROM products WHERE user_id = ? ORDER BY created_at DESC"
  ).all(req.user.uid);
  res.json(products);
});

// 📂 List Products by Category
app.get("/products/category/:category", verifyToken, (req, res) => {
  const products = db.prepare(
    "SELECT id, product_name AS productName, category, cost_price AS costPrice, selling_price AS sellingPrice FROM products WHERE user_id = ? AND category = ?"
  ).all(req.user.uid, req.params.category);
  res.json(products);
});

// ✏ Update Product
app.put("/products/update/:id", verifyToken, (req, res) => {
  try {
    const { productName, category, costPrice, sellingPrice } = req.body;

    const updates = [];
    const params = [];
    if (productName) { updates.push("product_name = ?"); params.push(productName); }
    if (category) { updates.push("category = ?"); params.push(category); }
    if (costPrice) { updates.push("cost_price = ?"); params.push(costPrice); }
    if (sellingPrice) { updates.push("selling_price = ?"); params.push(sellingPrice); }
    updates.push("updated_at = datetime('now')");
    params.push(req.params.id);

    db.prepare(`UPDATE products SET ${updates.join(", ")} WHERE id = ?`).run(...params);
    res.json({ message: "Product updated successfully ✅" });
  } catch (err) {
    console.error("Product update error:", err);
    res.status(500).json({ error: "Update failed" });
  }
});

// 🗑 Delete Product
app.delete("/products/delete/:id", verifyToken, (req, res) => {
  try {
    db.prepare("DELETE FROM products WHERE id = ? AND user_id = ?").run(req.params.id, req.user.uid);
    res.json({ message: "Product deleted ✅" });
  } catch (err) {
    res.status(500).json({ error: "Delete failed" });
  }
});

/* =====================
   INVENTORY MODULE
===================== */

// ➕ Add / Update Stock (and log as a Purchase)
app.post("/inventory/add", verifyToken, (req, res) => {
  try {
    const { productId, stockAdded, gst = 0 } = req.body;

    if (!productId || stockAdded <= 0) {
      return res.status(400).json({ error: "Invalid productId or stockAdded" });
    }

    const product = db.prepare("SELECT cost_price FROM products WHERE id = ? AND user_id = ?").get(productId, req.user.uid);
    if (!product) {
      return res.status(404).json({ error: "Product not found" });
    }

    // 1. Log purchase
    db.prepare(
      "INSERT INTO purchases (user_id, product_id, units_purchased, cost_price, gst) VALUES (?, ?, ?, ?, ?)"
    ).run(req.user.uid, productId, stockAdded, product.cost_price, gst);

    // 2. Update inventory
    const existing = db.prepare("SELECT current_stock FROM inventory WHERE product_id = ?").get(productId);

    if (!existing) {
      db.prepare(
        "INSERT INTO inventory (product_id, user_id, current_stock) VALUES (?, ?, ?)"
      ).run(productId, req.user.uid, stockAdded);
    } else {
      db.prepare(
        "UPDATE inventory SET current_stock = current_stock + ?, updated_at = datetime('now') WHERE product_id = ?"
      ).run(stockAdded, productId);
    }

    res.json({ message: "Stock updated securely mapped to Purchases ✅" });
  } catch (err) {
    console.error("Stock update error:", err);
    res.status(500).json({ error: "Stock update failed" });
  }
});

// 📜 Purchase History
app.get("/purchases/history", verifyToken, (req, res) => {
  const history = db.prepare(`
    SELECT pur.id, pur.product_id AS productId, pur.units_purchased AS quantity, 
           pur.cost_price AS costPrice, pur.gst, pur.purchase_date AS purchaseDate,
           p.product_name AS productName, p.category, p.selling_price AS sellingPrice
    FROM purchases pur
    JOIN products p ON p.id = pur.product_id
    WHERE pur.user_id = ?
    ORDER BY pur.purchase_date DESC
  `).all(req.user.uid);
  res.json(history);
});

// 📦 Inventory Status
app.get("/inventory/status", verifyToken, (req, res) => {
  const rows = db.prepare(`
    SELECT i.product_id AS productId, i.current_stock AS currentStock, i.updated_at AS updatedAt,
           p.product_name AS productName, p.category
    FROM inventory i
    JOIN products p ON p.id = i.product_id
    WHERE i.user_id = ?
    ORDER BY p.product_name
  `).all(req.user.uid);

  const stock = rows.map((row) => {
    let status = "Normal";
    if (row.currentStock === 0) status = "Out of Stock";
    else if (row.currentStock < LOW_STOCK_THRESHOLD) status = "Low";
    return { ...row, status };
  });

  res.json(stock);
});

// 📦 Inventory Check
app.get("/inventory", verifyToken, (req, res) => {
  const uid = req.user.uid;
  const rows = db.prepare("SELECT product_id AS productId, current_stock AS currentStock FROM inventory WHERE user_id = ?").all(uid);
  res.json(rows);
});

// 🏷 Products Listing
app.get("/products", verifyToken, (req, res) => {
  const uid = req.user.uid;
  const rows = db.prepare("SELECT id, product_name AS productName, category, cost_price AS costPrice, selling_price AS sellingPrice FROM products WHERE user_id = ?").all(uid);
  res.json(rows);
});

/* =====================
   TRANSACTIONS MODULE
===================== */

// 🛒 Sell Product
app.post("/transactions/sell", verifyToken, (req, res) => {
  try {
    const { productId, unitsSold, transactionMode } = req.body;

    if (!productId || unitsSold <= 0) {
      return res.status(400).json({ error: "Invalid productId or unitsSold" });
    }

    const product = db.prepare("SELECT id, product_name AS productName, category, cost_price AS costPrice, selling_price AS sellingPrice FROM products WHERE id = ?").get(productId);
    const inventory = db.prepare("SELECT product_id AS productId, current_stock AS currentStock FROM inventory WHERE product_id = ?").get(productId);

    if (!product || !inventory) {
      return res.status(404).json({ error: "Product or inventory not found" });
    }

    if (inventory.current_stock < unitsSold) {
      return res.status(400).json({ error: "Insufficient stock" });
    }

    const revenue = unitsSold * product.selling_price;
    const profit = unitsSold * (product.selling_price - product.cost_price);

    // Atomic transaction
    const sellTransaction = db.transaction(() => {
      db.prepare(
        "UPDATE inventory SET current_stock = current_stock - ?, updated_at = datetime('now') WHERE product_id = ?"
      ).run(unitsSold, productId);

      db.prepare(
        "INSERT INTO transactions (user_id, product_id, units_sold, transaction_mode, revenue, profit) VALUES (?, ?, ?, ?, ?, ?)"
      ).run(req.user.uid, productId, unitsSold, transactionMode || "Cash", revenue, profit);
    });

    sellTransaction();

    res.json({ message: "Transaction successful ✅", revenue, profit });
  } catch (err) {
    console.error("Transaction error:", err);
    res.status(500).json({ error: "Transaction failed" });
  }
});

// 📜 Transaction History
app.get("/transactions/history", verifyToken, (req, res) => {
  const rows = db.prepare(`
    SELECT t.id, t.product_id AS productId, t.units_sold AS unitsSold,
           t.transaction_mode AS transactionMode, t.revenue, t.profit,
           t.transaction_date AS transactionDate,
           p.product_name AS productName, p.category
    FROM transactions t
    JOIN products p ON p.id = t.product_id
    WHERE t.user_id = ?
    ORDER BY t.transaction_date DESC
    LIMIT 500
  `).all(req.user.uid);

  res.json(rows);
});

// 📊 Dashboard Summary (used by Flutter getDashboardSummary)
app.get("/dashboard/summary", verifyToken, (req, res) => {
  const uid = req.user.uid;

  const today = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND date(transaction_date) = date('now')
  `).get(uid);

  const monthly = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit,
           COALESCE(SUM(units_sold), 0) AS unitsSold, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND strftime('%Y-%m', transaction_date) = strftime('%Y-%m', 'now')
  `).get(uid);

  const lowStockCountRes = db.prepare(
    "SELECT COUNT(*) AS count FROM inventory WHERE user_id = ? AND current_stock < ?"
  ).get(uid, LOW_STOCK_THRESHOLD);
  const count = lowStockCountRes.count;
  
  console.log(`🔍 [DASHBOARD] Summary Request for ${uid}: lowStockCount=${count} (Threshold=${LOW_STOCK_THRESHOLD})`);

  res.json({
    totalRevenue: monthly.revenue,
    totalProfit: monthly.profit,
    totalTransactions: monthly.count,
    unitsSold: monthly.unitsSold,
    dailyRevenue: today.revenue,
    dailyProfit: today.profit,
    lowStockCount: count,
  });
});

/* =====================
   ANALYTICS MODULE
===================== */

// 📊 Daily Analytics
app.get("/analytics/daily", verifyToken, (req, res) => {
  const row = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS dailyRevenue,
           COALESCE(SUM(profit), 0) AS dailyProfit,
           COUNT(*) AS totalTransactions
    FROM transactions
    WHERE user_id = ? AND date(transaction_date) = date('now')
  `).get(req.user.uid);

  res.json(row);
});

// 📊 Dashboard Summary
app.get("/analytics/summary", verifyToken, (req, res) => {
  const uid = req.user.uid;

  const today = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND date(transaction_date) = date('now')
  `).get(uid);

  const week = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND transaction_date >= datetime('now', '-7 days')
  `).get(uid);

  const month = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND transaction_date >= datetime('now', '-30 days')
  `).get(uid);

  const topProducts = db.prepare(`
    SELECT p.product_name AS productName, SUM(t.units_sold) AS totalSold, SUM(t.revenue) AS totalRevenue
    FROM transactions t JOIN products p ON p.id = t.product_id
    WHERE t.user_id = ? AND t.transaction_date >= datetime('now', '-30 days')
    GROUP BY t.product_id ORDER BY totalRevenue DESC LIMIT 5
  `).all(uid);

  const lowStock = db.prepare(`
    SELECT p.product_name AS productName, i.current_stock AS currentStock
    FROM inventory i JOIN products p ON p.id = i.product_id
    WHERE i.user_id = ? AND i.current_stock < ?
    ORDER BY i.current_stock ASC LIMIT 5
  `).all(uid, LOW_STOCK_THRESHOLD);

  const productCount = db.prepare("SELECT COUNT(*) AS count FROM products WHERE user_id = ?").get(uid);

  res.json({
    today: { revenue: today.revenue, profit: today.profit, transactions: today.count },
    week: { revenue: week.revenue, profit: week.profit, transactions: week.count },
    month: { revenue: month.revenue, profit: month.profit, transactions: month.count },
    topProducts,
    lowStock,
    totalProducts: productCount.count,
  });
});

app.get("/analytics/overall-trend", verifyToken, (req, res) => {
  const rows = db.prepare(`
    SELECT date(transaction_date) AS day,
           COALESCE(SUM(revenue), 0) AS revenue,
           COALESCE(SUM(profit), 0) AS profit
    FROM transactions
    WHERE user_id = ? AND transaction_date >= datetime('now', '-90 days')
    GROUP BY date(transaction_date)
    ORDER BY day
  `).all(req.user.uid);
  res.json(rows);
});

// 📈 Weekly chart data (last 7 days — legacy but kept for compatibility)
app.get("/analytics/weekly-chart", verifyToken, (req, res) => {
  const rows = db.prepare(`
    SELECT date(transaction_date) AS day,
           COALESCE(SUM(revenue), 0) AS revenue,
           COALESCE(SUM(profit), 0) AS profit
    FROM transactions
    WHERE user_id = ? AND transaction_date >= datetime('now', '-7 days')
    GROUP BY date(transaction_date)
    ORDER BY day
  `).all(req.user.uid);
  res.json(rows);
});

/* =====================
   AI INSIGHT (Rule-based MVP)
===================== */

// Helper: strip markdown from AI response lines
function cleanMarkdownLine(line) {
  return line
    .replace(/^#+\s*/g, '')          // ### headings
    .replace(/\*\*(.+?)\*\*/g, '$1') // **bold**
    .replace(/\*(.+?)\*/g, '$1')     // *italic*
    .replace(/^[-*•]\s+/, '')        // leading bullet dash
    .replace(/\$/g, '₹')            // dollar to rupee
    .trim();
}

// Helper: common AI insight logic used by GET and POST routes
async function generateAiInsight(uid) {
  const context = getShopContext(uid);
  const validProducts = context.productsData.filter(p => p.costPrice != null && p.sellingPrice != null);

  const weeklyForecast = context.estimatedWeeklyProfit.toFixed(0);
  const dailyAvgProfit = context.dailyAverageProfit.toFixed(0);
  const dailyAvgSales  = context.dailyAverageSales.toFixed(1);

  const shopDataJson = JSON.stringify({
    totalProfit: context.totalProfit,
    totalSales: context.totalUnitsSold,
    dailyAverageProfit: context.dailyAverageProfit,
    dailyAverageSales: context.dailyAverageSales,
    estimatedWeeklyProfit: context.estimatedWeeklyProfit,
    products: validProducts.map(p => ({
      name: p.name,
      profitPerUnit: p.profitPerUnit,
      quantitySold: p.quantitySold
    }))
  }, null, 2);

  const assistantPrompt = `You are a professional business assistant for a small Indian shopkeeper.
Analyze the shop data below and give a 3-part business report.

RULES (follow strictly):
- Language: Simple English, shopkeeper-friendly, no jargon.
- Currency: Always ₹ (Indian Rupee). Never use $.
- Format: Plain text only. No markdown, no bullet points, no hashtags, no bold symbols.
- Structure: Always 3 labelled lines:
  Performance Summary: <one sentence on sales and profit trend>
  Inventory Insight: <one sentence on stock or product movement>
  Weekly Forecast: Based on daily average profit of ₹${dailyAvgProfit} and ${dailyAvgSales} units/day, you can expect ₹${weeklyForecast} profit next week.
- Max 1 sentence per section. Use real numbers from the data.
- Do not hallucinate, do not add sections beyond these 3.

DATA:
${shopDataJson}`;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 18000);

    const ollamaResponse = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt: assistantPrompt,
        stream: false,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (ollamaResponse.ok) {
      const data = await ollamaResponse.json();
      let reply = data.response || '';

      // Strip all markdown symbols and emojis line by line
      const cleaned = reply
        .split('\n')
        .map(l => cleanMarkdownLine(l))
        .filter(l => l.length > 0)
        .slice(0, 6) // cap at 6 meaningful lines
        .join('\n');

      if (cleaned.trim()) {
        return {
          insight: cleaned.trim(),
          source: 'assistant'
        };
      }
    }
  } catch (err) {
    console.warn(`Assistant call failed: ${err.message}`);
  }

  // Deterministic fallback using computed forecasting values
  const top = validProducts.sort((a, b) => b.quantitySold - a.quantitySold)[0];
  return {
    insight: top
      ? `Performance Summary: ${top.name} leads with ${top.quantitySold} units sold.\nInventory Insight: Monitor low stock items to avoid missed sales.\nWeekly Forecast: Based on daily average of ₹${dailyAvgProfit}/day, expect ₹${weeklyForecast} profit next week.`
      : `Performance Summary: Business activity is steady.\nInventory Insight: Keep recording sales to unlock deeper insights.\nWeekly Forecast: Add more sales data for an accurate forecast.`,
    source: 'fallback'
  };
}

// GET /ai/insights — Merged with modern assistant logic
app.get("/ai/insights", verifyToken, async (req, res) => {
  const result = await generateAiInsight(req.user.uid);
  res.json(result);
});

/* =====================
   AI CHAT (Ollama Integration)
===================== */

// Helper: gather shop context for AI
function getShopContext(uid) {
  const products = db.prepare("SELECT id, product_name FROM products WHERE user_id = ?").all(uid);
  
  const productsData = products.map(p => {
    // Latest costPrice from purchase history
    const latestPurchase = db.prepare(`
      SELECT cost_price FROM purchases 
      WHERE user_id = ? AND product_id = ? 
      ORDER BY purchase_date DESC LIMIT 1
    `).get(uid, p.id);

    // Latest sellingPrice from sales history (revenue / units)
    const latestSale = db.prepare(`
      SELECT (revenue / units_sold) as sellingPrice FROM transactions 
      WHERE user_id = ? AND product_id = ? 
      ORDER BY transaction_date DESC LIMIT 1
    `).get(uid, p.id);

    // Total quantity sold
    const stats = db.prepare(`
      SELECT SUM(units_sold) as quantitySold FROM transactions 
      WHERE user_id = ? AND product_id = ?
    `).get(uid, p.id);

    const costPrice = latestPurchase ? latestPurchase.cost_price : null;
    const sellingPrice = latestSale ? latestSale.sellingPrice : null;
    const quantitySold = stats ? (stats.quantitySold || 0) : 0;
    const profitPerUnit = (costPrice && sellingPrice) ? (sellingPrice - costPrice) : null;

    return {
      name: p.product_name,
      costPrice,
      sellingPrice,
      quantitySold,
      profitPerUnit
    };
  });

  const lowStock = db.prepare(`
    SELECT p.product_name, i.current_stock
    FROM inventory i JOIN products p ON p.id = i.product_id
    WHERE i.user_id = ? AND i.current_stock < ?
    ORDER BY i.current_stock ASC LIMIT 5
  `).all(uid, LOW_STOCK_THRESHOLD);

  const totals = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS totalRevenue, COALESCE(SUM(profit), 0) AS totalProfit,
           COALESCE(SUM(units_sold), 0) AS totalUnitsSold
    FROM transactions WHERE user_id = ?
  `).get(uid);

  // Daily averages for forecasting
  const firstTx = db.prepare("SELECT MIN(transaction_date) as firstDate FROM transactions WHERE user_id = ?").get(uid);
  const totalDays = firstTx.firstDate ? Math.max(1, Math.ceil((new Date() - new Date(firstTx.firstDate)) / (1000 * 60 * 60 * 24))) : 1;
  const dailyAverageProfit = totals.totalProfit / totalDays;
  const dailyAverageSales = totals.totalUnitsSold / totalDays;
  const estimatedWeeklyProfit = dailyAverageProfit * 7;

  return {
    totalRevenue: totals.totalRevenue,
    totalProfit: totals.totalProfit,
    totalUnitsSold: totals.totalUnitsSold,
    dailyAverageProfit,
    dailyAverageSales,
    estimatedWeeklyProfit,
    productsData,
    lowStockItems: lowStock.map(p => `${p.product_name} (stock: ${p.current_stock})`),
  };
}

// Rule-based fallback response
function getRuleBasedResponse(message, context) {
  const q = message.toLowerCase();

  if (q.includes('sale') || q.includes('revenue')) {
    return `Your total revenue is ₹${context.totalRevenue.toFixed(0)}. ${context.topProducts.length > 0 ? `Top seller: ${context.topProducts[0]}` : 'Start selling to see insights!'}`;
  }
  if (q.includes('profit')) {
    return `Estimated total profit: ₹${context.totalProfit.toFixed(0)}. Keep monitoring your cost prices to maintain healthy margins.`;
  }
  if (q.includes('stock') || q.includes('inventory')) {
    if (context.lowStockItems.length > 0) {
      return `⚠️ Low stock alert: ${context.lowStockItems.join(', ')}. Consider restocking these items soon.`;
    }
    return 'All products are well-stocked! No immediate restocking needed.';
  }
  if (q.includes('suggest') || q.includes('tip') || q.includes('insight')) {
    const tips = [
      context.topProducts.length > 0 ? `Bundle your top seller with slower movers to increase average order value.` : null,
      context.lowStockItems.length > 0 ? `Restock ${context.lowStockItems[0]} urgently to avoid lost sales.` : null,
      `Review your pricing quarterly to stay competitive while maintaining margins.`,
      `Track your daily sales patterns to optimize stock levels.`,
    ].filter(Boolean);
    return tips[Math.floor(Math.random() * tips.length)];
  }

  return `You have ${context.totalProducts} products, total revenue of ₹${context.totalRevenue.toFixed(0)}, and profit of ₹${context.totalProfit.toFixed(0)}. ${context.lowStockItems.length > 0 ? `⚠️ ${context.lowStockItems.length} items are low on stock.` : '✅ All stock levels are healthy.'} Ask me about sales, profit, stock, or suggestions!`;
}

// POST /ai/chat — Ollama-powered chat with intent handling and cleaning
app.post("/ai/chat", verifyToken, async (req, res) => {
  const uid = req.user.uid;
  const { message, history } = req.body;

  if (!message || !message.trim()) {
    return res.status(400).json({ error: "Message is required" });
  }

  const context = getShopContext(uid);
  const q = message.toLowerCase();

  // --- 1. Specific Data Intents (High Priority, Fast) ---
  const mentionedProduct = context.productsData.find(p => q.includes(p.name.toLowerCase()));
  if (mentionedProduct && (q.includes("restock") || q.includes("stock") || q.includes("how much") || q.includes("price"))) {
    const stockStatus = mentionedProduct.currentStock < LOW_STOCK_THRESHOLD ? "⚠️ LOW" : "✅ Healthy";
    return res.json({ 
      reply: `For ${mentionedProduct.name}: Current stock is ${mentionedProduct.currentStock} units (${stockStatus}). Prices: Cost ₹${mentionedProduct.costPrice}, Selling ₹${mentionedProduct.sellingPrice}.`,
      source: 'intent'
    });
  }

  // --- 2. Real AI Intelligence (Ollama Primary) ---
  const shopDataSummary = {
    totalProfit: context.totalProfit,
    totalRevenue: context.totalRevenue,
    topItems: context.topProducts,
    lowStock: context.lowStockItems
  };

  const assistantPrompt = `You are GrowthOS Assistant, a retail expert. 
Data: ${JSON.stringify(shopDataSummary)}. 
User: "${message}". 
Analyze the data and provide 2-3 professional, actionable business sentences for a shopkeeper. Use ₹.`;

  try {
    // Sort products by profit margin directly in Node before sending to Ollama to ensure accuracy
    const enrichedProducts = context.productsData
      .filter(p => p.profitPerUnit !== null)
      .sort((a, b) => b.profitPerUnit - a.profitPerUnit)
      .slice(0, 10); // Top 10 most profitable

    const assistantPrompt = `You are GrowthOS Assistant, a retail expert. 
Data: ${JSON.stringify(shopDataSummary)}. 
Top Profitable Products: ${JSON.stringify(enrichedProducts)}.
User: "${message}". 
Analyze the data and answer the user directly in a professional tone. MENTION EXACT RS PROFIT MARGINS. ALWAYS use the Indian Rupee symbol (₹) instead of $. Keep it under 3-4 sentences.`;
    
    console.log("SENDING TO AI:", assistantPrompt);
    const aiResponse = await axios.post(`${OLLAMA_URL}/api/generate`, {
      model: OLLAMA_MODEL,
      prompt: assistantPrompt,
      stream: false,
    }, { timeout: 30000 });

    if (aiResponse.data && aiResponse.data.response) {
      return res.json({ reply: aiResponse.data.response.trim(), source: 'ollama' });
    }
  } catch (err) {
    console.error("AI Error (falling back):", err.message);
  }

  // --- 3. Rule-Based Fallback (Safety Net) ---
  const fallback = getRuleBasedResponse(message, context);
  res.json({ reply: fallback, source: 'fallback' });
});

// POST /ai/insights — Aligning with the same logic
app.post("/ai/insights", verifyToken, async (req, res) => {
  const result = await generateAiInsight(req.user.uid);
  res.json(result);
});


/* =====================
   OCR MODULE
===================== */

// 📷 Scan image, extract text, and parse structured product data
app.post("/ocr/scan", verifyToken, async (req, res) => {
  try {
    const { image } = req.body;

    if (!image) {
      return res.status(400).json({ error: "Base64 image data is required" });
    }

    const imageBuffer = Buffer.from(image, "base64");
    const worker = await createWorker("eng");
    const { data: { text } } = await worker.recognize(imageBuffer);
    await worker.terminate();

    const rawText = text.trim();

    // --- Structured parsing ---
    const parsedProducts = parseReceiptText(rawText);

    // Try to extract a date from the text
    const dateMatch = rawText.match(
      /(?:date|dated?|dt)[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/i
    ) || rawText.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
    const extractedDate = dateMatch ? dateMatch[1] : new Date().toISOString().split("T")[0];

    // Try to extract vendor / shop name (first non-empty line)
    const lines = rawText.split("\n").map(l => l.trim()).filter(Boolean);
    const vendorName = lines.length > 0 ? lines[0] : "Unknown vendor";

    res.json({
      text: rawText,
      characters: rawText.length,
      extractedDate,
      vendorName,
      parsedProducts,
      message: "OCR scan completed successfully ✅",
    });
  } catch (err) {
    console.error("OCR error:", err);
    res.status(500).json({ error: "OCR processing failed" });
  }
});

/**
 * Parse receipt / invoice text into structured product rows.
 */
function parseReceiptText(text) {
  const lines = text.split("\n").map(l => l.trim()).filter(Boolean);
  const products = [];

  const skipPatterns = /^(subtotal|sub total|total|tax|gst|vat|amount|balance|change|cash|card|payment|receipt|invoice|bill|date|time|phone|tel|address|thank|www|http|email|\*+|-{3,}|={3,}|#{3,})/i;
  const totalLinePattern = /(subtotal|sub[\s-]?total|grand[\s-]?total|total\s*(amount|due|payable)?|tax|gst|vat|discount|net\s*amount|balance|change|cash|tendered)/i;

  for (const line of lines) {
    if (skipPatterns.test(line)) continue;
    if (totalLinePattern.test(line)) continue;
    if (line.length < 3) continue;

    // Pattern 1: "Item Name   qty x price   total"
    const qtyTimesPrice = line.match(/^(.+?)\s+(\d+)\s*[x×X]\s*\$?([\d,.]+)\s*(?:\$?([\d,.]+))?$/);
    if (qtyTimesPrice) {
      const name = qtyTimesPrice[1].replace(/[.]{2,}$/, "").trim();
      const qty = parseInt(qtyTimesPrice[2], 10);
      const unit = parseFloat(qtyTimesPrice[3].replace(",", ""));
      const total = qtyTimesPrice[4] ? parseFloat(qtyTimesPrice[4].replace(",", "")) : qty * unit;
      if (name.length > 1 && !isNaN(qty) && !isNaN(unit)) {
        products.push({ productName: cleanName(name), quantity: qty, costPrice: unit, sellingPrice: 0, totalPrice: Math.round(total * 100) / 100 });
        continue;
      }
    }

    // Pattern 2: "Item Name   qty   unit_price   total_price"
    const multiNum = line.match(/^(.+?)\s+(\d+)\s+\$?([\d,.]+)\s+\$?([\d,.]+)$/);
    if (multiNum) {
      const name = multiNum[1].replace(/[.]{2,}$/, "").trim();
      const qty = parseInt(multiNum[2], 10);
      const unitP = parseFloat(multiNum[3].replace(",", ""));
      const totalP = parseFloat(multiNum[4].replace(",", ""));
      if (name.length > 1 && qty > 0 && qty < 10000 && !isNaN(unitP)) {
        products.push({ productName: cleanName(name), quantity: qty, costPrice: unitP, sellingPrice: 0, totalPrice: Math.round(totalP * 100) / 100 });
        continue;
      }
    }

    // Pattern 3: "Item Name   $price"
    const singlePrice = line.match(/^(.+?)\s{2,}\$?([\d,.]+)$/);
    if (singlePrice) {
      const name = singlePrice[1].replace(/[.]{2,}$/, "").trim();
      const price = parseFloat(singlePrice[2].replace(",", ""));
      if (name.length > 1 && !isNaN(price) && price > 0 && price < 100000) {
        products.push({ productName: cleanName(name), quantity: 1, costPrice: price, sellingPrice: 0, totalPrice: price });
        continue;
      }
    }

    // Pattern 4: "qty Item Name   price"
    const qtyFirst = line.match(/^(\d+)\s+(.+?)\s{2,}\$?([\d,.]+)$/);
    if (qtyFirst) {
      const qty = parseInt(qtyFirst[1], 10);
      const name = qtyFirst[2].replace(/[.]{2,}$/, "").trim();
      const price = parseFloat(qtyFirst[3].replace(",", ""));
      if (name.length > 1 && qty > 0 && qty < 10000 && !isNaN(price)) {
        products.push({ productName: cleanName(name), quantity: qty, costPrice: Math.round((price / qty) * 100) / 100, sellingPrice: 0, totalPrice: price });
        continue;
      }
    }
  }
  return products;
}

function cleanName(name) {
  return name.replace(/^[\-\*\#\•\·]+\s*/, "").replace(/\s+/g, " ").replace(/[.]{2,}$/, "").trim();
}

/* =====================
   START SERVER
===================== */

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Ollama: ${OLLAMA_URL} | Model: ${OLLAMA_MODEL}`);
});