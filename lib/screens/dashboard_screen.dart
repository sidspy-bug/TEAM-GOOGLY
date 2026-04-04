import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../repositories/sales_repository.dart';
import '../models/dashboard_summary.dart';
import '../widgets/summary_card.dart';
import '../widgets/line_chart_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/top_products_table.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/today_focus_card.dart';
import '../widgets/revenue_trend_card.dart';

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
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
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

  /// Public method to trigger a data refresh from parent shell
  void refresh() {
    if (mounted) {
      setState(() {
        _summaryFuture = widget.salesRepository.getDashboardSummary();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<DashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l.loading),
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
                Text(l.errorLoadingDashboard),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(
                      () => _summaryFuture = widget.salesRepository.getDashboardSummary()),
                  child: Text(l.retry),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(child: Text(l.noData));
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
                      child: RevenueTrendCard(
                        salesOverTime: summary.salesOverTime,
                        costOverTime: summary.costOverTime,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: BarChartCard(soldVsStock: summary.soldVsStock),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    RevenueTrendCard(
                      salesOverTime: summary.salesOverTime,
                      costOverTime: summary.costOverTime,
                    ),
                    const SizedBox(height: 14),
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

  void _showCardDetails(int index, DashboardSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final double h = MediaQuery.of(ctx).size.height * 0.55;
        switch (index) {
          case 0:
            return SizedBox(height: h, child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: LineChartCard(
                salesOverTime: summary.salesOverTime, 
                costOverTime: summary.costOverTime,
                showSalesOnly: true,
                title: 'Total Sales Detail',
              ),
            ));
          case 1:
            return SizedBox(height: h, child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: LineChartCard(
                salesOverTime: summary.salesOverTime, 
                costOverTime: summary.costOverTime,
                showProfitOnly: true,
                title: 'Estimated Profit Detail',
              ),
            ));
          case 2:
            final lowStock = summary.lowProducts;
            return SizedBox(height: h, child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                Text(AppLocalizations.of(ctx).lowStockProducts, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: lowStock.length,
                    itemBuilder: (ctx, i) => ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text(lowStock[i].productName),
                      subtitle: Text('${AppLocalizations.of(ctx).stockLabel}: ${lowStock[i].currentStock}'),
                      trailing: const Text('Reorder soon', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                  ),
                ),
              ]),
            ));
          case 3:
            // Explicit descending sort by units sold
            final allSorted = List.of(summary.allProducts)..sort((a, b) => b.quantity.compareTo(a.quantity));
            final sorted = allSorted.take(10).toList();
            return SizedBox(height: h, child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                const Text('Top 10 Most Sold Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (ctx, i) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade50,
                        child: Text('${i + 1}', style: TextStyle(color: Colors.purple.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(sorted[i].productName),
                      subtitle: Text(sorted[i].category),
                      trailing: Text('${sorted[i].quantity} unit(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ]),
            ));
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildKpiCards(DashboardSummary summary, bool isDesktop, bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = [
      SummaryCard(
        title: 'Total Sales',
        value: '₹${summary.totalSales.toStringAsFixed(0)}',
        icon: Icons.storefront,
        color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
        onTap: () => _showCardDetails(0, summary),
      ),
      SummaryCard(
        title: 'Estimated Profit',
        value: '₹${summary.estimatedProfit.toStringAsFixed(0)}',
        icon: Icons.trending_up,
        color: isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50,
        onTap: () => _showCardDetails(1, summary),
      ),
      SummaryCard(
        title: 'Low Stock',
        value: '${summary.lowStockCount}',
        icon: Icons.warning_amber_rounded,
        color: isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50,
        onTap: () => _showCardDetails(2, summary),
      ),
      SummaryCard(
        title: 'Units Sold',
        value: '${summary.unitsSold}',
        icon: Icons.shopping_cart,
        color: isDark ? Colors.purple.shade900.withValues(alpha: 0.3) : Colors.purple.shade50,
        onTap: () => _showCardDetails(3, summary),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .expand((c) => [Expanded(child: c), const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      );
    } else if (isTablet) {
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
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: c,
        )).toList(),
      );
    }
  }
}