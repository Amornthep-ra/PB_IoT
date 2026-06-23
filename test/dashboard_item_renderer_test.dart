import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_item.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_item_renderer.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/smart_action_button.dart';

void main() {
  group('DashboardItemRenderer titles', () {
    testWidgets('hides exact and numbered factory titles', (tester) async {
      for (final title in <String>['New Button', 'NEW BUTTON', 'NEW BUTTON1']) {
        await tester.pumpWidget(
          _rendererTestApp(
            item: _item(
              type: DashboardItemType.button,
              title: title,
              rect: const GridRect(x: 0, y: 0, w: 14, h: 8),
              minW: 8,
              minH: 6,
            ),
          ),
        );

        expect(find.text(title.toUpperCase()), findsNothing);
      }
    });

    testWidgets('keeps numbered factory-title matching type-aware', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.slider,
            title: 'NEW BUTTON1',
            rect: const GridRect(x: 0, y: 0, w: 16, h: 5),
            minW: 12,
            minH: 5,
            dataKey: 'V1',
            value: 440000,
          ),
        ),
      );

      expect(find.text('NEW BUTTON1'), findsOneWidget);
    });

    testWidgets('renders custom titles and suppresses hidden custom titles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.button,
            title: 'Pump Control',
            rect: const GridRect(x: 0, y: 0, w: 14, h: 8),
            minW: 8,
            minH: 6,
          ),
        ),
      );

      expect(find.text('PUMP CONTROL'), findsOneWidget);

      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.button,
            title: 'Pump Control',
            titlePosition: DashboardItemTitlePosition.hidden,
            rect: const GridRect(x: 0, y: 0, w: 14, h: 8),
            minW: 8,
            minH: 6,
          ),
        ),
      );

      expect(find.text('PUMP CONTROL'), findsNothing);
    });

    testWidgets('edit and view mode agree on title visibility', (tester) async {
      final item = _item(
        type: DashboardItemType.gauge,
        title: 'Pump Control',
        rect: const GridRect(x: 0, y: 0, w: 11, h: 11),
        minW: 9,
        minH: 9,
        dataKey: 'V1',
        value: 440000,
      );

      await tester.pumpWidget(_rendererTestApp(item: item));
      expect(find.text('PUMP CONTROL'), findsOneWidget);

      await tester.pumpWidget(_rendererTestApp(item: item, isEditMode: true));
      expect(find.text('PUMP CONTROL'), findsOneWidget);
    });

    testWidgets(
      'can suppress title rendering without changing default behavior',
      (tester) async {
        final item = _item(
          type: DashboardItemType.button,
          title: 'Pump Control',
          rect: const GridRect(x: 0, y: 0, w: 14, h: 8),
          minW: 8,
          minH: 6,
        );

        await tester.pumpWidget(_rendererTestApp(item: item));
        expect(find.text('PUMP CONTROL'), findsOneWidget);

        await tester.pumpWidget(_rendererTestApp(item: item, showTitle: false));
        expect(find.text('PUMP CONTROL'), findsNothing);
      },
    );

    testWidgets('can reserve title slot without painting title text', (
      tester,
    ) async {
      final item = _item(
        type: DashboardItemType.button,
        title: 'Pump Control',
        rect: const GridRect(x: 0, y: 0, w: 14, h: 8),
        minW: 8,
        minH: 6,
      );

      await tester.pumpWidget(_rendererTestApp(item: item, paintTitle: false));

      expect(find.text('PUMP CONTROL'), findsNothing);
    });

    testWidgets('restores adaptive ON status text for large button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.button,
            title: 'Pump Control',
            rect: const GridRect(x: 0, y: 0, w: 18, h: 10),
            minW: 8,
            minH: 6,
          ).copyWith(enabled: true),
        ),
      );

      expect(find.byType(SmartActionButton), findsOneWidget);
      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('slider top title stays in bounds and above value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          size: const Size(240, 100),
          item: _item(
            type: DashboardItemType.slider,
            title: 'Pump Control',
            rect: const GridRect(x: 0, y: 0, w: 16, h: 5),
            minW: 12,
            minH: 5,
            dataKey: 'V1',
            value: 440000,
          ),
        ),
      );

      final frameRect = tester.getRect(find.byKey(_frameKey));
      final titleRect = tester.getRect(find.text('PUMP CONTROL'));
      final valueRect = tester.getRect(find.text('440000'));

      expect(titleRect.top, greaterThanOrEqualTo(frameRect.top));
      expect(titleRect.bottom, lessThanOrEqualTo(valueRect.top));
      expect(valueRect.bottom, lessThanOrEqualTo(frameRect.bottom));
      expect(valueRect.height, greaterThanOrEqualTo(15));
    });

    testWidgets('compact slider with top title still renders value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          size: const Size(216, 64),
          item: _item(
            type: DashboardItemType.slider,
            title: 'Pump Control',
            rect: const GridRect(x: 0, y: 0, w: 12, h: 4),
            minW: 10,
            minH: 4,
            dataKey: 'V1',
            value: 657000,
          ),
        ),
      );

      expect(find.text('657000'), findsOneWidget);
    });

    testWidgets('bottom title stays in bounds and below value', (tester) async {
      await tester.pumpWidget(
        _rendererTestApp(
          size: const Size(240, 100),
          item: _item(
            type: DashboardItemType.slider,
            title: 'Pump Control',
            titlePosition: DashboardItemTitlePosition.bottomOutside,
            rect: const GridRect(x: 0, y: 0, w: 16, h: 5),
            minW: 12,
            minH: 5,
            dataKey: 'V1',
            value: 440000,
          ),
        ),
      );

      final frameRect = tester.getRect(find.byKey(_frameKey));
      final titleRect = tester.getRect(find.text('PUMP CONTROL'));
      final valueRect = tester.getRect(find.text('440000'));

      expect(valueRect.top, greaterThanOrEqualTo(frameRect.top));
      expect(valueRect.bottom, lessThanOrEqualTo(titleRect.top));
      expect(titleRect.bottom, lessThanOrEqualTo(frameRect.bottom));
    });

    testWidgets('value display text scales with rendered widget size', (
      tester,
    ) async {
      Future<double> valueFontFor({
        required Size size,
        String? dataKey = 'V1',
        double value = 42,
      }) async {
        await tester.pumpWidget(
          _rendererTestApp(
            size: size,
            showTitle: false,
            item: _item(
              type: DashboardItemType.valueLabel,
              title: 'Value',
              rect: const GridRect(x: 0, y: 0, w: 14, h: 4),
              minW: 8,
              minH: 3,
              dataKey: dataKey,
              value: value,
            ),
          ),
        );

        final text = tester.widget<Text>(
          find.byKey(const ValueKey<String>('value_label_display_text')),
        );
        return text.style!.fontSize!;
      }

      final defaultFont = await valueFontFor(size: const Size(260, 140));
      final widthOnlyFont = await valueFontFor(size: const Size(320, 140));
      final heightOnlyFont = await valueFontFor(size: const Size(260, 200));
      final bothAxesFont = await valueFontFor(size: const Size(320, 200));
      final largeFont = await valueFontFor(size: const Size(420, 260));

      expect(defaultFont, inInclusiveRange(32.0, 35.0));
      expect(widthOnlyFont, greaterThan(defaultFont));
      expect(heightOnlyFont, defaultFont);
      expect(bothAxesFont, greaterThanOrEqualTo(widthOnlyFont));
      expect(bothAxesFont, greaterThan(heightOnlyFont));
      expect(largeFont, greaterThan(bothAxesFont));
      expect(largeFont, greaterThan(defaultFont + 8.0));
    });

    testWidgets('button power icon scales with rendered widget size', (
      tester,
    ) async {
      Future<Size> powerIconSizeFor(Size size) async {
        await tester.pumpWidget(
          _rendererTestApp(
            size: size,
            showTitle: false,
            item: _item(
              type: DashboardItemType.button,
              title: 'Pump Control',
              rect: const GridRect(x: 0, y: 0, w: 14, h: 8),
              minW: 8,
              minH: 6,
            ),
          ),
        );

        return tester.getSize(find.byIcon(Icons.power_settings_new_rounded));
      }

      final compactIconSize = await powerIconSizeFor(const Size(96, 96));
      final expandedIconSize = await powerIconSizeFor(const Size(420, 420));
      final frameRect = tester.getRect(find.byKey(_frameKey));

      expect(expandedIconSize.width, greaterThan(compactIconSize.width + 28));
      expect(expandedIconSize.height, greaterThan(compactIconSize.height + 28));
      expect(expandedIconSize.width, greaterThanOrEqualTo(52));
      expect(expandedIconSize.height, greaterThanOrEqualTo(52));
      expect(expandedIconSize.width, lessThan(frameRect.width * 0.3));
      expect(expandedIconSize.height, lessThan(frameRect.height * 0.3));
    });

    testWidgets('unbound value display stays readable without oversizing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          size: const Size(420, 260),
          showTitle: false,
          item: _item(
            type: DashboardItemType.valueLabel,
            title: 'Value',
            rect: const GridRect(x: 0, y: 0, w: 14, h: 4),
            minW: 8,
            minH: 3,
          ),
        ),
      );

      expect(find.text('--'), findsOneWidget);
      final text = tester.widget<Text>(
        find.byKey(const ValueKey<String>('value_label_display_text')),
      );
      expect(text.style!.fontSize, inInclusiveRange(14.0, 42.0));
    });

    testWidgets('expanded value display keeps long text inside bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          size: const Size(420, 260),
          showTitle: false,
          item: _item(
            type: DashboardItemType.valueLabel,
            title: 'Value',
            rect: const GridRect(x: 0, y: 0, w: 20, h: 10),
            minW: 8,
            minH: 3,
            dataKey: 'V1',
            value: 987654321,
          ),
        ),
      );

      final frameRect = tester.getRect(find.byKey(_frameKey));
      final valueRect = tester.getRect(
        find.byKey(const ValueKey<String>('value_label_display_text')),
      );

      expect(valueRect.left, greaterThanOrEqualTo(frameRect.left));
      expect(valueRect.right, lessThanOrEqualTo(frameRect.right));
      expect(valueRect.top, greaterThanOrEqualTo(frameRect.top));
      expect(valueRect.bottom, lessThanOrEqualTo(frameRect.bottom));
    });

    testWidgets('renders Step H and emits clamped horizontal increments', (
      tester,
    ) async {
      final changes = <DashboardItem>[];

      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.stepH,
            title: 'ปรับค่า H 1',
            rect: const GridRect(x: 0, y: 0, w: 12, h: 4),
            minW: 8,
            minH: 3,
            dataKey: 'V4',
            value: 9,
            minValue: 0,
            maxValue: 10,
            stepValue: 2,
          ),
          onItemChanged: changes.add,
          size: const Size(190, 72),
        ),
      );

      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      final frameRect = tester.getRect(find.byKey(_frameKey));
      expect(
        tester.getRect(find.byIcon(Icons.remove_rounded)).left,
        greaterThanOrEqualTo(frameRect.left),
      );
      expect(
        tester.getRect(find.byIcon(Icons.add_rounded)).right,
        lessThanOrEqualTo(frameRect.right),
      );

      await tester.tap(find.byTooltip('เพิ่มค่า'));
      await tester.pump();

      expect(changes.single.value, 10);
    });

    testWidgets('renders Step V and disables controls without bound data key', (
      tester,
    ) async {
      final changes = <DashboardItem>[];

      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.stepV,
            title: 'ปรับค่า V 1',
            rect: const GridRect(x: 0, y: 0, w: 4, h: 12),
            minW: 3,
            minH: 8,
            value: 4,
            minValue: 0,
            maxValue: 10,
            stepValue: 1,
          ),
          onItemChanged: changes.add,
          size: const Size(72, 190),
        ),
      );

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
      final frameRect = tester.getRect(find.byKey(_frameKey));
      expect(
        tester.getRect(find.byIcon(Icons.add_rounded)).top,
        greaterThanOrEqualTo(frameRect.top),
      );
      expect(
        tester.getRect(find.byIcon(Icons.remove_rounded)).bottom,
        lessThanOrEqualTo(frameRect.bottom),
      );

      await tester.tap(find.byTooltip('เพิ่มค่า'));
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('renders trend empty one-sample and history states', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.trend,
            title: 'กราฟแนวโน้ม 1',
            rect: const GridRect(x: 0, y: 0, w: 16, h: 7),
            minW: 10,
            minH: 5,
          ),
          size: const Size(240, 120),
        ),
      );

      expect(find.text('--'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('trend_chart_painter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('trend_chart_empty_surface')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.trend,
            title: 'Trend',
            rect: const GridRect(x: 0, y: 0, w: 16, h: 7),
            minW: 10,
            minH: 5,
            dataKey: 'V3',
            value: 24,
          ).copyWith(series: const <double>[24]),
          size: const Size(240, 120),
        ),
      );

      expect(find.text('24'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('trend_chart_empty_surface')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _rendererTestApp(
          item: _item(
            type: DashboardItemType.trend,
            title: 'Trend',
            rect: const GridRect(x: 0, y: 0, w: 16, h: 7),
            minW: 10,
            minH: 5,
            dataKey: 'V3',
            value: 24,
          ).copyWith(series: const <double>[20, 22, 24]),
          size: const Size(240, 120),
        ),
      );

      expect(find.text('24'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('trend_chart_painter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('trend_chart_history_surface')),
        findsOneWidget,
      );
    });

    testWidgets('renders led active inactive and unknown states', (
      tester,
    ) async {
      final base = _item(
        type: DashboardItemType.led,
        title: 'ไฟสถานะ 1',
        rect: const GridRect(x: 0, y: 0, w: 9, h: 6),
        minW: 6,
        minH: 4,
        dataKey: 'V1',
      ).copyWith(dataType: 'bool');

      await tester.pumpWidget(
        _rendererTestApp(
          item: base.copyWith(enabled: true, value: 1),
          size: const Size(150, 120),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('led_indicator_light')),
        findsOneWidget,
      );
      expect(find.text('ON'), findsNothing);
      expect(find.text('OFF'), findsNothing);

      await tester.pumpWidget(
        _rendererTestApp(
          item: base.copyWith(enabled: false, value: 0),
          size: const Size(150, 120),
        ),
      );
      expect(find.text('ON'), findsNothing);
      expect(find.text('OFF'), findsNothing);

      await tester.pumpWidget(
        _rendererTestApp(
          item: base.copyWith(clearDataKey: true),
          size: const Size(150, 120),
        ),
      );
      expect(find.text('--'), findsNothing);
    });
  });
}

const _frameKey = Key('renderer-frame');

Widget _rendererTestApp({
  required DashboardItem item,
  bool isEditMode = false,
  bool showTitle = true,
  bool paintTitle = true,
  Size size = const Size(220, 140),
  ValueChanged<DashboardItem>? onItemChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.fromSize(
          key: _frameKey,
          size: size,
          child: DashboardItemRenderer(
            item: item,
            isEditMode: isEditMode,
            showTitle: showTitle,
            paintTitle: paintTitle,
            onItemChanged: onItemChanged,
          ),
        ),
      ),
    ),
  );
}

DashboardItem _item({
  required DashboardItemType type,
  required String title,
  required GridRect rect,
  required int minW,
  required int minH,
  String? titlePosition,
  String? dataKey,
  double value = 0,
  double minValue = 0,
  double maxValue = 100,
  double stepValue = 1,
}) {
  return DashboardItem(
    id: '${type.name}-test',
    type: type,
    title: title,
    titlePosition: titlePosition,
    rect: rect,
    minW: minW,
    maxW: 28,
    minH: minH,
    maxH: 14,
    accentColor: const Color(0xFF4E9070),
    secondaryAccentColor: const Color(0xFFD94B4B),
    dataKey: dataKey,
    bindingMode: 'read_write',
    dataType:
        type == DashboardItemType.button || type == DashboardItemType.toggle
        ? 'bool'
        : 'number',
    value: value,
    minValue: minValue,
    maxValue: maxValue,
    stepValue: stepValue,
    enabled: false,
  );
}
