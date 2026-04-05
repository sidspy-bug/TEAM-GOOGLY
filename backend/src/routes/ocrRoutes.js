const express = require("express");
const { createWorker } = require("tesseract.js");

const verifyToken = require("../../middleware/auth");
const { parseReceiptText } = require("../utils/ocrParser");

const router = express.Router();

router.post("/ocr/scan", verifyToken, async (req, res) => {
  try {
    const { image } = req.body;

    if (!image) {
      return res.status(400).json({ error: "Base64 image data is required" });
    }

    const imageBuffer = Buffer.from(image, "base64");
    const worker = await createWorker("eng");
    const {
      data: { text },
    } = await worker.recognize(imageBuffer);
    await worker.terminate();

    const rawText = text.trim();
    const parsedProducts = parseReceiptText(rawText);

    const dateMatch =
      rawText.match(/(?:date|dated?|dt)[:\s]*(\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4})/i) ||
      rawText.match(/(\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4})/);
    const extractedDate = dateMatch ? dateMatch[1] : new Date().toISOString().split("T")[0];

    const lines = rawText
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);
    const vendorName = lines.length > 0 ? lines[0] : "Unknown vendor";

    return res.json({
      text: rawText,
      characters: rawText.length,
      extractedDate,
      vendorName,
      parsedProducts,
      message: "OCR scan completed successfully",
    });
  } catch (error) {
    console.error("OCR error:", error);
    return res.status(500).json({ error: "OCR processing failed" });
  }
});

module.exports = router;
