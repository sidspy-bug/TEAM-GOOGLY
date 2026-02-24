import 'package:flutter/material.dart';
import '../repositories/sales_repository.dart';
import '../models/dashboard_summary.dart';
import '../widgets/summary_card.dart';
import '../widgets/line_chart_card.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/product_list.dart';
import '../widgets/insight_card.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GestureDetector(
                onTap: _isPremium
                    ? null
                    : () {
                        widget.onPremiumToggle(true);
                      },
                child: Tooltip(
                  message: _isPremium ? 'Premium User' : 'Tap to Upgrade',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPremium ? Icons.star : Icons.star_border,
                        color: _isPremium ? Colors.amber : Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isPremium ? 'Premium' : 'Free',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(children: const [DrawerHeader(child: Text('Menu'))]),
      ),
      body: FutureBuilder<DashboardSummary>(
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
      ),
    );
  }

  Widget _buildDashboard(DashboardSummary summary) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              childAspectRatio: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                SummaryCard(
                  title: 'Total Sales',
                  value: '\$${summary.totalSales.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                ),
                SummaryCard(
                  title: 'Top Category',
                  value: summary.categorySales.keys.isNotEmpty
                      ? summary.categorySales.keys.first
                      : '-',
                  icon: Icons.category,
                ),
                SummaryCard(
                  title: 'Low Stock',
                  value: summary.lowStockCount.toString(),
                  icon: Icons.inventory_2,
                ),
                SummaryCard(
                  title: 'Trend',
                  value: summary.salesTrendUp ? 'Up' : 'Down',
                  icon: summary.salesTrendUp ? Icons.trending_up : Icons.trending_down,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Trend Chart
            LineChartCard(salesOverTime: summary.salesOverTime),
            const SizedBox(height: 16),

            // Category breakdown
            BarChartCard(categorySales: summary.categorySales),
            const SizedBox(height: 16),

            // Product Lists
            ProductList(topProducts: summary.topProducts, lowProducts: summary.lowProducts),
            const SizedBox(height: 16),

            // AI Insight
            InsightCard(isPremium: _isPremium, salesRepository: widget.salesRepository),
          ],
        ),
      );
    });
  }
}