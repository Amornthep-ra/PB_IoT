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

  testWidgets('project select screen shows Thai-first copy and date label', (
    WidgetTester tester,
  ) async {
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    expect(find.text('เลือกโปรเจกต์'), findsOneWidget);
    expect(find.text('เลือกพื้นที่ทำงานเพื่อเปิดแดชบอร์ด'), findsOneWidget);
    expect(find.text('สร้างโปรเจกต์'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('แก้ไขล่าสุด 1 มิ.ย. 2026'), findsOneWidget);
    expect(find.text('เลือกอยู่'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byTooltip('ตัวเลือกโปรเจกต์'), findsOneWidget);
  });

  testWidgets('project select screen constrains content on iPad portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    final headerRect = tester.getRect(find.text('เลือกโปรเจกต์'));
    final tileRect = tester.getRect(find.text('Test'));
    expect(headerRect.left, greaterThan(80));
    expect(tileRect.left, greaterThan(80));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('สร้างโปรเจกต์'), findsOneWidget);
  });

  testWidgets('project select remains usable on compact tablet portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    final headerRect = tester.getRect(find.text('เลือกโปรเจกต์'));
    final tileRect = tester.getRect(find.text('Test'));
    expect(headerRect.left, greaterThan(20));
    expect(tileRect.left, greaterThan(20));
    expect(find.text('สร้างโปรเจกต์'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('project select balances vertically on large tablet portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    final headerRect = tester.getRect(find.text('เลือกโปรเจกต์'));
    final tileRect = tester.getRect(find.text('Test'));
    expect(headerRect.top, greaterThan(95));
    expect(tileRect.left, greaterThan(180));
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('project select keeps phone FAB behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('สร้างโปรเจกต์'), findsOneWidget);
  });

  testWidgets('project select empty tablet state has one create action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    expect(find.text('สร้างโปรเจกต์แรกของคุณ'), findsOneWidget);
    expect(find.text('สร้างโปรเจกต์'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('project select row opens dashboard when tapped', (
    WidgetTester tester,
  ) async {
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard opened'), findsOneWidget);
  });

  testWidgets('project select menu opens Thai edit dialog', (
    WidgetTester tester,
  ) async {
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ตัวเลือกโปรเจกต์'));
    await tester.pumpAndSettle();

    expect(find.text('แก้ไข'), findsOneWidget);
    expect(find.text('ลบ'), findsOneWidget);

    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขโปรเจกต์'), findsOneWidget);
    expect(find.text('ไอคอนโปรเจกต์'), findsOneWidget);
    expect(find.text('ชื่อโปรเจกต์'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
  });

  testWidgets('project edit dialog is width capped on large tablet portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ตัวเลือกโปรเจกต์'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(
      find.byKey(const ValueKey('project_name_dialog_surface')),
    );
    expect(dialogRect.width, lessThanOrEqualTo(640.0));
    expect(dialogRect.left, greaterThan(180.0));
    expect(find.text('แก้ไขโปรเจกต์'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
  });

  testWidgets(
    'project edit dialog remains visible on compact tablet portrait',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      seedProjects();

      await tester.pumpWidget(projectSelectTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('ตัวเลือกโปรเจกต์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไข'));
      await tester.pumpAndSettle();

      final dialogRect = tester.getRect(
        find.byKey(const ValueKey('project_name_dialog_surface')),
      );
      expect(dialogRect.left, greaterThanOrEqualTo(20.0));
      expect(dialogRect.right, lessThanOrEqualTo(580.0));
      expect(find.text('แก้ไขโปรเจกต์'), findsOneWidget);
      expect(find.text('ชื่อโปรเจกต์'), findsOneWidget);
      expect(find.text('บันทึก'), findsOneWidget);
    },
  );

  testWidgets('project edit dialog keeps phone width behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ตัวเลือกโปรเจกต์'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(
      find.byKey(const ValueKey('project_name_dialog_surface')),
    );
    expect(dialogRect.left, 20.0);
    expect(dialogRect.right, 373.0);
    expect(find.text('แก้ไขโปรเจกต์'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
  });

  testWidgets('project edit dialog remains usable with keyboard inset', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ตัวเลือกโปรเจกต์'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขโปรเจกต์'), findsOneWidget);
    expect(find.text('ไอคอนโปรเจกต์'), findsOneWidget);
    expect(find.text('ชื่อโปรเจกต์'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
  });

  testWidgets('project select menu opens Thai delete confirmation', (
    WidgetTester tester,
  ) async {
    seedProjects();

    await tester.pumpWidget(projectSelectTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ตัวเลือกโปรเจกต์'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();

    expect(find.text('ลบโปรเจกต์'), findsOneWidget);
    expect(find.text('ลบ "Test"'), findsOneWidget);
    expect(
      find.text('เมื่อลบแล้วจะไม่สามารถเรียกคืนข้อมูลได้'),
      findsOneWidget,
    );
    expect(find.text('ยกเลิก'), findsOneWidget);
    expect(find.text('ลบ'), findsOneWidget);
  });
}
