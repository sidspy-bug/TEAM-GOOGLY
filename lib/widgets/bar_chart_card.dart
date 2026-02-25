import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartCard extends StatelessWidget {
  final Map<String, Map<String, int>> soldVsStock;

  const BarChartCard({super.key, this.soldVsStock = const {}});

  @override
  Widget build(BuildContext context) {
    try {
      final entries = soldVsStock.entries.toList();

      if (entries.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sold vs Stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const SizedBox(height: 160, child: Center(child: Text('No data'))),
              ],
            ),
          ),
        );
      }

      final groups = <BarChartGroupData>[];
      double maxValue = 0;
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final sold = (e.value['sold'] ?? 0).toDouble();
        final stock = (e.value['stock'] ?? 0).toDouble();
        if (sold > maxValue) maxValue = sold;
        if (stock > maxValue) maxValue = stock;
        groups.add(
          BarChartGroupData(
            x: i,
            barsSpace: 3,
            barRods: [
              BarChartRodData(toY: sold, color: Colors.blue, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
              BarChartRodData(toY: stock, color: Colors.orange, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
            ],
          ),
        );
      }

      if (maxValue == 0) maxValue = 100;
      final ceilMax = (maxValue * 1.2).ceilToDouble();
      // Compute a nice interval: ~5 ticks
      double interval = (ceilMax / 5).ceilToDouble();
      if (interval < 1) interval = 1;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Sold vs Stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _legend(Colors.blue, 'Sold'),
                  const SizedBox(width: 12),
                  _legend(Colors.orange, 'Stock'),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    maxY: ceilMax,
                    minY: 0,
                    barGroups: groups,
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                            final name = entries[idx].key;
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(name.length > 7 ? '${name.substring(0, 6)}..' : name, style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: interval,
                          getTitlesWidget: (v, meta) {
                            if (v == meta.max) return const SizedBox.shrink();
                            return Text(v.toInt().toString(), style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval),
                    borderData: FlBorderData(show: true, border: const Border(left: BorderSide(), bottom: BorderSide())),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sold vs Stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 160, child: Center(child: Text('Error: $e'))),
            ],
          ),
        ),
      );
    }
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
