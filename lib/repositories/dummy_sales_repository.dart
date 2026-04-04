import 'dart:math';
import '../models/sale.dart';
import '../models/dashboard_summary.dart';
import 'sales_repository.dart';

class DummySalesRepository implements SalesRepository {
  // Diversified product catalog: [id, name, category, sellingPrice, costPrice, stock]
  // Includes high sellers, low sellers, low stock, high stock, medium items
  static final _catalog = [
    // HIGH SELLERS — popular, fast-moving
    ['P001', 'Tea', 'Beverages', 30.0, 12.0, 120],
    ['P002', 'Samosa', 'Snacks', 15.0, 6.0, 200],
    ['P003', 'Biscuits', 'Snacks', 25.0, 11.0, 180],
    // MEDIUM SELLERS
    ['P004', 'Coffee', 'Beverages', 50.0, 22.0, 65],
    ['P005', 'Chips', 'Snacks', 20.0, 10.0, 90],
    ['P006', 'Notebook', 'Stationery', 40.0, 18.0, 55],
    ['P007', 'Juice', 'Beverages', 35.0, 15.0, 70],
    ['P008', 'Bread', 'Bakery', 30.0, 14.0, 45],
    // LOW SELLERS — slow-moving
    ['P009', 'Pen', 'Stationery', 10.0, 4.0, 300],
    ['P010', 'Soap', 'Personal Care', 45.0, 20.0, 40],
    // LOW STOCK — below threshold
    ['P011', 'Butter', 'Dairy', 55.0, 30.0, 3],
    ['P012', 'Shampoo', 'Personal Care', 120.0, 55.0, 2],
    ['P013', 'Cooking Oil', 'Grocery', 180.0, 140.0, 4],
    // HIGH STOCK
    ['P014', 'Sugar (1kg)', 'Grocery', 48.0, 38.0, 250],
    ['P015', 'Rice (1kg)', 'Grocery', 65.0, 50.0, 180],
    // PREMIUM ITEMS
    ['P016', 'Milk (1L)', 'Dairy', 32.0, 26.0, 30],
    ['P017', 'Detergent', 'Personal Care', 95.0, 60.0, 12],
    ['P018', 'Maggi Noodles', 'Snacks', 14.0, 10.0, 160],
  ];

  static const _modes = ['UPI', 'Cash', 'Card'];

  // Per-product quantity weights to create realistic distribution
  static const _qtyWeights = {
    'Tea': 8, 'Samosa': 7, 'Biscuits': 5,       // HIGH sellers
    'Coffee': 3, 'Chips': 3, 'Notebook': 2,      // MEDIUM
    'Juice': 2, 'Bread': 3, 'Maggi Noodles': 4,  // MEDIUM
    'Pen': 1, 'Soap': 1,                          // LOW sellers
  };

  @override
  Future<List<Sale>> getSales() async {
    final now = DateTime.now();
    final rand = Random(42);
    final List<Sale> list = [];

    for (var i = 0; i < 140; i++) {
      final p = _catalog[rand.nextInt(_catalog.length)];
      final productName = p[1] as String;
      final maxQty = _qtyWeights[productName] ?? 3;
      final qty = rand.nextInt(maxQty) + 1;
      final date = now.subtract(Duration(days: rand.nextInt(14), hours: rand.nextInt(12)));
      final mode = _modes[rand.nextInt(_modes.length)];
      final rawStock = (p[5] as int) - rand.nextInt(15);
      final clampedStock = rawStock < 0 ? 0 : rawStock;

      list.add(Sale(
        productId: p[0] as String,
        productName: productName,
        category: p[2] as String,
        quantity: qty,
        price: (p[3] as double),
        costPrice: (p[4] as double),
        currentStock: clampedStock,
        date: date,
        transactionMode: mode,
      ));
    }
    return list;
  }

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final sales = await getSales();
      double totalSales = 0;
      double totalCost = 0;
      int unitsSold = 0;
      final Map<String, double> categorySales = {};
      final Map<String, int> productQty = {};
      final Map<String, Sale> productLatest = {};
      final Map<String, double> salesByDate = {};
      final Map<String, double> costByDate = {};
      int lowStockCount = 0;
      final Set<String> lowStockIds = {};

      for (final s in sales) {
        final revenue = s.price * s.quantity;
        final cost = s.costPrice * s.quantity;
        totalSales += revenue;
        totalCost += cost;
        unitsSold += s.quantity;

        categorySales[s.category] = (categorySales[s.category] ?? 0) + revenue;
        productQty[s.productName] = (productQty[s.productName] ?? 0) + s.quantity;
        productLatest[s.productName] = s;

        final dateKey = DateTime(s.date.year, s.date.month, s.date.day).toIso8601String();
        salesByDate[dateKey] = (salesByDate[dateKey] ?? 0) + revenue;
        costByDate[dateKey] = (costByDate[dateKey] ?? 0) + cost;

        if (s.currentStock < 15 && !lowStockIds.contains(s.productId)) {
          lowStockIds.add(s.productId);
          lowStockCount++;
        }
      }

      // Build product-level aggregates for allProducts
      final Map<String, Sale> productAgg = {};
      for (final s in sales) {
        if (productAgg.containsKey(s.productName)) {
          final prev = productAgg[s.productName]!;
          productAgg[s.productName] = Sale(
            productId: s.productId,
            productName: s.productName,
            category: s.category,
            quantity: prev.quantity + s.quantity,
            price: s.price,
            costPrice: s.costPrice,
            currentStock: s.currentStock,
            date: s.date.isAfter(prev.date) ? s.date : prev.date,
            transactionMode: s.transactionMode,
          );
        } else {
          productAgg[s.productName] = s;
        }
      }

      final allProducts = productAgg.values.toList()
        ..sort((a, b) => b.quantity.compareTo(a.quantity));

      final topSales = allProducts.take(3).toList();
      final lowSales = allProducts.reversed.take(3).toList();

      // Sold vs Stock map
      final Map<String, Map<String, int>> soldVsStock = {};
      for (final p in allProducts) {
        soldVsStock[p.productName] = {
          'sold': p.quantity,
          'stock': p.currentStock,
        };
      }

      final salesTrendUp = salesByDate.values.isNotEmpty &&
          salesByDate.values.last >= salesByDate.values.first;

      return DashboardSummary(
        totalSales: double.parse(totalSales.toStringAsFixed(2)),
        totalCost: double.parse(totalCost.toStringAsFixed(2)),
        estimatedProfit: double.parse((totalSales - totalCost).toStringAsFixed(2)),
        unitsSold: unitsSold,
        categorySales: categorySales.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
        topProducts: topSales,
        lowProducts: lowSales,
        allProducts: allProducts,
        lowStockCount: lowStockCount,
        salesTrendUp: salesTrendUp,
        salesOverTime: salesByDate.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
        costOverTime: costByDate.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
        soldVsStock: soldVsStock,
      );
    } catch (e) {
      print('Error in getDashboardSummary: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String>?> getAiInsight() async {
    return {
      'insight': 'Increase tea combo offers',
      'reason': 'Beverages show steady demand during mornings',
      'action': 'Bundle tea with a snack at a small discount to increase average ticket',
    };
  }
}
