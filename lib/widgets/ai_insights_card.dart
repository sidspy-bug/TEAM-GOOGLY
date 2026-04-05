import 'package:flutter/material.dart';
import '../repositories/sales_repository.dart';

class AiInsightsCard extends StatefulWidget {
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
  State<AiInsightsCard> createState() => _AiInsightsCardState();
}

class _AiInsightsCardState extends State<AiInsightsCard> {
  // Key used to rebuild the FutureBuilder on manual refresh
  Key _futureKey = UniqueKey();
  bool _isRefreshing = false;

  void _refresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Clear the AI insight cache so we get a fresh response
    (widget.salesRepository as dynamic).clearCache?.call();

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _futureKey = UniqueKey();
        _isRefreshing = false;
      });
    }
  }

  /// Strips Markdown symbols from a single line so the card stays clean.
  String _cleanLine(String line) {
    return line
        .replaceAll(RegExp(r'^#+\s*'), '')        // ### headings
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // **bold**
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')     // *italic*
        .replaceAll(RegExp(r'^[-*•]\s+'), '')     // leading bullet
        .replaceAll(r'$', '₹')                   // stray dollar signs
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) {
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
                  'AI Business Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const Spacer(),
                // ── Refresh Button ──────────────────────────────────
                _isRefreshing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.indigo.shade400,
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.refresh_rounded, size: 20, color: Colors.indigo.shade400),
                        tooltip: 'Refresh insights',
                        onPressed: _refresh,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),
            // Use _futureKey to force a fresh call on refresh
            FutureBuilder<Map<String, String>?>(
              key: _futureKey,
              future: widget.salesRepository.getAiInsight(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.data == null || snapshot.data!['insight'] == null) {
                  return Text(
                    'Recording more sales (₹) will help the AI provide deeper insights.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                  );
                }

                final fullInsight = snapshot.data!['insight']!;

                // Parse lines, strip markdown, skip empty
                final lines = fullInsight
                    .split('\n')
                    .map(_cleanLine)
                    .where((l) => l.isNotEmpty)
                    .toList();

                return Column(
                  children: lines.map((line) {
                    IconData icon = Icons.info_outline;
                    Color color = Colors.indigo;

                    final lower = line.toLowerCase();
                    if (lower.contains('performance')) {
                      icon = Icons.trending_up;
                      color = Colors.green.shade400;
                    } else if (lower.contains('inventory')) {
                      icon = Icons.inventory_2_outlined;
                      color = Colors.orange.shade400;
                    } else if (lower.contains('forecast') || lower.contains('weekly') || lower.contains('expect')) {
                      icon = Icons.auto_graph;
                      color = Colors.purple.shade400;
                    } else if (lower.contains('recommend') || lower.contains('future')) {
                      icon = Icons.lightbulb_outline;
                      color = Colors.blue.shade400;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _insightRow(icon, color, line, isDark),
                    );
                  }).toList(),
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
              'Inventory data is limited for free users.',
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

  Widget _insightRow(IconData? icon, Color color, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: text.contains(':') ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
