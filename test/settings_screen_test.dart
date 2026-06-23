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

  testWidgets('settings page uses Thai-first copy and token actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SessionState.current = const SessionModel(
      token: 'sf_7123456789845',
      displayName: 'ทดสอบ',
      authType: 'token',
      authenticated: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const AccountSessionScreen(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('login opened')),
          '/projects': (_) => const Scaffold(body: Text('projects opened')),
        },
      ),
    );
    await tester.pump();

    expect(find.text('ตั้งค่า'), findsOneWidget);
    expect(find.text('รายละเอียดเซสชัน'), findsOneWidget);
    expect(find.text('ประเภทการเข้าสู่ระบบ'), findsOneWidget);
    expect(find.text('โทเค็น'), findsWidgets);
    expect(find.text('สถานะเซสชัน'), findsOneWidget);
    expect(find.text('ใช้งานอยู่'), findsOneWidget);
    expect(find.text('การตั้งค่า'), findsOneWidget);
    expect(find.text('การตั้งค่าทั่วไป'), findsOneWidget);
    expect(find.text('เปลี่ยนโปรเจกต์'), findsOneWidget);
    expect(find.text('นโยบายความเป็นส่วนตัว'), findsOneWidget);
    expect(find.text('ช่วยเหลือและสนับสนุน'), findsOneWidget);
    expect(find.byTooltip('กลับ'), findsOneWidget);
    expect(find.byTooltip('แสดงโทเค็น'), findsOneWidget);
    expect(find.byTooltip('คัดลอกโทเค็น'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pump();

    expect(find.text('ออกจากระบบ'), findsOneWidget);

    expect(find.text('Settings'), findsNothing);
    expect(find.text('Session Details'), findsNothing);
    expect(find.text('Auth Type'), findsNothing);
    expect(find.text('Session Status'), findsNothing);
    expect(find.text('Preferences'), findsNothing);
    expect(find.text('General Settings'), findsNothing);
    expect(find.text('Switch Project'), findsNothing);
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Active'), findsNothing);
    expect(find.text('Logout'), findsNothing);
  });

  testWidgets('settings page uses compact tablet shell width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(settingsTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('account_session_content_shell')),
    );
    expect(shellRect.width, lessThanOrEqualTo(560));
    expect(shellRect.width, greaterThanOrEqualTo(548));
    expect(shellRect.center.dx, closeTo(600 / 2, 12));
    expect(shellRect.top, greaterThanOrEqualTo(36));
    expect(find.text('ตั้งค่า'), findsOneWidget);
  });

  testWidgets('settings page uses standard tablet shell width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(settingsTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('account_session_content_shell')),
    );
    expect(shellRect.width, closeTo(768 * 0.82, 12));
    expect(shellRect.center.dx, closeTo(768 / 2, 12));
    expect(find.text('รายละเอียดเซสชัน'), findsOneWidget);
  });

  testWidgets('settings page uses iPad Air adaptive shell width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(settingsTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('account_session_content_shell')),
    );
    expect(shellRect.width, closeTo(820 * 0.82, 12));
    expect(shellRect.center.dx, closeTo(820 / 2, 12));
  });

  testWidgets('profile avatar picker shows full iPad grid and selects avatar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(settingsTestApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เลือกรูปโปรไฟล์').last);
    await tester.pumpAndSettle();

    expect(find.text('เลือกรูปโปรไฟล์'), findsOneWidget);
    expect(find.text('เลือกรูปโปรไฟล์สำเร็จรูปสำหรับบัญชีนี้'), findsOneWidget);

    for (var index = 1; index <= 14; index += 1) {
      final choiceFinder = find.byKey(
        ValueKey<String>('profile_avatar_choice_avatar$index'),
      );
      expect(choiceFinder, findsOneWidget);
      expect(tester.getBottomLeft(choiceFinder).dy, lessThan(1180));
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('profile_avatar_choice_avatar14')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('profile_avatar_choice_avatar14')),
      findsNothing,
    );
  });

  testWidgets('settings page caps shell width on large iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(settingsTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('account_session_content_shell')),
    );
    expect(shellRect.width, lessThanOrEqualTo(760));
    expect(shellRect.width, greaterThanOrEqualTo(748));
    expect(shellRect.center.dx, closeTo(1024 / 2, 12));
  });

  testWidgets('settings page keeps phone width padding behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(settingsTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('account_session_content_shell')),
    );
    expect(shellRect.left, 24);
    expect(shellRect.right, 369);
    expect(find.byTooltip('แสดงโทเค็น'), findsOneWidget);
  });
}
