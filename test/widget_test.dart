import 'package:flutter_test/flutter_test.dart';

import 'package:princebot_smartfarm/app.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const PrinceBotApp());

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
