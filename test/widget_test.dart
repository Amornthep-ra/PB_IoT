import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:pb_iot/app.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const PbIotApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
