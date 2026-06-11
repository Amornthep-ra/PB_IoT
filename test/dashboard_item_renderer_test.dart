import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_item.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_item_renderer.dart';

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
      final valueRect = tester.getRect(find.text('440K'));

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
          size: const Size(240, 74),
          item: _item(
            type: DashboardItemType.slider,
            title: 'Pump Control',
            rect: const GridRect(x: 0, y: 0, w: 16, h: 5),
            minW: 12,
            minH: 5,
            dataKey: 'V1',
            value: 657000,
          ),
        ),
      );

      expect(find.text('657K'), findsOneWidget);
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
      final valueRect = tester.getRect(find.text('440K'));

      expect(valueRect.top, greaterThanOrEqualTo(frameRect.top));
      expect(valueRect.bottom, lessThanOrEqualTo(titleRect.top));
      expect(titleRect.bottom, lessThanOrEqualTo(frameRect.bottom));
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
            rect: const GridRect(x: 0, y: 0, w: 14, h: 5),
            minW: 10,
            minH: 4,
            dataKey: 'V4',
            value: 9,
            minValue: 0,
            maxValue: 10,
            stepValue: 2,
          ),
          onItemChanged: changes.add,
        ),
      );

      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

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
            rect: const GridRect(x: 0, y: 0, w: 8, h: 10),
            minW: 6,
            minH: 8,
            value: 4,
            minValue: 0,
            maxValue: 10,
            stepValue: 1,
          ),
          onItemChanged: changes.add,
          size: const Size(120, 220),
        ),
      );

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.text('--'), findsOneWidget);

      await tester.tap(find.byTooltip('เพิ่มค่า'));
      await tester.pump();

      expect(changes, isEmpty);
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
