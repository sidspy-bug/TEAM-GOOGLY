const basicRoutes = require("./basicRoutes");
const userSettingsRoutes = require("./userSettingsRoutes");
const productRoutes = require("./productRoutes");
const inventoryRoutes = require("./inventoryRoutes");
const transactionRoutes = require("./transactionRoutes");
const analyticsRoutes = require("./analyticsRoutes");
const aiRoutes = require("./aiRoutes");
const ocrRoutes = require("./ocrRoutes");

function registerRoutes(app) {
  app.use(basicRoutes);
  app.use(userSettingsRoutes);
  app.use(productRoutes);
  app.use(inventoryRoutes);
  app.use(transactionRoutes);
  app.use(analyticsRoutes);
  app.use(aiRoutes);
  app.use(ocrRoutes);
}

module.exports = {
  registerRoutes,
};
