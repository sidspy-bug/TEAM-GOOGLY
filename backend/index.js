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

const LOW_STOCK_THRESHOLD = 5;

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

    const product = db.prepare("SELECT * FROM products WHERE id = ?").get(productId);
    const inventory = db.prepare("SELECT * FROM inventory WHERE product_id = ?").get(productId);

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
    LIMIT 100
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

  const total = db.prepare(`
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit,
           COALESCE(SUM(units_sold), 0) AS unitsSold, COUNT(*) AS count
    FROM transactions WHERE user_id = ?
  `).get(uid);

  const lowStockCount = db.prepare(
    "SELECT COUNT(*) AS count FROM inventory WHERE user_id = ? AND current_stock < ?"
  ).get(uid, LOW_STOCK_THRESHOLD);

  const productCount = db.prepare("SELECT COUNT(*) AS count FROM products WHERE user_id = ?").get(uid);

  res.json({
    totalRevenue: total.revenue,
    totalProfit: total.profit,
    totalTransactions: total.count,
    unitsSold: total.unitsSold,
    dailyRevenue: today.revenue,
    dailyProfit: today.profit,
    lowStockCount: lowStockCount.count,
    totalProducts: productCount.count,
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

// 📈 Weekly chart data (last 7 days)
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

app.get("/ai/insights", verifyToken, (req, res) => {
  const uid = req.user.uid;

  const topProduct = db.prepare(`
    SELECT p.product_name FROM transactions t JOIN products p ON p.id = t.product_id
    WHERE t.user_id = ? GROUP BY t.product_id ORDER BY SUM(t.revenue) DESC LIMIT 1
  `).get(uid);

  const lowStockCount = db.prepare(
    "SELECT COUNT(*) AS count FROM inventory WHERE user_id = ? AND current_stock < ?"
  ).get(uid, LOW_STOCK_THRESHOLD);

  let insight = "Your sales are stable. Consider increasing stock of high-selling products.";
  if (topProduct) {
    insight = `"${topProduct.product_name}" is your top seller. `;
  }
  if (lowStockCount.count > 0) {
    insight += `⚠️ ${lowStockCount.count} product(s) are running low on stock.`;
  }

  res.json({ insight });
});

/* =====================
   AI CHAT (Ollama Integration)
===================== */

// Helper: gather shop context for AI
function getShopContext(uid) {
  const topProducts = db.prepare(`
    SELECT p.product_name, SUM(t.units_sold) AS totalSold, SUM(t.revenue) AS totalRevenue
    FROM transactions t JOIN products p ON p.id = t.product_id
    WHERE t.user_id = ?
    GROUP BY t.product_id ORDER BY totalRevenue DESC LIMIT 5
  `).all(uid);

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

  const productCount = db.prepare("SELECT COUNT(*) AS count FROM products WHERE user_id = ?").get(uid);

  return {
    totalRevenue: totals.totalRevenue,
    totalProfit: totals.totalProfit,
    totalUnitsSold: totals.totalUnitsSold,
    totalProducts: productCount.count,
    topProducts: topProducts.map(p => `${p.product_name} (sold: ${p.totalSold}, revenue: ₹${p.totalRevenue})`),
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

// POST /ai/chat — Ollama-powered chat with fallback
app.post("/ai/chat", verifyToken, async (req, res) => {
  const uid = req.user.uid;
  const { message, history } = req.body;

  if (!message || !message.trim()) {
    return res.status(400).json({ error: "Message is required" });
  }

  const context = getShopContext(uid);

  // Format history
  const historyText = Array.isArray(history) && history.length > 0 
    ? `\nChat History:\n${history.join('\n')}\n`
    : '';

  // Try Ollama first
  try {
    const shopDataPrompt = `You are an expert retail business advisor for small shopkeepers.

Your role is to analyze shop data and answer business questions in a practical, profit-focused way.

You must support TWO MODES:

----------------------------------------
MODE 1: AUTO INSIGHTS (no user question)
----------------------------------------

If no user question is provided, generate structured business insights.

STRICT OUTPUT FORMAT:

🔴 Problem:
Identify one critical issue hurting the business (use specific product names, stock levels, or sales data).

🟢 Opportunity:
Identify one clear opportunity to increase revenue or profit (based on actual data trends).

💡 Action:
Give one clear, practical action the shopkeeper should take immediately.

RULES:
- Use real numbers and product names
- Avoid generic advice
- Keep it short and clear
- Focus on profit, stock, and sales improvement

----------------------------------------
MODE 2: BUSINESS ASSISTANT (user question present)
----------------------------------------

If a user question is provided, answer it directly.

RULES:
- CRITICAL: NEVER hallucinate, invent, or create dummy data. 
- You MUST securely and EXCLUSIVELY use the arrays and digits under the "DATA CONTEXT" below.
- If the shop has "No sales yet" or "None", you must truthfully report that data doesn't exist yet instead of making up hypothetical metrics.
- Be simple and practical (shopkeeper-friendly language)
- Give actionable advice
- Keep response concise (3–5 lines max)
- Avoid technical or complex explanations

----------------------------------------
DATA CONTEXT:
----------------------------------------

Shop Data:
- Total Revenue: ₹${context.totalRevenue.toFixed(0)}
- Total Profit: ₹${context.totalProfit.toFixed(0)}
- Total Units Sold: ${context.totalUnitsSold}
- Total Products: ${context.totalProducts}
- Top Products: ${context.topProducts.join(', ') || 'No sales yet'}
- Low Stock Items: ${context.lowStockItems.join(', ') || 'None'}
${historyText}
----------------------------------------
INPUT:
----------------------------------------

User Question:
${message}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000); // 15s timeout

    const ollamaResponse = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt: shopDataPrompt,
        stream: false,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!ollamaResponse.ok) {
      throw new Error(`Ollama returned ${ollamaResponse.status}`);
    }

    const data = await ollamaResponse.json();
    const reply = data.response || data.message || '';

    if (reply.trim()) {
      console.log(`✅ Ollama (${OLLAMA_MODEL}) responded successfully`);
      return res.json({ reply: reply.trim(), source: 'ollama' });
    }

    throw new Error('Empty Ollama response');
  } catch (err) {
    console.warn(`⚠️ Ollama unavailable (${err.message}), using rule-based fallback`);
  }

  // Fallback to rule-based
  const fallbackReply = getRuleBasedResponse(message, context);
  res.json({ reply: fallbackReply, source: 'rule-based' });
});

// POST /ai/insights — Ollama-powered insights with fallback
app.post("/ai/insights", verifyToken, async (req, res) => {
  const uid = req.user.uid;
  const context = getShopContext(uid);

  try {
    const prompt = `Analyze this small Indian retail shop data and give exactly 3 actionable insights:
- Total Revenue: ₹${context.totalRevenue.toFixed(0)}
- Total Profit: ₹${context.totalProfit.toFixed(0)}
- Top Products: ${context.topProducts.join(', ') || 'No sales yet'}
- Low Stock Items: ${context.lowStockItems.join(', ') || 'None'}

STRICT OUTPUT FORMAT:
🔴 Problem:
[identify one critical issue]

🟢 Opportunity:
[identify one clear opportunity to increase revenue or profit]

💡 Action:
[give one practical action]

RULES:
- Use real numbers and product names
- Keep it short and clear
- Focus on profit, stock, and sales improvement
- Use ₹ for currency.`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);

    const ollamaResponse = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt,
        stream: false,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (ollamaResponse.ok) {
      const data = await ollamaResponse.json();
      if (data.response && data.response.trim()) {
        console.log(`✅ Ollama insights generated successfully`);
        return res.json({ insight: data.response.trim(), source: 'ollama' });
      }
    }
    throw new Error('Ollama unavailable');
  } catch (err) {
    console.warn(`⚠️ Ollama insights fallback: ${err.message}`);
  }

  const fallbackInsight = `🔴 Problem:
${context.lowStockItems.length > 0 ? context.lowStockItems[0] + ' is critically low on stock.' : 'No major problems detected, but sales volume could be optimized.'}

🟢 Opportunity:
${context.topProducts.length > 0 ? context.topProducts[0] + ' is your best seller, consider promoting it more or bundling it.' : 'Start bundles to increase average order value.'}

💡 Action:
Review your pricing and reorder fast-moving items immediately.`;

  res.json({ insight: fallbackInsight, source: 'rule-based' });
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