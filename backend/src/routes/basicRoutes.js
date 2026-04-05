const express = require("express");

const verifyToken = require("../../middleware/auth");

const router = express.Router();

router.get("/", (req, res) => {
  res.send("Backend connected with SQLite");
});

router.get("/auth/test", verifyToken, (req, res) => {
  res.json({
    message: "User authenticated successfully",
    uid: req.user.uid,
    email: req.user.email,
  });
});

module.exports = router;
