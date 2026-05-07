// MVPFlutter widget test for GrowthOS App

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_business_insights_mvp/widgets/summary_card.dart';

void main() {
  testWidgets('SummaryCard renders title and value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryCard(
            title: 'Total Sales',
            value: '₹12,000',
            icon: Icons.currency_rupee,
          ),
        ),
      ),
    );

    expect(find.text('Total Sales'), findsOneWidget);
    expect(find.text('₹12,000'), findsOneWidget);
  });
}
