import 'package:flutter/material.dart';
import '../repositories/sales_repository.dart';
import '../models/dashboard_summary.dart';
import '../widgets/summary_card.dart';
import '../widgets/line_chart_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/top_products_table.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/today_focus_card.dart';

class DashboardScreen extends StatefulWidget {
  final SalesRepository salesRepository;
  final bool isPremiumUser;
  final ValueChanged<bool> onPremiumToggle;

  const DashboardScreen({
    super.key,
    required this.salesRepository,
    required this.isPremiumUser,
    required this.onPremiumToggle,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSummary> _summaryFuture;
  late bool _isPremium;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.salesRepository.getDashboardSummary();
    _isPremium = widget.isPremiumUser;
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPremiumUser != widget.isPremiumUser) {
      setState(() {
        _isPremium = widget.isPremiumUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading dashboard'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(
                      () => _summaryFuture = widget.salesRepository.getDashboardSummary()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data'));
        }

        final summary = snapshot.data!;
        return _buildDashboard(summary);
      },
    );
  }

  Widget _buildDashboard(DashboardSummary summary) {
    final topProductName = summary.topProducts.isNotEmpty ? summary.topProducts.first.productName : '-';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 900;
        final isTablet = width >= 600 && width < 900;
        // final isMobile = width < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Insights (Premium) or Today's Focus (Basic) — ABOVE everything
              if (_isPremium)
                AiInsightsCard(
                  isPremium: _isPremium,
                  lowStockCount: summary.lowStockCount,
                  topProduct: topProductName,
                  estimatedProfit: summary.estimatedProfit,
                  salesRepository: widget.salesRepository,
                )
              else
                TodayFocusCard(
                  lowStockCount: summary.lowStockCount,
                  topProduct: topProductName,
                  estimatedProfit: summary.estimatedProfit,
                ),
              const SizedBox(height: 14),

              // 4 KPI Summary Cards — responsive grid
              _buildKpiCards(summary, isDesktop, isTablet),
              const SizedBox(height: 14),

              // Charts in single row (desktop) or stacked (mobile)
              if (isDesktop || isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LineChartCard(
                        salesOverTime: summary.salesOverTime,
                        costOverTime: summary.costOverTime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BarChartCard(soldVsStock: summary.soldVsStock),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    LineChartCard(
                      salesOverTime: summary.salesOverTime,
                      costOverTime: summary.costOverTime,
                    ),
                    const SizedBox(height: 10),
                    BarChartCard(soldVsStock: summary.soldVsStock),
                  ],
                ),
              const SizedBox(height: 14),

              // Top 10 Products
              TopProductsTable(products: summary.allProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCards(DashboardSummary summary, bool isDesktop, bool isTablet) {
    final cards = [
      SummaryCard(
        title: "Today's Sales",
        value: '₹${summary.totalSales.toStringAsFixed(0)}',
        icon: Icons.storefront,
        color: Colors.blue.shade50,
      ),
      SummaryCard(
        title: 'Estimated Profit',
        value: '₹${summary.estimatedProfit.toStringAsFixed(0)}',
        icon: Icons.trending_up,
        color: Colors.green.shade50,
      ),
      SummaryCard(
        title: 'Low Stock',
        value: '${summary.lowStockCount}',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange.shade50,
      ),
      SummaryCard(
        title: 'Units Sold',
        value: '${summary.unitsSold}',
        icon: Icons.shopping_cart,
        color: Colors.purple.shade50,
      ),
    ];

    if (isDesktop) {
      // 4 in a row
      return Row(
        children: cards
            .expand((c) => [Expanded(child: c), const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      );
    } else if (isTablet) {
      // 2x2 grid
      return Column(
        children: [
          Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ]),
        ],
      );
    } else {
      // Stacked on mobile
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: c,
        )).toList(),
      );
    }
  }
}