// MVPFlutter widget test for Dashboard App

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_business_insights_mvp/main.dart';
import 'package:ai_business_insights_mvp/repositories/dummy_sales_repository.dart';

void main() {
  testWidgets('Dashboard renders without crashing', (WidgetTester tester) async {
    final repo = DummySalesRepository();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      salesRepository: repo,
      isPremiumUser: false,
    ));

    // Verify the app bar title is present
    expect(find.text('Business Dashboard'), findsOneWidget);
  });
}
