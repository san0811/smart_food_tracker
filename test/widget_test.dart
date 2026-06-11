import 'package:flutter_test/flutter_test.dart';

import 'package:smart_food_tracker/main.dart';

void main() {
  testWidgets('app renders dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartFoodApp());

    expect(find.text('Good Evening'), findsOneWidget);
    expect(find.text('Today at a glance'), findsOneWidget);
    expect(find.text('Diet plans'), findsNothing);
  });
}
