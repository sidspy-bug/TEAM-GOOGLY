import '../models/sale.dart';
import '../models/dashboard_summary.dart';

abstract class SalesRepository {
  Future<List<Sale>> getSales();
  Future<DashboardSummary> getDashboardSummary();
  // AI insight -- may be null for free users
  Future<Map<String, String>?> getAiInsight();
}
