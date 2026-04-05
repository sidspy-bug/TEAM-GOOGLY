import 'package:flutter/material.dart';
import '../models/sale.dart';

class TopProductsTable extends StatelessWidget {
  final List<Sale> products;
  const TopProductsTable({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final top10 = products.take(10).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 10 Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                columns: const [
                  DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Sold', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Sell ₹', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Cost ₹', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Profit ₹', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: top10.asMap().entries.map((entry) {
                  final p = entry.value;
                  final isTopProfit = entry.key < 3;
                  return DataRow(
                    color: isTopProfit ? WidgetStateProperty.all(Colors.green.shade50) : null,
                    cells: [
                    DataCell(Row(children: [
                      Text(p.productName),
                      if (isTopProfit) ...[const SizedBox(width: 4), Icon(Icons.emoji_events, size: 14, color: Colors.amber.shade700)],
                    ])),
                    DataCell(Text(p.category)),
                    DataCell(Text('${p.quantity}')),
                    DataCell(Text('${p.currentStock}')),
                    DataCell(Text('₹${p.price.toStringAsFixed(0)}')),
                    DataCell(Text('₹${p.costPrice.toStringAsFixed(0)}')),
                    DataCell(Text(
                      '₹${p.estimatedProfit.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: p.estimatedProfit >= 0 ? Colors.green.shade700 : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                  ]);
                }).toList().cast<DataRow>(),
              ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
