/**
 * generate_dataset.js — Realistic kirana store data generator for GrowthOS
 *
 * KIRANA STORE REALITY:
 *   - Purchases: BULK, infrequent (every 7-14 days per product, 15-50 units)
 *   - Sales: SMALL, frequent (2-6 per day, 1-3 units each)
 *   - Inventory: Always = total_purchased - total_sold (never negative)
 *   - Revenue/Profit: Derived strictly from product prices × units
 *
 * Date range: 2026-01-01 → 2026-04-05 (95 days)
 */

const fs = require('fs');
const path = require('path');

const TARGET_UID = 'rXLAE0lyv8Z5v8EwdBdBi1t0kcz2';
const START_DATE = new Date('2026-01-01T00:00:00');
const END_DATE = new Date('2026-04-05T23:59:59');

// ── Seeded PRNG ──────────────────────────────────────────────────────────
let seed = 42;
function rng() { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; }
function randInt(min, max) { return Math.floor(rng() * (max - min + 1)) + min; }
function pick(arr) { return arr[randInt(0, arr.length - 1)]; }

// ── HELPERS ──────────────────────────────────────────────────────────────
function dateStr(d) {
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}
function dateTimeStr(d, h, m) {
  return `${dateStr(d)} ${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:00`;
}
function isWeekend(d) { const day = d.getDay(); return day === 0 || day === 6; }
function addDays(d, n) { const r = new Date(d); r.setDate(r.getDate() + n); return r; }
function daysBetween(a, b) { return Math.floor((b - a) / 86400000); }

// ── PRODUCTS ─────────────────────────────────────────────────────────────
// Real kirana products with realistic demand tiers:
//   fast  = daily staples (milk, bread, eggs, snacks)
//   medium = weekly essentials (rice, oil, atta, dal)
//   slow  = monthly items (soap, shampoo, ghee, stationery)
const products = [
  // FAST MOVERS (sold almost every day, 1-4 units)
  { id: 618, name: 'Milk (1L)',           cat: 'Dairy',         cp: 26,  sp: 30,  gst: 0.00, tier: 'fast',   restock_days: 3,  restock_qty: [20, 35] },
  { id: 648, name: 'Curd (400g)',         cat: 'Dairy',         cp: 25,  sp: 30,  gst: 0.00, tier: 'fast',   restock_days: 3,  restock_qty: [15, 25] },
  { id: 622, name: 'Samosa (1pc)',        cat: 'Snacks',        cp: 6,   sp: 12,  gst: 0.05, tier: 'fast',   restock_days: 2,  restock_qty: [30, 50] },
  { id: 646, name: 'Biscuit (Parle-G)',   cat: 'Snacks',        cp: 8,   sp: 10,  gst: 0.05, tier: 'fast',   restock_days: 4,  restock_qty: [20, 40] },
  { id: 624, name: 'Maggi Noodles',       cat: 'Snacks',        cp: 10,  sp: 14,  gst: 0.12, tier: 'fast',   restock_days: 5,  restock_qty: [15, 30] },
  { id: 649, name: 'Onion (1kg)',         cat: 'Grocery',       cp: 30,  sp: 40,  gst: 0.00, tier: 'fast',   restock_days: 3,  restock_qty: [15, 25] },
  { id: 650, name: 'Tomato (1kg)',        cat: 'Grocery',       cp: 25,  sp: 35,  gst: 0.00, tier: 'fast',   restock_days: 3,  restock_qty: [15, 25] },
  { id: 613, name: 'Tata Salt (1kg)',     cat: 'Grocery',       cp: 22,  sp: 28,  gst: 0.05, tier: 'fast',   restock_days: 7,  restock_qty: [10, 20] },

  // MEDIUM MOVERS (sold 3-5 times per week, 1-2 units)
  { id: 614, name: 'Sugar (1kg)',         cat: 'Grocery',       cp: 38,  sp: 45,  gst: 0.05, tier: 'medium', restock_days: 7,  restock_qty: [10, 20] },
  { id: 615, name: 'Rice (5kg)',          cat: 'Grocery',       cp: 245, sp: 320, gst: 0.05, tier: 'medium', restock_days: 10, restock_qty: [8, 15]  },
  { id: 616, name: 'Cooking Oil (1L)',    cat: 'Grocery',       cp: 140, sp: 175, gst: 0.05, tier: 'medium', restock_days: 10, restock_qty: [8, 15]  },
  { id: 644, name: 'Atta (5kg)',          cat: 'Grocery',       cp: 210, sp: 265, gst: 0.05, tier: 'medium', restock_days: 10, restock_qty: [6, 12]  },
  { id: 645, name: 'Dal (1kg)',           cat: 'Grocery',       cp: 95,  sp: 120, gst: 0.05, tier: 'medium', restock_days: 7,  restock_qty: [8, 15]  },
  { id: 617, name: 'Amul Butter (200g)',  cat: 'Dairy',         cp: 52,  sp: 60,  gst: 0.05, tier: 'medium', restock_days: 7,  restock_qty: [6, 12]  },
  { id: 619, name: 'Tea (250g)',          cat: 'Beverages',     cp: 85,  sp: 110, gst: 0.05, tier: 'medium', restock_days: 10, restock_qty: [6, 10]  },
  { id: 623, name: 'Lays Chips',          cat: 'Snacks',        cp: 18,  sp: 20,  gst: 0.12, tier: 'medium', restock_days: 5,  restock_qty: [15, 25] },

  // SLOW MOVERS (sold 1-2 times per week, 1 unit)
  { id: 620, name: 'Coffee (200g)',       cat: 'Beverages',     cp: 120, sp: 155, gst: 0.05, tier: 'slow',   restock_days: 14, restock_qty: [5, 10]  },
  { id: 621, name: 'Mango Juice (1L)',    cat: 'Beverages',     cp: 55,  sp: 75,  gst: 0.12, tier: 'slow',   restock_days: 14, restock_qty: [6, 12]  },
  { id: 625, name: 'Dove Soap',           cat: 'Personal Care', cp: 38,  sp: 45,  gst: 0.18, tier: 'slow',   restock_days: 14, restock_qty: [5, 10]  },
  { id: 626, name: 'Head & Shoulders',    cat: 'Personal Care', cp: 175, sp: 220, gst: 0.18, tier: 'slow',   restock_days: 21, restock_qty: [3, 6]   },
  { id: 643, name: 'Ghee 1 kg',           cat: 'Grocery',       cp: 480, sp: 550, gst: 0.05, tier: 'slow',   restock_days: 21, restock_qty: [3, 5]   },
  { id: 647, name: 'Colgate Toothpaste',  cat: 'Personal Care', cp: 55,  sp: 72,  gst: 0.18, tier: 'slow',   restock_days: 14, restock_qty: [5, 8]   },
  { id: 627, name: 'Classmate Notebook',  cat: 'Stationery',    cp: 28,  sp: 40,  gst: 0.12, tier: 'slow',   restock_days: 21, restock_qty: [5, 10]  },
];

// Sale probability per day by tier
const SALE_CHANCE = { fast: 0.85, medium: 0.45, slow: 0.15 };
// Max units per sale by tier
const SALE_UNITS  = { fast: [1, 4], medium: [1, 2], slow: [1, 1] };

const PAYMENT_MODES   = ['Cash', 'UPI', 'Card'];
const PAYMENT_WEIGHTS = [55, 35, 10];

function weightedMode() {
  const r = rng() * 100;
  if (r < PAYMENT_WEIGHTS[0]) return PAYMENT_MODES[0];
  if (r < PAYMENT_WEIGHTS[0] + PAYMENT_WEIGHTS[1]) return PAYMENT_MODES[1];
  return PAYMENT_MODES[2];
}

// ── GENERATION ───────────────────────────────────────────────────────────

console.log('🔧 Generating realistic kirana store dataset...\n');

const totalDays = daysBetween(START_DATE, END_DATE) + 1;
const transactions = [];
const purchases = [];
const dailyMetrics = [];

// ── Initialize stock with a big bulk purchase on Dec 31 ──────────────────
const stock = {};
const lastRestock = {};
for (const p of products) {
  const qty = randInt(p.restock_qty[0], p.restock_qty[1]);
  stock[p.id] = qty;
  lastRestock[p.id] = new Date('2025-12-31');
  purchases.push({
    user_id: TARGET_UID,
    product_id: p.id,
    units_purchased: qty,
    cost_price: p.cp,
    gst: Math.round(qty * p.cp * p.gst * 100) / 100,
    purchase_date: '2025-12-31 09:00:00',
  });
}

// Per-product daily sales tracker for trend analysis
const productDailySales = {};
for (const p of products) productDailySales[p.id] = [];

// ── DAY BY DAY ───────────────────────────────────────────────────────────
for (let dayIdx = 0; dayIdx < totalDays; dayIdx++) {
  const today = addDays(START_DATE, dayIdx);
  const ds = dateStr(today);
  const weekend = isWeekend(today);

  // ── MORNING: Check if any product needs restocking ─────────────────
  for (const p of products) {
    const daysSinceLast = daysBetween(lastRestock[p.id], today);
    const needsRestock = stock[p.id] < 5 || daysSinceLast >= p.restock_days;

    if (needsRestock) {
      const qty = randInt(p.restock_qty[0], p.restock_qty[1]);
      const gst = Math.round(qty * p.cp * p.gst * 100) / 100;
      purchases.push({
        user_id: TARGET_UID,
        product_id: p.id,
        units_purchased: qty,
        cost_price: p.cp,
        gst,
        purchase_date: dateTimeStr(today, randInt(7, 9), randInt(0, 30)),
      });
      stock[p.id] += qty;
      lastRestock[p.id] = new Date(today);
    }
  }

  // ── DAYTIME: Generate sales ────────────────────────────────────────
  let dayRevenue = 0, dayProfit = 0, dayUnits = 0, dayTxCount = 0;
  const dayProductUnits = {};

  // Business hours: 9am - 9pm
  const hours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];

  for (const p of products) {
    // Determine if this product sells today
    let chance = SALE_CHANCE[p.tier];

    // Weekend boost for snacks/beverages
    if (weekend && (p.cat === 'Snacks' || p.cat === 'Beverages')) {
      chance = Math.min(chance * 1.3, 0.95);
    }
    // Seasonal: Jan-Feb → more tea/coffee; Mar-Apr → more juice/curd
    const month = today.getMonth();
    if (month <= 1 && (p.name.includes('Tea') || p.name.includes('Coffee'))) chance = Math.min(chance * 1.2, 0.95);
    if (month >= 2 && (p.name.includes('Juice') || p.name.includes('Curd'))) chance = Math.min(chance * 1.3, 0.95);

    // Slight growth over time (10% over 95 days)
    const growth = 1.0 + 0.10 * (dayIdx / totalDays);
    chance = Math.min(chance * growth, 0.95);

    if (rng() > chance) {
      productDailySales[p.id].push(0);
      continue;
    }

    // How many units sold today
    const [minU, maxU] = SALE_UNITS[p.tier];
    const units = Math.min(randInt(minU, maxU), stock[p.id]);
    if (units <= 0) {
      productDailySales[p.id].push(0);
      continue;
    }

    const revenue = units * p.sp;
    const profit = units * (p.sp - p.cp);
    const mode = weightedMode();
    const hour = pick(hours);

    transactions.push({
      user_id: TARGET_UID,
      product_id: p.id,
      units_sold: units,
      transaction_mode: mode,
      revenue: Math.round(revenue * 100) / 100,
      profit: Math.round(profit * 100) / 100,
      transaction_date: dateTimeStr(today, hour, randInt(0, 59)),
    });

    stock[p.id] -= units;
    dayRevenue += revenue;
    dayProfit += profit;
    dayUnits += units;
    dayTxCount++;
    dayProductUnits[p.id] = (dayProductUnits[p.id] || 0) + units;
    productDailySales[p.id].push(units);
  }

  // Fill 0 for products that didn't sell and weren't already tracked
  for (const p of products) {
    if (productDailySales[p.id].length < dayIdx + 1) {
      productDailySales[p.id].push(0);
    }
  }

  // ── DAILY METRICS ──────────────────────────────────────────────────
  const topEntry = Object.entries(dayProductUnits).sort((a, b) => b[1] - a[1])[0];
  const lowStockIds = products.filter(p => stock[p.id] < 5).map(p => p.id);

  // Peak hour: most common hour from today's transactions
  const todayTxHours = transactions
    .filter(t => t.transaction_date.startsWith(ds))
    .map(t => parseInt(t.transaction_date.split(' ')[1].split(':')[0]));
  const hourCounts = {};
  for (const h of todayTxHours) hourCounts[h] = (hourCounts[h] || 0) + 1;
  const peakHour = Object.entries(hourCounts).sort((a, b) => b[1] - a[1])[0];

  dailyMetrics.push({
    date: ds,
    total_revenue: Math.round(dayRevenue * 100) / 100,
    total_profit: Math.round(dayProfit * 100) / 100,
    total_units_sold: dayUnits,
    transactions_count: dayTxCount,
    avg_order_value: dayTxCount > 0 ? Math.round((dayRevenue / dayTxCount) * 100) / 100 : 0,
    top_selling_product_id: topEntry ? parseInt(topEntry[0]) : null,
    top_selling_units: topEntry ? topEntry[1] : 0,
    low_stock_products: lowStockIds,
    peak_sales_hour: peakHour ? `${String(peakHour[0]).padStart(2, '0')}:00` : '12:00',
  });
}

// ── OVERALL METRICS ──────────────────────────────────────────────────────
const totalRevenue = Math.round(transactions.reduce((s, t) => s + t.revenue, 0) * 100) / 100;
const totalProfit = Math.round(transactions.reduce((s, t) => s + t.profit, 0) * 100) / 100;
const totalUnitsSold = transactions.reduce((s, t) => s + t.units_sold, 0);
const totalTransactions = transactions.length;

const bestDay = dailyMetrics.reduce((b, d) => d.total_revenue > b.total_revenue ? d : b);
const worstDay = dailyMetrics.reduce((w, d) => d.total_revenue < w.total_revenue ? d : w);

// Per-product aggregation
const prodAgg = {};
for (const p of products) prodAgg[p.id] = { units: 0, revenue: 0, profit: 0 };
for (const tx of transactions) {
  prodAgg[tx.product_id].units += tx.units_sold;
  prodAgg[tx.product_id].revenue += tx.revenue;
  prodAgg[tx.product_id].profit += tx.profit;
}

const mostProfitable = products.reduce((best, p) => prodAgg[p.id].profit > prodAgg[best.id].profit ? p : best);
const leastProfitable = products.reduce((worst, p) => prodAgg[p.id].profit < prodAgg[worst.id].profit ? p : worst);

const overallMetrics = {
  total_revenue: totalRevenue,
  total_profit: totalProfit,
  total_units_sold: totalUnitsSold,
  total_transactions: totalTransactions,
  avg_daily_revenue: Math.round((totalRevenue / totalDays) * 100) / 100,
  avg_daily_profit: Math.round((totalProfit / totalDays) * 100) / 100,
  best_day: bestDay.date,
  worst_day: worstDay.date,
  most_profitable_product_id: mostProfitable.id,
  least_profitable_product_id: leastProfitable.id,
};

// ── PRODUCT PERFORMANCE ──────────────────────────────────────────────────
const productPerformance = products.map(p => {
  const agg = prodAgg[p.id];
  const sales = productDailySales[p.id];
  const daysActive = sales.filter(s => s > 0).length;

  // Trend: compare last 3 weeks avg vs first 3 weeks avg
  const firstWeeks = sales.slice(0, 21).reduce((a, b) => a + b, 0) / 21;
  const lastWeeks = sales.slice(-21).reduce((a, b) => a + b, 0) / 21;
  let trend = 'stable';
  if (lastWeeks > firstWeeks * 1.15) trend = 'increasing';
  else if (lastWeeks < firstWeeks * 0.85) trend = 'decreasing';

  return {
    product_id: p.id,
    product_name: p.name,
    total_units_sold: agg.units,
    total_revenue: Math.round(agg.revenue * 100) / 100,
    total_profit: Math.round(agg.profit * 100) / 100,
    avg_daily_sales: Math.round((agg.units / totalDays) * 100) / 100,
    sales_frequency: daysActive,
    trend,
  };
});

// ── FORECASTING ──────────────────────────────────────────────────────────
const next7DaysForecast = products.map(p => {
  const recent = productDailySales[p.id].slice(-14);
  const recentAvg = recent.reduce((a, b) => a + b, 0) / recent.length;
  const predicted = Math.max(1, Math.round(recentAvg * 1.05));
  const confidence = Math.min(0.95, 0.7 + (prodAgg[p.id].units > 50 ? 0.2 : prodAgg[p.id].units > 20 ? 0.1 : 0));

  return {
    product_id: p.id,
    product_name: p.name,
    predicted_daily_demand: predicted,
    confidence: Math.round(confidence * 100) / 100,
    recommended_restock: Math.max(0, (predicted * 7) - stock[p.id]),
  };
});

const stockAlerts = products.map(p => {
  const recent7 = productDailySales[p.id].slice(-7);
  const avgDaily = recent7.reduce((a, b) => a + b, 0) / 7;
  const daysUntil = avgDaily > 0 ? Math.round(stock[p.id] / avgDaily) : 999;
  let urgency = 'low';
  if (daysUntil <= 2) urgency = 'high';
  else if (daysUntil <= 5) urgency = 'medium';

  return {
    product_id: p.id,
    product_name: p.name,
    current_stock: stock[p.id],
    days_until_stockout: Math.min(daysUntil, 999),
    urgency,
  };
}).sort((a, b) => a.days_until_stockout - b.days_until_stockout);

const risingProducts = productPerformance.filter(p => p.trend === 'increasing').map(p => p.product_id);
const decliningProducts = productPerformance.filter(p => p.trend === 'decreasing').map(p => p.product_id);

// Weekend spike detection
const weekdayTotals = {}, weekendTotals = {};
let weekdayCount = 0, weekendCount = 0;
for (let i = 0; i < totalDays; i++) {
  const d = addDays(START_DATE, i);
  if (isWeekend(d)) { weekendCount++; } else { weekdayCount++; }
  for (const p of products) {
    const s = productDailySales[p.id][i] || 0;
    if (isWeekend(d)) { weekendTotals[p.id] = (weekendTotals[p.id] || 0) + s; }
    else { weekdayTotals[p.id] = (weekdayTotals[p.id] || 0) + s; }
  }
}
const weekendSpikeProducts = products
  .filter(p => ((weekendTotals[p.id] || 0) / weekendCount) > ((weekdayTotals[p.id] || 0) / weekdayCount) * 1.2)
  .map(p => p.id);

const trendSignals = {
  rising_products: risingProducts,
  declining_products: decliningProducts,
  seasonal_patterns: [
    { pattern: 'weekend spike', products: weekendSpikeProducts },
    { pattern: 'summer beverage surge (Mar-Apr)', products: products.filter(p => p.cat === 'Beverages' || p.name.includes('Curd')).map(p => p.id) },
  ],
};

// ── FINAL OUTPUT ─────────────────────────────────────────────────────────
const output = {
  uid: TARGET_UID,
  generated_at: new Date().toISOString(),
  date_range: { start: '2026-01-01', end: '2026-04-05', total_days: totalDays },
  products: products.map(p => ({
    id: p.id, user_id: TARGET_UID, product_name: p.name,
    category: p.cat, cost_price: p.cp, selling_price: p.sp,
  })),
  transactions,
  purchases,
  daily_metrics: dailyMetrics,
  overall_metrics: overallMetrics,
  product_performance: productPerformance,
  forecast: { next_7_days: next7DaysForecast, stock_alerts: stockAlerts, trend_signals: trendSignals },
};

// ── VALIDATION ───────────────────────────────────────────────────────────
console.log('🔍 VALIDATION:');

const allDates = new Set(dailyMetrics.map(d => d.date));
let missing = 0;
for (let i = 0; i < totalDays; i++) {
  if (!allDates.has(dateStr(addDays(START_DATE, i)))) missing++;
}
console.log(`  Dates: ${allDates.size}/${totalDays} (missing: ${missing}) ${missing === 0 ? '✅' : '❌'}`);
console.log(`  Negative profit txns: ${transactions.filter(t => t.profit < 0).length} ${transactions.filter(t => t.profit < 0).length === 0 ? '✅' : '❌'}`);

const txRevSum = Math.round(transactions.reduce((s, t) => s + t.revenue, 0) * 100) / 100;
console.log(`  Revenue match: overall=${overallMetrics.total_revenue} vs txSum=${txRevSum} ${Math.abs(overallMetrics.total_revenue - txRevSum) < 1 ? '✅' : '❌'}`);

const negStock = Object.entries(stock).filter(([_, v]) => v < 0);
console.log(`  Negative stock items: ${negStock.length} ${negStock.length === 0 ? '✅' : '❌'}`);

// Check realism
const avgTxPerDay = totalTransactions / totalDays;
console.log(`  Avg transactions/day: ${avgTxPerDay.toFixed(1)} (target: 3-8) ${avgTxPerDay >= 3 && avgTxPerDay <= 10 ? '✅' : '⚠️'}`);

const avgPurPerDay = purchases.length / totalDays;
console.log(`  Avg purchases/day: ${avgPurPerDay.toFixed(1)} (should be <3) ${avgPurPerDay < 3 ? '✅' : '⚠️'}`);

// Inventory cross-check
let invOk = true;
for (const p of products) {
  const bought = purchases.filter(r => r.product_id === p.id).reduce((s, r) => s + r.units_purchased, 0);
  const sold = transactions.filter(t => t.product_id === p.id).reduce((s, t) => s + t.units_sold, 0);
  const expected = bought - sold;
  if (expected !== stock[p.id]) { console.log(`  ❌ Stock mismatch ${p.name}: expected ${expected}, got ${stock[p.id]}`); invOk = false; }
}
console.log(`  Inventory integrity: ${invOk ? '✅' : '❌'}`);

console.log(`\n📊 SUMMARY:`);
console.log(`  Products:     ${products.length}`);
console.log(`  Sales (transactions): ${transactions.length} (across ${totalDays} days)`);
console.log(`  Purchases (restocks): ${purchases.length} (bulk orders)`);
console.log(`  Avg Sales/day: ${avgTxPerDay.toFixed(1)} rows — realistic kirana pattern`);
console.log(`  Avg Purchase/day: ${avgPurPerDay.toFixed(1)} rows — bulk periodic restocks`);
console.log(`  Total Revenue:  ₹${overallMetrics.total_revenue.toLocaleString()}`);
console.log(`  Total Profit:   ₹${overallMetrics.total_profit.toLocaleString()}`);
console.log(`  Best Day:       ${overallMetrics.best_day}`);
console.log(`  Worst Day:      ${overallMetrics.worst_day}`);

const outPath = path.join(__dirname, 'generated_dataset.json');
fs.writeFileSync(outPath, JSON.stringify(output, null, 2));
console.log(`\n💾 Written to: ${outPath} (${(fs.statSync(outPath).size / 1024).toFixed(0)} KB)`);
