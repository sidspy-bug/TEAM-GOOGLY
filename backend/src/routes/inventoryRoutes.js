const express = require("express");

const db = require("../../db");
const verifyToken = require("../../middleware/auth");
const { LOW_STOCK_THRESHOLD } = require("../config/constants");

const router = express.Router();

router.post("/inventory/add", verifyToken, (req, res) => {
  try {
    const { productId, stockAdded } = req.body;

    if (!productId || stockAdded <= 0) {
      return res.status(400).json({ error: "Invalid productId or stockAdded" });
    }

    const existing = db.prepare("SELECT current_stock FROM inventory WHERE product_id = ?").get(productId);

    if (!existing) {
      db
        .prepare("INSERT INTO inventory (product_id, user_id, current_stock) VALUES (?, ?, ?)")
        .run(productId, req.user.uid, stockAdded);
    } else {
      db
        .prepare(
          "UPDATE inventory SET current_stock = current_stock + ?, updated_at = datetime('now') WHERE product_id = ?"
        )
        .run(stockAdded, productId);
    }

    return res.json({ message: "Stock updated successfully" });
  } catch (error) {
    console.error("Stock update error:", error);
    return res.status(500).json({ error: "Stock update failed" });
  }
});

router.get("/inventory/status", verifyToken, (req, res) => {
  const rows = db
    .prepare(
      `
    SELECT i.product_id AS productId, i.current_stock AS currentStock, i.updated_at AS updatedAt,
           p.product_name AS productName, p.category
    FROM inventory i
    JOIN products p ON p.id = i.product_id
    WHERE i.user_id = ?
    ORDER BY p.product_name
  `
    )
    .all(req.user.uid);

  const stock = rows.map((row) => {
    let status = "Normal";
    if (row.currentStock === 0) {
      status = "Out of Stock";
    } else if (row.currentStock < LOW_STOCK_THRESHOLD) {
      status = "Low";
    }
    return { ...row, status };
  });

  res.json(stock);
});

module.exports = router;
