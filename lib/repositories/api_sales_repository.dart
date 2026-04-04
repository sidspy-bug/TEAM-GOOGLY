import '../models/sale.dart';
import '../models/dashboard_summary.dart';
import '../services/api_service.dart';
import 'sales_repository.dart';

/// SalesRepository implementation backed by the backend REST API.
/// Singleton so cache is shared across the app.
class ApiSalesRepository implements SalesRepository {
  static final ApiSalesRepository _instance = ApiSalesRepository._internal();
  factory ApiSalesRepository() => _instance;
  ApiSalesRepository._internal();

  final ApiService _api = ApiService();

  // Cached data per page load
  List<Sale>? _cachedSales;
  DashboardSummary? _cachedSummary;

  /// Clear caches (call on logout or manual refresh).
  void clearCache() {
    _cachedSales = null;
    _cachedSummary = null;
  }

  @override
  Future<List<Sale>> getSales() async {
    if (_cachedSales != null) return _cachedSales!;

    try {
      // Fetch products, inventory and transaction history in parallel.
      final results = await Future.wait([
        _api.get('/products/list'),
        _api.get('/inventory/status'),
        _api.get('/transactions/history'),
      ]);

      final List<dynamic> productsJson = results[0] is List ? results[0] : [];
      final List<dynamic> inventoryJson = results[1] is List ? results[1] : [];
      final List<dynamic> transactionsJson = results[2] is List ? results[2] : [];

      final Map<String, Map<String, dynamic>> productMap = {};
      for (final p in productsJson) {
        if (p is Map<String, dynamic> && p['id'] != null) {
          productMap[p['id'].toString()] = p;
        }
      }

      // Build inventory lookup by productId
      final Map<String, Map<String, dynamic>> inventoryMap = {};
      for (final inv in inventoryJson) {
        if (inv is Map<String, dynamic> && inv['productId'] != null) {
          inventoryMap[inv['productId'].toString()] = inv;
        }
      }

      final List<Sale> sales = [];

      final Set<String> txProductIds = {};
      for (final t in transactionsJson) {
        if (t is! Map<String, dynamic>) continue;
        final id = (t['productId'] ?? '').toString();
        if (id.isEmpty) continue;
        txProductIds.add(id);

        final product = productMap[id];
        final inv = inventoryMap[id];
        final units = _toInt(t['unitsSold']);
        final revenue = _toDouble(t['revenue']);
        final profit = _toDouble(t['profit']);
        final sellingPrice = units > 0
          ? (revenue / units).toDouble()
            : _toDouble(product?['sellingPrice']);
        final derivedCost = units > 0 ? ((revenue - profit) / units).toDouble() : 0.0;
        final costPrice = _toDouble(product?['costPrice']) > 0
            ? _toDouble(product?['costPrice'])
            : derivedCost;

        final rawStock = inv?['currentStock'] ?? 0;
        final stock = (rawStock is int ? rawStock : (rawStock as num).toInt());
        final clampedStock = stock < 0 ? 0 : stock;

        sales.add(Sale(
          productId: id,
          productName: (t['productName'] ?? product?['productName'] ?? 'Unknown').toString(),
          category: (t['category'] ?? product?['category'] ?? 'General').toString(),
          quantity: units,
          price: sellingPrice,
          costPrice: costPrice,
          currentStock: clampedStock,
          date: _parseDate(t['transactionDate']),
          transactionMode: (t['transactionMode'] ?? 'OCR').toString(),
        ));
      }

      // Also include products with no sales yet so inventory remains complete.
      for (final p in productsJson) {
        if (p is! Map<String, dynamic>) continue;
        final id = (p['id'] ?? '').toString();
        if (id.isEmpty || txProductIds.contains(id)) continue;

        final inv = inventoryMap[id];
        final rawStock = inv?['currentStock'] ?? 0;
        final stock = (rawStock is int ? rawStock : (rawStock as num).toInt());
        final clampedStock = stock < 0 ? 0 : stock;

        sales.add(Sale(
          productId: id,
          productName: (p['productName'] ?? 'Unknown').toString(),
          category: (p['category'] ?? 'General').toString(),
          quantity: 0,
          price: _toDouble(p['sellingPrice']),
          costPrice: _toDouble(p['costPrice']),
          currentStock: clampedStock,
          date: _parseDate(p['createdAt']),
          transactionMode: 'No Sales Yet',
        ));
      }

      _cachedSales = sales;
      return sales;
    } catch (e) {
      // If API fails, return empty list (screens handle empty gracefully)
      return [];
    }
  }

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    if (_cachedSummary != null) return _cachedSummary!;

    try {
      // Fetch dashboard summary and analytics in parallel
      final results = await Future.wait([
        _fetchSummaryEndpoint(),
        _api.get('/analytics/daily'),
        getSales(), // also fetches products + inventory
      ]);

      final summaryData = results[0] as Map<String, dynamic>;
      final analyticsData = results[1] as Map<String, dynamic>;
      final sales = results[2] as List<Sale>;

      final totalSales = _toDouble(summaryData['totalRevenue'] ?? summaryData['dailyRevenue'] ?? 0);
      final totalProfit = _toDouble(summaryData['totalProfit'] ?? summaryData['dailyProfit'] ?? 0);
      final lowStockCount = _toInt(summaryData['lowStockCount'] ?? 0);
      final unitsSold = _toInt(summaryData['totalTransactions'] ?? summaryData['unitsSold'] ?? 0);

      final dailyRevenue = _toDouble(analyticsData['dailyRevenue'] ?? 0);
      final dailyProfit = _toDouble(analyticsData['dailyProfit'] ?? 0);

      // Build aggregated data from sales list
      final Map<String, double> categorySales = {};
      final Map<String, Map<String, int>> soldVsStock = {};
      int computedLowStock = 0;

      final oldestDate = sales.isNotEmpty 
          ? sales.map((s) => s.date).reduce((a, b) => a.isBefore(b) ? a : b) 
          : DateTime.now();
      final diffDays = DateTime.now().difference(oldestDate).inDays;
      final numberOfDays = diffDays > 0 ? diffDays : 14; 

      final Map<String, Sale> perProduct = {};
      for (final s in sales) {
        final key = s.productId;
        if (!perProduct.containsKey(key)) {
          perProduct[key] = s;
        } else {
          final prev = perProduct[key]!;
          perProduct[key] = Sale(
            productId: s.productId,
            productName: s.productName,
            category: s.category,
            quantity: prev.quantity + s.quantity,
            price: s.quantity > 0 ? s.price : prev.price,
            costPrice: s.costPrice > 0 ? s.costPrice : prev.costPrice,
            currentStock: s.currentStock,
            date: s.date.isAfter(prev.date) ? s.date : prev.date,
            transactionMode: s.transactionMode,
          );
        }
      }

      final List<Sale> isolatedLowStockProducts = [];

      for (final s in perProduct.values) {
        categorySales[s.category] = (categorySales[s.category] ?? 0) + s.dailyRevenue;
        soldVsStock[s.productName] = {
          'sold': s.quantity,
          'stock': s.currentStock,
        };

        // Dynamic threshold: avgDaily * 3 or minimum of 3
        final avgDaily = s.quantity / numberOfDays;
        final threshold = (avgDaily * 3).ceil();
        final actualThreshold = threshold > 3 ? threshold : 3;
        
        if (s.currentStock <= actualThreshold) {
           computedLowStock++;
           isolatedLowStockProducts.add(s);
        }
      }

      // Sort by quantity for top/low products
      final sorted = List<Sale>.from(perProduct.values)..sort((a, b) => b.quantity.compareTo(a.quantity));
      final topProducts = sorted.take(3).toList();
      final lowProducts = isolatedLowStockProducts
        ..sort((a, b) => a.currentStock.compareTo(b.currentStock));

      // Build salesOverTime and costOverTime dynamically over actual history dates
      final Map<String, double> salesOverTime = {};
      final Map<String, double> costOverTime = {};
      
      // If no valid sales exist, fill today with zero
      if (sales.isEmpty) {
        final dateKey = DateTime.now().toIso8601String();
        salesOverTime[dateKey] = 0;
        costOverTime[dateKey] = 0;
      } else {
        // Group everything by day
        for (final s in sales) {
          final dateKey = DateTime(s.date.year, s.date.month, s.date.day).toIso8601String();
          salesOverTime[dateKey] = (salesOverTime[dateKey] ?? 0) + s.dailyRevenue;
          costOverTime[dateKey] = (costOverTime[dateKey] ?? 0) + (s.dailyRevenue - s.estimatedProfit);
        }
      }

      _cachedSummary = DashboardSummary(
        totalSales: totalSales > 0 ? totalSales : _sumField(sales, (s) => s.dailyRevenue),
        totalCost: (totalSales - totalProfit).abs(),
        estimatedProfit: totalProfit > 0 ? totalProfit : _sumField(sales, (s) => s.estimatedProfit),
        unitsSold: unitsSold > 0 ? unitsSold : sales.fold(0, (sum, s) => sum + s.quantity),
        categorySales: categorySales,
        topProducts: topProducts,
        lowProducts: lowProducts,
        allProducts: sorted,
        lowStockCount: computedLowStock,
        salesTrendUp: dailyProfit >= 0,
        salesOverTime: salesOverTime,
        costOverTime: costOverTime,
        soldVsStock: soldVsStock,
      );

      return _cachedSummary!;
    } catch (e) {
      if (_cachedSummary != null) return _cachedSummary!;
      throw Exception('Failed to load dashboard summary: $e');
    }
  }

  /// Try /dashboard/summary first, fall back to /analytics/daily data.
  Future<Map<String, dynamic>> _fetchSummaryEndpoint() async {
    try {
      final data = await _api.get('/dashboard/summary');
      if (data is Map<String, dynamic>) return data;
      return {};
    } catch (_) {
      // Endpoint may not exist; return empty map and let caller use analytics
      return {};
    }
  }

  @override
  Future<Map<String, String>?> getAiInsight() async {
    try {
      final data = await _api.get('/ai/insights');
      if (data is Map<String, dynamic> && data['insight'] != null) {
        return {
          'insight': data['insight'].toString(),
          'reason': data['reason']?.toString() ?? 'Based on your recent sales patterns.',
          'action': data['action']?.toString() ?? 'Review your product mix and pricing.',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    // Firestore Timestamp-like
    if (v is Map && v['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
    }
    return DateTime.now();
  }

  double _sumField(List<Sale> sales, double Function(Sale) fn) {
    return sales.fold(0.0, (sum, s) => sum + fn(s));
  }

}
