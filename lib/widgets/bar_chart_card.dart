import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartCard extends StatelessWidget {
  final Map<String, double> categorySales;

  const BarChartCard({super.key, required this.categorySales});

  @override
  Widget build(BuildContext context) {
    try {
      final entries = categorySales.entries.toList();

      if (entries.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const SizedBox(height: 200, child: Center(child: Text('No categories found'))),
              ],
            ),
          ),
        );
      }

      final groups = <BarChartGroupData>[];
      double maxValue = 0;
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        if (e.value > maxValue) maxValue = e.value;
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: e.value.toDouble(), color: Theme.of(context).primaryColor, width: 18)
            ],
          ),
        );
      }

      if (maxValue == 0) maxValue = 100;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue * 1.2,
                    minY: 0,
                    barGroups: groups,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(entries[idx].key, style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
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
              const Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: Center(child: Text('Error: $e'))),
            ],
          ),
        ),
      );
    }
  }
}
