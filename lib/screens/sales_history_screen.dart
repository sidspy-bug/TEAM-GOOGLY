import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../repositories/sales_repository.dart';

class SalesHistoryScreen extends StatefulWidget {
  final SalesRepository salesRepository;
  const SalesHistoryScreen({super.key, required this.salesRepository});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late Future<List<Sale>> _salesFuture;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _salesFuture = widget.salesRepository.getSales();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 14)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilter() {
    setState(() => _dateRange = null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Sale>>(
      future: _salesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        var sales = snapshot.data ?? [];

        // Sort by date descending
        sales.sort((a, b) => b.date.compareTo(a.date));

        // Apply date filter
        if (_dateRange != null) {
          sales = sales.where((s) {
            final d = DateTime(s.date.year, s.date.month, s.date.day);
            return !d.isBefore(_dateRange!.start) && !d.isAfter(_dateRange!.end);
          }).toList();
        }

        // Group by date
        final Map<String, List<Sale>> grouped = {};
        for (final s in sales) {
          final key = '${s.date.day}/${s.date.month}/${s.date.year}';
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(s);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and date filter
              Row(
                children: [
                  const Text('Sales History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_dateRange != null) ...[
                    Chip(
                      label: Text(
                        '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _clearFilter,
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Filter by Date'),
                    onPressed: _pickDateRange,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary card
              if (sales.isNotEmpty)
                Card(
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.indigo.shade600, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Total Sales: ₹${sales.fold<double>(0, (sum, s) => sum + s.dailyRevenue).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '${sales.length} transactions',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              if (sales.isNotEmpty) const SizedBox(height: 12),

              if (sales.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No sales found for the selected period.')),
                  ),
                )
              else
                ...grouped.entries.map((entry) {
                  final dateLabel = entry.key;
                  final dateSales = entry.value;
                  final dayRevenue = dateSales.fold<double>(0, (sum, s) => sum + s.dailyRevenue);
                  final dayProfit = dateSales.fold<double>(0, (sum, s) => sum + s.estimatedProfit);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.indigo.shade600),
                            const SizedBox(width: 8),
                            Text(dateLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                            const Spacer(),
                            Text('Revenue: ₹${dayRevenue.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            const SizedBox(width: 12),
                            Text('Profit: ₹${dayProfit.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: dayProfit >= 0 ? Colors.green.shade700 : Colors.red)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 24,
                            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                            columns: const [
                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                              DataColumn(label: Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                            ],
                            rows: dateSales.map((s) {
                              return DataRow(cells: [
                                DataCell(Text('${s.date.day}/${s.date.month}/${s.date.year}')),
                                DataCell(Text(s.productName)),
                                DataCell(Text('${s.quantity}')),
                                DataCell(Text(s.transactionMode)),
                                DataCell(Text('₹${s.dailyRevenue.toStringAsFixed(0)}')),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
