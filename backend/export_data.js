const Database = require('better-sqlite3');
const path = require('path');

const TARGET_UID = 'rXLAE0lyv8Z5v8EwdBdBi1t0kcz2';
const db = new Database(path.join(__dirname, 'shop.db'));

function exportData() {
  console.log('--- START EXPORT ---');
  
  const products = db.prepare('SELECT id, product_name, category, cost_price, selling_price FROM products WHERE user_id = ?').all(TARGET_UID);
  
  const transactions = db.prepare(`
    SELECT t.*, p.product_name 
    FROM transactions t 
    JOIN products p ON t.product_id = p.id 
    WHERE t.user_id = ?
  `).all(TARGET_UID);
  
  const purchases = db.prepare(`
    SELECT pur.*, p.product_name 
    FROM purchases pur 
    JOIN products p ON pur.product_id = p.id 
    WHERE pur.user_id = ?
  `).all(TARGET_UID);

  const data = {
    uid: TARGET_UID,
    products,
    salesHistory: transactions,
    purchaseHistory: purchases
  };

  console.log(JSON.stringify(data, null, 2));
  console.log('--- END EXPORT ---');
}

exportData();
db.close();
