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
      if (data.isNotEmpty) return data;
    } catch (_) {}
    return fallback.getSales();
  }

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final summary = await primary.getDashboardSummary();
      // If all values are zero, the API returned empty — use fallback
      if (summary.totalSales > 0 || summary.allProducts.isNotEmpty) {
        return summary;
      }
    } catch (_) {}
    return fallback.getDashboardSummary();
  }

  @override
  Future<Map<String, String>?> getAiInsight() async {
    try {
      final insight = await primary.getAiInsight();
      if (insight != null) return insight;
    } catch (_) {}
    return fallback.getAiInsight();
  }
}
