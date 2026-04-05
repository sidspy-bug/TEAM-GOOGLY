import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/dashboard_summary.dart';
import '../repositories/sales_repository.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/line_chart_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/today_focus_card.dart';
import '../widgets/top_products_table.dart';

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
      setState(() => _isPremium = widget.isPremiumUser);
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
                  onPressed: () {
                    setState(() => _summaryFuture = widget.salesRepository.getDashboardSummary());
                  },
                  child: Text(l.retry),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(child: Text(l.noData));
        }

        return _buildDashboard(snapshot.data!);
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

        return Stack(
          children: [
            Positioned(
              top: -80,
              left: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF59C7FF).withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -80,
              top: 110,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5BFFA9).withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedSection(
                    index: 0,
                    child: _buildHeroBanner(summary, isDesktop),
                  ),
                  const SizedBox(height: 14),
                  _buildAnimatedSection(
                    index: 1,
                    child: _isPremium
                        ? AiInsightsCard(
                            isPremium: _isPremium,
                            lowStockCount: summary.lowStockCount,
                            topProduct: topProductName,
                            estimatedProfit: summary.estimatedProfit,
                            salesRepository: widget.salesRepository,
                          )
                        : TodayFocusCard(
                            lowStockCount: summary.lowStockCount,
                            topProduct: topProductName,
                            estimatedProfit: summary.estimatedProfit,
                          ),
                  ),
                  const SizedBox(height: 14),
                  _buildAnimatedSection(
                    index: 3,
                    child: _buildKpiCards(summary, isDesktop, isTablet),
                  ),
                  const SizedBox(height: 14),
                  _buildAnimatedSection(
                    index: 4,
                    child: (isDesktop || isTablet)
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: LineChartCard(
                                  salesOverTime: summary.salesOverTime,
                                  costOverTime: summary.costOverTime,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: BarChartCard(soldVsStock: summary.soldVsStock)),
                            ],
                          )
                        : Column(
                            children: [
                              LineChartCard(
                                salesOverTime: summary.salesOverTime,
                                costOverTime: summary.costOverTime,
                              ),
                              const SizedBox(height: 10),
                              BarChartCard(soldVsStock: summary.soldVsStock),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  _buildAnimatedSection(
                    index: 5,
                    child: TopProductsTable(products: summary.allProducts),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroBanner(DashboardSummary summary, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B294D), Color(0xFF10517E), Color(0xFF148B8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B294D).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildHeroText(summary)),
                const SizedBox(width: 18),
                _buildHeroBadge(summary),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroText(summary),
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: _buildHeroBadge(summary)),
              ],
            ),
    );
  }

  Widget _buildHeroText(DashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Growth Command Center',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track sales, stock, profit and execution in one luminous dashboard experience.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTag('Today Sales: Rs ${summary.totalSales.toStringAsFixed(0)}'),
            _buildTag('Units Sold: ${summary.unitsSold}'),
            _buildTag(summary.salesTrendUp ? 'Trend: Upward' : 'Trend: Needs Attention'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroBadge(DashboardSummary summary) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            summary.lowStockCount > 0
                ? '${summary.lowStockCount} low-stock alerts'
                : 'Stock health looks good',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.circle, size: 9, color: Color(0xFF7CFFB2)),
              SizedBox(width: 6),
              Text('Realtime Sync Active', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: 0.14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    final base = 280;
    final step = 90;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: base + (index * step)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, builtChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: builtChild,
        ),
      ),
      child: child,
    );
  }

  void _showCardDetails(int index, DashboardSummary summary) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        switch (index) {
          case 0:
          case 1:
            return SizedBox(
              height: 350,
              child: LineChartCard(
                salesOverTime: summary.salesOverTime,
                costOverTime: summary.costOverTime,
              ),
            );
          case 2:
            final lowStock = summary.allProducts.where((p) => p.currentStock < 10).toList();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(ctx).lowStockProducts,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lowStock.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        title: Text(lowStock[i].productName),
                        subtitle: Text('${AppLocalizations.of(ctx).stockLabel}: ${lowStock[i].currentStock}'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          case 3:
            final sorted = List.of(summary.allProducts)
              ..sort((a, b) => b.quantity.compareTo(a.quantity));
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Most Sold Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.shopping_cart, color: Colors.purple),
                        title: Text(sorted[i].productName),
                        trailing: Text('Sold: ${sorted[i].quantity}'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildKpiCards(DashboardSummary summary, bool isDesktop, bool isTablet) {
    final cards = [
      SummaryCard(
        title: 'Total Sales',
        value: '₹${summary.totalSales.toStringAsFixed(0)}',
        icon: Icons.storefront,
        color: Colors.blue.shade50,
        onTap: () => _showCardDetails(0, summary),
      ),
      SummaryCard(
        title: 'Estimated Profit',
        value: '₹${summary.estimatedProfit.toStringAsFixed(0)}',
        icon: Icons.trending_up,
        color: Colors.green.shade50,
        onTap: () => _showCardDetails(1, summary),
      ),
      SummaryCard(
        title: 'Low Stock',
        value: '${summary.lowStockCount}',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange.shade50,
        onTap: () => _showCardDetails(2, summary),
      ),
      SummaryCard(
        title: 'Units Sold',
        value: '${summary.unitsSold}',
        icon: Icons.shopping_cart,
        color: Colors.purple.shade50,
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
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Column(
      children: cards
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: c,
              ))
          .toList(),
    );
  }
}
