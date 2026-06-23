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
import 'package:pb_iot/features/dashboard_builder/widgets/settings/domain/widget_settings_binding_catalog.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/settings/domain/widget_settings_binding_validator.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/settings/domain/widget_settings_capabilities.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/settings/domain/widget_settings_draft.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/settings/domain/widget_settings_preview_mapper.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/settings/domain/widget_settings_result_mapper.dart';
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

  group('widget settings domain', () {
    test('draft initializes binding and appearance from an item', () {
      final item =
          devicesDashboardItem(
            id: 'draft-value',
            title: 'Temperature',
            dataKey: 'status.temperature',
          ).copyWith(
            dataKeyLabel: 'Device Status / temperature',
            unit: '°C',
            value: 24,
            accentColor: const Color(0xFF159A66),
          );

      final draft = WidgetSettingsDraft.fromItem(
        item: item,
        capabilities: WidgetSettingsCapabilities.forType(item.type),
        defaultSecondaryAccentColor: const Color(0xFFE5A39D),
        defaultButtonBorderWidth: 1.2,
        defaultValueLabelBorderWidth: 1.2,
        defaultGaugeBorderWidth: 1.0,
        defaultSliderBorderWidth: 1.0,
        defaultToggleBorderWidth: 1.0,
        defaultGlowBlur: 18,
      );

      expect(draft.title, 'Temperature');
      expect(draft.bindingKey, 'status.temperature');
      expect(draft.bindingLabel, 'Device Status / temperature');
      expect(draft.dataType, 'number');
      expect(draft.unit, '°C');
      expect(draft.value, 24);
    });

    test('capabilities expose supported design and save targets', () {
      final button = WidgetSettingsCapabilities.forType(
        DashboardItemType.button,
      );
      final step = WidgetSettingsCapabilities.forType(DashboardItemType.stepH);
      final led = WidgetSettingsCapabilities.forType(DashboardItemType.led);

      expect(button.showSecondaryColor, isTrue);
      expect(
        button.borderColorField,
        WidgetSettingsBorderColorField.buttonBorderColor,
      );
      expect(button.borderWidthField, WidgetSettingsBorderWidthField.button);
      expect(
        button.defaultBindingModeFor(DashboardItemType.button),
        'read_write',
      );
      expect(step.showPrimaryColor, isFalse);
      expect(step.borderWidthField, WidgetSettingsBorderWidthField.slider);
      expect(led.showSecondaryColor, isTrue);
      expect(led.borderWidthField, WidgetSettingsBorderWidthField.toggle);
      expect(led.defaultBindingModeFor(DashboardItemType.led), 'read');
    });

    test('binding catalog canonicalizes runtime-supported keys', () {
      expect(WidgetSettingsBindingCatalog.entryFor('V3')?.name, 'V3');
      expect(
        WidgetSettingsBindingCatalog.sourceLabelForKey('status.temperature'),
        'Device Status / temperature',
      );
      expect(
        WidgetSettingsBindingCatalog.sourceLabelForKey('online'),
        'Device State / online',
      );
      expect(
        WidgetSettingsBindingCatalog.sourceLabelForKey('control.soilThreshold'),
        'Control / soilThreshold',
      );
      expect(WidgetSettingsBindingValidator.isValidVirtualPin('V255'), isTrue);
      expect(WidgetSettingsBindingValidator.isValidVirtualPin('V256'), isFalse);
      expect(
        WidgetSettingsBindingValidator.isSupportedRuntimePath(
          'status.temperature',
        ),
        isTrue,
      );
      expect(
        WidgetSettingsBindingValidator.isSupportedRuntimePath('foo.bar'),
        isFalse,
      );
    });

    test('preview and result mappers consume the same draft values', () {
      final item = stepDashboardItem(
        id: 'mapper-slider',
        type: DashboardItemType.slider,
        title: 'Slider',
        dataKey: 'V2',
        value: 12,
      );
      final capabilities = WidgetSettingsCapabilities.forType(item.type);
      final draft = WidgetSettingsDraft.fromItem(
        item: item,
        capabilities: capabilities,
        defaultSecondaryAccentColor: const Color(0xFFE5A39D),
        defaultButtonBorderWidth: 1.2,
        defaultValueLabelBorderWidth: 1.2,
        defaultGaugeBorderWidth: 1.0,
        defaultSliderBorderWidth: 1.0,
        defaultToggleBorderWidth: 1.0,
        defaultGlowBlur: 18,
      );
      draft
        ..value = 42
        ..minValue = 0
        ..maxValue = 100
        ..stepValue = 5
        ..bindingKey = 'control.soilThreshold'
        ..bindingLabel = 'Control / soilThreshold'
        ..unit = '%';

      final preview = WidgetSettingsPreviewMapper.buildPreviewItem(
        source: item,
        draft: draft,
        capabilities: capabilities,
        previewRect: const GridRect(x: 0, y: 0, w: 12, h: 4),
        previewValue: 42,
        minValue: 0,
        maxValue: 100,
        stepValue: 5,
      );
      final result = WidgetSettingsResultMapper.buildResult(
        source: item,
        draft: draft,
        capabilities: capabilities,
        minValue: 0,
        maxValue: 100,
        stepValue: 5,
        value: 42,
        defaultSurfaceColor: draft.surfaceColor,
        defaultInnerColor: draft.innerColor,
        defaultButtonBorderColor: draft.borderColor,
        defaultButtonBorderWidth: 1.2,
        defaultValueLabelBorderWidth: 1.2,
        defaultGaugeBorderWidth: 1.0,
        defaultSliderBorderWidth: 1.0,
        defaultToggleBorderWidth: 1.0,
        defaultGlowStrength: 0.08,
        defaultGlowBlur: 18,
      ).item!;

      expect(preview.dataKey, 'control.soilThreshold');
      expect(result.dataKey, 'control.soilThreshold');
      expect(preview.value, 42);
      expect(result.value, 42);
      expect(preview.stepValue, 5);
      expect(result.stepValue, 5);
      expect(result.sliderBorderWidth, isNull);
      expect(result.glowStrength, isNull);
    });
  });

  testWidgets(
    'value display widgets have expanded vertical constraints and persist',
    (WidgetTester tester) async {
      final valueLabel = DashboardWidgetFactory.createItem(
        type: DashboardItemType.valueLabel,
        existingItems: const <DashboardItem>[],
        seed: 11,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      );

      expect(valueLabel.title, 'แสดงค่า 1');
      expect(valueLabel.bindingMode, 'read');
      expect(valueLabel.dataType, 'number');
      expect(valueLabel.rect.x, 0);
      expect(valueLabel.rect.y, 0);
      expect(valueLabel.rect.w, 8);
      expect(valueLabel.rect.h, 3);
      expect(valueLabel.minW, 8);
      expect(valueLabel.maxW, 24);
      expect(valueLabel.minH, 3);
      expect(valueLabel.maxH, 14);

      final storage = DashboardBuilderLayoutStorageService();
      await storage.saveItems([valueLabel]);
      final loaded = await storage.loadItems();

      expect(loaded, isNotNull);
      expect(loaded!.single.type, DashboardItemType.valueLabel);
      expect(loaded.single.rect.w, 8);
      expect(loaded.single.rect.h, 3);
    },
  );

  testWidgets(
    'slider widgets have compact factory defaults and persist through storage',
    (WidgetTester tester) async {
      final slider = DashboardWidgetFactory.createItem(
        type: DashboardItemType.slider,
        existingItems: const <DashboardItem>[],
        seed: 10,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      );

      expect(slider.title, 'สไลด์ 1');
      expect(slider.bindingMode, 'read_write');
      expect(slider.dataType, 'number');
      expect(slider.stepValue, 1);
      expect(slider.rect.x, 0);
      expect(slider.rect.y, 0);
      expect(slider.rect.w, 12);
      expect(slider.rect.h, 4);
      expect(slider.minW, 10);
      expect(slider.maxW, 28);
      expect(slider.minH, 4);
      expect(slider.maxH, 8);

      final storage = DashboardBuilderLayoutStorageService();
      await storage.saveItems([slider]);
      final loaded = await storage.loadItems();

      expect(loaded, isNotNull);
      expect(loaded!.single.type, DashboardItemType.slider);
      expect(loaded.single.rect.w, 12);
      expect(loaded.single.rect.h, 4);
    },
  );

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
      expect(stepH.rect.x, 0);
      expect(stepH.rect.y, 0);
      expect(stepH.rect.w, 12);
      expect(stepH.rect.h, 4);
      expect(stepH.minW, 8);
      expect(stepH.maxW, 18);
      expect(stepH.minH, 3);
      expect(stepH.maxH, 5);
      expect(stepV.title, 'ปรับค่า V 1');
      expect(stepV.bindingMode, 'read_write');
      expect(stepV.rect.x, 0);
      expect(stepV.rect.y, 0);
      expect(stepV.rect.w, 4);
      expect(stepV.rect.h, 12);
      expect(stepV.minW, 3);
      expect(stepV.maxW, 5);
      expect(stepV.minH, 8);
      expect(stepV.maxH, 18);

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

  testWidgets(
    'trend and led widgets have factory defaults and persist through storage',
    (WidgetTester tester) async {
      final trend = DashboardWidgetFactory.createItem(
        type: DashboardItemType.trend,
        existingItems: const <DashboardItem>[],
        seed: 3,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      );
      final led = DashboardWidgetFactory.createItem(
        type: DashboardItemType.led,
        existingItems: <DashboardItem>[trend],
        seed: 4,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      );

      expect(trend.title, 'กราฟแนวโน้ม 1');
      expect(trend.bindingMode, 'read');
      expect(trend.dataType, 'number');
      expect(trend.series, isEmpty);
      expect(led.title, 'ไฟสถานะ 1');
      expect(led.bindingMode, 'read');
      expect(led.dataType, 'bool');
      expect(led.enabled, isFalse);
      expect(led.rect.x, 0);
      expect(led.rect.y, 0);
      expect(led.rect.w, 4);
      expect(led.rect.h, 4);
      expect(led.minH, 4);
      expect(led.maxW, 8);

      final storage = DashboardBuilderLayoutStorageService();
      await storage.saveItems([
        trend.copyWith(series: const <double>[1, 2, 3]),
        led,
      ]);
      final loaded = await storage.loadItems();

      expect(loaded, isNotNull);
      expect(loaded!.map((item) => item.type), [
        DashboardItemType.trend,
        DashboardItemType.led,
      ]);
      expect(loaded.first.bindingMode, 'read');
      expect(loaded.first.series, isEmpty);
      expect(loaded.last.dataType, 'bool');
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
    expect(find.text('กราฟ'), findsOneWidget);
    expect(find.text('ไฟสถานะ'), findsOneWidget);
  });

  testWidgets('add widget sheet stays compact on phone widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_sheet_surface')),
    );
    final guideRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_guide_card')),
    );
    final gridRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_option_grid')),
    );

    expect(sheetRect.height, lessThan(700));
    expect(guideRect.height, lessThan(160));
    expect(gridRect.top, greaterThan(guideRect.bottom));
    expect(find.text('ปุ่ม'), findsOneWidget);
    expect(find.text('แสดงค่า'), findsOneWidget);
  });

  testWidgets('add widget sheet centers final iPad option row', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    expect(
      find.byKey(const ValueKey<String>('add_widget_sheet_surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('add_widget_option_grid')),
      findsOneWidget,
    );
    expect(find.text('ปุ่ม'), findsOneWidget);
    expect(find.text('สวิตช์'), findsOneWidget);
    expect(find.text('สไลด์'), findsOneWidget);
    expect(find.text('ปรับค่า H'), findsOneWidget);
    expect(find.text('ปรับค่า V'), findsOneWidget);
    expect(find.text('เกจ'), findsOneWidget);
    expect(find.text('แสดงค่า'), findsOneWidget);
    expect(find.text('กราฟ'), findsOneWidget);
    expect(find.text('ไฟสถานะ'), findsOneWidget);

    final gridRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_option_grid')),
    );
    final gaugeRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_option_gauge')),
    );
    final valueLabelRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_option_valueLabel')),
    );
    final trendRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_option_trend')),
    );
    final ledRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_option_led')),
    );
    final finalRowCenter = (gaugeRect.left + ledRect.right) / 2;
    expect(finalRowCenter, closeTo(gridRect.center.dx, 1));
    expect(valueLabelRect.left, greaterThan(gaugeRect.right));
    expect(trendRect.left, greaterThan(valueLabelRect.right));
    expect(ledRect.left, greaterThan(trendRect.right));
  });

  testWidgets('add widget sheet returns selected widget type', (
    WidgetTester tester,
  ) async {
    DashboardItemType? selectedType;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  selectedType = await showModalBottomSheet<DashboardItemType>(
                    context: context,
                    builder: (context) => AddWidgetSheet(
                      scrollController: ScrollController(),
                      themePreset: dashboardThemePresets.first,
                    ),
                  );
                },
                child: const Text('open add widget'),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open add widget'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('add_widget_option_toggle')),
    );
    await tester.pumpAndSettle();

    expect(selectedType, DashboardItemType.toggle);
  });

  testWidgets('adjust value settings expose range step and preserve styling', (
    WidgetTester tester,
  ) async {
    final item =
        stepDashboardItem(
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
      WidgetSettingsSheetTestHost(item: item, onResult: capturedResults.add),
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

  testWidgets('stepper settings hide the main control color picker', (
    WidgetTester tester,
  ) async {
    final item = stepDashboardItem(
      id: 'step-color',
      type: DashboardItemType.stepV,
      title: 'ปรับค่า V 1',
      dataKey: 'V4',
    );

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกแบบ'));
    await tester.pumpAndSettle();

    expect(find.text('สไลเดอร์'), findsNothing);
    expect(find.text('สีสไลเดอร์'), findsNothing);
    expect(find.text('MAIN'), findsNothing);
    expect(find.text('พื้นหลัง'), findsOneWidget);
    expect(find.text('สีขอบ'), findsOneWidget);
    expect(find.text('สีชื่อวิดเจ็ต'), findsNothing);
    expect(find.text('ขนาดชื่อ'), findsNothing);
    expect(find.text('ตำแหน่งชื่อ'), findsNothing);
  });

  testWidgets('button design hides advanced title and glow detail controls', (
    WidgetTester tester,
  ) async {
    final item = DashboardItem(
      id: 'button-design-simple',
      type: DashboardItemType.button,
      title: 'ปุ่ม 1',
      rect: const GridRect(x: 0, y: 0, w: 8, h: 8),
      minW: 4,
      maxW: 24,
      minH: 4,
      maxH: 24,
      accentColor: const Color(0xFF22C55E),
      secondaryAccentColor: const Color(0xFFEF4444),
      buttonInnerColor: const Color(0xFFEAF7F0),
      buttonBorderColor: const Color(0xFF16A34A),
      buttonBorderWidth: 2,
      titleColor: const Color(0xFF123456),
      titleFontSize: 11,
      titlePosition: DashboardItemTitlePosition.bottomOutside,
      dataKey: 'V0',
      bindingMode: 'read_write',
      dataType: 'bool',
    );
    final capturedResults = <WidgetSettingsResult>[];

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: capturedResults.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกแบบ'));
    await tester.pumpAndSettle();

    expect(find.text('สีหลัก'), findsOneWidget);
    expect(find.text('สีรอง/ปิด'), findsOneWidget);
    expect(find.text('พื้นหลัง'), findsOneWidget);
    expect(find.text('สีขอบ'), findsOneWidget);
    expect(find.text('สีชื่อวิดเจ็ต'), findsNothing);
    expect(find.text('ขนาดชื่อ'), findsNothing);
    expect(find.text('ตำแหน่งชื่อ'), findsNothing);
    expect(find.text('สีแสงเรือง'), findsNothing);
    expect(find.text('ความนุ่ม'), findsNothing);

    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = capturedResults.single.item!;
    expect(saved.titleColor, const Color(0xFF123456));
    expect(saved.titleFontSize, 11);
    expect(saved.titlePosition, DashboardItemTitlePosition.bottomOutside);
    expect(saved.buttonInnerColor, const Color(0xFFEAF7F0));
    expect(saved.buttonBorderColor, const Color(0xFF16A34A));
    expect(saved.buttonBorderWidth, 2);
  });

  testWidgets('toggle design uses simplified controls and real save targets', (
    WidgetTester tester,
  ) async {
    final item = DashboardItem(
      id: 'toggle-design',
      type: DashboardItemType.toggle,
      title: 'สวิตช์ 1',
      rect: const GridRect(x: 0, y: 0, w: 11, h: 5),
      minW: 6,
      maxW: 18,
      minH: 4,
      maxH: 8,
      accentColor: const Color(0xFF22C55E),
      secondaryAccentColor: const Color(0xFFEF4444),
      buttonShellColor: const Color(0xFF315E48),
      buttonInnerColor: const Color(0xFFEAF7F0),
      buttonBorderColor: const Color(0xFF9C27B0),
      toggleBorderWidth: 2.4,
      dataKey: 'V1',
      bindingMode: 'read_write',
      dataType: 'bool',
    );
    final capturedResults = <WidgetSettingsResult>[];

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: capturedResults.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกแบบ'));
    await tester.pumpAndSettle();

    expect(find.text('สีหลัก'), findsOneWidget);
    expect(find.text('สีรอง/ปิด'), findsOneWidget);
    expect(find.text('พื้นหลัง'), findsOneWidget);
    expect(find.text('สีขอบ'), findsOneWidget);
    expect(find.text('สีแสงเรือง'), findsNothing);
    expect(find.text('ความนุ่ม'), findsNothing);

    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = capturedResults.single.item!;
    expect(saved.buttonShellColor, const Color(0xFF315E48));
    expect(saved.buttonInnerColor, const Color(0xFFEAF7F0));
    expect(saved.buttonBorderColor, isNull);
    expect(saved.toggleBorderWidth, 2.4);
  });

  testWidgets('trend design exposes and persists shell styling', (
    WidgetTester tester,
  ) async {
    final item = DashboardItem(
      id: 'trend-design',
      type: DashboardItemType.trend,
      title: 'กราฟแนวโน้ม 1',
      rect: const GridRect(x: 0, y: 0, w: 14, h: 7),
      minW: 8,
      maxW: 24,
      minH: 4,
      maxH: 12,
      accentColor: const Color(0xFF38BDF8),
      buttonShellColor: const Color(0xFF1E5672),
      buttonInnerColor: const Color(0xFFE7F7FF),
      sliderBorderWidth: 2.2,
      glowStrength: 0.2,
      dataKey: 'V2',
      bindingMode: 'read',
      dataType: 'number',
    );
    final capturedResults = <WidgetSettingsResult>[];

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: capturedResults.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกแบบ'));
    await tester.pumpAndSettle();

    expect(find.text('สีหลัก'), findsOneWidget);
    expect(find.text('พื้นหลัง'), findsOneWidget);
    expect(find.text('สีขอบ'), findsOneWidget);
    expect(find.text('แสงเรือง'), findsOneWidget);

    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = capturedResults.single.item!;
    expect(saved.accentColor, const Color(0xFF38BDF8));
    expect(saved.buttonShellColor, const Color(0xFF1E5672));
    expect(saved.buttonInnerColor, const Color(0xFFE7F7FF));
    expect(saved.sliderBorderWidth, 2.2);
    expect(saved.glowStrength, 0.2);
  });

  testWidgets('led design exposes and persists state and shell styling', (
    WidgetTester tester,
  ) async {
    final item = DashboardItem(
      id: 'led-design',
      type: DashboardItemType.led,
      title: 'ไฟสถานะ 1',
      rect: const GridRect(x: 0, y: 0, w: 8, h: 5),
      minW: 4,
      maxW: 8,
      minH: 4,
      maxH: 8,
      accentColor: const Color(0xFF22C55E),
      secondaryAccentColor: const Color(0xFF64748B),
      buttonShellColor: const Color(0xFF24533A),
      buttonInnerColor: const Color(0xFFEAF7F0),
      toggleBorderWidth: 2.6,
      glowStrength: 0.14,
      dataKey: 'V3',
      bindingMode: 'read',
      dataType: 'bool',
    );
    final capturedResults = <WidgetSettingsResult>[];

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: capturedResults.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกแบบ'));
    await tester.pumpAndSettle();

    expect(find.text('สีหลัก'), findsOneWidget);
    expect(find.text('สีรอง/ปิด'), findsOneWidget);
    expect(find.text('พื้นหลัง'), findsOneWidget);
    expect(find.text('สีขอบ'), findsOneWidget);
    expect(find.text('แสงเรือง'), findsOneWidget);

    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = capturedResults.single.item!;
    expect(saved.accentColor, const Color(0xFF22C55E));
    expect(saved.secondaryAccentColor, const Color(0xFF64748B));
    expect(saved.buttonShellColor, const Color(0xFF24533A));
    expect(saved.buttonInnerColor, const Color(0xFFEAF7F0));
    expect(saved.toggleBorderWidth, 2.6);
    expect(saved.glowStrength, 0.14);
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

    final item = stepDashboardItem(
      id: 'step-key',
      type: DashboardItemType.stepH,
      title: 'Stepper',
      dataKey: 'V4',
    );

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.tap(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom Virtual Pin'));
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(TextFormField, 'ชื่อ');
    await tester.tap(nameField);
    await tester.pumpAndSettle();
    await tester.enterText(nameField, 'knob_value');
    await tester.pumpAndSettle();

    expect(find.text('knob_value'), findsOneWidget);
    expect(tester.getRect(find.text('knob_value')).top, greaterThan(0));
  });

  testWidgets('binding picker shows grouped runtime sources', (
    WidgetTester tester,
  ) async {
    final item = stepDashboardItem(
      id: 'slider-binding',
      type: DashboardItemType.slider,
      title: 'Slider',
      dataKey: '',
    );

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.tap(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.pumpAndSettle();

    final pickerList = find.byType(ListView).last;
    expect(find.text('เลือกแหล่งข้อมูล'), findsOneWidget);
    expect(find.text('Custom Virtual Pin'), findsOneWidget);
    expect(find.text('Advanced Path Binding'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Virtual Pin'),
      pickerList,
      const Offset(0, -240),
    );
    expect(find.text('Virtual Pin'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Device Status'),
      pickerList,
      const Offset(0, -240),
    );
    expect(find.text('Device Status'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Device State'),
      pickerList,
      const Offset(0, -240),
    );
    expect(find.text('Device State'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Control'),
      pickerList,
      const Offset(0, -240),
    );
    expect(find.text('Control'), findsOneWidget);
    expect(find.text('เลือกข้อมูลที่เชื่อมต่อ (V Pin)'), findsNothing);
  });

  testWidgets('selecting status temperature saves a path binding', (
    WidgetTester tester,
  ) async {
    final results = <WidgetSettingsResult>[];
    final item = devicesDashboardItem(
      id: 'temp-binding',
      title: 'Temperature',
      dataKey: '',
    );

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: results.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.tap(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Device Status / temperature'),
      find.byType(ListView).last,
      const Offset(0, -240),
    );
    await tester.tap(find.text('Device Status / temperature'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = results.single.item!;
    expect(saved.dataKey, 'status.temperature');
    expect(saved.dataKeyLabel, 'Device Status / temperature');
  });

  testWidgets('selecting online saves a device state binding', (
    WidgetTester tester,
  ) async {
    final results = <WidgetSettingsResult>[];
    final item = devicesDashboardItem(
      id: 'online-binding',
      title: 'Online',
      dataKey: '',
    );

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: results.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.tap(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Device State / online'),
      find.byType(ListView).last,
      const Offset(0, -240),
    );
    await tester.tap(find.text('Device State / online'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = results.single.item!;
    expect(saved.dataKey, 'online');
    expect(saved.dataKeyLabel, 'Device State / online');
  });

  testWidgets('slider can select control soilThreshold binding', (
    WidgetTester tester,
  ) async {
    final results = <WidgetSettingsResult>[];
    final item = stepDashboardItem(
      id: 'control-binding',
      type: DashboardItemType.slider,
      title: 'Slider',
      dataKey: '',
    );

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: results.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.tap(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Control / soilThreshold'),
      find.byType(ListView).last,
      const Offset(0, -240),
    );
    await tester.tap(find.text('Control / soilThreshold'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();

    final saved = results.single.item!;
    expect(saved.dataKey, 'control.soilThreshold');
    expect(saved.dataKeyLabel, 'Control / soilThreshold');
  });

  testWidgets('advanced path binding rejects unsupported paths', (
    WidgetTester tester,
  ) async {
    final item = devicesDashboardItem(
      id: 'advanced-binding',
      title: 'Advanced',
      dataKey: '',
    );

    await tester.pumpWidget(
      WidgetSettingsSheetTestHost(item: item, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.tap(
      find.byKey(const ValueKey('widget_settings_binding_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced Path Binding'));
    await tester.pumpAndSettle();

    final keyField = find.widgetWithText(
      TextFormField,
      'เช่น status.temperature หรือ control.soilThreshold',
    );
    await tester.enterText(keyField, 'foo.bar');
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Use a supported binding such as status.temperature, online, virtualPins.V3, or control.soilThreshold.',
      ),
      findsOneWidget,
    );
  });
}
