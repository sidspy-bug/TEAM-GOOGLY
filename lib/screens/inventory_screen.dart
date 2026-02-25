import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../repositories/sales_repository.dart';

class InventoryScreen extends StatefulWidget {
  final SalesRepository salesRepository;
  const InventoryScreen({super.key, required this.salesRepository});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Sale>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _productsFuture = widget.salesRepository.getSales().then((sales) {
      final Map<String, Sale> agg = {};
      for (final s in sales) {
        if (agg.containsKey(s.productName)) {
          final prev = agg[s.productName]!;
          agg[s.productName] = Sale(
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
          agg[s.productName] = s;
        }
      }
      return agg.values.toList()..sort((a, b) => a.productId.compareTo(b.productId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Sale>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${products.length} products', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Last Txn Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Units Sold', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Current Stock', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Sell Price (₹)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Cost Price (₹)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Revenue (₹)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Est. Profit (₹)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    ],
                    rows: products.map((p) {
                      final clampedStock = p.currentStock < 0 ? 0 : p.currentStock;
                      final isLow = clampedStock < 15;
                      final wasNegative = p.currentStock < 0;
                      return DataRow(
                        color: isLow ? WidgetStateProperty.all(Colors.red.shade50) : null,
                        cells: [
                          DataCell(Text(p.productId)),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(p.productName),
                            if (isLow) ...[const SizedBox(width: 6), const Icon(Icons.warning_amber, size: 16, color: Colors.red)],
                            if (wasNegative) ...[const SizedBox(width: 4), Tooltip(message: 'Stock was negative, clamped to 0', child: Icon(Icons.error_outline, size: 16, color: Colors.orange.shade700))],
                          ])),
                          DataCell(Text(p.category)),
                          DataCell(Text('${p.date.day}/${p.date.month}/${p.date.year}')),
                          DataCell(Text('${p.quantity}')),
                          DataCell(Text('$clampedStock', style: TextStyle(
                            color: isLow ? Colors.red : null,
                            fontWeight: isLow ? FontWeight.bold : null,
                          ))),
                          DataCell(Text('₹${p.price.toStringAsFixed(0)}')),
                          DataCell(Text('₹${p.costPrice.toStringAsFixed(0)}')),
                          DataCell(Text('₹${p.dailyRevenue.toStringAsFixed(0)}')),
                          DataCell(Text('₹${p.estimatedProfit.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: p.estimatedProfit >= 0 ? Colors.green.shade700 : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
