import 'package:flutter/material.dart';
import '../repositories/sales_repository.dart';

class AiInsightsCard extends StatelessWidget {
  final bool isPremium;
  final int lowStockCount;
  final String topProduct;
  final double estimatedProfit;
  final SalesRepository salesRepository;

  const AiInsightsCard({
    super.key,
    required this.isPremium,
    required this.lowStockCount,
    required this.topProduct,
    required this.estimatedProfit,
    required this.salesRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return _buildPremiumInsights(context);
    }
    return _buildFreeInsights(context);
  }

  Widget _buildPremiumInsights(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.indigo.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.indigo.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.amber.shade900.withValues(alpha: 0.4) : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text('Premium', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _insightRow(
              Icons.warning_amber_rounded,
              Colors.red.shade400,
              lowStockCount > 0
                  ? '⚠️ $lowStockCount products are below the low-stock threshold. Consider restocking soon to avoid stockouts.'
                  : '✅ All products are well-stocked. No restocking needed right now.',
              isDark,
            ),
            const SizedBox(height: 10),
            _insightRow(
              Icons.emoji_events,
              Colors.amber.shade600,
              '🏆 Top selling product today: $topProduct. Consider bundling it with slower movers for higher ticket value.',
              isDark,
            ),
            const SizedBox(height: 10),
            _insightRow(
              Icons.trending_up,
              Colors.green.shade400,
              '💰 Estimated profit: ₹${estimatedProfit.toStringAsFixed(0)}. Maintain margins by reviewing cost prices regularly.',
              isDark,
            ),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, String>?>(
              future: salesRepository.getAiInsight(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final data = snapshot.data!;
                return _insightRow(
                  Icons.lightbulb_outline,
                  Colors.indigo.shade400,
                  '💡 ${data['insight'] ?? ''} — ${data['reason'] ?? ''}. Action: ${data['action'] ?? ''}',
                  isDark,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeInsights(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: isDark ? Colors.white54 : Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Free', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.grey.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _insightRow(
              Icons.warning_amber_rounded,
              Colors.red.shade400,
              lowStockCount > 0
                  ? '⚠️ $lowStockCount products are low on stock.'
                  : '✅ All products are well-stocked.',
              isDark,
            ),
            const SizedBox(height: 10),
            _insightRow(
              Icons.emoji_events,
              Colors.amber.shade600,
              '🏆 Top seller: $topProduct',
              isDark,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade900.withValues(alpha: 0.2) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.amber.shade800.withValues(alpha: 0.3) : Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.amber.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium for detailed profit insights, smart recommendations, and AI-powered actions.',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightRow(IconData icon, Color color, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white : Colors.black87))),
      ],
    );
  }
}
