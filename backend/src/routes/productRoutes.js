const express = require("express");

const db = require("../../db");
const verifyToken = require("../../middleware/auth");

const router = express.Router();

router.post("/products/add", verifyToken, (req, res) => {
  try {
    const { productName, category, costPrice, sellingPrice } = req.body;

    if (!productName || !category) {
      return res.status(400).json({ error: "Product name and category are required" });
    }
    if (costPrice <= 0 || sellingPrice <= 0) {
      return res.status(400).json({ error: "Prices must be greater than 0" });
    }

    const result = db
      .prepare(
        "INSERT INTO products (user_id, product_name, category, cost_price, selling_price) VALUES (?, ?, ?, ?, ?)"
      )
      .run(req.user.uid, productName, category, costPrice, sellingPrice);

    return res.json({ message: "Product added successfully", id: result.lastInsertRowid });
  } catch (error) {
    console.error("Product add error:", error);
    return res.status(500).json({ error: "Product add failed" });
  }
});

router.get("/products/list", verifyToken, (req, res) => {
  const products = db
    .prepare(
      "SELECT id, product_name AS productName, category, cost_price AS costPrice, selling_price AS sellingPrice, created_at AS createdAt FROM products WHERE user_id = ? ORDER BY created_at DESC"
    )
    .all(req.user.uid);

  res.json(products);
});

router.get("/products/category/:category", verifyToken, (req, res) => {
  const products = db
    .prepare(
      "SELECT id, product_name AS productName, category, cost_price AS costPrice, selling_price AS sellingPrice FROM products WHERE user_id = ? AND category = ?"
    )
    .all(req.user.uid, req.params.category);

  res.json(products);
});

router.put("/products/update/:id", verifyToken, (req, res) => {
  try {
    const { productName, category, costPrice, sellingPrice } = req.body;

    const updates = [];
    const params = [];

    if (productName) {
      updates.push("product_name = ?");
      params.push(productName);
    }
    if (category) {
      updates.push("category = ?");
      params.push(category);
    }
    if (costPrice) {
      updates.push("cost_price = ?");
      params.push(costPrice);
    }
    if (sellingPrice) {
      updates.push("selling_price = ?");
      params.push(sellingPrice);
    }

    updates.push("updated_at = datetime('now')");
    params.push(req.params.id);

    db.prepare(`UPDATE products SET ${updates.join(", ")} WHERE id = ?`).run(...params);
    res.json({ message: "Product updated successfully" });
  } catch (error) {
    console.error("Product update error:", error);
    res.status(500).json({ error: "Update failed" });
  }
});

router.delete("/products/delete/:id", verifyToken, (req, res) => {
  try {
    db.prepare("DELETE FROM products WHERE id = ? AND user_id = ?").run(req.params.id, req.user.uid);
    res.json({ message: "Product deleted" });
  } catch (error) {
    res.status(500).json({ error: "Delete failed" });
  }
});

module.exports = router;
