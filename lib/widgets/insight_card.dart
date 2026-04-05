import 'package:flutter/material.dart';
import '../repositories/sales_repository.dart';

class InsightCard extends StatelessWidget {
  final bool isPremium;
  final SalesRepository salesRepository;

  const InsightCard({super.key, required this.isPremium, required this.salesRepository});

  @override
  Widget build(BuildContext context) {
    if (!isPremium) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock, color: Colors.amber, size: 32),
              const SizedBox(height: 12),
              const Text(
                'Premium Feature',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Tap the star icon in the top-right to unlock AI-generated business insights.'),
              const SizedBox(height: 12),
              Text(
                'Premium users get actionable insights powered by AI.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, String>?>(
      future: salesRepository.getAiInsight(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Insight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(data['insight'] ?? ''),
                const SizedBox(height: 6),
                Text('Reason: ${data['reason']}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                Text('Suggested Action: ${data['action']}', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        );
      },
    );
  }
}
