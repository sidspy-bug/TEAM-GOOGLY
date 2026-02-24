import 'package:flutter/material.dart';

class DashboardScreenMinimal extends StatelessWidget {
  const DashboardScreenMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Dashboard - Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Total Sales', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 8),
                  Text('\$5000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Top Category', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 8),
                  Text('Beverages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Low Stock Items', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 8),
                  Text('4', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Sales Trend', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 8),
                  Text('Up ↑', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
