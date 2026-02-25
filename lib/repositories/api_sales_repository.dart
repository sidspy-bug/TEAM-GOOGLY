import '../models/sale.dart';
import '../models/dashboard_summary.dart';
import '../services/api_service.dart';
import 'sales_repository.dart';

/// SalesRepository implementation backed by the backend REST API.
/// Falls back to DummySalesRepository data if the API is unreachable.
class ApiSalesRepository implements SalesRepository {
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
      // Fetch products and inventory in parallel
      final results = await Future.wait([
        _api.get('/products/list'),
        _api.get('/inventory/status'),
      ]);

      final List<dynamic> productsJson = results[0] is List ? results[0] : [];
      final List<dynamic> inventoryJson = results[1] is List ? results[1] : [];

      // Build inventory lookup by productId
      final Map<String, Map<String, dynamic>> inventoryMap = {};
      for (final inv in inventoryJson) {
        if (inv is Map<String, dynamic> && inv['productId'] != null) {
          inventoryMap[inv['productId'].toString()] = inv;
        }
      }

      final List<Sale> sales = [];
      for (final p in productsJson) {
        if (p is! Map<String, dynamic>) continue;
        final id = (p['id'] ?? p['productId'] ?? '').toString();
        final inv = inventoryMap[id];
        final rawStock = inv?['currentStock'] ?? 0;
        final stock = (rawStock is int ? rawStock : (rawStock as num).toInt());
        final clampedStock = stock < 0 ? 0 : stock;
        final invStatus = inv?['status'] ?? 'Normal';

        final sellingPrice = _toDouble(p['sellingPrice'] ?? p['price'] ?? 0);
        final costPrice = _toDouble(p['costPrice'] ?? 0);

        sales.add(Sale(
          productId: id,
          productName: (p['productName'] ?? p['name'] ?? 'Unknown').toString(),
          category: (p['category'] ?? '').toString(),
          quantity: clampedStock, // use stock as quantity proxy when no transactions
          price: sellingPrice,
          costPrice: costPrice,
          currentStock: clampedStock,
          date: _parseDate(p['createdAt']),
          transactionMode: invStatus == 'Low' ? 'Low Stock' : 'Normal',
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

      for (final s in sales) {
        categorySales[s.category] = (categorySales[s.category] ?? 0) + s.dailyRevenue;
        soldVsStock[s.productName] = {
          'sold': s.quantity,
          'stock': s.currentStock,
        };
        if (s.currentStock < 15) computedLowStock++;
      }

      // Sort by quantity for top/low products
      final sorted = List<Sale>.from(sales)..sort((a, b) => b.quantity.compareTo(a.quantity));
      final topProducts = sorted.take(3).toList();
      final lowProducts = sorted.reversed.take(3).toList();

      // Build salesOverTime and costOverTime from analytics
      // Use daily data as single-day point; for multi-day, the API would need expansion
      final now = DateTime.now();
      final dateKey = DateTime(now.year, now.month, now.day).toIso8601String();
      final Map<String, double> salesOverTime = {dateKey: dailyRevenue > 0 ? dailyRevenue : totalSales};
      final Map<String, double> costOverTime = {dateKey: dailyRevenue > 0 ? dailyRevenue - dailyProfit : totalSales - totalProfit};

      _cachedSummary = DashboardSummary(
        totalSales: totalSales > 0 ? totalSales : _sumField(sales, (s) => s.dailyRevenue),
        totalCost: (totalSales - totalProfit).abs(),
        estimatedProfit: totalProfit > 0 ? totalProfit : _sumField(sales, (s) => s.estimatedProfit),
        unitsSold: unitsSold > 0 ? unitsSold : sales.fold(0, (sum, s) => sum + s.quantity),
        categorySales: categorySales,
        topProducts: topProducts,
        lowProducts: lowProducts,
        allProducts: sorted,
        lowStockCount: lowStockCount > 0 ? lowStockCount : computedLowStock,
        salesTrendUp: dailyProfit >= 0,
        salesOverTime: salesOverTime,
        costOverTime: costOverTime,
        soldVsStock: soldVsStock,
      );

      return _cachedSummary!;
    } catch (e) {
      // Build a minimal summary from whatever sales data we have
      final sales = _cachedSales ?? [];
      return _buildFallbackSummary(sales);
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

  DashboardSummary _buildFallbackSummary(List<Sale> sales) {
    final Map<String, double> categorySales = {};
    final Map<String, Map<String, int>> soldVsStock = {};
    int lowStockCount = 0;

    for (final s in sales) {
      categorySales[s.category] = (categorySales[s.category] ?? 0) + s.dailyRevenue;
      soldVsStock[s.productName] = {'sold': s.quantity, 'stock': s.currentStock};
      if (s.currentStock < 15) lowStockCount++;
    }

    final sorted = List<Sale>.from(sales)..sort((a, b) => b.quantity.compareTo(a.quantity));

    return DashboardSummary(
      totalSales: _sumField(sales, (s) => s.dailyRevenue),
      estimatedProfit: _sumField(sales, (s) => s.estimatedProfit),
      unitsSold: sales.fold(0, (sum, s) => sum + s.quantity),
      categorySales: categorySales,
      topProducts: sorted.take(3).toList(),
      lowProducts: sorted.reversed.take(3).toList(),
      allProducts: sorted,
      lowStockCount: lowStockCount,
      salesTrendUp: true,
      salesOverTime: {},
      costOverTime: {},
      soldVsStock: soldVsStock,
    );
  }
}
