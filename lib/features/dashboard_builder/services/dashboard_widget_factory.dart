import 'package:flutter/material.dart';

import '../models/dashboard_item.dart';

typedef ButtonRectResolver = GridRect Function(String title);
typedef DashboardWidgetFactoryButtonRectResolver =
    GridRect Function(String title);

class DashboardWidgetFactory {
  const DashboardWidgetFactory._();

  static DashboardItem createItem({
    required DashboardItemType type,
    required List<DashboardItem> existingItems,
    required int seed,
    required int buttonMinW,
    required int buttonMaxW,
    required int buttonMinH,
    required int buttonMaxH,
    DashboardWidgetFactoryButtonRectResolver? buttonRectResolver,
  }) {
    final defaultTitle = _nextDefaultTitle(type, existingItems);

    switch (type) {
      case DashboardItemType.button:
        return DashboardItem(
          id: 'button-$seed',
          type: DashboardItemType.button,
          title: defaultTitle,
          rect:
              buttonRectResolver?.call(defaultTitle) ??
              const GridRect(x: 0, y: 0, w: 14, h: 8),
          minW: buttonMinW,
          maxW: buttonMaxW,
          minH: buttonMinH,
          maxH: buttonMaxH,
          accentColor: const Color(0xFF1F9443),
          secondaryAccentColor: const Color(0xFFD94B4B),
          dataSource: 'device_channel',
          bindingMode: 'read_write',
          dataType: 'bool',
          sendBehavior: 'switch',
          enabled: false,
        );
      case DashboardItemType.slider:
        return DashboardItem(
          id: 'slider-$seed',
          type: DashboardItemType.slider,
          title: defaultTitle,
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 16, h: 5),
          minW: 12,
          maxW: 28,
          minH: 5,
          maxH: 5,
          accentColor: const Color(0xFF9BE7C4),
          value: 0,
          dataSource: 'device_channel',
          bindingMode: 'read_write',
          dataType: 'number',
          stepValue: 1,
          sendBehavior: 'on_release',
        );
      case DashboardItemType.gauge:
        return DashboardItem(
          id: 'gauge-$seed',
          type: DashboardItemType.gauge,
          title: defaultTitle,
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 11, h: 11),
          minW: 9,
          maxW: 14,
          minH: 9,
          maxH: 14,
          accentColor: const Color(0xFFEF7C39),
          value: 0,
          dataSource: 'device_channel',
          bindingMode: 'read',
          dataType: 'number',
        );
      case DashboardItemType.toggle:
        return DashboardItem(
          id: 'toggle-$seed',
          type: DashboardItemType.toggle,
          title: defaultTitle,
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 12, h: 5),
          minW: 8,
          maxW: 18,
          minH: 4,
          maxH: 8,
          accentColor: const Color(0xFF5BD57D),
          secondaryAccentColor: const Color(0xFFD94B4B),
          dataSource: 'device_channel',
          bindingMode: 'read_write',
          dataType: 'bool',
          sendBehavior: 'on_release',
          value: 0,
          enabled: false,
        );
      case DashboardItemType.valueLabel:
        return DashboardItem(
          id: 'value-$seed',
          type: DashboardItemType.valueLabel,
          title: defaultTitle,
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 14, h: 4),
          minW: 8,
          maxW: 24,
          minH: 3,
          maxH: 6,
          accentColor: const Color(0xFF7FD7FF),
          value: 0,
          dataSource: 'device_channel',
          bindingMode: 'read',
          dataType: 'number',
        );
      case DashboardItemType.stepH:
        return DashboardItem(
          id: 'step-h-$seed',
          type: DashboardItemType.stepH,
          title: defaultTitle,
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 15, h: 5),
          minW: 10,
          maxW: 24,
          minH: 4,
          maxH: 7,
          accentColor: const Color(0xFF6CB8F6),
          value: 0,
          minValue: 0,
          maxValue: 100,
          dataSource: 'device_channel',
          bindingMode: 'read_write',
          dataType: 'number',
          stepValue: 1,
          sendBehavior: 'on_release',
        );
      case DashboardItemType.stepV:
        return DashboardItem(
          id: 'step-v-$seed',
          type: DashboardItemType.stepV,
          title: defaultTitle,
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 8, h: 10),
          minW: 6,
          maxW: 12,
          minH: 8,
          maxH: 16,
          accentColor: const Color(0xFF6CB8F6),
          value: 0,
          minValue: 0,
          maxValue: 100,
          dataSource: 'device_channel',
          bindingMode: 'read_write',
          dataType: 'number',
          stepValue: 1,
          sendBehavior: 'on_release',
        );
    }
  }

  static String _nextDefaultTitle(
    DashboardItemType type,
    List<DashboardItem> existingItems,
  ) {
    var maxIndex = 0;
    for (final item in existingItems) {
      if (item.type != type) {
        continue;
      }

      final index = _defaultTitleIndex(type, item.title);
      if (index != null && index > maxIndex) {
        maxIndex = index;
      }
    }

    return dashboardDefaultTitleForType(type, maxIndex + 1);
  }

  static int? _defaultTitleIndex(DashboardItemType type, String title) {
    final normalized = title.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    final prefixes = <String>[
      dashboardDefaultTitlePrefix(type),
      dashboardLegacyDefaultTitlePrefixes[type] ?? '',
    ].where((prefix) => prefix.isNotEmpty);

    for (final prefix in prefixes) {
      final normalizedPrefix = prefix.toUpperCase();
      if (normalized == normalizedPrefix) {
        return 1;
      }
      if (!normalized.startsWith(normalizedPrefix)) {
        continue;
      }

      final suffix = normalized.substring(normalizedPrefix.length).trimLeft();
      final index = int.tryParse(suffix);
      if (index != null && index > 0) {
        return index;
      }
    }

    return null;
  }
}
