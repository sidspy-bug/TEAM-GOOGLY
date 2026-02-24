import 'dart:math';
import '../models/sale.dart';
import '../models/dashboard_summary.dart';
import 'sales_repository.dart';

class DummySalesRepository implements SalesRepository {
  @override
  Future<List<Sale>> getSales() async {
    // Generate some dummy sales across categories
    final now = DateTime.now();
    final rand = Random(42);
    final products = [
      ['Tea', 'Beverages'],
      ['Coffee', 'Beverages'],
      ['Samosa', 'Snacks'],
      ['Chips', 'Snacks'],
      ['Soap', 'Essentials'],
      ['Shampoo', 'Essentials'],
      ['Notebook', 'Stationery'],
    ];

    final List<Sale> list = [];
    for (var i = 0; i < 80; i++) {
      final p = products[rand.nextInt(products.length)];
      final qty = rand.nextInt(5) + 1;
      final price = (rand.nextDouble() * 50) + 10;
      final date = now.subtract(Duration(days: rand.nextInt(14)));
      list.add(Sale(
        productName: p[0],
        category: p[1],
        quantity: qty,
        price: double.parse((price).toStringAsFixed(2)),
        date: date,
      ));
    }

    return list;
  }

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final sales = await getSales();
      double total = 0;
      final Map<String, double> categorySales = {};
      final Map<String, int> productCounts = {};
      final Map<String, double> salesByDate = {};

      for (final s in sales) {
        final amount = s.price * s.quantity;
        total += amount;
        categorySales[s.category] =
            (categorySales[s.category] ?? 0) + amount;
        productCounts[s.productName] =
            (productCounts[s.productName] ?? 0) + s.quantity;
        final dateKey =
            DateTime(s.date.year, s.date.month, s.date.day).toIso8601String();
        salesByDate[dateKey] = (salesByDate[dateKey] ?? 0) + amount;
      }

      // top products
      final topProductsList = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = topProductsList.take(3).map((e) => e.key).toList();

      // Build Sale objects for top and low lists (mock quantities)
      final topSales = top
          .map((name) => Sale(
              productName: name,
              category: '',
              quantity: productCounts[name] ?? 0,
              price: 0,
              date: DateTime.now()))
          .toList();

      final low = topProductsList.reversed.take(3).map((e) => e.key).toList();
      final lowSales = low
          .map((name) => Sale(
              productName: name,
              category: '',
              quantity: productCounts[name] ?? 0,
              price: 0,
              date: DateTime.now()))
          .toList();

      final salesTrendUp = (salesByDate.values.isNotEmpty &&
          salesByDate.values.last >= (salesByDate.values.first));

      return DashboardSummary(
        totalSales: double.parse(total.toStringAsFixed(2)),
        categorySales: categorySales.map(
            (k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
        topProducts: topSales,
        lowProducts: lowSales,
        lowStockCount: 4,
        salesTrendUp: salesTrendUp,
        salesOverTime:
            salesByDate.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
      );
    } catch (e) {
      print('Error in getDashboardSummary: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String>?> getAiInsight() async {
    // Dummy insight
    return {
      'insight': 'Increase tea combo offers',
      'reason': 'Beverages show steady demand during mornings',
      'action': 'Bundle tea with a snack at a small discount to increase average ticket',
    };
  }
}
