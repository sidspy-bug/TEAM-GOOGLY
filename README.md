# TEAM-GOOGLY

Integrated repository containing:
- Flutter frontend dashboard app
- Node.js/Express backend API with Firebase Admin

## Frontend (Flutter)

A data-driven Flutter dashboard for small shop owners (MSMEs), including summary cards, charts, product insights, and a premium insights panel.

### Frontend Quick Start

Prerequisites:
- Flutter SDK 2.18+

Run on web:
```bash
flutter pub get
flutter build web
cd build/web
python3 -m http.server 5000
```
Open `http://localhost:5000`.

Or run in debug mode:
```bash
flutter run -d web-server --web-port=3000
```
Open `http://localhost:3000`.

## Backend (Node.js + Express + Firebase Admin)

Base URL: `http://localhost:3000`  
Auth: Firebase ID Token (Bearer)

### Backend Quick Start

```bash
cd backend
npm install
npm start
```

Place your Firebase service account key at:
- `backend/serviceAccountKey.json`

### API Contract (MVP)

#### GET `/analytics/daily`
Response:
```json
{
  "dailyRevenue": "number",
  "dailyProfit": "number",
  "totalTransactions": "number"
}
```

#### GET `/products/list`
Response:
```json
[
  {
    "id": "string",
    "productName": "string",
    "category": "string",
    "costPrice": "number",
    "sellingPrice": "number"
  }
]
```

#### GET `/inventory/status`
Response:
```json
[
  {
    "productId": "string",
    "currentStock": "number",
    "status": "Normal | Low | Out of Stock"
  }
]
```

#### GET `/dashboard/summary`
Response:
```json
{
  "totalRevenue": "number",
  "totalProfit": "number",
  "dailyRevenue": "number",
  "dailyProfit": "number",
  "totalTransactions": "number",
  "topCategory": "string",
  "lowStockCount": "number"
}
```
