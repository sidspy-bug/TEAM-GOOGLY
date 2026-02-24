import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartCard extends StatelessWidget {
  final Map<String, double> salesOverTime;

  const LineChartCard({super.key, required this.salesOverTime});

  @override
  Widget build(BuildContext context) {
    try {
      final entries = salesOverTime.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      if (entries.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const SizedBox(height: 200, child: Center(child: Text('No data available'))),
              ],
            ),
          ),
        );
      }

      final spots = <FlSpot>[];
      for (var i = 0; i < entries.length; i++) {
        spots.add(FlSpot(i.toDouble(), entries[i].value));
      }

      final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    maxY: maxY * 1.2,
                    minY: 0,
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                            final label = DateTime.tryParse(entries[idx].key);
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(label != null ? '${label.month}/${label.day}' : '', style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: Theme.of(context).primaryColor,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                    ],
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
              const Text('Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: Center(child: Text('Error: $e'))),
            ],
          ),
        ),
      );
    }
  }
}
