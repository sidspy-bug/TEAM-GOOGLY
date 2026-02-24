import 'package:flutter/material.dart';
import '../models/sale.dart';

class ProductList extends StatelessWidget {
  final List<Sale> topProducts;
  final List<Sale> lowProducts;

  const ProductList({super.key, required this.topProducts, required this.lowProducts});

  Widget _buildList(String title, List<Sale> items) {
    return Flexible(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(s.productName),
                    trailing: Text('${s.quantity} pcs'),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      if (isWide) {
        return Row(children: [_buildList('Top Products', topProducts), const SizedBox(width: 8), _buildList('Slow Moving', lowProducts)]);
      }
      return Column(children: [_buildList('Top Products', topProducts), const SizedBox(height: 8), _buildList('Slow Moving', lowProducts)]);
    });
  }
}
