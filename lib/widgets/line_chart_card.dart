import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartCard extends StatelessWidget {
  final Map<String, double> salesOverTime;
  final Map<String, double> costOverTime;

  const LineChartCard({super.key, required this.salesOverTime, this.costOverTime = const {}});

  String _formatRupee(double v) {
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

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
                const Text('Daily Earnings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const SizedBox(height: 160, child: Center(child: Text('No data available'))),
              ],
            ),
          ),
        );
      }

      final salesSpots = <FlSpot>[];
      final costSpots = <FlSpot>[];
      for (var i = 0; i < entries.length; i++) {
        salesSpots.add(FlSpot(i.toDouble(), entries[i].value));
        final costVal = costOverTime[entries[i].key] ?? 0;
        costSpots.add(FlSpot(i.toDouble(), costVal));
      }

      final allValues = [...salesSpots.map((s) => s.y), ...costSpots.map((s) => s.y)];
      final rawMaxY = allValues.reduce((a, b) => a > b ? a : b);
      final ceilMaxY = (rawMaxY * 1.15).ceilToDouble();
      double yInterval = (ceilMaxY / 5).ceilToDouble();
      if (yInterval < 1) yInterval = 1;
      // Round yInterval to a nice number
      if (yInterval > 100) {
        yInterval = (yInterval / 100).ceil() * 100;
      } else if (yInterval > 10) {
        yInterval = (yInterval / 10).ceil() * 10;
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Daily Earnings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _legend(Colors.green, 'Sales'),
                  const SizedBox(width: 12),
                  _legend(Colors.red, 'Cost'),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    maxY: ceilMaxY,
                    minY: 0,
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: yInterval),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          interval: yInterval,
                          getTitlesWidget: (v, meta) {
                            if (v == meta.max) return const SizedBox.shrink();
                            return Text(_formatRupee(v), style: const TextStyle(fontSize: 9));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                            final label = DateTime.tryParse(entries[idx].key);
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(label != null ? '${label.day}/${label.month}' : '', style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(spots: salesSpots, isCurved: true, color: Colors.green, barWidth: 2, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.08))),
                      LineChartBarData(spots: costSpots, isCurved: true, color: Colors.red, barWidth: 2, dotData: FlDotData(show: false), dashArray: [4, 3]),
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
              const Text('Daily Earnings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
