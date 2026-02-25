// MVPFlutter widget test for GrowthOS App

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_business_insights_mvp/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the login screen appears
    expect(find.text('GrowthOS'), findsOneWidget);
  });
}
