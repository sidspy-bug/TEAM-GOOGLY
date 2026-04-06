import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartCard extends StatelessWidget {
  final Map<String, Map<String, int>> soldVsStock;

  const BarChartCard({super.key, this.soldVsStock = const {}});

  @override
  Widget build(BuildContext context) {
    try {
      var entries = soldVsStock.entries.toList()
        ..sort((a, b) => (b.value['sold'] ?? 0).compareTo(a.value['sold'] ?? 0));

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
      double maxRaw = 0;
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final soldRaw = (e.value['sold'] ?? 0).toDouble();
        final stockRaw = (e.value['stock'] ?? 0).toDouble();
        
        if (soldRaw > maxRaw) maxRaw = soldRaw;
        if (stockRaw > maxRaw) maxRaw = stockRaw;

        // Visual Normalization: sqrt() makes small bars visible and compares them better to large ones.
        final soldVisual = math.sqrt(soldRaw);
        final stockVisual = math.sqrt(stockRaw);

        groups.add(
          BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: soldVisual,
                width: 16,
                gradient: LinearGradient(
                  colors: [Colors.cyan.shade300, Colors.cyan.shade700],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              BarChartRodData(
                toY: stockVisual,
                width: 16,
                gradient: LinearGradient(
                  colors: [Colors.orange.shade300, Colors.orange.shade700],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        );
      }

      // Max scaled Y value
      final maxVisual = math.sqrt(maxRaw > 0 ? maxRaw : 100);
      final ceilMaxVisual = (maxVisual * 1.1);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   const Icon(Icons.bar_chart_rounded, color: Colors.indigo, size: 20),
                   const SizedBox(width: 8),
                  const Text('Sold vs Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _legend(Colors.cyan.shade400, 'Sold'),
                  const SizedBox(width: 12),
                  _legend(Colors.orange.shade400, 'Stock'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: entries.length * 60.0 + 40.0, // Fixed width per bar group
                    child: BarChart(
                      BarChartData(
                        maxY: ceilMaxVisual,
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
                              interval: 5, // Visual interval (sqrt units)
                              getTitlesWidget: (v, meta) {
                                if (v == 0) return const Text('0', style: TextStyle(fontSize: 10));
                                // Show original number square (v*v)
                                final original = math.pow(v, 2).round();
                                return Text(original.toString(), style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                             bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                      ),
                    ),
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
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
