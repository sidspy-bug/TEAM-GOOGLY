const express = require("express");

const db = require("../../db");
const verifyToken = require("../../middleware/auth");
const { LOW_STOCK_THRESHOLD } = require("../config/constants");

const router = express.Router();

router.post("/transactions/sell", verifyToken, (req, res) => {
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

    const sellTransaction = db.transaction(() => {
      db
        .prepare(
          "UPDATE inventory SET current_stock = current_stock - ?, updated_at = datetime('now') WHERE product_id = ?"
        )
        .run(unitsSold, productId);

      db
        .prepare(
          "INSERT INTO transactions (user_id, product_id, units_sold, transaction_mode, revenue, profit) VALUES (?, ?, ?, ?, ?, ?)"
        )
        .run(req.user.uid, productId, unitsSold, transactionMode || "Cash", revenue, profit);
    });

    sellTransaction();

    return res.json({ message: "Transaction successful", revenue, profit });
  } catch (error) {
    console.error("Transaction error:", error);
    return res.status(500).json({ error: "Transaction failed" });
  }
});

router.get("/transactions/history", verifyToken, (req, res) => {
  const rows = db
    .prepare(
      `
    SELECT t.id, t.product_id AS productId, t.units_sold AS unitsSold,
           t.transaction_mode AS transactionMode, t.revenue, t.profit,
           t.transaction_date AS transactionDate,
           p.product_name AS productName, p.category
    FROM transactions t
    JOIN products p ON p.id = t.product_id
    WHERE t.user_id = ?
    ORDER BY t.transaction_date DESC
    LIMIT 100
  `
    )
    .all(req.user.uid);

  res.json(rows);
});

router.get("/dashboard/summary", verifyToken, (req, res) => {
  const uid = req.user.uid;

  const today = db
    .prepare(
      `
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND date(transaction_date) = date('now')
  `
    )
    .get(uid);

  const total = db
    .prepare(
      `
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit,
           COALESCE(SUM(units_sold), 0) AS unitsSold, COUNT(*) AS count
    FROM transactions WHERE user_id = ?
  `
    )
    .get(uid);

  const lowStockCount = db
    .prepare("SELECT COUNT(*) AS count FROM inventory WHERE user_id = ? AND current_stock < ?")
    .get(uid, LOW_STOCK_THRESHOLD);

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

module.exports = router;
