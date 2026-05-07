import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/dashboard_summary.dart';
import 'sales_repository.dart';

class DummySalesRepository implements SalesRepository {
  // Product catalog: [id, name, category, sellingPrice, costPrice, stock]
  static final _catalog = [
    ['P001', 'Tea', 'Beverages', 30.0, 12.0, 120],
    ['P002', 'Coffee', 'Beverages', 50.0, 22.0, 80],
    ['P003', 'Samosa', 'Snacks', 15.0, 6.0, 200],
    ['P004', 'Chips', 'Snacks', 20.0, 10.0, 150],
    ['P005', 'Soap', 'Essentials', 45.0, 20.0, 60],
    ['P006', 'Shampoo', 'Essentials', 120.0, 55.0, 35],
    ['P007', 'Notebook', 'Stationery', 40.0, 18.0, 90],
    ['P008', 'Pen', 'Stationery', 10.0, 4.0, 300],
    ['P009', 'Biscuits', 'Snacks', 25.0, 11.0, 180],
    ['P010', 'Juice', 'Beverages', 35.0, 15.0, 70],
    ['P011', 'Bread', 'Bakery', 30.0, 14.0, 45],
    ['P012', 'Butter', 'Dairy', 55.0, 30.0, 8],
  ];

  static const _modes = ['UPI', 'Cash', 'Card'];

  @override
  Future<List<Sale>> getSales() async {
    final now = DateTime.now();
    final rand = Random(42);
    final List<Sale> list = [];

    for (var i = 0; i < 120; i++) {
      final p = _catalog[rand.nextInt(_catalog.length)];
      final qty = rand.nextInt(6) + 1;
      final date = now.subtract(Duration(days: rand.nextInt(14)));
      final mode = _modes[rand.nextInt(_modes.length)];
      final rawStock = (p[5] as int) - rand.nextInt(20);
      final clampedStock = rawStock < 0 ? 0 : rawStock;
      // Ensure units sold never exceeds available stock
      final maxQty = clampedStock + qty; // opening stock approximation
      final validQty = qty <= maxQty ? qty : maxQty;
      list.add(Sale(
        productId: p[0] as String,
        productName: p[1] as String,
        category: p[2] as String,
        quantity: validQty,
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
      debugPrint('Error in getDashboardSummary: $e');
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
