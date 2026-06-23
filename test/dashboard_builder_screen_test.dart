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
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_grid_painter.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/add_widget_sheet.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_home_view.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_item_renderer.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/smart_action_button.dart';
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

  Future<List<Rect>> captureSelectionAndResizePreviewRects(
    WidgetTester tester,
    DashboardItem item,
  ) async {
    seedProjectState();
    final layoutStorage = DashboardBuilderLayoutStorageService();
    await layoutStorage.clearBuilderDraft();
    await layoutStorage.clearBuilderHistory();
    await layoutStorage.saveItems([item]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final selectionRect = tester.getRect(
      find.byKey(
        ValueKey<String>('dashboard_builder_selection_chrome_${item.id}'),
      ),
    );
    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandles.first),
    );
    await tester.pump();

    final previewRect = tester.getRect(
      find.byKey(
        ValueKey<String>('dashboard_builder_preview_overlay_${item.id}'),
      ),
    );
    final placeholderRect = tester.getRect(
      find.byKey(
        ValueKey<String>(
          'dashboard_builder_resize_placeholder_body_${item.id}',
        ),
      ),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    await layoutStorage.clearBuilderDraft();
    await layoutStorage.clearBuilderHistory();
    return <Rect>[selectionRect, previewRect, placeholderRect];
  }

  DashboardItem factoryPreviewItem({
    required DashboardItemType type,
    required String id,
    required GridRect rect,
    required int seed,
  }) {
    return DashboardWidgetFactory.createItem(
      type: type,
      existingItems: const <DashboardItem>[],
      seed: seed,
      buttonMinW: 8,
      buttonMaxW: 28,
      buttonMinH: 6,
      buttonMaxH: 14,
    ).copyWith(id: id, rect: rect, dataKey: 'V1');
  }

  Set<String> rectSignatures(Iterable<Rect> rects) {
    return rects
        .map(
          (rect) => [
            rect.left.toStringAsFixed(2),
            rect.top.toStringAsFixed(2),
            rect.width.toStringAsFixed(2),
            rect.height.toStringAsFixed(2),
          ].join(':'),
        )
        .toSet();
  }

  testWidgets('dashboard builder empty state uses Thai guidance and labels', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(dashboardBuilderTestApp());
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
    expect(find.byTooltip('เปลี่ยนธีม'), findsNothing);
    expect(find.byTooltip('วิธีใช้งาน'), findsOneWidget);
    expect(find.bySemanticsLabel('เพิ่มวิดเจ็ต'), findsWidgets);
    expect(find.bySemanticsLabel('เปลี่ยนธีม'), findsNothing);

    semantics.dispose();
  });

  testWidgets('dashboard builder app bar is capped on large iPad portrait', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final appBarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_app_bar_surface')),
    );
    expect(appBarRect.width, lessThanOrEqualTo(760.0));
    expect(appBarRect.width, greaterThanOrEqualTo(728.0));
    expect(appBarRect.center.dx, closeTo(1024 / 2, 12));
    expect(find.text('โหมดแก้ไข'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
  });

  testWidgets('dashboard builder app bar keeps phone width behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final appBarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_app_bar_surface')),
    );
    expect(appBarRect.left, 14.0);
    expect(appBarRect.right, 379.0);
    expect(find.text('โหมดแก้ไข'), findsOneWidget);
  });

  testWidgets('dashboard builder shows vertical resize handles on phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final valueItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: const <DashboardItem>[],
          seed: 1,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'phone-value',
          rect: const GridRect(x: 0, y: 10, w: 14, h: 3),
          dataKey: 'V1',
          value: 615000,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([valueItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );

    expect(resizeHandles, findsNWidgets(4));
  });

  testWidgets(
    'dashboard builder button resize preview matches fake button shell',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final buttonItem =
          DashboardWidgetFactory.createItem(
            type: DashboardItemType.button,
            existingItems: const <DashboardItem>[],
            seed: 1,
            buttonMinW: 8,
            buttonMaxW: 28,
            buttonMinH: 6,
            buttonMaxH: 14,
          ).copyWith(
            id: 'preview-button',
            rect: const GridRect(x: 4, y: 10, w: 12, h: 6),
          );
      seedProjectState();
      await DashboardBuilderLayoutStorageService().saveItems([buttonItem]);

      await tester.pumpWidget(dashboardBuilderTestApp());
      await tester.pumpAndSettle();
      final itemFinder = find.byType(DashboardItemRenderer).first;
      final runtimeShellRectBeforeResize = tester.getRect(
        find.descendant(
          of: itemFinder,
          matching: find.byType(SmartActionButton),
        ),
      );
      final runtimeIconBeforeResize = tester.widget<Icon>(
        find.descendant(
          of: itemFinder,
          matching: find.byIcon(Icons.power_settings_new_rounded),
        ),
      );
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      final resizeHandles = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ResizeHandle',
      );
      final gesture = await tester.startGesture(
        tester.getCenter(resizeHandles.first),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('dashboard_builder_button_resize_placeholder'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>(
              'dashboard_builder_button_resize_placeholder',
            ),
          ),
          matching: find.byType(DashboardItemRenderer),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>(
              'dashboard_builder_button_resize_placeholder',
            ),
          ),
          matching: find.byType(SmartActionButton),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_button_resize_placeholder_center',
          ),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);

      final placeholderRect = tester.getRect(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_button_resize_placeholder_shell',
          ),
        ),
      );
      expect(
        placeholderRect.left,
        closeTo(runtimeShellRectBeforeResize.left, 0.01),
      );
      expect(
        placeholderRect.top,
        closeTo(runtimeShellRectBeforeResize.top, 0.01),
      );
      expect(
        placeholderRect.width,
        closeTo(runtimeShellRectBeforeResize.width, 0.01),
      );
      expect(
        placeholderRect.height,
        closeTo(runtimeShellRectBeforeResize.height, 0.01),
      );
      final previewIcon = tester.widget<Icon>(
        find.byIcon(Icons.power_settings_new_rounded),
      );
      expect(previewIcon.size, closeTo(runtimeIconBeforeResize.size!, 0.01));

      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();

      final previewOverlayRect = tester.getRect(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_preview_overlay_preview-button',
          ),
        ),
      );
      expect(previewOverlayRect.left, closeTo(placeholderRect.left, 0.01));
      expect(previewOverlayRect.top, closeTo(placeholderRect.top, 0.01));
      expect(previewOverlayRect.width, closeTo(placeholderRect.width, 0.01));
      expect(previewOverlayRect.height, closeTo(placeholderRect.height, 0.01));

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'dashboard builder button resize preview matches inactive custom off accent',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const offAccent = Color(0xFF7D5CDB);
      final buttonItem =
          DashboardWidgetFactory.createItem(
            type: DashboardItemType.button,
            existingItems: const <DashboardItem>[],
            seed: 4,
            buttonMinW: 8,
            buttonMaxW: 28,
            buttonMinH: 6,
            buttonMaxH: 14,
          ).copyWith(
            id: 'inactive-preview-button',
            enabled: false,
            secondaryAccentColor: offAccent,
            rect: const GridRect(x: 4, y: 10, w: 12, h: 6),
          );
      seedProjectState();
      await DashboardBuilderLayoutStorageService().saveItems([buttonItem]);

      await tester.pumpWidget(dashboardBuilderTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DashboardItemRenderer).first);
      await tester.pumpAndSettle();

      final resizeHandles = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ResizeHandle',
      );
      final gesture = await tester.startGesture(
        tester.getCenter(resizeHandles.first),
      );
      await tester.pump();

      final placeholderControl = tester.widget<DecoratedBox>(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_button_resize_placeholder_control',
          ),
        ),
      );
      final controlDecoration = placeholderControl.decoration as BoxDecoration;
      final expectedInactiveVisual = Color.lerp(
        offAccent,
        const Color(0xFFD94B4B),
        0.42,
      )!;

      expect(
        controlDecoration.border!.top.color,
        expectedInactiveVisual.withValues(alpha: 0.38),
      );
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.power_settings_new_rounded),
      );
      expect(icon.color, expectedInactiveVisual);

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'dashboard builder button resize preview matches custom shell inner and border colors',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const shellColor = Color(0xFF1A2238);
      const innerColor = Color(0xFFF5D08A);
      const borderColor = Color(0xFF2EB67D);
      const borderWidth = 2.7;
      final buttonItem =
          DashboardWidgetFactory.createItem(
            type: DashboardItemType.button,
            existingItems: const <DashboardItem>[],
            seed: 5,
            buttonMinW: 8,
            buttonMaxW: 28,
            buttonMinH: 6,
            buttonMaxH: 14,
          ).copyWith(
            id: 'custom-preview-button',
            buttonShellColor: shellColor,
            buttonInnerColor: innerColor,
            buttonBorderColor: borderColor,
            buttonBorderWidth: borderWidth,
            rect: const GridRect(x: 4, y: 10, w: 12, h: 6),
          );
      seedProjectState();
      await DashboardBuilderLayoutStorageService().saveItems([buttonItem]);

      await tester.pumpWidget(dashboardBuilderTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DashboardItemRenderer).first);
      await tester.pumpAndSettle();

      final resizeHandles = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ResizeHandle',
      );
      final gesture = await tester.startGesture(
        tester.getCenter(resizeHandles.first),
      );
      await tester.pump();

      final shellDecoration =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey<String>(
                        'dashboard_builder_button_resize_placeholder_shell',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final controlDecoration =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey<String>(
                        'dashboard_builder_button_resize_placeholder_control',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration;

      expect(shellDecoration.gradient, isA<LinearGradient>());
      expect(
        (shellDecoration.gradient! as LinearGradient).colors.first,
        shellColor,
      );
      expect(shellDecoration.border!.top.color, borderColor);
      expect(shellDecoration.border!.top.width, borderWidth);
      expect(
        (controlDecoration.gradient! as LinearGradient).colors.first,
        innerColor,
      );

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('dashboard builder selection chrome matches wide button shell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const itemId = 'wide-button';
    final buttonItem = DashboardWidgetFactory.createItem(
      type: DashboardItemType.button,
      existingItems: const <DashboardItem>[],
      seed: 2,
      buttonMinW: 8,
      buttonMaxW: 28,
      buttonMinH: 6,
      buttonMaxH: 14,
    ).copyWith(id: itemId, rect: const GridRect(x: 2, y: 10, w: 16, h: 6));
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([buttonItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final itemFinder = find.byType(DashboardItemRenderer).first;
    await tester.tap(itemFinder);
    await tester.pumpAndSettle();

    final shellRect = tester.getRect(
      find.descendant(of: itemFinder, matching: find.byType(SmartActionButton)),
    );
    final selectionChromeFinder = find.byKey(
      const ValueKey<String>('dashboard_builder_selection_chrome_wide-button'),
    );
    final selectionRect = tester.getRect(selectionChromeFinder);
    final selectionDecoration =
        tester.widget<DecoratedBox>(selectionChromeFinder).decoration
            as BoxDecoration;

    expect(selectionRect.left, closeTo(shellRect.left, 0.01));
    expect(selectionRect.top, closeTo(shellRect.top, 0.01));
    expect(selectionRect.width, closeTo(shellRect.width, 0.01));
    expect(selectionRect.height, closeTo(shellRect.height, 0.01));
    expect(
      selectionDecoration.border!.top.color,
      const Color(0xFF2FAE7A).withValues(alpha: 0.68),
    );
    expect(selectionDecoration.border!.top.width, closeTo(1.15, 0.01));
  });

  testWidgets(
    'dashboard builder selection chrome matches near-square button shell',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const itemId = 'square-button';
      final buttonItem = DashboardWidgetFactory.createItem(
        type: DashboardItemType.button,
        existingItems: const <DashboardItem>[],
        seed: 3,
        buttonMinW: 8,
        buttonMaxW: 28,
        buttonMinH: 6,
        buttonMaxH: 14,
      ).copyWith(id: itemId, rect: const GridRect(x: 5, y: 10, w: 8, h: 8));
      seedProjectState();
      await DashboardBuilderLayoutStorageService().saveItems([buttonItem]);

      await tester.pumpWidget(dashboardBuilderTestApp());
      await tester.pumpAndSettle();

      final itemFinder = find.byType(DashboardItemRenderer).first;
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      final shellRect = tester.getRect(
        find.descendant(
          of: itemFinder,
          matching: find.byType(SmartActionButton),
        ),
      );
      final selectionRect = tester.getRect(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_selection_chrome_square-button',
          ),
        ),
      );

      expect(selectionRect.left, closeTo(shellRect.left, 0.01));
      expect(selectionRect.top, closeTo(shellRect.top, 0.01));
      expect(selectionRect.width, closeTo(shellRect.width, 0.01));
      expect(selectionRect.height, closeTo(shellRect.height, 0.01));
    },
  );

  testWidgets(
    'dashboard builder value label preview matches selection chrome',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final valueItem =
          DashboardWidgetFactory.createItem(
            type: DashboardItemType.valueLabel,
            existingItems: const <DashboardItem>[],
            seed: 6,
            buttonMinW: 8,
            buttonMaxW: 28,
            buttonMinH: 6,
            buttonMaxH: 14,
          ).copyWith(
            id: 'value-preview-parity',
            rect: const GridRect(x: 4, y: 10, w: 14, h: 8),
            dataKey: 'V1',
            value: 4095,
          );
      seedProjectState();
      await DashboardBuilderLayoutStorageService().saveItems([valueItem]);

      await tester.pumpWidget(dashboardBuilderTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DashboardItemRenderer).first);
      await tester.pumpAndSettle();

      final selectionRect = tester.getRect(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_selection_chrome_value-preview-parity',
          ),
        ),
      );
      final resizeHandles = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ResizeHandle',
      );
      final gesture = await tester.startGesture(
        tester.getCenter(resizeHandles.first),
      );
      await tester.pump();

      final previewOverlayFinder = find.byKey(
        const ValueKey<String>(
          'dashboard_builder_preview_overlay_value-preview-parity',
        ),
      );
      final previewRect = tester.getRect(previewOverlayFinder);
      final previewDecoration =
          tester.widget<AnimatedContainer>(previewOverlayFinder).decoration
              as BoxDecoration;
      expect(previewRect.left, closeTo(selectionRect.left, 0.01));
      expect(previewRect.top, closeTo(selectionRect.top, 0.01));
      expect(previewRect.width, closeTo(selectionRect.width, 0.01));
      expect(previewRect.height, closeTo(selectionRect.height, 0.01));
      expect(
        previewDecoration.border!.top.color,
        const Color(0xFF159A66).withValues(alpha: 0.78),
      );
      expect(previewDecoration.border!.top.width, closeTo(1.25, 0.01));

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('dashboard builder invalid preview overlay stays red', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movingItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: const <DashboardItem>[],
          seed: 18,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'invalid-preview-moving',
          rect: const GridRect(x: 2, y: 10, w: 8, h: 6),
          dataKey: 'V1',
          value: 1024,
        );
    final blockingItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: <DashboardItem>[movingItem],
          seed: 19,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'invalid-preview-blocking',
          rect: const GridRect(x: 12, y: 10, w: 8, h: 6),
          dataKey: 'V2',
          value: 2048,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([
      movingItem,
      blockingItem,
    ]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final rightHandleCenter = tester.getCenter(resizeHandles.at(1));
    final gesture = await tester.startGesture(rightHandleCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(112, 0));
    await tester.pump();

    final previewOverlayFinder = find.byKey(
      const ValueKey<String>(
        'dashboard_builder_preview_overlay_invalid-preview-moving',
      ),
    );
    final previewDecoration =
        tester.widget<AnimatedContainer>(previewOverlayFinder).decoration
            as BoxDecoration;

    expect(
      previewDecoration.border!.top.color,
      const Color(0xFFD16A6A).withValues(alpha: 0.82),
    );
    expect(previewDecoration.border!.top.width, closeTo(1.45, 0.01));
    expect(find.text('พื้นที่ทับกัน'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard builder slider preview matches selection chrome', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sliderItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.slider,
          existingItems: const <DashboardItem>[],
          seed: 7,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'slider-preview-parity',
          rect: const GridRect(x: 4, y: 10, w: 16, h: 6),
          dataKey: 'V1',
          value: 42,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([sliderItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final selectionRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_selection_chrome_slider-preview-parity',
        ),
      ),
    );
    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandles.first),
    );
    await tester.pump();

    final previewRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_preview_overlay_slider-preview-parity',
        ),
      ),
    );
    final placeholderBodyRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_slider_resize_placeholder_body',
        ),
      ),
    );
    expect(previewRect.left, closeTo(selectionRect.left, 0.01));
    expect(previewRect.top, closeTo(selectionRect.top, 0.01));
    expect(previewRect.width, closeTo(selectionRect.width, 0.01));
    expect(previewRect.height, closeTo(selectionRect.height, 0.01));
    expect(placeholderBodyRect.left, closeTo(previewRect.left, 0.01));
    expect(placeholderBodyRect.top, closeTo(previewRect.top, 0.01));
    expect(placeholderBodyRect.width, closeTo(previewRect.width, 0.01));
    expect(placeholderBodyRect.height, closeTo(previewRect.height, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard builder tall slider preview wraps visible card', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sliderItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.slider,
          existingItems: const <DashboardItem>[],
          seed: 17,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'slider-tall-preview-body',
          rect: const GridRect(x: 5, y: 18, w: 16, h: 8),
          dataKey: 'V1',
          value: 42,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([sliderItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final selectionRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_selection_chrome_slider-tall-preview-body',
        ),
      ),
    );
    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandles.first),
    );
    await tester.pump();

    final previewRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_preview_overlay_slider-tall-preview-body',
        ),
      ),
    );
    final placeholderBodyRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_slider_resize_placeholder_body',
        ),
      ),
    );

    expect(selectionRect.left, closeTo(itemRect.left, 0.01));
    expect(selectionRect.top, closeTo(itemRect.top, 0.01));
    expect(selectionRect.width, closeTo(itemRect.width, 0.01));
    expect(selectionRect.height, closeTo(itemRect.height, 0.01));
    expect(selectionRect.center.dy, closeTo(itemRect.center.dy, 0.01));
    expect(previewRect.left, closeTo(selectionRect.left, 0.01));
    expect(previewRect.top, closeTo(selectionRect.top, 0.01));
    expect(previewRect.width, closeTo(selectionRect.width, 0.01));
    expect(previewRect.height, closeTo(selectionRect.height, 0.01));
    expect(placeholderBodyRect.left, closeTo(previewRect.left, 0.01));
    expect(placeholderBodyRect.top, closeTo(previewRect.top, 0.01));
    expect(placeholderBodyRect.width, closeTo(previewRect.width, 0.01));
    expect(placeholderBodyRect.height, closeTo(previewRect.height, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard builder gauge preview follows centered gauge body', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gaugeItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.gauge,
          existingItems: const <DashboardItem>[],
          seed: 8,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'gauge-preview-body',
          rect: const GridRect(x: 6, y: 9, w: 11, h: 11),
          dataKey: 'V1',
          value: 56,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([gaugeItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final selectionRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_selection_chrome_gauge-preview-body',
        ),
      ),
    );
    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandles.first),
    );
    await tester.pump();

    final previewRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_preview_overlay_gauge-preview-body',
        ),
      ),
    );
    final placeholderBodyRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_gauge_resize_placeholder_body',
        ),
      ),
    );
    expect(previewRect.width, closeTo(previewRect.height, 0.01));
    expect(previewRect.width, lessThan(selectionRect.width));
    expect(previewRect.height, lessThan(selectionRect.height));
    expect(previewRect.center.dx, closeTo(selectionRect.center.dx, 0.01));
    expect(previewRect.center.dy, closeTo(selectionRect.center.dy, 0.01));
    expect(placeholderBodyRect.left, closeTo(previewRect.left, 0.01));
    expect(placeholderBodyRect.top, closeTo(previewRect.top, 0.01));
    expect(placeholderBodyRect.width, closeTo(previewRect.width, 0.01));
    expect(placeholderBodyRect.height, closeTo(previewRect.height, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard builder led preview follows centered indicator body', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ledItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.led,
          existingItems: const <DashboardItem>[],
          seed: 9,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'led-preview-body',
          rect: const GridRect(x: 8, y: 11, w: 8, h: 8),
          dataKey: 'D1',
          enabled: true,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([ledItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final selectionRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_selection_chrome_led-preview-body',
        ),
      ),
    );
    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandles.first),
    );
    await tester.pump();

    final previewRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_preview_overlay_led-preview-body',
        ),
      ),
    );
    final placeholderBodyRect = tester.getRect(
      find.byKey(
        const ValueKey<String>('dashboard_builder_led_resize_placeholder_body'),
      ),
    );
    expect(previewRect.width, closeTo(previewRect.height, 0.01));
    expect(previewRect.width, lessThan(selectionRect.width));
    expect(previewRect.height, lessThan(selectionRect.height));
    expect(previewRect.center.dx, closeTo(selectionRect.center.dx, 0.01));
    expect(previewRect.center.dy, closeTo(selectionRect.center.dy, 0.01));
    expect(placeholderBodyRect.left, closeTo(previewRect.left, 0.01));
    expect(placeholderBodyRect.top, closeTo(previewRect.top, 0.01));
    expect(placeholderBodyRect.width, closeTo(previewRect.width, 0.01));
    expect(placeholderBodyRect.height, closeTo(previewRect.height, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'dashboard builder full card widget previews match selection chrome',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final items = <DashboardItem>[
        factoryPreviewItem(
          type: DashboardItemType.toggle,
          id: 'toggle-preview-parity',
          rect: const GridRect(x: 5, y: 9, w: 10, h: 4),
          seed: 10,
        ),
        factoryPreviewItem(
          type: DashboardItemType.trend,
          id: 'trend-preview-parity',
          rect: const GridRect(x: 3, y: 10, w: 16, h: 7),
          seed: 11,
        ),
        factoryPreviewItem(
          type: DashboardItemType.stepH,
          id: 'step-h-preview-parity',
          rect: const GridRect(x: 4, y: 12, w: 12, h: 4),
          seed: 12,
        ),
        factoryPreviewItem(
          type: DashboardItemType.stepV,
          id: 'step-v-preview-parity',
          rect: const GridRect(x: 9, y: 8, w: 4, h: 12),
          seed: 13,
        ),
      ];

      for (final item in items) {
        final rects = await captureSelectionAndResizePreviewRects(tester, item);
        final selectionRect = rects[0];
        final previewRect = rects[1];
        final placeholderRect = rects[2];

        expect(
          previewRect.left,
          closeTo(selectionRect.left, 0.01),
          reason: '${item.type.name} preview left should match selection',
        );
        expect(
          previewRect.top,
          closeTo(selectionRect.top, 0.01),
          reason: '${item.type.name} preview top should match selection',
        );
        expect(
          previewRect.width,
          closeTo(selectionRect.width, 0.01),
          reason: '${item.type.name} preview width should match selection',
        );
        expect(
          previewRect.height,
          closeTo(selectionRect.height, 0.01),
          reason: '${item.type.name} preview height should match selection',
        );
        expect(
          placeholderRect.left,
          closeTo(previewRect.left, 0.01),
          reason: '${item.type.name} placeholder left should match preview',
        );
        expect(
          placeholderRect.top,
          closeTo(previewRect.top, 0.01),
          reason: '${item.type.name} placeholder top should match preview',
        );
        expect(
          placeholderRect.width,
          closeTo(previewRect.width, 0.01),
          reason: '${item.type.name} placeholder width should match preview',
        );
        expect(
          placeholderRect.height,
          closeTo(previewRect.height, 0.01),
          reason: '${item.type.name} placeholder height should match preview',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('dashboard builder keeps right-edge value inside phone canvas', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final valueItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: const <DashboardItem>[],
          seed: 1,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'right-edge-value',
          rect: const GridRect(x: 8, y: 12, w: 14, h: 8),
          dataKey: 'V1',
          value: 4095,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([valueItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is DashboardGridPainter,
      ),
    );
    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);

    expect(itemRect.left, greaterThanOrEqualTo(canvasRect.left));
    expect(itemRect.right, lessThanOrEqualTo(canvasRect.right));
  });

  testWidgets('dashboard builder floating toolbar is centered on iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_floating_toolbar')),
    );
    expect(toolbarRect.center.dx, closeTo(820 / 2, 12));
    expect(toolbarRect.width, greaterThan(200));
    expect(toolbarRect.width, lessThan(300));
    expect(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
      findsOneWidget,
    );
    expect(find.byTooltip('เพิ่มวิดเจ็ต'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Redo'), findsOneWidget);

    final addRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );
    expect(addRect.center.dx, closeTo(toolbarRect.center.dx, 1));
  });

  testWidgets('dashboard builder iPad toolbar width follows visible actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final idleToolbarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_floating_toolbar')),
    );
    final idleAddRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปุ่ม'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final selectedToolbarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_floating_toolbar')),
    );
    final selectedAddRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );

    expect(idleToolbarRect.center.dx, closeTo(820 / 2, 12));
    expect(selectedToolbarRect.center.dx, closeTo(820 / 2, 12));
    expect(selectedToolbarRect.width, greaterThan(idleToolbarRect.width));
    expect(selectedToolbarRect.width, lessThan(580));
    expect(selectedAddRect.width, closeTo(idleAddRect.width, 0.01));
    expect(selectedAddRect.height, closeTo(idleAddRect.height, 0.01));
  });

  testWidgets('dashboard builder add action stays centered on phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_floating_toolbar')),
    );
    final addRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );
    expect(addRect.center.dx, closeTo(toolbarRect.center.dx, 1));
    expect(toolbarRect.width, lessThan(393.0 - 48.0));

    await tester.tap(find.byTooltip('เพิ่มวิดเจ็ต'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปุ่ม'));
    await tester.pumpAndSettle();

    final selectedToolbarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_floating_toolbar')),
    );
    final selectedAddRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );

    expect(selectedToolbarRect.width, closeTo(toolbarRect.width, 1));
    expect(selectedToolbarRect.height, closeTo(toolbarRect.height, 1));
    expect(selectedToolbarRect.width, lessThanOrEqualTo(393.0));
    expect(selectedAddRect.width, closeTo(addRect.width, 0.01));
    expect(selectedAddRect.height, closeTo(addRect.height, 0.01));
  });

  testWidgets('dashboard builder toolbar reveals selection actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('dashboard_builder_left_context_actions'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard_builder_right_context_actions'),
      ),
      findsNothing,
    );
    final idleToolbarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_floating_toolbar')),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปุ่ม'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_floating_toolbar')),
    );
    expect(toolbarRect.width, greaterThan(idleToolbarRect.width));
    expect(toolbarRect.height, closeTo(idleToolbarRect.height, 1));
    expect(toolbarRect.width, lessThanOrEqualTo(393.0));

    expect(
      find.byKey(
        const ValueKey<String>('dashboard_builder_left_context_actions'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard_builder_right_context_actions'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Duplicate'), findsOneWidget);
    expect(find.byTooltip('Select'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets(
    'dashboard builder toolbar shell becomes translucent during resize',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final valueItem =
          DashboardWidgetFactory.createItem(
            type: DashboardItemType.valueLabel,
            existingItems: const <DashboardItem>[],
            seed: 18,
            buttonMinW: 8,
            buttonMaxW: 28,
            buttonMinH: 6,
            buttonMaxH: 14,
          ).copyWith(
            id: 'toolbar-translucent-value',
            rect: const GridRect(x: 4, y: 22, w: 14, h: 8),
            dataKey: 'V1',
            value: 512,
          );
      seedProjectState();
      await DashboardBuilderLayoutStorageService().saveItems([valueItem]);

      await tester.pumpWidget(dashboardBuilderTestApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('dashboard_builder_floating_toolbar_shell'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_floating_toolbar_shell_translucent',
          ),
        ),
        findsNothing,
      );
      final addButtonRect = tester.getRect(
        find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
      );

      await tester.tap(find.byType(DashboardItemRenderer).first);
      await tester.pumpAndSettle();

      final resizeHandles = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ResizeHandle',
      );
      final gesture = await tester.startGesture(
        tester.getCenter(resizeHandles.first),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>(
            'dashboard_builder_floating_toolbar_shell_translucent',
          ),
        ),
        findsOneWidget,
      );
      final activeAddButtonRect = tester.getRect(
        find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
      );
      expect(activeAddButtonRect.width, closeTo(addButtonRect.width, 0.01));
      expect(activeAddButtonRect.height, closeTo(addButtonRect.height, 0.01));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('dashboard_builder_floating_toolbar_shell'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('dashboard builder resize auto-scroll matches drag behavior', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final valueItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: const <DashboardItem>[],
          seed: 30,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'resize-autoscroll-value',
          rect: const GridRect(x: 4, y: 38, w: 14, h: 8),
          dataKey: 'V1',
          value: 256,
        );
    final trailingItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: <DashboardItem>[valueItem],
          seed: 35,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'resize-autoscroll-trailing',
          rect: const GridRect(x: 4, y: 60, w: 14, h: 8),
          dataKey: 'V2',
          value: 512,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().clearBuilderDraft();
    await DashboardBuilderLayoutStorageService().clearBuilderHistory();
    await DashboardBuilderLayoutStorageService().saveItems([
      valueItem,
      trailingItem,
    ]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    final itemFinder = find.byType(DashboardItemRenderer).first;
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(itemFinder);
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final initialOffset = scrollable.position.pixels;
    final viewportRect = tester.getRect(
      find.byType(SingleChildScrollView).first,
    );
    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandles.last),
    );
    await tester.pump();
    await gesture.moveTo(
      Offset(viewportRect.center.dx, viewportRect.bottom - 4),
    );
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 160));

    expect(scrollable.position.pixels, greaterThan(initialOffset));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard builder no-op move does not create undo history', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final layoutStorage = DashboardBuilderLayoutStorageService();
    final valueItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: const <DashboardItem>[],
          seed: 31,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'noop-move-value',
          rect: const GridRect(x: 4, y: 12, w: 14, h: 8),
          dataKey: 'V1',
          value: 512,
        );
    seedProjectState();
    await layoutStorage.clearBuilderDraft();
    await layoutStorage.clearBuilderHistory();
    await layoutStorage.saveItems([valueItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final itemFinder = find.byType(DashboardItemRenderer).first;
    final itemRect = tester.getRect(itemFinder);
    final gesture = await tester.startGesture(itemRect.center);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();

    final history = await layoutStorage.loadBuilderHistory();
    expect(history, isNull);
  });

  testWidgets('dashboard builder no-op resize does not create undo history', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final layoutStorage = DashboardBuilderLayoutStorageService();
    final valueItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: const <DashboardItem>[],
          seed: 32,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'noop-resize-value',
          rect: const GridRect(x: 4, y: 12, w: 14, h: 8),
          dataKey: 'V1',
          value: 1024,
        );
    seedProjectState();
    await layoutStorage.clearBuilderDraft();
    await layoutStorage.clearBuilderHistory();
    await layoutStorage.saveItems([valueItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final resizeHandles = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ResizeHandle',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandles.first),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final history = await layoutStorage.loadBuilderHistory();
    expect(history, isNull);
  });

  testWidgets('dashboard builder duplicate keeps duplicated multi-select set', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final firstItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: const <DashboardItem>[],
          seed: 33,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'duplicate-origin-a',
          rect: const GridRect(x: 2, y: 10, w: 8, h: 6),
          dataKey: 'V1',
          value: 1,
        );
    final secondItem =
        DashboardWidgetFactory.createItem(
          type: DashboardItemType.valueLabel,
          existingItems: <DashboardItem>[firstItem],
          seed: 34,
          buttonMinW: 8,
          buttonMaxW: 28,
          buttonMinH: 6,
          buttonMaxH: 14,
        ).copyWith(
          id: 'duplicate-origin-b',
          rect: const GridRect(x: 12, y: 10, w: 8, h: 6),
          dataKey: 'V2',
          value: 2,
        );
    seedProjectState();
    await DashboardBuilderLayoutStorageService().clearBuilderDraft();
    await DashboardBuilderLayoutStorageService().clearBuilderHistory();
    await DashboardBuilderLayoutStorageService().saveItems([
      firstItem,
      secondItem,
    ]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final originalRects = rectSignatures(
      tester
          .widgetList(find.byType(DashboardItemRenderer))
          .map((widget) => tester.getRect(find.byWidget(widget))),
    );

    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Select'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).at(1));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('dashboard_builder_left_context_actions'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Duplicate'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_selection_chrome_duplicate-origin-a',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'dashboard_builder_selection_chrome_duplicate-origin-b',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.key is ValueKey<String> &&
            (widget.key as ValueKey<String>).value.startsWith(
              'dashboard_builder_selection_chrome_',
            ),
      ),
      findsNWidgets(2),
    );

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    final remainingRects = rectSignatures(
      List<Rect>.generate(
        tester.widgetList(find.byType(DashboardItemRenderer)).length,
        (index) => tester.getRect(find.byType(DashboardItemRenderer).at(index)),
      ),
    );
    expect(remainingRects, originalRects);
  });

  testWidgets('dashboard builder add widget sheet is shorter on iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard_builder_add_action')),
    );
    await tester.pumpAndSettle();

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey<String>('add_widget_sheet_surface')),
    );
    expect(sheetRect.height, lessThan(1180 * 0.50));
    expect(sheetRect.height, greaterThan(1180 * 0.40));
    expect(
      find.byKey(const ValueKey<String>('add_widget_option_grid')),
      findsOneWidget,
    );
    expect(find.text('ปุ่ม'), findsOneWidget);
    expect(find.text('แสดงค่า'), findsOneWidget);
  });

  testWidgets('dashboard builder empty guidance is raised on large iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    final emptyCardRect = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard_builder_empty_state_card')),
    );
    expect(emptyCardRect.center.dy, lessThan(880.0));
    expect(find.text('เริ่มจัดวางวิดเจ็ตในโหมดแก้ไข'), findsOneWidget);
  });

  testWidgets('dashboard builder places widgets with compact iPad canvas cap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('เพิ่มวิดเจ็ต'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปุ่ม'));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, greaterThan(70));
    expect(itemRect.width, lessThan(300));
    expect(itemRect.left, greaterThan(16));
    expect(itemRect.right, lessThan(584));
  });

  testWidgets(
    'dashboard builder places widgets with standard iPad canvas cap',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(dashboardBuilderTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('เพิ่มวิดเจ็ต'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ปุ่ม'));
      await tester.pumpAndSettle();

      final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
      expect(itemRect.width, greaterThan(80));
      expect(itemRect.width, lessThan(360));
      expect(itemRect.left, greaterThan(68));
      expect(itemRect.right, lessThan(700));
    },
  );

  testWidgets('dashboard builder places widgets with iPad Air canvas width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('เพิ่มวิดเจ็ต'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปุ่ม'));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, greaterThan(90));
    expect(itemRect.width, lessThan(360));
    expect(itemRect.left, greaterThan(72));
    expect(itemRect.right, lessThan(748));
  });

  testWidgets('dashboard builder keeps selected edge chrome inside canvas', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final edgeItem = stepDashboardItem(
      id: 'right-edge-step',
      type: DashboardItemType.stepH,
      title: 'Right Edge Step',
      dataKey: 'V4',
    ).copyWith(rect: const GridRect(x: 16, y: 26, w: 10, h: 4));
    seedProjectState();
    await DashboardBuilderLayoutStorageService().saveItems([edgeItem]);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DashboardItemRenderer).first);
    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is DashboardGridPainter,
      ),
    );
    final handleRects = tester
        .widgetList<Widget>(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ResizeHandle',
          ),
        )
        .map((widget) => tester.getRect(find.byWidget(widget)))
        .toList();

    expect(handleRects, isNotEmpty);
    for (final handleRect in handleRects) {
      expect(handleRect.left, greaterThanOrEqualTo(canvasRect.left));
      expect(handleRect.right, lessThanOrEqualTo(canvasRect.right));
      expect(handleRect.top, greaterThanOrEqualTo(canvasRect.top));
      expect(handleRect.bottom, lessThanOrEqualTo(canvasRect.bottom));
    }
  });

  testWidgets('dashboard builder canvas remains capped on large iPad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('เพิ่มวิดเจ็ต'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปุ่ม'));
    await tester.pumpAndSettle();

    final itemRect = tester.getRect(find.byType(DashboardItemRenderer).first);
    expect(itemRect.width, lessThan(360));
    expect(itemRect.center.dx, lessThan(1024 / 2));
    expect(itemRect.left, greaterThan(130));
    expect(itemRect.right, lessThan(894));
  });

  testWidgets('dashboard builder back dialog uses Thai actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(dashboardBuilderStackTestApp());
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
