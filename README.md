# TEAM-GOOGLY
## Backend API Contract (MVP)

Base URL: http://localhost:3000  
Auth: Firebase ID Token (Bearer)

### GET /analytics/daily
Response:
{
  "dailyRevenue": number,
  "dailyProfit": number,
  "totalTransactions": number
}

### GET /products/list
Response:
[
  {
    "id": string,
    "productName": string,
    "category": string,
    "costPrice": number,
    "sellingPrice": number
  }
]

### GET /inventory/status
Response:
[
  {
    "productId": string,
    "currentStock": number,
    "status": "Normal | Low | Out of Stock"
  }
]
### GET /dashboard/summary

Response:
{
  "totalRevenue": number,
  "totalProfit": number,
  "dailyRevenue": number,
  "dailyProfit": number,
  "totalTransactions": number,
  "topCategory": string,
  "lowStockCount": number
}
