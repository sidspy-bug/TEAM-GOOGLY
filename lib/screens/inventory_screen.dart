import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/sale.dart';
import '../repositories/sales_repository.dart';
import 'manual_entry_screen.dart';

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
      String keyOf(String name) => name.trim().toLowerCase();
      final Map<String, Sale> agg = {};
      for (final s in sales) {
        final key = keyOf(s.productName);
        if (agg.containsKey(key)) {
          final prev = agg[key]!;
          agg[key] = Sale(
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
          agg[key] = s;
        }
      }
      return agg.values.toList()..sort((a, b) => a.productId.compareTo(b.productId));
    });
  }

  void _openAddProduct() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ManualEntryScreen(mode: 'product'),
      ),
    );
    // Refresh inventory after returning
    setState(() => _loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        FutureBuilder<List<Sale>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${l.error}: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l.inventory, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${products.length} ${l.productsLabel}', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                    columns: [
                      DataColumn(label: Text(l.idLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l.product, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l.category, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l.lastTxnDate, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l.unitsSold, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text(l.currentStock, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text(l.sellPrice, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text(l.costPrice, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text(l.revenueLabel, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text(l.estimatedProfit, style: const TextStyle(fontWeight: FontWeight.bold)), numeric: true),
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
    ),
    Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add),
        label: Text(l.addProduct),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    ),
    ],
    );
  }
}
