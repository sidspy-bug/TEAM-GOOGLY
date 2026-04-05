function parseReceiptText(text) {
  const lines = text
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);
  const products = [];

  const skipPatterns =
    /^(subtotal|sub total|total|tax|gst|vat|amount|balance|change|cash|card|payment|receipt|invoice|bill|date|time|phone|tel|address|thank|www|http|email|\*+|-{3,}|={3,}|#{3,})/i;
  const totalLinePattern =
    /(subtotal|sub[\s-]?total|grand[\s-]?total|total\s*(amount|due|payable)?|tax|gst|vat|discount|net\s*amount|balance|change|cash|tendered)/i;

  for (const line of lines) {
    if (skipPatterns.test(line) || totalLinePattern.test(line) || line.length < 3) {
      continue;
    }

    const qtyTimesPrice = line.match(/^(.+?)\s+(\d+)\s*[x×X]\s*\$?([\d,.]+)\s*(?:\$?([\d,.]+))?$/);
    if (qtyTimesPrice) {
      const name = qtyTimesPrice[1].replace(/[.]{2,}$/, "").trim();
      const qty = parseInt(qtyTimesPrice[2], 10);
      const unit = parseFloat(qtyTimesPrice[3].replace(",", ""));
      const total = qtyTimesPrice[4]
        ? parseFloat(qtyTimesPrice[4].replace(",", ""))
        : qty * unit;

      if (name.length > 1 && !Number.isNaN(qty) && !Number.isNaN(unit)) {
        products.push({
          productName: cleanName(name),
          quantity: qty,
          costPrice: unit,
          sellingPrice: 0,
          totalPrice: Math.round(total * 100) / 100,
        });
        continue;
      }
    }

    const multiNum = line.match(/^(.+?)\s+(\d+)\s+\$?([\d,.]+)\s+\$?([\d,.]+)$/);
    if (multiNum) {
      const name = multiNum[1].replace(/[.]{2,}$/, "").trim();
      const qty = parseInt(multiNum[2], 10);
      const unitPrice = parseFloat(multiNum[3].replace(",", ""));
      const totalPrice = parseFloat(multiNum[4].replace(",", ""));

      if (name.length > 1 && qty > 0 && qty < 10000 && !Number.isNaN(unitPrice)) {
        products.push({
          productName: cleanName(name),
          quantity: qty,
          costPrice: unitPrice,
          sellingPrice: 0,
          totalPrice: Math.round(totalPrice * 100) / 100,
        });
        continue;
      }
    }

    const singlePrice = line.match(/^(.+?)\s{2,}\$?([\d,.]+)$/);
    if (singlePrice) {
      const name = singlePrice[1].replace(/[.]{2,}$/, "").trim();
      const price = parseFloat(singlePrice[2].replace(",", ""));

      if (name.length > 1 && !Number.isNaN(price) && price > 0 && price < 100000) {
        products.push({
          productName: cleanName(name),
          quantity: 1,
          costPrice: price,
          sellingPrice: 0,
          totalPrice: price,
        });
        continue;
      }
    }

    const qtyFirst = line.match(/^(\d+)\s+(.+?)\s{2,}\$?([\d,.]+)$/);
    if (qtyFirst) {
      const qty = parseInt(qtyFirst[1], 10);
      const name = qtyFirst[2].replace(/[.]{2,}$/, "").trim();
      const price = parseFloat(qtyFirst[3].replace(",", ""));

      if (name.length > 1 && qty > 0 && qty < 10000 && !Number.isNaN(price)) {
        products.push({
          productName: cleanName(name),
          quantity: qty,
          costPrice: Math.round((price / qty) * 100) / 100,
          sellingPrice: 0,
          totalPrice: price,
        });
      }
    }
  }

  return products;
}

function cleanName(name) {
  return name
    .replace(/^[\-\*\#\u2022\u00B7]+\s*/, "")
    .replace(/\s+/g, " ")
    .replace(/[.]{2,}$/, "")
    .trim();
}

module.exports = {
  parseReceiptText,
};
