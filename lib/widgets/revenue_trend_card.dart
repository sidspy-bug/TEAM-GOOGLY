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
    if (v == 0) return '0';
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
                _legend(Colors.indigo.shade400, 'Sales'),
                const SizedBox(width: 12),
                _legend(Colors.teal.shade400, 'Profit'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: isDark ? const Color(0xFF334155) : Colors.white70,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            _formatRupee(spot.y),
                            TextStyle(
                              color: spot.barIndex == 0 ? Colors.indigo : Colors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white10 : Colors.black12,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (v, meta) => Text(
                          _formatRupee(v),
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                        ),
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(dt != null ? '${dt.day}/${dt.month}' : '', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: salesSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.indigo.shade400,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade400.withValues(alpha: 0.2),
                            Colors.indigo.shade400.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: profitSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.teal.shade400,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade400.withValues(alpha: 0.2),
                            Colors.teal.shade400.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
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
