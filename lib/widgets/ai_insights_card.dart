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
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.indigo.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber.shade800),
                      const SizedBox(width: 4),
                      Text('Premium', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber.shade900)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _insightRow(
              Icons.warning_amber_rounded,
              Colors.red.shade600,
              lowStockCount > 0
                  ? '⚠️ $lowStockCount products are below the low-stock threshold. Consider restocking soon to avoid stockouts.'
                  : '✅ All products are well-stocked. No restocking needed right now.',
            ),
            const SizedBox(height: 10),
            _insightRow(
              Icons.emoji_events,
              Colors.amber.shade700,
              '🏆 Top selling product today: $topProduct. Consider bundling it with slower movers for higher ticket value.',
            ),
            const SizedBox(height: 10),
            _insightRow(
              Icons.trending_up,
              Colors.green.shade700,
              '💰 Estimated profit: ₹${estimatedProfit.toStringAsFixed(0)}. Maintain margins by reviewing cost prices regularly.',
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
                  Colors.indigo.shade600,
                  '💡 ${data['insight'] ?? ''} — ${data['reason'] ?? ''}. Action: ${data['action'] ?? ''}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeInsights(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Free', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _insightRow(
              Icons.warning_amber_rounded,
              Colors.red.shade600,
              lowStockCount > 0
                  ? '⚠️ $lowStockCount products are low on stock.'
                  : '✅ All products are well-stocked.',
            ),
            const SizedBox(height: 10),
            _insightRow(
              Icons.emoji_events,
              Colors.amber.shade700,
              '🏆 Top seller: $topProduct',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Upgrade to Premium for detailed profit insights, smart recommendations, and AI-powered actions.',
                      style: TextStyle(fontSize: 12),
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

  Widget _insightRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
      ],
    );
  }
}
