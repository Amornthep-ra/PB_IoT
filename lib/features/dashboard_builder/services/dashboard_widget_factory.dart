import 'package:flutter/material.dart';

import '../models/dashboard_item.dart';

typedef ButtonRectResolver = GridRect Function(String title);
typedef DashboardWidgetFactoryButtonRectResolver =
    GridRect Function(String title);

class DashboardWidgetFactory {
  const DashboardWidgetFactory._();

  static const String buttonDefaultTitle = 'NEW BUTTON';

  static DashboardItem createItem({
    required DashboardItemType type,
    required int seed,
    required int buttonMinW,
    required int buttonMaxW,
    required int buttonMinH,
    required int buttonMaxH,
    DashboardWidgetFactoryButtonRectResolver? buttonRectResolver,
  }) {
    switch (type) {
      case DashboardItemType.button:
        const defaultTitle = buttonDefaultTitle;
        return DashboardItem(
          id: 'button-$seed',
          type: DashboardItemType.button,
          title: defaultTitle,
          titleColor: const Color(0xFF15212B),
          rect:
              buttonRectResolver?.call(defaultTitle) ??
              const GridRect(x: 0, y: 0, w: 14, h: 8),
          minW: buttonMinW,
          maxW: buttonMaxW,
          minH: buttonMinH,
          maxH: buttonMaxH,
          accentColor: const Color(0xFF1F9443),
          secondaryAccentColor: const Color(0xFFFF0000),
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
          title: 'New Slider',
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 14, h: 4),
          minW: 10,
          maxW: 28,
          minH: 4,
          maxH: 4,
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
          title: 'New Gauge',
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 10, h: 10),
          minW: 8,
          maxW: 14,
          minH: 8,
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
          title: 'New Toggle',
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 14, h: 6),
          minW: 6,
          maxW: 18,
          minH: 3,
          maxH: 8,
          accentColor: const Color(0xFF5BD57D),
          secondaryAccentColor: const Color(0xFFD93A3A),
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
          title: 'New Value',
          titleColor: const Color(0xFF15212B),
          rect: const GridRect(x: 0, y: 0, w: 14, h: 5),
          minW: 7,
          maxW: 14,
          minH: 4,
          maxH: 6,
          accentColor: const Color(0xFF7FD7FF),
          value: 0,
          dataSource: 'device_channel',
          bindingMode: 'read',
          dataType: 'number',
        );
    }
  }
}
