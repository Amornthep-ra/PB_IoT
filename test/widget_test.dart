import 'dart:convert';

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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ProjectState.current = null;
    SessionState.current = null;
  });

  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const PbIotApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

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

  testWidgets('project select screen shows Thai-first copy and date label', (
    WidgetTester tester,
  ) async {
    _seedProjects();

    await tester.pumpWidget(_projectSelectTestApp());
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

  testWidgets('project select row opens dashboard when tapped', (
    WidgetTester tester,
  ) async {
    _seedProjects();

    await tester.pumpWidget(_projectSelectTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard opened'), findsOneWidget);
  });

  testWidgets('project select menu opens Thai edit dialog', (
    WidgetTester tester,
  ) async {
    _seedProjects();

    await tester.pumpWidget(_projectSelectTestApp());
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

  testWidgets('project edit dialog remains usable with keyboard inset', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    _seedProjects();

    await tester.pumpWidget(_projectSelectTestApp());
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
    _seedProjects();

    await tester.pumpWidget(_projectSelectTestApp());
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

  testWidgets('dashboard empty state shows Thai copy and widget CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_dashboardHomeTestApp());
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

    await tester.pumpWidget(_dashboardHomeTestApp());
    await tester.pumpAndSettle();

    final hasCompactCanvas = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .any((widget) => widget.height == 520);
    expect(hasCompactCanvas, isTrue);
    expect(find.text('เริ่มสร้างแดชบอร์ดของคุณ'), findsOneWidget);
  });

  testWidgets('dashboard empty state CTA opens dashboard builder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_dashboardHomeTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มวิดเจ็ต').last);
    await tester.pumpAndSettle();

    expect(find.text('builder opened'), findsOneWidget);
  });

  testWidgets('dashboard header CTA opens dashboard builder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_dashboardHomeTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มวิดเจ็ต').first);
    await tester.pumpAndSettle();

    expect(find.text('builder opened'), findsOneWidget);
  });

  testWidgets(
    'dashboard bottom navigation uses Thai labels and switches tabs',
    (WidgetTester tester) async {
      await tester.pumpWidget(_dashboardShellTestApp());
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

  testWidgets(
    'dashboard reserves scroll space for floating bottom navigation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(_dashboardShellTestApp());
      await tester.pump();

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final padding = scrollView.padding as EdgeInsets;
      expect(padding.bottom, greaterThanOrEqualTo(150));
    },
  );

  testWidgets('dashboard can scroll a bottom widget above the nav reserve', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bottomItem = _stepDashboardItem(
      id: 'bottom-step',
      type: DashboardItemType.stepH,
      title: 'Bottom Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 4, y: 66, w: 14, h: 5));

    await tester.pumpWidget(
      _dashboardHomeTestApp(items: [bottomItem], bottomContentPadding: 160),
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
    final bottomItem = _stepDashboardItem(
      id: 'scroll-step',
      type: DashboardItemType.stepH,
      title: 'Scroll Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 4, y: 66, w: 14, h: 5));
    _seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([bottomItem]);

    await tester.pumpWidget(_dashboardShellTestApp());
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

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(navOpacity().opacity, 1);
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

    await tester.pumpWidget(_dashboardShellTestApp());
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

  testWidgets('create alert editor uses Thai-first copy and sticky actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([
      _alertEditorDashboardItem(),
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

  testWidgets(
    'step widgets have factory defaults and persist through storage',
    (WidgetTester tester) async {
      final stepH = DashboardWidgetFactory.createItem(
        type: DashboardItemType.stepH,
        existingItems: const <DashboardItem>[],
        seed: 1,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      );
      final stepV = DashboardWidgetFactory.createItem(
        type: DashboardItemType.stepV,
        existingItems: <DashboardItem>[stepH],
        seed: 2,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      );

      expect(stepH.title, 'ปรับค่า H 1');
      expect(stepH.bindingMode, 'read_write');
      expect(stepH.dataType, 'number');
      expect(stepH.stepValue, 1);
      expect(stepV.title, 'ปรับค่า V 1');
      expect(stepV.bindingMode, 'read_write');

      final storage = DashboardBuilderLayoutStorageService();
      await storage.saveItems([stepH, stepV]);
      final loaded = await storage.loadItems();

      expect(loaded, isNotNull);
      expect(loaded!.map((item) => item.type), [
        DashboardItemType.stepH,
        DashboardItemType.stepV,
      ]);
      expect(loaded.first.stepValue, 1);
    },
  );

  testWidgets('add widget sheet shows Thai stepper labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddWidgetSheet(
            scrollController: ScrollController(),
            themePreset: dashboardThemePresets.first,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ปรับค่า H'), findsOneWidget);
    expect(find.text('ปรับค่า V'), findsOneWidget);
  });

  testWidgets('adjust value settings expose range step and preserve styling', (
    WidgetTester tester,
  ) async {
    final item =
        _stepDashboardItem(
          id: 'step-settings',
          type: DashboardItemType.stepH,
          title: 'ปรับค่า H 1',
          dataKey: 'V4',
          value: 10,
          stepValue: 1,
        ).copyWith(
          buttonShellColor: const Color(0xFF316A9E),
          buttonInnerColor: const Color(0xFFE9F4FF),
          sliderBorderWidth: 2.5,
        );
    final capturedResults = <WidgetSettingsResult>[];

    await tester.pumpWidget(
      _WidgetSettingsSheetTestHost(item: item, onResult: capturedResults.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();

    expect(find.text('ช่วงค่า'), findsOneWidget);
    expect(find.text('ขั้น'), findsOneWidget);
    expect(find.text('ค่าขั้น'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'ค่าขั้น'), '5');
    await tester.pump();
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = capturedResults.single.item!;
    expect(saved.stepValue, 5);
    expect(saved.buttonShellColor, const Color(0xFF316A9E));
    expect(saved.buttonInnerColor, const Color(0xFFE9F4FF));
    expect(saved.sliderBorderWidth, 2.5);
  });

  testWidgets('custom data key name remains visible while keyboard is open', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final item = _stepDashboardItem(
      id: 'step-key',
      type: DashboardItemType.stepH,
      title: 'Stepper',
      dataKey: 'V4',
    );

    await tester.pumpWidget(
      _WidgetSettingsSheetTestHost(item: item, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Stepper (V4)'));
    await tester.tap(find.text('Stepper (V4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขคีย์ข้อมูลที่กำหนดเอง'));
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(TextFormField, 'ชื่อ');
    await tester.tap(nameField);
    await tester.pumpAndSettle();
    await tester.enterText(nameField, 'knob_value');
    await tester.pumpAndSettle();

    expect(find.text('knob_value'), findsOneWidget);
    expect(tester.getRect(find.text('knob_value')).top, greaterThan(0));
  });

  testWidgets('step widget reads backend value and writes on tap', (
    WidgetTester tester,
  ) async {
    final service = _FakeDashboardService(
      DeviceSnapshotModel(
        online: true,
        updatedAt: DateTime.now(),
        virtualPins: const <String, dynamic>{'V4': 10},
      ),
    );
    final item = _stepDashboardItem(
      id: 'step-runtime',
      type: DashboardItemType.stepH,
      title: 'Step Runtime',
      dataKey: 'V4',
      value: 0,
      stepValue: 5,
    );

    await tester.pumpWidget(
      _dashboardHomeTestApp(service: service, items: [item]),
    );
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);

    await tester.tap(find.byTooltip('เพิ่มค่า'));
    await tester.pump();

    expect(service.writes.single.pin, 'V4');
    expect(service.writes.single.value, 15);
  });

  testWidgets(
    'dashboard runtime initial failure uses cached offline data and recovers by polling',
    (WidgetTester tester) async {
      _seedProjectState();
      final item = _stepDashboardItem(
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
      final service = _FailThenSuccessDashboardService(
        DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V4': 64},
        ),
      );
      final controller = DashboardRuntimeController(
        dashboardService: service,
        layoutStorage: _FakeDashboardLayoutStorage([item]),
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

  testWidgets('devices and alert editor accept horizontal adjuster source', (
    WidgetTester tester,
  ) async {
    final stepItem = _stepDashboardItem(
      id: 'step-source',
      type: DashboardItemType.stepH,
      title: 'แหล่งปรับค่า H',
      dataKey: 'V4',
      value: 12,
    );

    await tester.pumpWidget(
      _devicesTestApp(
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
    expect(find.text('V4'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await DashboardBuilderLayoutStorageService().saveItems([stepItem]);
    await tester.pumpWidget(const MaterialApp(home: AlertRuleEditorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('แหล่งปรับค่า H (ปรับค่า H)'), findsOneWidget);
    expect(find.text('V4'), findsWidgets);
  });

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

  testWidgets('devices page hides backend-only virtual pins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _devicesTestApp(
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

  testWidgets('devices page shows bound waiting and live pins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V3': 77},
        ),
        items: [
          _devicesDashboardItem(
            id: 'waiting',
            title: 'Waiting Widget',
            dataKey: 'V2',
          ),
          _devicesDashboardItem(
            id: 'live',
            title: 'Live Widget',
            dataKey: 'V3',
          ),
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
      _devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V0': null, 'V2': null},
        ),
        items: [
          _devicesDashboardItem(
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
      _devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V12': 1, 'V13': 40},
        ),
        items: [
          _devicesDashboardItem(
            id: 'accidental',
            title: 'Accidental Widget',
            dataKey: 'abcV12xyz',
          ),
          _devicesDashboardItem(
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
      _devicesTestApp(snapshot: const DeviceSnapshotModel()),
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
      _devicesTestApp(
        snapshot: DeviceSnapshotModel(
          online: true,
          updatedAt: DateTime.now(),
          virtualPins: const <String, dynamic>{'V1': 42, 'V3': 77},
        ),
        items: [
          _devicesDashboardItem(
            id: 'waiting',
            title: 'Waiting Widget',
            dataKey: 'V2',
          ),
          _devicesDashboardItem(
            id: 'live',
            title: 'Live Widget',
            dataKey: 'V3',
          ),
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

    await tester.tap(find.byIcon(Icons.close_rounded));
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
        '${previousDay.day} ${_thaiShortMonth(previousDay.month)} ${previousDay.year} '
        '${previousDay.hour.toString().padLeft(2, '0')}:'
        '${previousDay.minute.toString().padLeft(2, '0')}:'
        '${previousDay.second.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      _devicesTestApp(
        snapshot: DeviceSnapshotModel(online: true, updatedAt: today),
      ),
    );
    await tester.pump();
    expect(find.text('09:05:06'), findsOneWidget);

    await tester.pumpWidget(
      _devicesTestApp(
        snapshot: DeviceSnapshotModel(online: true, updatedAt: previousDay),
      ),
    );
    await tester.pump();
    expect(find.text(previousDayLabel), findsOneWidget);

    await tester.pumpWidget(
      _devicesTestApp(snapshot: const DeviceSnapshotModel(online: true)),
    );
    await tester.pump();
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('devices page reserves space for floating bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _devicesTestApp(
        snapshot: const DeviceSnapshotModel(),
        bottomContentPadding: 118,
      ),
    );
    await tester.pump();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding as EdgeInsets;
    expect(padding.bottom, greaterThanOrEqualTo(100));
  });

  testWidgets(
    'notifications page uses shell bottom padding and accurate history copy',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'notification_permission_prompt_seen_v1': true,
      });
      _seedProjectState();
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
        dashboardService: _FakeDashboardService(),
        layoutStorage: _FakeDashboardLayoutStorage(),
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

  testWidgets('dashboard builder empty state uses Thai guidance and labels', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    expect(find.text('โหมดแก้ไข'), findsOneWidget);
    expect(find.text('เริ่มจัดวางวิดเจ็ตในโหมดแก้ไข'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
    expect(
      find.text('แตะปุ่ม + เพื่อเพิ่มวิดเจ็ต แล้วลากจัดวางบนพื้นที่นี้'),
      findsOneWidget,
    );
    expect(find.byTooltip('ไม่มีการเปลี่ยนแปลงให้บันทึก'), findsOneWidget);
    expect(find.byTooltip('เพิ่มวิดเจ็ต'), findsOneWidget);
    expect(find.byTooltip('เปลี่ยนธีม'), findsOneWidget);
    expect(find.byTooltip('วิธีใช้งาน'), findsOneWidget);
    expect(find.bySemanticsLabel('เพิ่มวิดเจ็ต'), findsWidgets);
    expect(find.bySemanticsLabel('เปลี่ยนธีม'), findsWidgets);
    expect(find.bySemanticsLabel('วิธีใช้งาน'), findsWidgets);

    semantics.dispose();
  });

  testWidgets('dashboard builder back dialog uses Thai actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_dashboardBuilderStackTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('open builder'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('เพิ่มวิดเจ็ต'));
    await tester.pumpAndSettle();
    expect(find.text('สไลด์'), findsWidgets);
    expect(find.textContaining('สไลเดอร์'), findsNothing);
    await tester.tap(find.text('ปุ่ม'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('ปุ่ม'), findsWidgets);
    expect(find.text('V Pin: ไม่มี'), findsOneWidget);
    expect(find.textContaining('ขนาด:'), findsOneWidget);
    expect(find.textContaining('x:'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก'), findsOneWidget);
    expect(
      find.text(
        'คุณมีการเปลี่ยนแปลงวิดเจ็ตที่ยังไม่ได้บันทึก ต้องการบันทึกก่อนออกจากหน้านี้หรือไม่?',
      ),
      findsOneWidget,
    );
    expect(find.text('ยกเลิก'), findsOneWidget);
    expect(find.text('ออกโดยไม่บันทึก'), findsOneWidget);
    expect(find.text('บันทึก'), findsWidgets);
    expect(find.text('You have unsaved changes.'), findsNothing);
    expect(find.textContaining('widget'), findsNothing);
    expect(find.text('ไม่บันทึก'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Discard'), findsNothing);
    expect(find.text('Save'), findsNothing);
  });
}

Widget _dashboardHomeTestApp({
  DashboardService? service,
  List<DashboardItem> items = const <DashboardItem>[],
  double bottomContentPadding = 0,
  ValueChanged<bool>? onScrollActivityChanged,
}) {
  _seedProjectState();
  return _DashboardHomeTestHost(
    service: service,
    items: items,
    bottomContentPadding: bottomContentPadding,
    onScrollActivityChanged: onScrollActivityChanged,
  );
}

Widget _devicesTestApp({
  required DeviceSnapshotModel snapshot,
  List<DashboardItem> items = const <DashboardItem>[],
  double bottomContentPadding = 0,
}) {
  _seedProjectState();
  return _DevicesTestHost(
    key: ValueKey<Object>(Object.hash(snapshot.updatedAt, items.length)),
    snapshot: snapshot,
    items: items,
    bottomContentPadding: bottomContentPadding,
  );
}

Widget _dashboardShellTestApp() {
  _seedProjectState();
  return MaterialApp(
    home: const DashboardScreen(),
    routes: {
      '/dashboard-builder': (_) => const Scaffold(body: Text('builder opened')),
      '/account-session': (_) => const Scaffold(body: Text('settings opened')),
    },
  );
}

Widget _dashboardBuilderTestApp() {
  _seedProjectState();
  return const MaterialApp(home: DashboardBuilderScreen());
}

Widget _dashboardBuilderStackTestApp() {
  _seedProjectState();
  return MaterialApp(
    home: Builder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DashboardBuilderScreen(),
                  ),
                );
              },
              child: const Text('open builder'),
            ),
          ),
        );
      },
    ),
  );
}

Widget _projectSelectTestApp() {
  return MaterialApp(
    home: const ProjectSelectScreen(),
    routes: {
      '/dashboard': (_) => const Scaffold(body: Text('dashboard opened')),
    },
  );
}

void _seedProjects() {
  _seedProjectState();
  SharedPreferences.setMockInitialValues({
    'projects_v1': jsonEncode([
      {
        'id': 'project_test',
        'name': 'Test',
        'iconKey': 'sprout',
        'createdAt': '2026-06-01T08:42:45.000',
        'updatedAt': '2026-06-01T08:42:45.000',
      },
    ]),
    'selected_project_id_v1': 'project_test',
  });
}

void _seedProjectState() {
  ProjectState.current = ProjectModel(
    id: 'project_test',
    name: 'Test',
    iconKey: 'sprout',
    createdAt: DateTime(2026, 6, 1, 8, 42, 45),
    updatedAt: DateTime(2026, 6, 1, 8, 42, 45),
  );
}

class _FakeDashboardService extends DashboardService {
  _FakeDashboardService([this.snapshot = const DeviceSnapshotModel()]);

  final DeviceSnapshotModel snapshot;
  final List<_RecordedBindingWrite> writes = <_RecordedBindingWrite>[];

  @override
  Future<DeviceSnapshotModel> fetchRuntimeSnapshot() async {
    return snapshot;
  }

  @override
  DeviceSnapshotModel buildMockSnapshot() {
    return snapshot;
  }

  @override
  Future<void> writeBindingValue({
    required WidgetBindingModel binding,
    required Object? value,
  }) async {
    writes.add(_RecordedBindingWrite(pin: binding.pin, value: value));
  }
}

class _FailThenSuccessDashboardService extends DashboardService {
  _FailThenSuccessDashboardService(this.successSnapshot);

  final DeviceSnapshotModel successSnapshot;
  int fetchCount = 0;

  @override
  Future<DeviceSnapshotModel> fetchRuntimeSnapshot() async {
    fetchCount += 1;
    if (fetchCount == 1) {
      throw const DashboardServiceException('backend unavailable');
    }
    return successSnapshot;
  }

  @override
  DeviceSnapshotModel buildMockSnapshot() {
    return const DeviceSnapshotModel(
      online: true,
      virtualPins: <String, dynamic>{'V10': 1, 'V13': 40},
    );
  }
}

class _RecordedBindingWrite {
  const _RecordedBindingWrite({required this.pin, required this.value});

  final String? pin;
  final Object? value;
}

class _FakeDashboardLayoutStorage extends DashboardBuilderLayoutStorageService {
  _FakeDashboardLayoutStorage([this.items = const <DashboardItem>[]]);

  final List<DashboardItem> items;

  @override
  Future<DashboardThemePreset> loadDashboardThemePreset() async {
    return dashboardThemePresets.first;
  }

  @override
  Future<List<DashboardItem>?> loadItems() async {
    return items;
  }
}

class _DevicesTestHost extends StatefulWidget {
  const _DevicesTestHost({
    super.key,
    required this.snapshot,
    required this.items,
    this.bottomContentPadding = 0,
  });

  final DeviceSnapshotModel snapshot;
  final List<DashboardItem> items;
  final double bottomContentPadding;

  @override
  State<_DevicesTestHost> createState() => _DevicesTestHostState();
}

class _DevicesTestHostState extends State<_DevicesTestHost> {
  late final DashboardRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  DashboardRuntimeController _buildController() {
    return DashboardRuntimeController(
      dashboardService: _FakeDashboardService(widget.snapshot),
      layoutStorage: _FakeDashboardLayoutStorage(widget.items),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DevicesScreen(
          runtimeController: _controller,
          bottomContentPadding: widget.bottomContentPadding,
        ),
      ),
    );
  }
}

class _DashboardHomeTestHost extends StatefulWidget {
  const _DashboardHomeTestHost({
    this.service,
    this.items = const [],
    this.bottomContentPadding = 0,
    this.onScrollActivityChanged,
  });

  final DashboardService? service;
  final List<DashboardItem> items;
  final double bottomContentPadding;
  final ValueChanged<bool>? onScrollActivityChanged;

  @override
  State<_DashboardHomeTestHost> createState() => _DashboardHomeTestHostState();
}

class _DashboardHomeTestHostState extends State<_DashboardHomeTestHost> {
  late final DashboardRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardRuntimeController(
      dashboardService: widget.service ?? _FakeDashboardService(),
      layoutStorage: _FakeDashboardLayoutStorage(widget.items),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DashboardHomeView(
          runtimeController: _controller,
          dashboardService: widget.service,
          bottomContentPadding: widget.bottomContentPadding,
          onScrollActivityChanged: widget.onScrollActivityChanged,
        ),
      ),
      routes: {
        '/dashboard-builder': (_) =>
            const Scaffold(body: Text('builder opened')),
      },
    );
  }
}

class _WidgetSettingsSheetTestHost extends StatelessWidget {
  const _WidgetSettingsSheetTestHost({
    required this.item,
    required this.onResult,
  });

  final DashboardItem item;
  final ValueChanged<WidgetSettingsResult> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<WidgetSettingsResult>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => WidgetSettingsSheet(item: item),
                      );
                  if (result != null) {
                    onResult(result);
                  }
                },
                child: const Text('open settings'),
              );
            },
          ),
        ),
      ),
    );
  }
}

DashboardItem _devicesDashboardItem({
  required String id,
  required String title,
  required String dataKey,
}) {
  return DashboardItem(
    id: id,
    type: DashboardItemType.valueLabel,
    title: title,
    rect: const GridRect(x: 0, y: 0, w: 10, h: 6),
    minW: 8,
    maxW: 28,
    minH: 4,
    maxH: 14,
    accentColor: const Color(0xFF4E9070),
    dataKey: dataKey,
    bindingMode: 'read',
    dataType: 'number',
  );
}

DashboardItem _alertEditorDashboardItem() {
  return DashboardItem(
    id: 'alert_button_1',
    type: DashboardItemType.button,
    title: 'ปุ่ม 1',
    rect: const GridRect(x: 0, y: 0, w: 10, h: 6),
    minW: 8,
    maxW: 28,
    minH: 4,
    maxH: 14,
    accentColor: const Color(0xFF4E9070),
    dataKey: 'V0',
    dataKeyLabel: 'คำสั่งสวิตช์',
    bindingMode: 'read',
    dataType: 'boolean',
  );
}

DashboardItem _stepDashboardItem({
  required String id,
  required DashboardItemType type,
  required String title,
  required String dataKey,
  double value = 0,
  double stepValue = 1,
}) {
  return DashboardItem(
    id: id,
    type: type,
    title: title,
    rect: type == DashboardItemType.stepV
        ? const GridRect(x: 0, y: 0, w: 8, h: 10)
        : const GridRect(x: 0, y: 0, w: 14, h: 5),
    minW: type == DashboardItemType.stepV ? 6 : 10,
    maxW: type == DashboardItemType.stepV ? 12 : 24,
    minH: type == DashboardItemType.stepV ? 8 : 4,
    maxH: type == DashboardItemType.stepV ? 16 : 7,
    accentColor: const Color(0xFF6CB8F6),
    value: value,
    minValue: 0,
    maxValue: 100,
    stepValue: stepValue,
    dataSource: 'device_channel',
    dataKey: dataKey,
    dataKeyLabel: 'Stepper',
    bindingMode: 'read_write',
    dataType: 'number',
  );
}

String _thaiShortMonth(int month) {
  const months = <String>[
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  return months[month - 1];
}
