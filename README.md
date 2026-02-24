# AI-Powered Business Insights App (MVP)

A clean, data-driven Flutter dashboard for small shop owners (MSMEs). Shows business analytics and unlocks AI insights for premium users.

## Features

✅ **Summary Cards** — Total Sales, Top Category, Low Stock count, Sales Trend  
✅ **Sales Trend Chart** — Line chart showing sales over 14 days  
✅ **Category Breakdown** — Bar chart with category-wise sales  
✅ **Product Focus** — Top 3 & Bottom 3 products by quantity  
✅ **AI Insights Panel** — Premium-only insights with reasons & actions  
✅ **Premium Upgrade** — Click the star icon in AppBar to upgrade instantly  
✅ **Responsive Design** — Works on mobile and desktop  
✅ **Flutter Web Ready** — Tested and working on Chrome/Web  

## Quick Start

**Prerequisites:**
- Flutter SDK 2.18+
- Any browser (Chrome, Firefox, Edge)

**Run on Web:**
```bash
flutter pub get
flutter build web
cd build/web
python3 -m http.server 5000
# Open http://localhost:5000 in your browser
```

**Or run in debug mode:**
```bash
flutter run -d web-server --web-port=3000
# Open http://localhost:3000 in your browser
```

**Toggle Premium Mode:**
Click the **star icon** in the top-right of the AppBar:
- **Outlined star** = Free user
- **Filled amber star** = Premium user
- Tapping the star upgrades instantly (premium state updates globally)

## Project Structure

```
lib/
  ├── main.dart                 # Entry point, app config
  ├── models/
  │   ├── sale.dart             # Sale model (product, category, qty, price, date)
  │   └── dashboard_summary.dart # Aggregated dashboard data
  ├── repositories/
  │   ├── sales_repository.dart       # Abstract repository interface
  │   └── dummy_sales_repository.dart # Mock implementation with dummy data
  ├── screens/
  │   └── dashboard_screen.dart       # Main dashboard (with state for premium toggle)
  └── widgets/
      ├── summary_card.dart      # Summary card (Sales, Category, Stock, Trend)
      ├── line_chart_card.dart   # Sales trend chart
      ├── bar_chart_card.dart    # Category breakdown chart
      ├── product_list.dart      # Top & slow-moving product lists
      └── insight_card.dart      # AI insight panel (free: upgrade, premium: insight)
```

## Data Flow

1. **UI** (DashboardScreen) depends on **Repository**
2. **Repository** (DummySalesRepository) returns mock **Models** (DashboardSummary, Sale)
3. **Widgets** receive data and render (no hardcoded values)

This keeps the UI decoupled from backend logic, so you can swap `DummySalesRepository` with `FirebaseRepository` later.

## Customization

**Change premium flag in code (for testing):**
Edit `lib/main.dart` line 8:
```dart
const bool isPremiumUser = true;  // Toggle for testing
```

**Modify dummy data:**
Edit `lib/repositories/dummy_sales_repository.dart` to change product names, categories, sales values, etc.

**Adjust dashboard layout:**
Edit `lib/screens/dashboard_screen.dart` to add/remove cards or reorder sections.

## Next Steps (Not Implemented)

- 🔐 Firebase Auth (login/signup)
- 📊 Firestore (real data backend)
- 🤖 Google Gemini API (AI insights generation)
- 💳 Payment system (premium subscriptions)
- 📱 Mobile app packaging (APK/IPA)

## Tech Stack

- **Frontend:** Flutter (Material Design)
- **Charts:** fl_chart 0.66.2
- **Backend:** (Placeholder) Firebase/Cloud Run
- **AI:** (Placeholder) Google Gemini API

## Notes

- UI is fully functional with dummy data — no backend connection required
- Charts are Web-safe with error handling (try/catch, null checks)
- Responsive: Grid cards adapt to screen size, drawer on mobile
- All widgets are stateless or minimal state (clean architecture)

this is the hackathone project trail for the ui
it is actually good to see it 

