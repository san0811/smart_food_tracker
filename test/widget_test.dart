import 'package:flutter_test/flutter_test.dart';

import 'package:smart_food_tracker/main.dart';

void main() {
  testWidgets('app renders dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const FridgiApp());

    expect(find.text('Today at a glance'), findsOneWidget);
    expect(find.text('Inventory priorities'), findsOneWidget);
    expect(find.text('Diet plans'), findsNothing);
  });
}
