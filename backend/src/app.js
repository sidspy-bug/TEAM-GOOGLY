const express = require("express");
const cors = require("cors");

const { initializeFirebaseAdmin } = require("./config/firebase");
const { registerRoutes } = require("./routes");

function createApp() {
  initializeFirebaseAdmin();

  const app = express();

  app.use(cors());
  app.use(express.json({ limit: "10mb" }));
  app.use(express.urlencoded({ limit: "10mb", extended: true }));

  registerRoutes(app);

  return app;
}

module.exports = {
  createApp,
};
