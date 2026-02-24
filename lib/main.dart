import 'package:flutter/material.dart';
import 'repositories/dummy_sales_repository.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isPremium = false;

  void _setPremium(bool value) {
    setState(() {
      _isPremium = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesRepository = DummySalesRepository();

    return MaterialApp(
      title: 'AI Business Insights (MVP)',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: DashboardScreen(
        salesRepository: salesRepository,
        isPremiumUser: _isPremium,
        onPremiumToggle: _setPremium,
      ),
    );
  }
}
