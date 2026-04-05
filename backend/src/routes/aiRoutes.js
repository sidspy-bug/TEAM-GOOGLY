const express = require("express");

const db = require("../../db");
const verifyToken = require("../../middleware/auth");
const { LOW_STOCK_THRESHOLD } = require("../config/constants");

const router = express.Router();

router.get("/ai/insights", verifyToken, (req, res) => {
  const uid = req.user.uid;

  const topProduct = db
    .prepare(
      `
    SELECT p.product_name FROM transactions t JOIN products p ON p.id = t.product_id
    WHERE t.user_id = ? GROUP BY t.product_id ORDER BY SUM(t.revenue) DESC LIMIT 1
  `
    )
    .get(uid);

  const lowStockCount = db
    .prepare("SELECT COUNT(*) AS count FROM inventory WHERE user_id = ? AND current_stock < ?")
    .get(uid, LOW_STOCK_THRESHOLD);

  let insight = "Your sales are stable. Consider increasing stock of high-selling products.";
  if (topProduct) {
    insight = `\"${topProduct.product_name}\" is your top seller. `;
  }
  if (lowStockCount.count > 0) {
    insight += `${lowStockCount.count} product(s) are running low on stock.`;
  }

  res.json({ insight });
});

module.exports = router;
