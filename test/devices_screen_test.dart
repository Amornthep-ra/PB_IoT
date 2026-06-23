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

  testWidgets('devices and alert editor accept horizontal adjuster source', (
    WidgetTester tester,
  ) async {
    final stepItem = stepDashboardItem(
      id: 'step-source',
      type: DashboardItemType.stepH,
      title: 'แหล่งปรับค่า H',
      dataKey: 'V4',
      value: 12,
    );

    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V4': 12},
        ),
        items: [stepItem],
      ),
    );
    await tester.pump();

    expect(find.text('แหล่งปรับค่า H'), findsOneWidget);
    expect(find.text('V4'), findsWidgets);
    expect(find.text('12'), findsOneWidget);

    await DashboardBuilderLayoutStorageService().saveItems([stepItem]);
    await tester.pumpWidget(const MaterialApp(home: AlertRuleEditorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('แหล่งปรับค่า H (ปรับค่า H)'), findsOneWidget);
    expect(find.text('V4'), findsWidgets);
  });

  testWidgets('devices page hides backend-only virtual pins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V1': 42},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('V1'), findsNothing);
    expect(find.text('42'), findsNothing);
    expect(find.text('รายงานจากอุปกรณ์'), findsNothing);
    expect(
      find.text(
        'ยังไม่มีข้อมูล Virtual Pin และยังไม่มี Widget ใดผูกกับพิน — สร้าง Widget จากหน้า Dashboard แล้ว Bind Pin เพื่อเริ่มติดตามค่า',
      ),
      findsOneWidget,
    );
  });

  testWidgets('devices page uses compact tablet shell width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      devicesTestApp(snapshot: const DeviceSnapshotModel()),
    );
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('devices_content_shell')),
    );
    expect(shellRect.width, lessThanOrEqualTo(560));
    expect(shellRect.width, greaterThanOrEqualTo(548));
    expect(shellRect.center.dx, closeTo(600 / 2, 12));
    expect(shellRect.top, greaterThanOrEqualTo(36));
    expect(find.text('อุปกรณ์'), findsOneWidget);
  });

  testWidgets('devices page uses standard tablet shell width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      devicesTestApp(snapshot: const DeviceSnapshotModel()),
    );
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('devices_content_shell')),
    );
    expect(shellRect.width, closeTo(768 * 0.82, 12));
    expect(shellRect.center.dx, closeTo(768 / 2, 12));
    expect(find.text('Virtual Pins'), findsOneWidget);
    expect(find.text('ภาพรวมอุปกรณ์'), findsOneWidget);
    expect(find.text('ตัวชี้วัดสำคัญ'), findsNothing);
  });

  testWidgets('devices page uses iPad Air adaptive shell width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      devicesTestApp(snapshot: const DeviceSnapshotModel()),
    );
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('devices_content_shell')),
    );
    expect(shellRect.width, closeTo(820 * 0.82, 12));
    expect(shellRect.center.dx, closeTo(820 / 2, 12));
  });

  testWidgets('devices page caps shell width on large iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      devicesTestApp(snapshot: const DeviceSnapshotModel()),
    );
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('devices_content_shell')),
    );
    expect(shellRect.width, lessThanOrEqualTo(760));
    expect(shellRect.width, greaterThanOrEqualTo(748));
    expect(shellRect.center.dx, closeTo(1024 / 2, 12));
  });

  testWidgets('devices page keeps phone width padding behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      devicesTestApp(snapshot: const DeviceSnapshotModel()),
    );
    await tester.pump();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding as EdgeInsets;
    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('devices_content_shell')),
    );
    expect(padding.left, 20);
    expect(padding.right, 20);
    expect(padding.top, 18);
    expect(shellRect.left, 20);
    expect(shellRect.right, 373);
  });

  testWidgets('devices page shows bound waiting and live pins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V3': 77},
        ),
        items: [
          devicesDashboardItem(
            id: 'waiting',
            title: 'Waiting Widget',
            dataKey: 'V2',
          ),
          devicesDashboardItem(id: 'live', title: 'Live Widget', dataKey: 'V3'),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('V2'), findsOneWidget);
    expect(find.text('Waiting Widget'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);
    expect(find.text('V3'), findsOneWidget);
    expect(find.text('Live Widget'), findsOneWidget);
    expect(find.text('77'), findsOneWidget);
    expect(find.text('รอข้อมูล'), findsWidgets);
  });

  testWidgets('devices page hides unbound pins but keeps bound null pins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V0': null, 'V2': null},
        ),
        items: [
          devicesDashboardItem(
            id: 'bound-null',
            title: 'Bound Null Widget',
            dataKey: 'V2',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('V0'), findsNothing);
    expect(find.text('V2'), findsOneWidget);
    expect(find.text('Bound Null Widget'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);

    await tester.ensureVisible(find.text('Live').last);
    await tester.pump();
    await tester.tap(find.text('Live').last);
    await tester.pump();
    expect(find.text('V2'), findsNothing);

    await tester.tap(find.text('รอข้อมูล').last);
    await tester.pump();
    expect(find.text('V2'), findsOneWidget);
  });

  testWidgets('devices page only extracts intentional virtual pin data keys', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V12': 1, 'V13': 40},
        ),
        items: [
          devicesDashboardItem(
            id: 'accidental',
            title: 'Accidental Widget',
            dataKey: 'abcV12xyz',
          ),
          devicesDashboardItem(
            id: 'path',
            title: 'Path Widget',
            dataKey: 'virtualPins.V13',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('V12'), findsNothing);
    expect(find.text('Accidental Widget'), findsNothing);
    expect(find.text('V13'), findsOneWidget);
    expect(find.text('Path Widget'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('devices page empty state only appears with no pins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      devicesTestApp(snapshot: const DeviceSnapshotModel()),
    );
    await tester.pump();

    expect(
      find.text(
        'ยังไม่มีข้อมูล Virtual Pin และยังไม่มี Widget ใดผูกกับพิน — สร้าง Widget จากหน้า Dashboard แล้ว Bind Pin เพื่อเริ่มติดตามค่า',
      ),
      findsOneWidget,
    );
  });

  testWidgets('devices page search and filters use only bound pins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V1': 42, 'V3': 77},
        ),
        items: [
          devicesDashboardItem(
            id: 'waiting',
            title: 'Waiting Widget',
            dataKey: 'V2',
          ),
          devicesDashboardItem(id: 'live', title: 'Live Widget', dataKey: 'V3'),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('V1'), findsNothing);

    await tester.enterText(find.byType(TextField), '77');
    await tester.pump();
    expect(find.text('V1'), findsNothing);
    expect(find.text('V2'), findsNothing);
    expect(find.text('V3'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.ensureVisible(find.text('รอข้อมูล').last);
    await tester.pump();
    await tester.tap(find.text('รอข้อมูล').last);
    await tester.pump();

    expect(find.text('V1'), findsNothing);
    expect(find.text('V2'), findsOneWidget);
    expect(find.text('V3'), findsNothing);
  });

  testWidgets('devices page formats update timestamps by freshness', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9, 5, 6);
    final previousDay = now.subtract(const Duration(days: 1));
    final previousDayLabel =
        '${previousDay.day} ${thaiShortMonth(previousDay.month)} ${previousDay.year} '
        '${previousDay.hour.toString().padLeft(2, '0')}:'
        '${previousDay.minute.toString().padLeft(2, '0')}:'
        '${previousDay.second.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(online: true, updatedAt: today),
      ),
    );
    await tester.pump();
    expect(find.text('09:05:06'), findsOneWidget);

    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(online: true, updatedAt: previousDay),
      ),
    );
    await tester.pump();
    expect(find.text(previousDayLabel), findsOneWidget);

    await tester.pumpWidget(
      devicesTestApp(snapshot: const DeviceSnapshotModel(online: true)),
    );
    await tester.pump();
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('devices page shows freshness without backend metrics panel', (
    WidgetTester tester,
  ) async {
    final updatedAt = DateTime.now().subtract(const Duration(seconds: 8));
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: updatedAt,
          status: const <String, dynamic>{'temperature': 26.5, 'humidity': 61},
          units: const <String, dynamic>{'temperature': 'C', 'humidity': '%'},
          virtualPins: const <String, dynamic>{'V3': 77},
        ),
        items: [
          devicesDashboardItem(id: 'live', title: 'Live Widget', dataKey: 'V3'),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('ภาพรวมอุปกรณ์'), findsOneWidget);
    expect(find.text('สดใหม่'), findsOneWidget);
    expect(find.text('ตัวชี้วัดสำคัญ'), findsNothing);
    expect(find.text('Temperature'), findsNothing);
    expect(find.text('26.5 C'), findsNothing);
    expect(find.text('Humidity'), findsNothing);
    expect(find.text('61 %'), findsNothing);
  });

  testWidgets('devices page marks stale data without backend metrics panel', (
    WidgetTester tester,
  ) async {
    final updatedAt = DateTime.now().subtract(const Duration(minutes: 5));
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: false,
          updatedAt: updatedAt,
          virtualPins: const <String, dynamic>{'V4': 18},
        ),
        items: [
          devicesDashboardItem(
            id: 'offline',
            title: 'Offline Widget',
            dataKey: 'V4',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('ข้อมูลค้าง'), findsOneWidget);
    expect(find.text('V4'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('ตัวชี้วัดสำคัญ'), findsNothing);
  });

  testWidgets('devices page reserves space for floating bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      devicesTestApp(
        snapshot: const DeviceSnapshotModel(),
        bottomContentPadding: 118,
      ),
    );
    await tester.pump();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding as EdgeInsets;
    expect(padding.bottom, greaterThanOrEqualTo(100));
  });
}
