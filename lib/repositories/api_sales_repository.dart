import 'dart:math' as math;
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
  Map<String, String>? _cachedAiInsight;

  /// Clear caches (call on logout or manual refresh).
  void clearCache() {
    _cachedSales = null;
    _cachedSummary = null;
    _cachedAiInsight = null;
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
    // Force refresh to ensure Low Stock count (1 vs 2) is always accurate
    // if (_cachedSummary != null) return _cachedSummary!;

    try {
      // Fetch dashboard summary and overall trend in parallel
      final results = await Future.wait([
        _fetchSummaryEndpoint(),
        _api.get('/analytics/overall-trend'),
        getSales(), // still useful for low stock / category stats
      ]);

      final summaryData = results[0] as Map<String, dynamic>;
      final trendData = results[1] as List<dynamic>;
      final sales = results[2] as List<Sale>;

      print('🔍 [DEBUG] API summaryData: $summaryData');
      print('🔍 [DEBUG] Sales list length: ${sales.length}');

      final totalSales = _toDouble(summaryData['totalRevenue'] ?? 0);
      final totalProfit = _toDouble(summaryData['totalProfit'] ?? 0);
      final lowStockCount = _toInt(summaryData['lowStockCount'] ?? 0);
      final unitsSold = _toInt(summaryData['unitsSold'] ?? 0);

      // Build chart data directly from the trend data
      final Map<String, double> salesOverTime = {};
      final Map<String, double> costOverTime = {};
      
      for (final dayObj in trendData) {
        if (dayObj is Map<String, dynamic>) {
          final dateStr = dayObj['day'].toString();
          final rev = _toDouble(dayObj['revenue']);
          final prof = _toDouble(dayObj['profit']);
          salesOverTime[dateStr] = rev;
          costOverTime[dateStr] = math.max(0.0, rev - prof);
        }
      }

      // Metadata calculation logic derived from full sales list
      final Map<String, double> categorySales = {};
      final Map<String, Map<String, int>> soldVsStock = {};
      
      // We process allProducts but only for auxiliary data.
      // Category sales and Sold vs Stock.
      for (final s in sales) {
        categorySales[s.category] = (categorySales[s.category] ?? 0) + s.dailyRevenue;
        soldVsStock[s.productName] = {
           'sold': s.quantity,
           'stock': s.currentStock,
        };
      }

      final Map<String, Sale> aggregated = {};
      for (final s in sales) {
        if (!aggregated.containsKey(s.productId)) {
          aggregated[s.productId] = s;
        } else {
          final existing = aggregated[s.productId]!;
          aggregated[s.productId] = Sale(
            productId: s.productId,
            productName: s.productName,
            category: s.category,
            quantity: existing.quantity + s.quantity,
            price: s.price,
            costPrice: s.costPrice,
            currentStock: s.currentStock,
            date: s.date,
            transactionMode: s.transactionMode,
          );
        }
      }

      final sorted = aggregated.values.toList()..sort((a, b) => b.dailyRevenue.compareTo(a.dailyRevenue));
      
      final uniqueSales = <String, Sale>{};
      for(final s in sales) { uniqueSales[s.productId] = s; }
      
      final lowProducts = uniqueSales.values.where((s) => s.currentStock < 10).toList()
        ..sort((a, b) => a.currentStock.compareTo(b.currentStock));

      _cachedSummary = DashboardSummary(
        totalSales: totalSales,
        totalCost: math.max(0.0, totalSales - totalProfit),
        estimatedProfit: totalProfit,
        unitsSold: unitsSold,
        categorySales: categorySales,
        topProducts: sorted.take(10).toList(),
        lowProducts: lowProducts,
        allProducts: sorted,
        lowStockCount: math.max(lowStockCount, lowProducts.length),
        salesTrendUp: true, // simplified
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
    if (_cachedAiInsight != null) return _cachedAiInsight!;

    try {
      final data = await _api.get('/ai/insights');
      if (data is Map<String, dynamic> && data['insight'] != null) {
        _cachedAiInsight = {
          'insight': data['insight'].toString(),
          'reason': data['reason']?.toString() ?? 'Based on your recent sales patterns.',
          'action': data['action']?.toString() ?? 'Review your product mix and pricing.',
        };
        return _cachedAiInsight;
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
