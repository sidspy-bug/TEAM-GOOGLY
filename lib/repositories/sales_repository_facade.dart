import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/dashboard_summary.dart';
import 'sales_repository.dart';
import 'api_sales_repository.dart';

/// Facade that tries the primary (API) repository first,
/// and falls back to the fallback (dummy) repository on error or empty data.
class SalesRepositoryFacade implements SalesRepository {
  final SalesRepository primary;
  final SalesRepository fallback;

  SalesRepositoryFacade(this.primary, this.fallback);

  /// Clear cached data so next fetch hits the API again.
  void clearCache() {
    if (primary is ApiSalesRepository) {
      (primary as ApiSalesRepository).clearCache();
    }
  }

  @override
  Future<List<Sale>> getSales() async {
    try {
      final data = await primary.getSales();
      if (data.isNotEmpty) {
        debugPrint('[SalesRepo] ✅ Using API data (${data.length} sales)');
        return data;
      }
      debugPrint('[SalesRepo] ⚠️ API returned empty sales, falling back to dummy data');
    } catch (e) {
      debugPrint('[SalesRepo] ❌ API getSales failed: $e — using dummy fallback');
    }
    return fallback.getSales();
  }

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final summary = await primary.getDashboardSummary();
      // If all values are zero, the API returned empty — use fallback
      if (summary.totalSales > 0 || summary.allProducts.isNotEmpty) {
        debugPrint('[SalesRepo] ✅ Using API dashboard (sales=₹${summary.totalSales.toStringAsFixed(0)}, products=${summary.allProducts.length})');
        return summary;
      }
      debugPrint('[SalesRepo] ⚠️ API dashboard empty, falling back to dummy data');
    } catch (e) {
      debugPrint('[SalesRepo] ❌ API getDashboardSummary failed: $e — using dummy fallback');
    }
    return fallback.getDashboardSummary();
  }

  @override
  Future<Map<String, String>?> getAiInsight() async {
    try {
      final insight = await primary.getAiInsight();
      if (insight != null) {
        debugPrint('[SalesRepo] ✅ Using API AI insight');
        return insight;
      }
      debugPrint('[SalesRepo] ⚠️ API AI insight null, falling back to dummy');
    } catch (e) {
      debugPrint('[SalesRepo] ❌ API getAiInsight failed: $e — using dummy fallback');
    }
    return fallback.getAiInsight();
  }
}
