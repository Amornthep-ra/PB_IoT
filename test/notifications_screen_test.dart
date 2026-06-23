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
import 'package:pb_iot/features/notifications/models/alert_rule_model.dart';
import 'package:pb_iot/features/notifications/screens/alert_rule_editor_screen.dart';
import 'package:pb_iot/features/notifications/screens/alert_event_detail_screen.dart';
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

  testWidgets(
    'notifications page uses shell bottom padding and accurate history copy',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'notification_permission_prompt_seen_v1': true,
      });
      seedProjectState();
      await NotificationService().saveHistoryEvents([
        AlertEventModel(
          id: 'history-1',
          ruleId: 'rule-1',
          ruleTitle: 'Rule',
          widgetId: 'widget-1',
          widgetTitle: 'Widget',
          message: 'Message',
          createdAt: DateTime(2026, 6, 10, 12),
          payload: const <String, dynamic>{'triggerValue': '12'},
        ),
      ]);
      final controller = DashboardRuntimeController(
        dashboardService: FakeDashboardService(),
        layoutStorage: FakeDashboardLayoutStorage(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationsScreen(
              runtimeController: controller,
              bottomContentPadding: 140,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ประวัติทั้งหมด').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'ระบบจะบันทึกทุกเหตุการณ์ไว้ที่นี่ และคุณสามารถล้างหรือลบรายการได้เมื่อต้องการ',
        ),
        findsOneWidget,
      );
      expect(find.text('ล้างทั้งหมด'), findsOneWidget);
      expect(find.textContaining('ไม่สามารถลบได้'), findsNothing);

      final paddedListViews = tester.widgetList<ListView>(
        find.byType(ListView),
      );
      expect(
        paddedListViews.any((listView) {
          final padding = listView.padding;
          return padding is EdgeInsets && padding.bottom == 140;
        }),
        isTrue,
      );

      controller.dispose();
    },
  );

  testWidgets(
    'notifications page places history switcher inside events section header',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'notification_permission_prompt_seen_v1': true,
      });

      await tester.pumpWidget(notificationsTestApp());
      await tester.pumpAndSettle();

      final eventsSectionRect = tester.getRect(
        find.byKey(const ValueKey<String>('notification_events_section')),
      );
      final switcherRect = tester.getRect(
        find.byKey(
          const ValueKey<String>('notification_events_header_switcher'),
        ),
      );

      expect(switcherRect.top, greaterThanOrEqualTo(eventsSectionRect.top));
      expect(switcherRect.bottom, lessThanOrEqualTo(eventsSectionRect.bottom));
      expect(switcherRect.width, lessThan(eventsSectionRect.width));
      expect(find.text('เหตุการณ์ล่าสุด'), findsWidgets);
      expect(find.text('ประวัติทั้งหมด'), findsWidgets);
    },
  );

  testWidgets('notifications page uses compact tablet shell width', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('notifications_content_shell')),
    );
    expect(shellRect.width, lessThanOrEqualTo(560));
    expect(shellRect.width, greaterThanOrEqualTo(548));
    expect(shellRect.center.dx, closeTo(600 / 2, 12));
    expect(shellRect.top, greaterThanOrEqualTo(36));
    expect(find.text('การแจ้งเตือน'), findsOneWidget);
  });

  testWidgets('notifications page uses standard tablet shell width', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('notifications_content_shell')),
    );
    expect(shellRect.width, closeTo(768 * 0.82, 12));
    expect(shellRect.center.dx, closeTo(768 / 2, 12));
    expect(find.text('กฎแจ้งเตือน'), findsWidgets);
  });

  testWidgets('notifications page uses iPad Air adaptive shell width', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('notifications_content_shell')),
    );
    expect(shellRect.width, closeTo(820 * 0.82, 12));
    expect(shellRect.center.dx, closeTo(820 / 2, 12));
  });

  testWidgets('notifications page caps shell width on large iPad', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('notifications_content_shell')),
    );
    expect(shellRect.width, lessThanOrEqualTo(760));
    expect(shellRect.width, greaterThanOrEqualTo(748));
    expect(shellRect.center.dx, closeTo(1024 / 2, 12));
  });

  testWidgets('notifications page keeps phone width padding behavior', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('notifications_content_shell')),
    );
    expect(shellRect.left, 20);
    expect(shellRect.right, 373);
    expect(shellRect.top, 18);
  });

  testWidgets('empty events card is centered and capped on iPad', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('notifications_content_shell')),
    );
    final emptyRect = tester.getRect(
      find.byKey(const ValueKey<String>('notification_empty_events_card')),
    );
    expect(emptyRect.width, lessThanOrEqualTo(520));
    expect(emptyRect.width, lessThan(shellRect.width - 36));
    expect(emptyRect.center.dx, closeTo(shellRect.center.dx, 1));
    expect(find.text('เหตุการณ์ล่าสุด'), findsWidgets);
    expect(find.text('ยังไม่มีเหตุการณ์ใหม่'), findsOneWidget);
    expect(
      find.text('เหตุการณ์ใหม่จะแสดงที่นี่จนกว่าคุณจะล้างรายการนี้'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('notification_empty_rules_content')),
      findsOneWidget,
    );
  });

  testWidgets('empty events card keeps full inner width on phone', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('notifications_content_shell')),
    );
    final emptyRect = tester.getRect(
      find.byKey(const ValueKey<String>('notification_empty_events_card')),
    );
    expect(emptyRect.width, closeTo(shellRect.width - 38, 1));
    expect(emptyRect.center.dx, closeTo(shellRect.center.dx, 1));
    expect(find.text('ยังไม่มีเหตุการณ์ใหม่'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('notification_rules_primary_create_action'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('notification_rules_overflow_action')),
      findsOneWidget,
    );
  });

  testWidgets('empty rules content stays centered on phone', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    final rulesSectionRect = tester.getRect(
      find.byKey(const ValueKey<String>('notification_rules_section')),
    );
    final emptyRulesRect = tester.getRect(
      find.byKey(const ValueKey<String>('notification_empty_rules_content')),
    );

    expect(emptyRulesRect.center.dx, closeTo(rulesSectionRect.center.dx, 2));
    expect(find.text('ยังไม่มีกฎแจ้งเตือน'), findsOneWidget);
  });

  testWidgets('rules count chip is hidden on phone header', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    seedProjectState();
    await NotificationService().saveRules([_testAlertRule()]);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    expect(find.text('กฎแจ้งเตือน'), findsOneWidget);
    expect(find.text('1 กฎ'), findsNothing);
    expect(find.text('แจ้งเตือนปุ่มกด (V0)'), findsOneWidget);
  });

  testWidgets('rules count chip remains visible on tablet header', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    seedProjectState();
    await NotificationService().saveRules([_testAlertRule()]);
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    expect(find.text('กฎแจ้งเตือน'), findsOneWidget);
    expect(find.text('1 กฎ'), findsOneWidget);
  });

  testWidgets('history clear feedback stays compact and undoable', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    seedProjectState();
    await NotificationService().saveHistoryEvents([
      AlertEventModel(
        id: 'history-1',
        ruleId: 'rule-1',
        ruleTitle: 'แจ้งเตือนปุ่มกด',
        widgetId: 'button-1',
        widgetTitle: 'ปุ่ม 1',
        message: 'ปุ่ม 1 is ON',
        createdAt: DateTime(2026, 6, 19, 17, 2),
        payload: const <String, dynamic>{'dataKey': 'V0'},
      ),
    ]);
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ประวัติทั้งหมด').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ล้างทั้งหมด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ล้างทั้งหมด').last);
    await tester.pumpAndSettle();

    expect(find.text('ล้างประวัติทั้งหมดแล้ว'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('notification_history_feedback_surface'),
      ),
      findsOneWidget,
    );

    final feedbackRect = tester.getRect(
      find.byKey(
        const ValueKey<String>('notification_history_feedback_surface'),
      ),
    );
    expect(feedbackRect.height, lessThan(72));
  });

  testWidgets('rules overflow menu opens delete action on phone', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'notification_permission_prompt_seen_v1': true,
    });
    seedProjectState();
    await NotificationService().saveRules([_testAlertRule()]);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(notificationsTestApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('notification_rules_overflow_action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ลบกฎแจ้งเตือน').last, findsOneWidget);
  });

  testWidgets('notification permission prompt is capped on iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NotificationPermissionPromptCard(
              onDismiss: () {},
              onAllow: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final promptRect = tester.getRect(
      find.byKey(
        const ValueKey<String>('notification_permission_prompt_surface'),
      ),
    );
    expect(promptRect.width, lessThanOrEqualTo(640));
    expect(promptRect.center.dx, closeTo(820 / 2, 12));
    expect(find.text('ไม่ใช่ตอนนี้'), findsOneWidget);
    expect(find.text('อนุญาต'), findsOneWidget);
  });

  testWidgets('alert detail content uses iPad Air adaptive shell width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_alertDetailTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('alert_event_detail_content_shell')),
    );
    expect(shellRect.width, closeTo(820 * 0.82, 12));
    expect(shellRect.center.dx, closeTo(820 / 2, 12));
  });

  testWidgets('alert detail content caps shell width on large iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_alertDetailTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('alert_event_detail_content_shell')),
    );
    expect(shellRect.width, lessThanOrEqualTo(760));
    expect(shellRect.width, greaterThanOrEqualTo(748));
    expect(shellRect.center.dx, closeTo(1024 / 2, 12));
  });

  testWidgets('alert detail content keeps phone side padding behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_alertDetailTestApp());
    await tester.pump();

    final shellRect = tester.getRect(
      find.byKey(const ValueKey<String>('alert_event_detail_content_shell')),
    );
    expect(shellRect.left, 20);
    expect(shellRect.right, 373);
  });

  testWidgets('alert detail content renders event copy and payload rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_alertDetailTestApp());
    await tester.pump();

    expect(find.text('Alert Details'), findsOneWidget);
    expect(find.text('test (V0)'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Payload'), findsOneWidget);
    expect(find.text('Rule ID'), findsOneWidget);
    expect(find.text('rule_1781258959361896'), findsOneWidget);
    expect(find.text('Widget ID'), findsOneWidget);
    expect(find.text('button-1'), findsOneWidget);
    expect(find.text('dataKey'), findsOneWidget);
    expect(find.text('V0'), findsWidgets);
    expect(find.text('value'), findsOneWidget);
    expect(find.text('true'), findsOneWidget);
  });
}

Widget _alertDetailTestApp() {
  return MaterialApp(home: AlertEventDetailScreen(event: _alertDetailEvent()));
}

AlertEventModel _alertDetailEvent() {
  return AlertEventModel(
    id: 'event-1',
    ruleId: 'rule_1781258959361896',
    ruleTitle: 'test',
    widgetId: 'button-1',
    widgetTitle: 'ปุ่ม 1',
    message: 'test',
    createdAt: DateTime(2026, 6, 13, 14, 48, 50),
    isRead: true,
    payload: const <String, dynamic>{
      'widgetType': 'button',
      'dataKey': 'V0',
      'value': true,
    },
  );
}

AlertRuleModel _testAlertRule() {
  return AlertRuleModel(
    id: 'rule-1',
    title: 'แจ้งเตือนปุ่มกด',
    widgetId: 'button-1',
    widgetTitle: 'ปุ่ม 1',
    widgetType: DashboardItemType.button,
    dataKey: 'V0',
    dataType: 'boolean',
    condition: AlertRuleCondition.isOn,
    message: 'ปุ่ม 1 is ON',
    createdAt: DateTime(2026, 6, 19, 17, 0),
    severity: AlertRuleSeverity.info,
  );
}
