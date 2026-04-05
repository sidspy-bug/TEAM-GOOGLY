const express = require("express");

const db = require("../../db");
const verifyToken = require("../../middleware/auth");
const { VALID_LANGUAGES } = require("../config/constants");

const router = express.Router();

router.get("/user/settings", verifyToken, (req, res) => {
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
    language: row.language || "en",
  });
});

router.put("/user/settings", verifyToken, (req, res) => {
  const uid = req.user.uid;
  const { shopName, avatarIndex, onboarded, language } = req.body;

  const existing = db.prepare("SELECT uid FROM user_settings WHERE uid = ?").get(uid);

  if (!existing) {
    db.prepare(
      "INSERT INTO user_settings (uid, shop_name, avatar_index, onboarded, language) VALUES (?, ?, ?, ?, ?)"
    ).run(
      uid,
      shopName || "My Shop",
      avatarIndex ?? -1,
      onboarded ? 1 : 0,
      VALID_LANGUAGES.includes(language) ? language : "en"
    );
  } else {
    const updates = [];
    const params = [];

    if (shopName !== undefined) {
      updates.push("shop_name = ?");
      params.push(shopName);
    }
    if (avatarIndex !== undefined) {
      updates.push("avatar_index = ?");
      params.push(avatarIndex);
    }
    if (onboarded !== undefined) {
      updates.push("onboarded = ?");
      params.push(onboarded ? 1 : 0);
    }
    if (language !== undefined && VALID_LANGUAGES.includes(language)) {
      updates.push("language = ?");
      params.push(language);
    }

    updates.push("updated_at = datetime('now')");
    params.push(uid);

    db.prepare(`UPDATE user_settings SET ${updates.join(", ")} WHERE uid = ?`).run(...params);
  }

  res.json({ message: "Settings updated" });
});

module.exports = router;
