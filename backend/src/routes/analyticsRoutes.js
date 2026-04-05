const express = require("express");

const db = require("../../db");
const verifyToken = require("../../middleware/auth");
const { LOW_STOCK_THRESHOLD } = require("../config/constants");

const router = express.Router();

router.get("/analytics/daily", verifyToken, (req, res) => {
  const row = db
    .prepare(
      `
    SELECT COALESCE(SUM(revenue), 0) AS dailyRevenue,
           COALESCE(SUM(profit), 0) AS dailyProfit,
           COUNT(*) AS totalTransactions
    FROM transactions
    WHERE user_id = ? AND date(transaction_date) = date('now')
  `
    )
    .get(req.user.uid);

  res.json(row);
});

router.get("/analytics/summary", verifyToken, (req, res) => {
  const uid = req.user.uid;

  const today = db
    .prepare(
      `
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND date(transaction_date) = date('now')
  `
    )
    .get(uid);

  const week = db
    .prepare(
      `
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND transaction_date >= datetime('now', '-7 days')
  `
    )
    .get(uid);

  const month = db
    .prepare(
      `
    SELECT COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(profit), 0) AS profit, COUNT(*) AS count
    FROM transactions WHERE user_id = ? AND transaction_date >= datetime('now', '-30 days')
  `
    )
    .get(uid);

  const topProducts = db
    .prepare(
      `
    SELECT p.product_name AS productName, SUM(t.units_sold) AS totalSold, SUM(t.revenue) AS totalRevenue
    FROM transactions t JOIN products p ON p.id = t.product_id
    WHERE t.user_id = ? AND t.transaction_date >= datetime('now', '-30 days')
    GROUP BY t.product_id ORDER BY totalRevenue DESC LIMIT 5
  `
    )
    .all(uid);

  const lowStock = db
    .prepare(
      `
    SELECT p.product_name AS productName, i.current_stock AS currentStock
    FROM inventory i JOIN products p ON p.id = i.product_id
    WHERE i.user_id = ? AND i.current_stock < ?
    ORDER BY i.current_stock ASC LIMIT 5
  `
    )
    .all(uid, LOW_STOCK_THRESHOLD);

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

router.get("/analytics/weekly-chart", verifyToken, (req, res) => {
  const rows = db
    .prepare(
      `
    SELECT date(transaction_date) AS day,
           COALESCE(SUM(revenue), 0) AS revenue,
           COALESCE(SUM(profit), 0) AS profit
    FROM transactions
    WHERE user_id = ? AND transaction_date >= datetime('now', '-7 days')
    GROUP BY date(transaction_date)
    ORDER BY day
  `
    )
    .all(req.user.uid);

  res.json(rows);
});

module.exports = router;
