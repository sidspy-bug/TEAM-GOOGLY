import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartCard extends StatelessWidget {
  final Map<String, double> salesOverTime;
  final Map<String, double> costOverTime;
  final String? title;
  final bool showSalesOnly;
  final bool showProfitOnly;

  const LineChartCard({
    super.key,
    required this.salesOverTime,
    this.costOverTime = const {},
    this.title,
    this.showSalesOnly = false,
    this.showProfitOnly = false,
  });

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
                Text(title ?? 'Daily Earnings', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const SizedBox(height: 160, child: Center(child: Text('No data available'))),
              ],
            ),
          ),
        );
      }

      final List<FlSpot> mainSpots = [];
      final List<FlSpot> secondarySpots = [];
      
      for (var i = 0; i < entries.length; i++) {
        final date = entries[i].key;
        final salesVal = entries[i].value;
        final costVal = costOverTime[date] ?? 0;
        
        if (showProfitOnly) {
          mainSpots.add(FlSpot(i.toDouble(), salesVal - costVal));
        } else if (showSalesOnly) {
          mainSpots.add(FlSpot(i.toDouble(), salesVal));
        } else {
          mainSpots.add(FlSpot(i.toDouble(), salesVal));
          secondarySpots.add(FlSpot(i.toDouble(), costVal));
        }
      }

      final allValues = [...mainSpots.map((s) => s.y), ...secondarySpots.map((s) => s.y)];
      final rawMaxY = allValues.reduce((a, b) => a > b ? a : b);
      final ceilMaxY = (rawMaxY * 1.15).ceilToDouble();
      double yInterval = (ceilMaxY / 5).ceilToDouble();
      if (yInterval < 1) yInterval = 1;
      
      if (yInterval > 100) {
        yInterval = (yInterval / 100).ceil() * 100;
      } else if (yInterval > 10) {
        yInterval = (yInterval / 10).ceil() * 10;
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title ?? (showProfitOnly ? 'Profit Trend' : (showSalesOnly ? 'Sales Trend' : 'Daily Earnings')), 
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (!showSalesOnly && !showProfitOnly) ...[
                    _legend(Colors.green, 'Sales'),
                    const SizedBox(width: 12),
                    _legend(Colors.red, 'Cost'),
                  ] else if (showProfitOnly)
                    _legend(Colors.blue, 'Profit')
                  else
                    _legend(Colors.green, 'Sales'),
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
                      LineChartBarData(
                        spots: mainSpots,
                        isCurved: true,
                        color: showProfitOnly ? Colors.blue : Colors.green,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true, 
                          color: (showProfitOnly ? Colors.blue : Colors.green).withValues(alpha: 0.1)
                        ),
                      ),
                      if (secondarySpots.isNotEmpty)
                        LineChartBarData(
                          spots: secondarySpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          dashArray: [4, 4],
                        ),
                    ],
                    borderData: FlBorderData(show: true, border: Border(left: BorderSide(color: isDark ? Colors.white24 : Colors.black12), bottom: BorderSide(color: isDark ? Colors.white24 : Colors.black12))),
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
              Text(title ?? 'Daily Earnings', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
