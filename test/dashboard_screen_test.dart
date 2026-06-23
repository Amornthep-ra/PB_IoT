// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pb_iot/app.dart';
import 'package:pb_iot/features/dashboard/models/device_snapshot_model.dart';
import 'package:pb_iot/features/dashboard/models/widget_binding_model.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_alert_evaluator.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_runtime_controller.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_polling_driver.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_snapshot_refresher.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_runtime_value_storage.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_service.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_item.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_theme_preset.dart';
import 'package:pb_iot/features/dashboard_builder/models/widget_settings_result.dart';
import 'package:pb_iot/features/dashboard_builder/screens/dashboard_builder_screen.dart';
import 'package:pb_iot/features/dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import 'package:pb_iot/features/dashboard_builder/services/dashboard_grid_metrics.dart';
import 'package:pb_iot/features/dashboard_builder/services/dashboard_widget_factory.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/add_widget_sheet.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_home_view.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_item_renderer.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/widget_settings_sheet.dart';
import 'package:pb_iot/features/devices/screens/devices_screen.dart';
import 'package:pb_iot/features/notifications/models/alert_event_model.dart';
import 'package:pb_iot/features/notifications/models/alert_rule_model.dart';
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

class _FakePeriodicTimer implements Timer {
  _FakePeriodicTimer(this.callback);

  final void Function(Timer timer) callback;
  bool _isActive = true;
  int _tick = 0;

  void fire() {
    if (!_isActive) {
      return;
    }
    _tick += 1;
    callback(this);
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _isActive = false;
  }
}

void main() {
  setUpWidgetTestEnvironment();

  DashboardItem alertToggleItem({
    required String id,
    required bool enabled,
    double value = 0,
  }) {
    return DashboardItem(
      id: id,
      type: DashboardItemType.toggle,
      title: 'Alert Toggle',
      rect: const GridRect(x: 0, y: 0, w: 10, h: 5),
      minW: 8,
      maxW: 28,
      minH: 4,
      maxH: 14,
      accentColor: const Color(0xFF4E9070),
      dataKey: 'V1',
      bindingMode: 'read',
      dataType: 'boolean',
      enabled: enabled,
      value: value,
    );
  }

  AlertRuleModel alertRule({
    required String id,
    required String widgetId,
    required DashboardItemType widgetType,
    required AlertRuleCondition condition,
    double? thresholdValue,
    bool enabled = true,
  }) {
    return AlertRuleModel(
      id: id,
      title: 'Alert Rule',
      widgetId: widgetId,
      widgetTitle: 'Alert Widget',
      widgetType: widgetType,
      dataKey: 'V1',
      dataType: widgetType == DashboardItemType.toggle ? 'boolean' : 'number',
      condition: condition,
      thresholdValue: thresholdValue,
      message: 'Triggered',
      enabled: enabled,
      createdAt: DateTime(2026, 6, 22, 12),
    );
  }

  test('dashboard grid metrics keep right-edge rect inside phone canvas', () {
    const width = 393.0;
    const rect = GridRect(x: 8, y: 0, w: 14, h: 4);
    final columns = DashboardGridMetrics.columnsForWidth(width);
    final cellWidth = DashboardGridMetrics.cellWidthFor(
      width: width,
      columns: columns,
    );
    final stepX = DashboardGridMetrics.stepFor(cellWidth);
    final right =
        (rect.x * stepX) +
        DashboardGridMetrics.itemWidthFor(rect: rect, cellWidth: cellWidth);

    expect(columns, 22);
    expect(rect.right, columns);
    expect(right, closeTo(width, 0.001));
  });

  testWidgets('dashboard empty state shows Thai copy and widget CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(dashboardHomeTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('เริ่มสร้างแดชบอร์ดของคุณ'), findsOneWidget);
    expect(
      find.text('เพิ่มวิดเจ็ตตัวแรกเพื่อเริ่มติดตามอุปกรณ์'),
      findsOneWidget,
    );
    expect(find.text('เพิ่มวิดเจ็ต'), findsNWidgets(2));
    expect(find.text('Edit Mode'), findsNothing);
  });

  testWidgets('dashboard empty canvas uses compact mobile height', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardHomeTestApp());
    await tester.pumpAndSettle();

    final hasCompactCanvas = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .any((widget) => widget.height == 520);
    expect(hasCompactCanvas, isTrue);
    expect(find.text('เริ่มสร้างแดชบอร์ดของคุณ'), findsOneWidget);
  });

  testWidgets('dashboard canvas uses compact tablet cap on iPad portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = stepDashboardItem(
      id: 'ipad-step',
      type: DashboardItemType.stepH,
      title: 'iPad Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 0, y: 0, w: 26, h: 6));

    await tester.pumpWidget(dashboardHomeTestApp(items: [item]));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, lessThanOrEqualTo(560));
    expect(itemRect.width, greaterThanOrEqualTo(548));
    expect(itemRect.center.dx, closeTo(600 / 2, 12));
  });

  testWidgets('dashboard canvas uses standard tablet cap on iPad portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = stepDashboardItem(
      id: 'standard-ipad-step',
      type: DashboardItemType.stepH,
      title: 'Standard iPad Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 0, y: 0, w: 26, h: 6));

    await tester.pumpWidget(dashboardHomeTestApp(items: [item]));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, closeTo(768 * 0.82, 12));
    expect(itemRect.center.dx, closeTo(768 / 2, 12));
  });

  testWidgets('dashboard canvas scales on iPad Air portrait width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = stepDashboardItem(
      id: 'air-ipad-step',
      type: DashboardItemType.stepH,
      title: 'iPad Air Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 0, y: 0, w: 26, h: 6));

    await tester.pumpWidget(dashboardHomeTestApp(items: [item]));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, closeTo(820 * 0.82, 12));
    expect(itemRect.center.dx, closeTo(820 / 2, 12));
  });

  testWidgets('dashboard canvas keeps phone width behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = stepDashboardItem(
      id: 'phone-step',
      type: DashboardItemType.stepH,
      title: 'Phone Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 0, y: 0, w: 22, h: 6));

    await tester.pumpWidget(dashboardHomeTestApp(items: [item]));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, lessThanOrEqualTo(393));
    expect(itemRect.center.dx, closeTo(393 / 2, 12));
  });

  testWidgets('dashboard keeps right-edge value widget inside phone canvas', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = devicesDashboardItem(
      id: 'right-edge-value',
      title: 'Right Edge Value',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 8, y: 12, w: 14, h: 8), value: 4095);

    await tester.pumpWidget(dashboardHomeTestApp(items: [item]));
    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_canvas_surface')),
    );
    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);

    expect(itemRect.left, greaterThanOrEqualTo(canvasRect.left));
    expect(itemRect.right, lessThanOrEqualTo(canvasRect.right));
  });

  testWidgets('dashboard canvas remains capped on large iPad portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = stepDashboardItem(
      id: 'large-ipad-step',
      type: DashboardItemType.stepH,
      title: 'Large iPad Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 0, y: 0, w: 26, h: 6));

    await tester.pumpWidget(dashboardHomeTestApp(items: [item]));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, lessThanOrEqualTo(760));
    expect(itemRect.width, greaterThanOrEqualTo(748));
    expect(itemRect.center.dx, closeTo(1024 / 2, 12));
  });

  testWidgets(
    'dashboard header is capped and centered on large iPad portrait',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(dashboardHomeTestApp());
      await tester.pumpAndSettle();

      final headerRect = tester.getRect(
        find.byKey(const ValueKey<String>('dashboard_header_surface')),
      );
      expect(headerRect.width, lessThanOrEqualTo(760.0));
      expect(headerRect.width, greaterThanOrEqualTo(728.0));
      expect(headerRect.center.dx, closeTo(1024 / 2, 12));
      expect(find.text('Test'), findsOneWidget);
    },
  );

  testWidgets('dashboard shell keeps phone header width behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardHomeTestApp());
    await tester.pumpAndSettle();

    final headerRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_header_surface')),
    );
    expect(headerRect.left, 16.0);
    expect(headerRect.right, 377.0);
  });

  testWidgets('dashboard empty state CTA opens dashboard builder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(dashboardHomeTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มวิดเจ็ต').last);
    await tester.pumpAndSettle();

    expect(find.text('builder opened'), findsOneWidget);
  });

  testWidgets('dashboard header CTA opens dashboard builder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(dashboardHomeTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มวิดเจ็ต').first);
    await tester.pumpAndSettle();

    expect(find.text('builder opened'), findsOneWidget);
  });

  testWidgets(
    'dashboard bottom navigation uses Thai labels and switches tabs',
    (WidgetTester tester) async {
      await tester.pumpWidget(dashboardShellTestApp());
      await tester.pump();

      expect(find.text('แดชบอร์ด'), findsOneWidget);
      expect(find.text('อุปกรณ์'), findsOneWidget);
      expect(find.text('แจ้งเตือน'), findsOneWidget);
      expect(find.text('ตั้งค่า'), findsOneWidget);

      await tester.tap(find.text('อุปกรณ์'));
      await tester.pump();

      expect(find.text('อุปกรณ์'), findsWidgets);
    },
  );

  testWidgets('dashboard bottom nav is capped and centered on large iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardShellTestApp());
    await tester.pump();

    final navRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_bottom_nav_surface')),
    );
    expect(navRect.width, lessThanOrEqualTo(760.0));
    expect(navRect.width, greaterThanOrEqualTo(748.0));
    expect(navRect.center.dx, closeTo(1024 / 2, 12));
    expect(find.text('แดชบอร์ด'), findsOneWidget);
    expect(find.text('ตั้งค่า'), findsOneWidget);
  });

  testWidgets('dashboard bottom nav keeps phone width behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardShellTestApp());
    await tester.pump();

    final navRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_bottom_nav_surface')),
    );
    expect(navRect.left, 14.0);
    expect(navRect.right, 379.0);
  });

  testWidgets(
    'dashboard reserves scroll space for floating bottom navigation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(dashboardShellTestApp());
      await tester.pump();
      await tester.pump();

      final navRect = tester.getRect(
        find.byKey(const ValueKey<String>('dashboard_bottom_nav_surface')),
      );
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final padding = scrollView.padding as EdgeInsets;
      expect(padding.bottom, closeTo(navRect.height + 34 + 8 + 24 + 24, 1));
    },
  );

  testWidgets(
    'dashboard nav reserve tracks measured height with large text scale',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      seedProjectState();
      final preferences = await SharedPreferences.getInstance();
      await DashboardBuilderLayoutStorageService(
        preferences: preferences,
      ).saveItems([
        stepDashboardItem(
          id: 'large-text-step',
          type: DashboardItemType.stepH,
          title: 'Large Text Step',
          dataKey: 'V4',
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.8),
              ),
              child: child!,
            );
          },
          home: const DashboardScreen(),
          routes: {
            '/dashboard-builder': (_) =>
                const Scaffold(body: Text('builder opened')),
            '/account-session': (_) =>
                const Scaffold(body: Text('settings opened')),
          },
        ),
      );
      await tester.pump();
      await tester.pump();

      final navRect = tester.getRect(
        find.byKey(const ValueKey<String>('dashboard_bottom_nav_surface')),
      );
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final padding = scrollView.padding as EdgeInsets;
      expect(padding.bottom, closeTo(navRect.height + 34 + 8 + 24 + 24, 1));
      expect(navRect.height, greaterThan(68));
    },
  );

  testWidgets('dashboard can scroll a bottom widget above the nav reserve', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bottomItem = stepDashboardItem(
      id: 'bottom-step',
      type: DashboardItemType.stepH,
      title: 'Bottom Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 4, y: 66, w: 14, h: 5));

    await tester.pumpWidget(
      dashboardHomeTestApp(items: [bottomItem], bottomContentPadding: 160),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).last);
    expect(itemRect.bottom, lessThanOrEqualTo(932 - 160));
  });

  testWidgets('dashboard nav softens while scrolling and restores when idle', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bottomItem = stepDashboardItem(
      id: 'scroll-step',
      type: DashboardItemType.stepH,
      title: 'Scroll Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 4, y: 66, w: 14, h: 5));
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([bottomItem]);

    await tester.pumpWidget(dashboardShellTestApp());
    await tester.pumpAndSettle();

    AnimatedOpacity navOpacity() => tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('dashboard-bottom-nav-opacity')),
    );

    expect(navOpacity().opacity, 1);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -240),
    );
    await tester.pump();

    expect(navOpacity().opacity, 0.78);

    await tester.tap(find.text('ตั้งค่า'));
    await tester.pumpAndSettle();

    expect(find.text('settings opened'), findsOneWidget);
    final navOpacityBehindSettings = tester.widget<AnimatedOpacity>(
      find.byKey(
        const ValueKey<String>('dashboard-bottom-nav-opacity'),
        skipOffstage: false,
      ),
    );
    expect(navOpacityBehindSettings.opacity, 1);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  });

  testWidgets('alerts tab uses Thai-first copy and empty states', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardShellTestApp());
    await tester.tap(find.text('แจ้งเตือน'));
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือน'), findsOneWidget);
    expect(find.text('กฎแจ้งเตือน'), findsWidgets);
    expect(find.text('เหตุการณ์ล่าสุด'), findsWidgets);
    expect(find.text('ประวัติทั้งหมด'), findsWidgets);
    expect(find.text('ยังไม่มีกฎแจ้งเตือน'), findsOneWidget);
    expect(find.text('ยังไม่มีเหตุการณ์ใหม่'), findsOneWidget);
    expect(find.text('0 รายการล่าสุด'), findsOneWidget);
    expect(find.text('0 ประวัติทั้งหมด'), findsOneWidget);

    expect(find.text('Alerts'), findsNothing);
    expect(find.text('Alert Rules'), findsNothing);
    expect(find.text('Event History'), findsNothing);
    expect(find.text('All History'), findsNothing);
    expect(find.text('No alert rules yet'), findsNothing);
    expect(find.text('No current events'), findsNothing);
    expect(find.text('Create'), findsNothing);
  });

  testWidgets(
    'dashboard shell preserves devices search state across tab switches',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      seedProjectState();
      await DashboardBuilderLayoutStorageService().saveItems([
        devicesDashboardItem(
          id: 'live-device-pin',
          title: 'Live Widget',
          dataKey: 'V13',
        ),
        devicesDashboardItem(
          id: 'waiting-device-pin',
          title: 'Waiting Widget',
          dataKey: 'V2',
        ),
      ]);

      await tester.pumpWidget(dashboardShellTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('อุปกรณ์'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'V13');
      await tester.pumpAndSettle();

      expect(find.text('Live Widget'), findsOneWidget);
      expect(find.text('Waiting Widget'), findsNothing);

      await tester.tap(find.text('แดชบอร์ด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('อุปกรณ์'));
      await tester.pumpAndSettle();

      expect(find.text('Live Widget'), findsOneWidget);
      expect(find.text('Waiting Widget'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'V13',
      );
    },
  );

  testWidgets(
    'dashboard shell preserves notifications selected page across tab switches',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'notification_permission_prompt_seen_v1': true,
      });
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(dashboardShellTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('แจ้งเตือน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ประวัติทั้งหมด').last);
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีประวัติ'), findsOneWidget);
      expect(find.text('ยังไม่มีเหตุการณ์ใหม่'), findsNothing);

      await tester.tap(find.text('อุปกรณ์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แจ้งเตือน'));
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีประวัติ'), findsOneWidget);
      expect(find.text('ยังไม่มีเหตุการณ์ใหม่'), findsNothing);
    },
  );

  testWidgets('create alert editor uses Thai-first copy and sticky actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([
      alertEditorDashboardItem(),
    ]);

    await tester.pumpWidget(const MaterialApp(home: AlertRuleEditorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('สร้างการแจ้งเตือน'), findsOneWidget);
    expect(find.text('ชื่อการแจ้งเตือน'), findsOneWidget);
    expect(find.text('วิดเจ็ต'), findsOneWidget);
    expect(find.text('เงื่อนไข'), findsOneWidget);
    expect(find.text('ระดับความสำคัญ'), findsOneWidget);
    expect(find.text('ข้อความแจ้งเตือน'), findsWidgets);
    expect(find.text('ตัวอย่าง'), findsOneWidget);
    expect(find.text('ทดสอบแจ้งเตือน'), findsOneWidget);
    expect(find.text('บันทึกการแจ้งเตือน'), findsOneWidget);
    expect(find.text('ปุ่ม 1 (ปุ่ม)'), findsOneWidget);

    expect(find.text('คำสั่งสวิตช์'), findsWidgets);
    expect(find.text('V0'), findsWidgets);
    expect(find.text('บูลีน'), findsWidgets);
    expect(find.text('อ่านค่า'), findsWidgets);

    expect(find.text('Create Alert'), findsNothing);
    expect(find.text('Alert name'), findsNothing);
    expect(find.text('Widget'), findsNothing);
    expect(find.text('Condition'), findsNothing);
    expect(find.text('Severity'), findsNothing);
    expect(find.text('Preview'), findsNothing);
    expect(find.text('Test alert'), findsNothing);
    expect(find.text('Save alert'), findsNothing);
    expect(find.text('ปุ่ม 1 (button)'), findsNothing);
  });

  testWidgets('step widget reads backend value and writes on tap', (
    WidgetTester tester,
  ) async {
    final service = FakeDashboardService(
      DeviceSnapshotModel(
        online: true,
        updatedAt: DateTime.now(),
        virtualPins: const <String, dynamic>{'V4': 10},
      ),
    );
    final item = stepDashboardItem(
      id: 'step-runtime',
      type: DashboardItemType.stepH,
      title: 'Step Runtime',
      dataKey: 'V4',
      value: 0,
      stepValue: 5,
    );

    await tester.pumpWidget(
      dashboardHomeTestApp(service: service, items: [item]),
    );
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);

    await tester.tap(find.byTooltip('เพิ่มค่า'));
    await tester.pump();

    expect(service.writes.single.pin, 'V4');
    expect(service.writes.single.value, 15);
  });

  testWidgets('dashboard runtime reads status path bindings', (
    WidgetTester tester,
  ) async {
    final item = devicesDashboardItem(
      id: 'status-temperature',
      title: 'Status Temperature',
      dataKey: 'status.temperature',
    ).copyWith(value: 0);
    final controller = DashboardRuntimeController(
      dashboardService: FakeDashboardService(
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          status: const <String, dynamic>{'temperature': 28},
        ),
      ),
      layoutStorage: FakeDashboardLayoutStorage([item]),
    );

    await controller.initialize();

    expect(controller.items.single.value, 28);

    controller.dispose();
  });

  testWidgets('dashboard runtime reads top-level online binding', (
    WidgetTester tester,
  ) async {
    final led = DashboardWidgetFactory.createItem(
      type: DashboardItemType.led,
      existingItems: const <DashboardItem>[],
      seed: 1,
      buttonMinW: 8,
      buttonMaxW: 28,
      buttonMinH: 6,
      buttonMaxH: 14,
    ).copyWith(dataKey: 'online', enabled: false, value: 0);
    final controller = DashboardRuntimeController(
      dashboardService: FakeDashboardService(
        DeviceSnapshotModel(online: true, updatedAt: DateTime.now()),
      ),
      layoutStorage: FakeDashboardLayoutStorage([led]),
    );

    await controller.initialize();

    expect(controller.items.single.enabled, isTrue);
    expect(controller.items.single.value, 1);

    controller.dispose();
  });

  testWidgets('dashboard runtime reads virtualPins path bindings', (
    WidgetTester tester,
  ) async {
    final item = devicesDashboardItem(
      id: 'virtual-pin-path',
      title: 'Virtual Pin Path',
      dataKey: 'virtualPins.V3',
    ).copyWith(value: 0);
    final controller = DashboardRuntimeController(
      dashboardService: FakeDashboardService(
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V3': 44},
        ),
      ),
      layoutStorage: FakeDashboardLayoutStorage([item]),
    );

    await controller.initialize();

    expect(controller.items.single.value, 44);

    controller.dispose();
  });

  testWidgets('dashboard runtime leaves unresolved path binding unchanged', (
    WidgetTester tester,
  ) async {
    final item = devicesDashboardItem(
      id: 'unknown-status',
      title: 'Unknown Status',
      dataKey: 'status.unknownMetric',
    ).copyWith(value: 12);
    final controller = DashboardRuntimeController(
      dashboardService: FakeDashboardService(
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          status: const <String, dynamic>{'temperature': 28},
        ),
      ),
      layoutStorage: FakeDashboardLayoutStorage([item]),
    );

    await controller.initialize();

    expect(controller.items.single.value, 12);

    controller.dispose();
  });

  testWidgets(
    'dashboard runtime write-only binding does not hydrate from snapshot',
    (WidgetTester tester) async {
      final item = DashboardItem(
        id: 'write-only-toggle',
        type: DashboardItemType.toggle,
        title: 'Write Only Toggle',
        rect: const GridRect(x: 0, y: 0, w: 10, h: 5),
        minW: 8,
        maxW: 28,
        minH: 4,
        maxH: 14,
        accentColor: const Color(0xFF4E9070),
        dataKey: 'V1',
        bindingMode: 'write',
        dataType: 'boolean',
        enabled: false,
        value: 0,
      );
      final controller = DashboardRuntimeController(
        dashboardService: FakeDashboardService(
          DeviceSnapshotModel(
            online: true,
            updatedAt: DateTime.now(),
            virtualPins: const <String, dynamic>{'V1': 1},
          ),
        ),
        layoutStorage: FakeDashboardLayoutStorage([item]),
      );

      await controller.initialize();

      expect(controller.items.single.enabled, isFalse);
      expect(controller.items.single.value, 0);

      controller.dispose();
    },
  );

  testWidgets('step widget writes backend control alias without pin', (
    WidgetTester tester,
  ) async {
    final service = FakeDashboardService(
      DeviceSnapshotModel(online: true, updatedAt: DateTime.now()),
    );
    final item = stepDashboardItem(
      id: 'soil-threshold-step',
      type: DashboardItemType.stepH,
      title: 'Soil Threshold',
      dataKey: 'control.soilThreshold',
      value: 0,
      stepValue: 5,
    );

    await tester.pumpWidget(
      dashboardHomeTestApp(service: service, items: [item]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('เพิ่มค่า'));
    await tester.pump();

    expect(service.writes.single.pin, isNull);
    expect(service.writes.single.writeKey, 'control.soilThreshold');
    expect(service.writes.single.value, 5);
  });

  testWidgets('trend and led widgets read runtime snapshots without writes', (
    WidgetTester tester,
  ) async {
    final trend = DashboardWidgetFactory.createItem(
      type: DashboardItemType.trend,
      existingItems: const <DashboardItem>[],
      seed: 1,
      buttonMinW: 8,
      buttonMaxW: 28,
      buttonMinH: 6,
      buttonMaxH: 14,
    ).copyWith(dataKey: 'V3', dataKeyLabel: 'อุณหภูมิ');
    final led = DashboardWidgetFactory.createItem(
      type: DashboardItemType.led,
      existingItems: <DashboardItem>[trend],
      seed: 2,
      buttonMinW: 8,
      buttonMaxW: 28,
      buttonMinH: 6,
      buttonMaxH: 14,
    ).copyWith(dataKey: 'V1', dataKeyLabel: 'สถานะ');
    final service = FakeDashboardService(
      DeviceSnapshotModel(
        online: true,
        updatedAt: DateTime.now(),
        virtualPins: const <String, dynamic>{'V3': 25, 'V1': 'online'},
      ),
    );

    await tester.pumpWidget(
      dashboardHomeTestApp(service: service, items: [trend, led]),
    );
    await tester.pumpAndSettle();

    expect(find.text('25'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('trend_chart_painter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('led_indicator_light')),
      findsOneWidget,
    );
    expect(find.text('ON'), findsNothing);
    expect(service.writes, isEmpty);
  });

  testWidgets('trend runtime appends first sample and skips duplicates', (
    WidgetTester tester,
  ) async {
    final trend = DashboardWidgetFactory.createItem(
      type: DashboardItemType.trend,
      existingItems: const <DashboardItem>[],
      seed: 1,
      buttonMinW: 8,
      buttonMaxW: 28,
      buttonMinH: 6,
      buttonMaxH: 14,
    ).copyWith(dataKey: 'V3');
    final controller = DashboardRuntimeController(
      dashboardService: FakeDashboardService(
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V3': 99},
        ),
      ),
      layoutStorage: FakeDashboardLayoutStorage([trend]),
    );

    await controller.initialize();

    expect(controller.items.single.value, 99);
    expect(controller.items.single.series, const <double>[99]);

    await controller.refreshSnapshotFromServer();

    expect(controller.items.single.value, 99);
    expect(controller.items.single.series, const <double>[99]);

    controller.dispose();
  });

  testWidgets('trend runtime changed samples are capped at thirty values', (
    WidgetTester tester,
  ) async {
    final trend =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.trend,
          existingItems: const <DashboardItem>[],
          seed: 1,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          dataKey: 'V3',
          series: List<double>.generate(30, (index) => index.toDouble()),
        );
    final controller = DashboardRuntimeController(
      dashboardService: FakeDashboardService(
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V3': 99},
        ),
      ),
      layoutStorage: FakeDashboardLayoutStorage([trend]),
    );

    await controller.initialize();

    expect(controller.items.single.value, 99);
    expect(controller.items.single.series, hasLength(30));
    expect(controller.items.single.series.first, 1);
    expect(controller.items.single.series.last, 99);

    controller.dispose();
  });

  testWidgets('led runtime coerces accepted status values', (
    WidgetTester tester,
  ) async {
    final cases = <Object?, bool>{
      true: true,
      1: true,
      'on': true,
      'online': true,
      false: false,
      0: false,
      'off': false,
      'offline': false,
    };

    for (final entry in cases.entries) {
      final led = DashboardWidgetFactory.createItem(
        type: DashboardItemType.led,
        existingItems: const <DashboardItem>[],
        seed: 1,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      ).copyWith(dataKey: 'V1');
      final controller = DashboardRuntimeController(
        dashboardService: FakeDashboardService(
          DeviceSnapshotModel(
            online: true,
            updatedAt: DateTime.now(),
            virtualPins: <String, dynamic>{'V1': entry.key},
          ),
        ),
        layoutStorage: FakeDashboardLayoutStorage([led]),
      );

      await controller.initialize();

      expect(controller.items.single.enabled, entry.value);
      expect(controller.items.single.value, entry.value ? 1 : 0);

      controller.dispose();
    }
  });

  testWidgets(
    'dashboard runtime initial failure uses cached offline data and recovers by polling',
    (WidgetTester tester) async {
      seedProjectState();
      final item = stepDashboardItem(
        id: 'cached-step',
        type: DashboardItemType.stepH,
        title: 'Cached Step',
        dataKey: 'V4',
        value: 0,
        stepValue: 1,
      );
      await DashboardRuntimeValueStorage().saveFromItems([
        item.copyWith(value: 42),
      ]);
      final service = FailThenSuccessDashboardService(
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V4': 64},
        ),
      );
      final controller = DashboardRuntimeController(
        dashboardService: service,
        layoutStorage: FakeDashboardLayoutStorage([item]),
      );

      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.errorText, isNotNull);
      expect(controller.snapshot?.online, isFalse);
      expect(controller.snapshot?.virtualPins, isEmpty);
      expect(controller.items.single.value, 42);

      await tester.pump(const Duration(milliseconds: 2100));

      expect(service.fetchCount, greaterThanOrEqualTo(2));
      expect(controller.errorText, isNull);
      expect(controller.snapshot?.online, isTrue);
      expect(controller.snapshot?.virtualPins, isNot(contains('V10')));
      expect(controller.items.single.value, 64);

      controller.dispose();
    },
  );

  test('polling driver starts one timer and polls on tick', () async {
    final timers = <_FakePeriodicTimer>[];
    var pollCount = 0;
    final driver = DashboardPollingDriver(
      pollInterval: const Duration(seconds: 2),
      onPoll: () async {
        pollCount += 1;
      },
      periodicTimerFactory: (_, callback) {
        final timer = _FakePeriodicTimer(callback);
        timers.add(timer);
        return timer;
      },
    );

    driver.start();
    driver.start();
    expect(timers, hasLength(1));

    timers.single.fire();
    await Future<void>.delayed(Duration.zero);
    expect(pollCount, 1);

    driver.dispose();
  });

  test('polling driver stops and resumes across lifecycle changes', () async {
    final timers = <_FakePeriodicTimer>[];
    var pollCount = 0;
    final driver = DashboardPollingDriver(
      pollInterval: const Duration(seconds: 2),
      onPoll: () async {
        pollCount += 1;
      },
      periodicTimerFactory: (_, callback) {
        final timer = _FakePeriodicTimer(callback);
        timers.add(timer);
        return timer;
      },
    );

    driver.start();
    expect(timers, hasLength(1));
    expect(timers.single.isActive, isTrue);

    driver.handleLifecycleState(AppLifecycleState.paused);
    expect(timers.single.isActive, isFalse);

    driver.handleLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(pollCount, 1);
    expect(timers, hasLength(2));
    expect(timers.last.isActive, isTrue);

    driver.dispose();
    expect(timers.last.isActive, isFalse);
  });

  test(
    'snapshot refresher returns snapshot without session recovery',
    () async {
      final snapshot = DeviceSnapshotModel(
        online: true,
        updatedAt: DateTime(2026, 6, 22, 12),
        virtualPins: const <String, dynamic>{'V4': 18},
      );
      final service = FakeDashboardService(snapshot);
      final authService = FakeAuthService(
        session: const SessionModel(
          token: 'token',
          displayName: 'Tester',
          authenticated: true,
        ),
      );
      final refresher = DashboardSnapshotRefresher(
        dashboardService: service,
        authService: authService,
      );

      final result = await refresher.refresh();

      expect(result.isSuccess, isTrue);
      expect(result.snapshot, same(snapshot));
      expect(result.errorText, isNull);
      expect(result.attemptedSessionRecovery, isFalse);
      expect(result.didRecoverSession, isFalse);
      expect(authService.fetchCurrentSessionCount, 0);
    },
  );

  test(
    'snapshot refresher returns error when offline recovery is not eligible',
    () async {
      final service = SequenceDashboardService([
        const DashboardServiceException('backend unavailable'),
      ]);
      final authService = FakeAuthService(
        session: const SessionModel(
          token: 'token',
          displayName: 'Tester',
          authenticated: true,
        ),
      );
      final refresher = DashboardSnapshotRefresher(
        dashboardService: service,
        authService: authService,
      );

      final result = await refresher.refresh();

      expect(result.isSuccess, isFalse);
      expect(result.snapshot, isNull);
      expect(result.errorText, 'backend unavailable');
      expect(result.attemptedSessionRecovery, isFalse);
      expect(result.didRecoverSession, isFalse);
      expect(authService.fetchCurrentSessionCount, 0);
    },
  );

  test(
    'snapshot refresher recovers offline session and retries successfully',
    () async {
      SessionState.current = const SessionModel(
        token: 'cached-token',
        displayName: 'Cached User',
        authenticated: true,
        isOfflineMode: true,
      );
      final recoveredSnapshot = DeviceSnapshotModel(
        online: true,
        updatedAt: DateTime(2026, 6, 22, 13),
        virtualPins: const <String, dynamic>{'V4': 72},
      );
      final service = SequenceDashboardService([
        const DashboardServiceException('backend unavailable'),
        recoveredSnapshot,
      ]);
      final authService = FakeAuthService(
        session: const SessionModel(
          token: 'fresh-token',
          displayName: 'Recovered User',
          authenticated: true,
        ),
      );
      final refresher = DashboardSnapshotRefresher(
        dashboardService: service,
        authService: authService,
      );

      final result = await refresher.refresh();

      expect(result.isSuccess, isTrue);
      expect(result.snapshot, same(recoveredSnapshot));
      expect(result.attemptedSessionRecovery, isTrue);
      expect(result.didRecoverSession, isTrue);
      expect(authService.fetchCurrentSessionCount, 1);
      expect(SessionState.current?.isOfflineMode, isFalse);
      expect(SessionState.current?.token, 'fresh-token');
      expect(service.fetchCount, 2);
    },
  );

  test(
    'snapshot refresher throttles repeated offline recovery attempts',
    () async {
      SessionState.current = const SessionModel(
        token: 'cached-token',
        displayName: 'Cached User',
        authenticated: true,
        isOfflineMode: true,
      );
      final service = SequenceDashboardService([
        const DashboardServiceException('backend unavailable'),
        const DashboardServiceException('backend unavailable'),
      ]);
      final authService = FakeAuthService(
        session: const SessionModel(
          token: 'fresh-token',
          displayName: 'Recovered User',
          authenticated: true,
        ),
      );
      var tick = 0;
      final refresher = DashboardSnapshotRefresher(
        dashboardService: service,
        authService: authService,
        now: () => DateTime(2026, 6, 22, 14, 0, tick),
      );

      final firstResult = await refresher.refresh();
      tick = 1;
      final secondResult = await refresher.refresh();

      expect(firstResult.isSuccess, isFalse);
      expect(firstResult.attemptedSessionRecovery, isTrue);
      expect(secondResult.isSuccess, isFalse);
      expect(secondResult.attemptedSessionRecovery, isFalse);
      expect(authService.fetchCurrentSessionCount, 1);
    },
  );

  test('alert evaluator emits threshold event only on rising edge', () {
    final evaluator = DashboardAlertEvaluator();
    final rule = alertRule(
      id: 'threshold-rule',
      widgetId: 'temperature',
      widgetType: DashboardItemType.valueLabel,
      condition: AlertRuleCondition.greaterThan,
      thresholdValue: 30,
    );
    final inactiveItem = devicesDashboardItem(
      id: 'temperature',
      title: 'Temperature',
      dataKey: 'status.temperature',
    ).copyWith(value: 28);
    final activeItem = inactiveItem.copyWith(value: 33);
    final higherActiveItem = inactiveItem.copyWith(value: 35);

    final firstResult = evaluator.evaluate(
      rules: [rule],
      previousItems: [inactiveItem],
      nextItems: [activeItem],
    );
    final secondResult = evaluator.evaluate(
      rules: [rule],
      previousItems: [activeItem],
      nextItems: [higherActiveItem],
    );

    expect(firstResult.newEvents, hasLength(1));
    expect(firstResult.newEvents.single.payload['value'], 33);
    expect(secondResult.newEvents, isEmpty);
  });

  test('alert evaluator emits again after inactive to active transition', () {
    final evaluator = DashboardAlertEvaluator();
    final rule = alertRule(
      id: 'threshold-rule',
      widgetId: 'temperature',
      widgetType: DashboardItemType.valueLabel,
      condition: AlertRuleCondition.greaterThan,
      thresholdValue: 30,
    );
    final lowItem = devicesDashboardItem(
      id: 'temperature',
      title: 'Temperature',
      dataKey: 'status.temperature',
    ).copyWith(value: 20);
    final highItem = lowItem.copyWith(value: 34);

    evaluator.evaluate(
      rules: [rule],
      previousItems: [lowItem],
      nextItems: [highItem],
    );
    final inactiveResult = evaluator.evaluate(
      rules: [rule],
      previousItems: [highItem],
      nextItems: [lowItem],
    );
    final reactivatedResult = evaluator.evaluate(
      rules: [rule],
      previousItems: [lowItem],
      nextItems: [highItem],
    );

    expect(inactiveResult.newEvents, isEmpty);
    expect(reactivatedResult.newEvents, hasLength(1));
  });

  test('alert evaluator handles becameOn and becameOff transitions only', () {
    final evaluator = DashboardAlertEvaluator();
    final toggleOff = alertToggleItem(id: 'pump', enabled: false);
    final toggleOn = alertToggleItem(id: 'pump', enabled: true, value: 1);
    final becameOnRule = alertRule(
      id: 'became-on',
      widgetId: 'pump',
      widgetType: DashboardItemType.toggle,
      condition: AlertRuleCondition.becameOn,
    );
    final becameOffRule = alertRule(
      id: 'became-off',
      widgetId: 'pump',
      widgetType: DashboardItemType.toggle,
      condition: AlertRuleCondition.becameOff,
    );

    final onResult = evaluator.evaluate(
      rules: [becameOnRule],
      previousItems: [toggleOff],
      nextItems: [toggleOn],
    );
    final steadyOnResult = evaluator.evaluate(
      rules: [becameOnRule],
      previousItems: [toggleOn],
      nextItems: [toggleOn],
    );
    final offResult = evaluator.evaluate(
      rules: [becameOffRule],
      previousItems: [toggleOn],
      nextItems: [toggleOff],
    );

    expect(onResult.newEvents, hasLength(1));
    expect(steadyOnResult.newEvents, isEmpty);
    expect(offResult.newEvents, hasLength(1));
  });

  test(
    'alert evaluator clears active state for disabled and missing rules',
    () {
      final evaluator = DashboardAlertEvaluator();
      final rule = alertRule(
        id: 'pump-rule',
        widgetId: 'pump',
        widgetType: DashboardItemType.toggle,
        condition: AlertRuleCondition.isOn,
      );
      final toggleOn = alertToggleItem(id: 'pump', enabled: true, value: 1);

      final firstResult = evaluator.evaluate(
        rules: [rule],
        previousItems: const [],
        nextItems: [toggleOn],
      );
      final disabledResult = evaluator.evaluate(
        rules: [rule.copyWith(enabled: false)],
        previousItems: [toggleOn],
        nextItems: [toggleOn],
      );
      final reenabledResult = evaluator.evaluate(
        rules: [rule],
        previousItems: [toggleOn],
        nextItems: [toggleOn],
      );
      final missingResult = evaluator.evaluate(
        rules: [rule],
        previousItems: [toggleOn],
        nextItems: const [],
      );
      final restoredResult = evaluator.evaluate(
        rules: [rule],
        previousItems: const [],
        nextItems: [toggleOn],
      );

      expect(firstResult.newEvents, hasLength(1));
      expect(disabledResult.newEvents, isEmpty);
      expect(reenabledResult.newEvents, hasLength(1));
      expect(missingResult.newEvents, isEmpty);
      expect(restoredResult.newEvents, hasLength(1));
    },
  );

  testWidgets(
    'dashboard runtime refresh failure keeps hydrated items unchanged and only updates error state',
    (WidgetTester tester) async {
      seedProjectState();
      final item = stepDashboardItem(
        id: 'refresh-failure-step',
        type: DashboardItemType.stepH,
        title: 'Refresh Failure Step',
        dataKey: 'V4',
        value: 0,
      );
      final service = SequenceDashboardService([
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V4': 18},
        ),
        const DashboardServiceException('backend unavailable'),
      ]);
      final controller = DashboardRuntimeController(
        dashboardService: service,
        layoutStorage: FakeDashboardLayoutStorage([item]),
      );

      await controller.initialize();
      expect(controller.items.single.value, 18);

      await controller.refreshSnapshotFromServer();

      expect(controller.items.single.value, 18);
      expect(controller.errorText, 'backend unavailable');
      expect(controller.snapshot?.virtualPins['V4'], 18);

      controller.dispose();
    },
  );

  testWidgets(
    'dashboard runtime refresh can recover offline session and hydrate fresh values',
    (WidgetTester tester) async {
      seedProjectState();
      SessionState.current = const SessionModel(
        token: 'cached-token',
        displayName: 'Cached User',
        authenticated: true,
        isOfflineMode: true,
      );
      final item = stepDashboardItem(
        id: 'refresh-recovery-step',
        type: DashboardItemType.stepH,
        title: 'Refresh Recovery Step',
        dataKey: 'V4',
        value: 0,
      );
      final initialSnapshot = DeviceSnapshotModel(
        online: true,
        updatedAt: DateTime.now(),
        virtualPins: const <String, dynamic>{'V4': 18},
      );
      final recoveredSnapshot = DeviceSnapshotModel(
        online: true,
        updatedAt: DateTime.now().add(const Duration(seconds: 1)),
        virtualPins: const <String, dynamic>{'V4': 64},
      );
      final service = SequenceDashboardService([
        initialSnapshot,
        const DashboardServiceException('backend unavailable'),
        recoveredSnapshot,
      ]);
      final refresher = DashboardSnapshotRefresher(
        dashboardService: service,
        authService: FakeAuthService(
          session: const SessionModel(
            token: 'fresh-token',
            displayName: 'Recovered User',
            authenticated: true,
          ),
        ),
      );
      final controller = DashboardRuntimeController(
        dashboardService: service,
        layoutStorage: FakeDashboardLayoutStorage([item]),
        snapshotRefresher: refresher,
      );

      await controller.initialize();
      expect(controller.items.single.value, 18);

      await controller.refreshSnapshotFromServer();

      expect(controller.errorText, isNull);
      expect(controller.items.single.value, 64);
      expect(controller.snapshot?.virtualPins['V4'], 64);
      expect(SessionState.current?.isOfflineMode, isFalse);

      controller.dispose();
    },
  );

  testWidgets(
    'dashboard runtime appends alert events and dispatches local notifications from evaluator output',
    (WidgetTester tester) async {
      final notificationService = FakeNotificationService(
        rules: [
          alertRule(
            id: 'pump-became-on',
            widgetId: 'pump',
            widgetType: DashboardItemType.toggle,
            condition: AlertRuleCondition.becameOn,
          ),
        ],
      );
      final dispatchedEvents = <AlertEventModel>[];
      final controller = DashboardRuntimeController(
        dashboardService: FakeDashboardService(),
        notificationService: notificationService,
        layoutStorage: FakeDashboardLayoutStorage([
          alertToggleItem(id: 'pump', enabled: false),
        ]),
        alertNotificationCallback: (event) async {
          dispatchedEvents.add(event);
        },
      );

      await controller.initialize();
      await controller.updateRuntimeItems([
        alertToggleItem(id: 'pump', enabled: true, value: 1),
      ]);

      final currentEvents = await notificationService.loadEvents();
      final historyEvents = await notificationService.loadHistoryEvents();

      expect(currentEvents, hasLength(1));
      expect(historyEvents, hasLength(1));
      expect(dispatchedEvents, hasLength(1));
      expect(currentEvents.single.ruleId, 'pump-became-on');
      expect(currentEvents.single.payload['value'], isTrue);

      await controller.updateRuntimeItems([
        alertToggleItem(id: 'pump', enabled: true, value: 1),
      ]);

      expect(await notificationService.loadEvents(), hasLength(1));
      expect(dispatchedEvents, hasLength(1));

      controller.dispose();
    },
  );

  testWidgets(
    'dashboard runtime resumes polling and refreshes after app lifecycle resume',
    (WidgetTester tester) async {
      seedProjectState();
      final item = stepDashboardItem(
        id: 'lifecycle-step',
        type: DashboardItemType.stepH,
        title: 'Lifecycle Step',
        dataKey: 'V4',
        value: 0,
      );
      final service = SequenceDashboardService([
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V4': 18},
        ),
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now().add(const Duration(seconds: 1)),
          virtualPins: const <String, dynamic>{'V4': 64},
        ),
      ]);
      final controller = DashboardRuntimeController(
        dashboardService: service,
        layoutStorage: FakeDashboardLayoutStorage([item]),
      );

      await controller.initialize();
      expect(controller.items.single.value, 18);

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      expect(controller.items.single.value, 64);
      expect(service.fetchCount, greaterThanOrEqualTo(2));

      controller.dispose();
    },
  );
}
