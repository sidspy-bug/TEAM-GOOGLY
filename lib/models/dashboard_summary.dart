import 'sale.dart';

class DashboardSummary {
  final double totalSales;
  final double totalCost;
  final double estimatedProfit;
  final int unitsSold;
  final Map<String, double> categorySales;
  final List<Sale> topProducts;
  final List<Sale> lowProducts;
  final List<Sale> allProducts; // full product list for inventory / top-10
  final int lowStockCount;
  final bool salesTrendUp;
  final Map<String, double> salesOverTime;
  final Map<String, double> costOverTime;
  final Map<String, Map<String, int>> soldVsStock; // product -> {sold, stock}

  DashboardSummary({
    required this.totalSales,
    this.totalCost = 0,
    this.estimatedProfit = 0,
    this.unitsSold = 0,
    required this.categorySales,
    required this.topProducts,
    required this.lowProducts,
    this.allProducts = const [],
    required this.lowStockCount,
    required this.salesTrendUp,
    required this.salesOverTime,
    this.costOverTime = const {},
    this.soldVsStock = const {},
  });
}
