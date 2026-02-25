import 'package:flutter/material.dart';

class TodayFocusCard extends StatelessWidget {
  final int lowStockCount;
  final String topProduct;
  final double estimatedProfit;

  const TodayFocusCard({
    super.key,
    required this.lowStockCount,
    required this.topProduct,
    required this.estimatedProfit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 6),
                const Text("Today's Focus", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            _row(Icons.warning_amber, Colors.red, '$lowStockCount items are low on stock — reorder soon'),
            const SizedBox(height: 6),
            _row(Icons.star, Colors.indigo, 'Top seller today: $topProduct'),
            const SizedBox(height: 6),
            _row(Icons.trending_up, Colors.green, 'Estimated profit so far: ₹${estimatedProfit.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
