# GrowthOS — AI-Powered Business Insights for Small Shop Owners

GrowthOS is a full-stack Flutter + Node.js application that helps small shop owners (MSMEs) manage their products, track sales, monitor inventory, and get AI-driven business insights — all from a clean, responsive dashboard.

---

## Features

✅ **Firebase Authentication** — Email/Password, Google, and Facebook sign-in with email verification  
✅ **Onboarding Flow** — Shop name and avatar setup on first login  
✅ **Dashboard** — Summary cards (revenue, profit, units sold, low stock), sales trend chart, category breakdown, top products table, and AI insights  
✅ **Inventory Management** — Add products with cost/selling price, manage stock levels, view low-stock alerts  
✅ **Sales Recording** — Record transactions (cash/card/UPI), auto-deducts from inventory  
✅ **Sales History** — Filterable transaction log with product, quantity, revenue, and profit columns  
✅ **OCR Receipt Scanner** — Photograph a purchase or sales invoice; Tesseract.js extracts text and pre-fills product rows for one-tap import  
✅ **AI Insights** — Rule-based insights surfacing your top seller and low-stock warnings (premium panel)  
✅ **Premium Toggle** — Star icon in the AppBar switches between Basic and Premium tier in-app  
✅ **Settings** — Change shop name, avatar, currency, notification and theme preferences; view account details; delete account  
✅ **Responsive Design** — Permanent sidebar on desktop, hamburger drawer on mobile  
✅ **Floating AI Assistant** — Contextual AI chat panel on the Dashboard screen  

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 2.18+ (Material Design 3), `fl_chart`, `image_picker` |
| Auth | Firebase Authentication (email/password, Google, Facebook) |
| Analytics | Firebase Analytics |
| Backend | Node.js + Express 5 |
| Database | SQLite via `better-sqlite3` (WAL mode) |
| OCR | Tesseract.js (`tesseract.js` v7) |
| HTTP Client | `package:http` with automatic Firebase ID-token injection |

---

## Quick Start

### Prerequisites

- Flutter SDK ≥ 2.18
- Node.js ≥ 18
- A browser (Chrome recommended for Flutter Web)

### 1 — Start the Backend

```bash
cd backend
npm install
node index.js
# Server runs on http://localhost:3000
```

### 2 — Run the Flutter App

```bash
flutter pub get
flutter run -d web-server --web-port=5000
# Open http://localhost:5000 in your browser
```

> **Codespaces / remote hosts:** The Flutter app auto-detects GitHub Codespaces URLs and rewrites the API base URL to the port-3000 forwarded host. Just make sure port 3000 is set to **Public** in the Ports panel.

---

## Project Structure

```
TEAM-GOOGLY/
├── lib/                          # Flutter frontend
│   ├── main.dart                 # Entry point — Firebase init, auth routing, AppShell
│   ├── firebase_options.dart     # Generated Firebase config
│   ├── models/
│   │   ├── sale.dart             # Sale / product model (id, name, category, qty, price, stock)
│   │   └── dashboard_summary.dart# Aggregated dashboard data passed to widgets
│   ├── repositories/
│   │   ├── sales_repository.dart          # Abstract interface (getSales, getDashboardSummary, getAiInsight)
│   │   ├── api_sales_repository.dart      # Live implementation — calls backend REST API, with in-memory cache
│   │   ├── dummy_sales_repository.dart    # Mock implementation — offline/fallback data
│   │   └── sales_repository_facade.dart   # Tries API first, falls back to dummy on error/empty
│   ├── services/
│   │   ├── api_service.dart      # Singleton HTTP client — attaches Bearer token, handles 401 logout
│   │   ├── auth_service.dart     # Singleton Firebase Auth wrapper (sign-in, sign-up, Google, Facebook, sign-out)
│   │   └── shop_config.dart      # Singleton shop settings — syncs to backend, caches in SharedPreferences
│   ├── screens/
│   │   ├── login_screen.dart             # Email/password + Google + Facebook sign-in
│   │   ├── signup_screen.dart            # Account creation + email verification trigger
│   │   ├── email_verification_screen.dart# Polls email-verified flag; resend link option
│   │   ├── forgot_password_screen.dart   # Password-reset email flow
│   │   ├── otp_verification_screen.dart  # OTP / phone verification
│   │   ├── onboarding_screen.dart        # First-login shop setup (name + avatar)
│   │   ├── dashboard_screen.dart         # Main dashboard with charts, summary cards, AI insights
│   │   ├── inventory_screen.dart         # Product list, add product, add stock, sell product dialogs
│   │   ├── sales_history_screen.dart     # Paginated transaction history
│   │   ├── ocr_screen.dart               # Camera/gallery image → OCR → editable product rows → save
│   │   └── settings_screen.dart          # Shop name, avatar, currency, notifications, theme, account
│   └── widgets/
│       ├── summary_card.dart       # Metric card (label + value + optional trend icon)
│       ├── line_chart_card.dart    # Sales-over-time line chart (fl_chart)
│       ├── bar_chart_card.dart     # Category-breakdown bar chart (fl_chart)
│       ├── top_products_table.dart # Sortable table of top products by revenue
│       ├── ai_insights_card.dart   # Premium AI insight tile (insight + reason + action)
│       ├── today_focus_card.dart   # "Today's Focus" highlight card
│       ├── insight_card.dart       # Generic insight chip
│       ├── product_list.dart       # Top-3 / Bottom-3 product lists
│       ├── floating_ai_assistant.dart # Floating chat button + slide-in panel
│       └── ai_assistant_panel.dart    # AI assistant conversation panel
└── backend/                      # Node.js / Express backend
    ├── index.js                  # All REST API routes
    ├── db.js                     # SQLite schema creation and connection
    ├── middleware/
    │   └── auth.js               # Firebase Admin token verification middleware
    ├── serviceAccountKey.json    # Firebase service account (not committed in production)
    └── package.json
```

---

## Backend API Reference

All endpoints (except `GET /`) require a `Authorization: Bearer <Firebase ID token>` header.

### User Settings
| Method | Path | Description |
|--------|------|-------------|
| GET | `/user/settings` | Get shop name, avatar index, onboarded flag |
| PUT | `/user/settings` | Update shop name / avatar / onboarded flag |

### Products
| Method | Path | Description |
|--------|------|-------------|
| POST | `/products/add` | Add a new product (name, category, costPrice, sellingPrice) |
| GET | `/products/list` | List all products for the authenticated user |
| GET | `/products/category/:category` | List products filtered by category |
| PUT | `/products/update/:id` | Update product fields |
| DELETE | `/products/delete/:id` | Delete a product |

### Inventory
| Method | Path | Description |
|--------|------|-------------|
| POST | `/inventory/add` | Add / top-up stock for a product |
| GET | `/inventory/status` | Stock levels with Normal / Low / Out-of-Stock status |

### Transactions
| Method | Path | Description |
|--------|------|-------------|
| POST | `/transactions/sell` | Record a sale (deducts stock atomically) |
| GET | `/transactions/history` | Last 100 transactions with product details |

### Analytics & Dashboard
| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard/summary` | Total revenue, profit, units sold, low-stock count |
| GET | `/analytics/daily` | Today's revenue, profit, transaction count |
| GET | `/analytics/summary` | Today / 7-day / 30-day breakdowns + top products + low stock |
| GET | `/analytics/weekly-chart` | Daily revenue & profit for the last 7 days |

### AI & OCR
| Method | Path | Description |
|--------|------|-------------|
| GET | `/ai/insights` | Rule-based insight: top seller + low-stock warning |
| POST | `/ocr/scan` | Base64 image → Tesseract OCR → structured product rows |

---

## Database Schema (SQLite)

```sql
user_settings  (uid PK, shop_name, avatar_index, onboarded, created_at, updated_at)
products       (id PK, user_id, product_name, category, cost_price, selling_price, created_at, updated_at)
inventory      (product_id PK → products.id, user_id, current_stock, updated_at)
transactions   (id PK, user_id, product_id → products.id, units_sold, transaction_mode, revenue, profit, transaction_date)
```

Indexed on `user_id` columns and `transaction_date` for fast per-user queries.

---

## Data Flow

```
Firebase Auth ──► AuthService ──► main.dart (auth state listener)
                                       │
                              ShopConfig.loadForUser()
                                       │
                              AppShell (Dashboard / Inventory / Sales / Settings / OCR)
                                       │
                         SalesRepositoryFacade
                         ┌─────────────┴──────────────┐
                  ApiSalesRepository           DummySalesRepository
                  (live backend calls)          (offline fallback)
                         │
                    ApiService (HTTP + Bearer token)
                         │
                  Node.js / Express backend
                         │
                      SQLite DB
```

1. On login, `ShopConfig` loads the user's settings from the backend (falls back to local `SharedPreferences` cache).
2. `SalesRepositoryFacade` tries `ApiSalesRepository` first; if the API is unreachable or returns empty data, it falls back to `DummySalesRepository`.
3. `ApiService` is a singleton that automatically attaches the Firebase ID token to every request and triggers logout on 401.
4. All write operations (sell, add product, update stock) hit the backend and invalidate the in-memory cache in `ApiSalesRepository`.

---

## Notes

- The OCR endpoint uses `tesseract.js` (server-side) with four receipt parsing patterns; results are pre-filled in an editable table so the user can correct them before saving.
- Low-stock threshold is set to **5 units** in `backend/index.js` (`LOW_STOCK_THRESHOLD = 5`).
- Premium mode is toggled client-side via the star button in the AppBar (no payment integration yet).
- `serviceAccountKey.json` is required for Firebase Admin token verification in production; the backend logs a warning and runs without it (all requests accepted) if the file is absent.

