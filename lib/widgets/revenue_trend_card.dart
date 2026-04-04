import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueTrendCard extends StatelessWidget {
  final Map<String, double> salesOverTime;
  final Map<String, double> costOverTime;

  const RevenueTrendCard({
    super.key,
    required this.salesOverTime,
    required this.costOverTime,
  });

  String _formatRupee(double v) {
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final entries = salesOverTime.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const SizedBox.shrink();

    final salesSpots = <FlSpot>[];
    final profitSpots = <FlSpot>[];
    
    for (var i = 0; i < entries.length; i++) {
       final date = entries[i].key;
       final sales = entries[i].value;
       final profit = sales - (costOverTime[date] ?? 0);
       salesSpots.add(FlSpot(i.toDouble(), sales));
       profitSpots.add(FlSpot(i.toDouble(), profit));
    }

    final allValues = [...salesSpots.map((s) => s.y), ...profitSpots.map((s) => s.y)];
    final maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.2;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                const Text('Sales vs Profit Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                _legend(Colors.green, 'Sales'),
                const SizedBox(width: 12),
                _legend(Colors.blue, 'Profit'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (v, meta) => Text(_formatRupee(v), style: const TextStyle(fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= entries.length || idx % 2 != 0) return const SizedBox.shrink();
                          final dt = DateTime.tryParse(entries[idx].key);
                          return Text(dt != null ? '${dt.day}/${dt.month}' : '', style: const TextStyle(fontSize: 9));
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: salesSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
                    ),
                    LineChartBarData(
                      spots: profitSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
                    ),
                  ],
                  borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
