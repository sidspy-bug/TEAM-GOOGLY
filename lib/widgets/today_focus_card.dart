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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.amber.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 20),
                const SizedBox(width: 6),
                Text("Today's Focus", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const SizedBox(height: 10),
            _row(Icons.warning_amber, Colors.red.shade400, '$lowStockCount items are low on stock — reorder soon', isDark),
            const SizedBox(height: 6),
            _row(Icons.trending_up, Colors.green.shade400, 'Estimated profit so far: ₹${estimatedProfit.toStringAsFixed(0)}', isDark),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87))),
      ],
    );
  }
}
