// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pb_iot/app.dart';
import 'package:pb_iot/features/dashboard/models/device_snapshot_model.dart';
import 'package:pb_iot/features/dashboard/models/widget_binding_model.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_runtime_controller.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_runtime_value_storage.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_service.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_item.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_theme_preset.dart';
import 'package:pb_iot/features/dashboard_builder/models/widget_settings_result.dart';
import 'package:pb_iot/features/dashboard_builder/screens/dashboard_builder_screen.dart';
import 'package:pb_iot/features/dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import 'package:pb_iot/features/dashboard_builder/services/dashboard_widget_factory.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/add_widget_sheet.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_home_view.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_item_renderer.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/widget_settings_sheet.dart';
import 'package:pb_iot/features/devices/screens/devices_screen.dart';
import 'package:pb_iot/features/notifications/models/alert_event_model.dart';
import 'package:pb_iot/features/notifications/screens/alert_rule_editor_screen.dart';
import 'package:pb_iot/features/notifications/screens/notifications_screen.dart';
import 'package:pb_iot/features/notifications/services/notification_service.dart';
import 'package:pb_iot/features/projects/models/project_model.dart';
import 'package:pb_iot/features/projects/services/project_state.dart';
import 'package:pb_iot/models/session_model.dart';
import 'package:pb_iot/screens/account_session_screen.dart';
import 'package:pb_iot/screens/dashboard_screen.dart';
import 'package:pb_iot/screens/project_select_screen.dart';
import 'package:pb_iot/screens/token_login_screen.dart';
import 'package:pb_iot/services/session_state.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  setUpWidgetTestEnvironment();

  testWidgets('login screen shows Thai-first copy and remember semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TokenLoginScreen()));
    await tester.pump();

    expect(find.text('โทเค็นเข้าใช้งาน', findRichText: true), findsOneWidget);
    expect(find.text('ชื่อโปรไฟล์', findRichText: true), findsOneWidget);
    expect(find.text('จดจำโทเค็นบนอุปกรณ์นี้'), findsOneWidget);
    expect(find.text('เก็บโทเค็นอย่างปลอดภัยบนอุปกรณ์นี้'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(find.text('ขอโทเค็น / ลืมโทเค็น? คลิกที่นี่'), findsOneWidget);
    expect(find.text('นโยบายความเป็นส่วนตัว'), findsOneWidget);
    expect(find.text('ลบบัญชี'), findsOneWidget);
    final rememberSemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'จดจำโทเค็นบนอุปกรณ์นี้',
      ),
    );
    expect(rememberSemantics.properties.button, isTrue);
    expect(rememberSemantics.properties.toggled, isFalse);
  });

  testWidgets('login screen keeps form visible when keyboard is open', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const MaterialApp(home: TokenLoginScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.text('โทเค็นเข้าใช้งาน', findRichText: true), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('login screen constrains content on iPad portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TokenLoginScreen()));
    await tester.pumpAndSettle();

    final tokenFieldRect = tester.getRect(
      find.text('โทเค็นเข้าใช้งาน', findRichText: true),
    );
    final loginButtonRect = tester.getRect(find.text('เข้าสู่ระบบ'));
    expect(tokenFieldRect.left, greaterThan(80));
    expect(loginButtonRect.width, lessThanOrEqualTo(640));
  });

  testWidgets('login screen remains usable on compact tablet portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TokenLoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('โทเค็นเข้าใช้งาน', findRichText: true), findsOneWidget);
    expect(find.text('ชื่อโปรไฟล์', findRichText: true), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    final loginButtonRect = tester.getRect(find.text('เข้าสู่ระบบ'));
    expect(loginButtonRect.width, lessThanOrEqualTo(544));
  });

  testWidgets('login screen balances vertically on large tablet portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TokenLoginScreen()));
    await tester.pumpAndSettle();

    final tokenFieldRect = tester.getRect(
      find.text('โทเค็นเข้าใช้งาน', findRichText: true),
    );
    final loginButtonRect = tester.getRect(find.text('เข้าสู่ระบบ'));
    expect(tokenFieldRect.top, greaterThan(260));
    expect(loginButtonRect.width, lessThanOrEqualTo(640));
  });

  testWidgets('login notices use info color while errors stay red', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (_) {
          return MaterialPageRoute<void>(
            settings: const RouteSettings(
              arguments: TokenLoginScreen.sessionExpiredRouteArgument,
            ),
            builder: (_) => const TokenLoginScreen(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session หมดอายุ'), findsOneWidget);
    final sessionIcon = tester.widget<Icon>(
      find.byIcon(Icons.lock_outline_rounded),
    );
    expect(sessionIcon.color, const Color(0xFF2F80A8));

    await tester.pumpWidget(const MaterialApp(home: TokenLoginScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอก Token'), findsOneWidget);
    final errorIcon = tester.widget<Icon>(find.byIcon(Icons.vpn_key_rounded));
    expect(errorIcon.color, const Color(0xFFB24A4A));
  });
}
