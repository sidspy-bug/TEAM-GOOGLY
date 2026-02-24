import 'sale.dart';

class DashboardSummary {
  final double totalSales;
  final Map<String, double> categorySales;
  final List<Sale> topProducts;
  final List<Sale> lowProducts;
  final int lowStockCount;
  final bool salesTrendUp;
  // sales over time: date string (ISO) -> value
  final Map<String, double> salesOverTime;

  DashboardSummary({
    required this.totalSales,
    required this.categorySales,
    required this.topProducts,
    required this.lowProducts,
    required this.lowStockCount,
    required this.salesTrendUp,
    required this.salesOverTime,
  });
}
