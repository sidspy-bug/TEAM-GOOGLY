const express = require("express");
const admin = require("firebase-admin");
const cors = require("cors");

const verifyToken = require("./middleware/auth");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const app = express();

app.use(cors());
app.use(express.json());

const LOW_STOCK_THRESHOLD = 5;

/* =====================
   BASIC ROUTES
===================== */

app.get("/", (req, res) => {
  res.send("Backend connected with Firebase ✅");
});

app.get("/auth/test", verifyToken, (req, res) => {
  res.json({
    message: "User authenticated successfully ✅",
    uid: req.user.uid,
    email: req.user.email,
  });
});

/* =====================
   PRODUCT MODULE
===================== */

// ➕ Add Product
app.post("/products/add", verifyToken, async (req, res) => {
  try {
    const { productName, category, costPrice, sellingPrice } = req.body;

    if (!productName || !category) {
      return res.status(400).json({ error: "Product name & category required" });
    }

    if (costPrice <= 0 || sellingPrice <= 0) {
      return res.status(400).json({ error: "Prices must be > 0" });
    }

    if (sellingPrice <= costPrice) {
      return res.status(400).json({
        error: "Selling price must be greater than cost price",
      });
    }

    await db.collection("products").add({
      userId: req.user.uid,
      productName,
      category,
      costPrice,
      sellingPrice,
      createdAt: new Date(),
    });

    res.json({ message: "Product added successfully ✅" });
  } catch (err) {
    res.status(500).json({ error: "Product add failed" });
  }
});

// 📋 List Products
app.get("/products/list", verifyToken, async (req, res) => {
  const snapshot = await db
    .collection("products")
    .where("userId", "==", req.user.uid)
    .get();

  const products = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  res.json(products);
});

// 📂 List Products by Category
app.get("/products/category/:category", verifyToken, async (req, res) => {
  const snapshot = await db
    .collection("products")
    .where("userId", "==", req.user.uid)
    .where("category", "==", req.params.category)
    .get();

  const products = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  res.json(products);
});

// ✏ Update Product
app.put("/products/update/:id", verifyToken, async (req, res) => {
  try {
    const { productName, category, costPrice, sellingPrice } = req.body;

    if (
      sellingPrice !== undefined &&
      costPrice !== undefined &&
      sellingPrice <= costPrice
    ) {
      return res.status(400).json({
        error: "Selling price must be greater than cost price",
      });
    }

    await db.collection("products").doc(req.params.id).update({
      ...(productName && { productName }),
      ...(category && { category }),
      ...(costPrice && { costPrice }),
      ...(sellingPrice && { sellingPrice }),
      updatedAt: new Date(),
    });

    res.json({ message: "Product updated successfully ✅" });
  } catch (err) {
    res.status(500).json({ error: "Update failed" });
  }
});

/* =====================
   INVENTORY MODULE
===================== */

// ➕ Add / Update Stock
app.post("/inventory/add", verifyToken, async (req, res) => {
  try {
    const { productId, stockAdded } = req.body;

    if (!productId || stockAdded <= 0) {
      return res.status(400).json({
        error: "Invalid productId or stockAdded",
      });
    }

    const ref = db.collection("inventory").doc(productId);
    const doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        userId: req.user.uid,
        productId,
        currentStock: stockAdded,
        updatedAt: new Date(),
      });
    } else {
      await ref.update({
        currentStock: doc.data().currentStock + stockAdded,
        updatedAt: new Date(),
      });
    }

    res.json({ message: "Stock updated successfully ✅" });
  } catch (err) {
    res.status(500).json({ error: "Stock update failed" });
  }
});

// 📦 Inventory Status
app.get("/inventory/status", verifyToken, async (req, res) => {
  const snapshot = await db
    .collection("inventory")
    .where("userId", "==", req.user.uid)
    .get();

  const stock = snapshot.docs.map((doc) => {
    const data = doc.data();
    let status = "Normal";

    if (data.currentStock === 0) status = "Out of Stock";
    else if (data.currentStock < LOW_STOCK_THRESHOLD) status = "Low";

    return { ...data, status };
  });

  res.json(stock);
});

/* =====================
   TRANSACTIONS MODULE
===================== */

// 🛒 Sell Product
app.post("/transactions/sell", verifyToken, async (req, res) => {
  try {
    const { productId, unitsSold, transactionMode } = req.body;

    if (!productId || unitsSold <= 0) {
      return res.status(400).json({
        error: "Invalid productId or unitsSold",
      });
    }

    const productRef = db.collection("products").doc(productId);
    const inventoryRef = db.collection("inventory").doc(productId);

    const productDoc = await productRef.get();
    const inventoryDoc = await inventoryRef.get();

    if (!productDoc.exists || !inventoryDoc.exists) {
      return res.status(404).json({
        error: "Product or inventory not found",
      });
    }

    const product = productDoc.data();
    const inventory = inventoryDoc.data();

    if (inventory.currentStock < unitsSold) {
      return res.status(400).json({
        error: "Insufficient stock",
      });
    }

    const revenue = unitsSold * product.sellingPrice;
    const profit =
      unitsSold * (product.sellingPrice - product.costPrice);

    await inventoryRef.update({
      currentStock: inventory.currentStock - unitsSold,
      updatedAt: new Date(),
    });

    await db.collection("transactions").add({
      userId: req.user.uid,
      productId,
      unitsSold,
      transactionMode: transactionMode || "Cash",
      revenue,
      profit,
      transactionDate: new Date(),
    });

    res.json({
      message: "Transaction successful ✅",
      revenue,
      profit,
    });
  } catch (err) {
    res.status(500).json({ error: "Transaction failed" });
  }
});

/* =====================
   ANALYTICS MODULE
===================== */

// 📊 Daily Analytics
app.get("/analytics/daily", verifyToken, async (req, res) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const snapshot = await db
    .collection("transactions")
    .where("userId", "==", req.user.uid)
    .where("transactionDate", ">=", today)
    .get();

  let revenue = 0;
  let profit = 0;

  snapshot.forEach((doc) => {
    revenue += doc.data().revenue;
    profit += doc.data().profit;
  });

  res.json({
    dailyRevenue: revenue,
    dailyProfit: profit,
    totalTransactions: snapshot.size,
  });
});

/* =====================
   AI INSIGHT (MVP)
===================== */

app.get("/ai/insights", verifyToken, (req, res) => {
  res.json({
    insight:
      "Your sales are stable. Consider increasing stock of high-selling products.",
  });
});

/* =====================
   START SERVER
===================== */

app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});