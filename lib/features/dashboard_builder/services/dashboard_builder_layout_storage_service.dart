import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_item.dart';

class DashboardBuilderLayoutStorageService {
  DashboardBuilderLayoutStorageService({
    SharedPreferences? preferences,
    this.storageKey = _defaultStorageKey,
  }) : _preferences = preferences;

  static const String _defaultStorageKey = 'dashboard_builder_layout_v1';
  static const String _dashboardTitleStorageKey = 'dashboard_builder_title_v1';
  static const String defaultDashboardTitle = 'Your Dashboard Name';

  final SharedPreferences? _preferences;
  final String storageKey;

  Future<String> loadDashboardTitle() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    return _normalizeDashboardTitle(
      preferences.getString(_dashboardTitleStorageKey),
    );
  }

  Future<void> saveDashboardTitle(String title) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setString(
      _dashboardTitleStorageKey,
      _normalizeDashboardTitle(title),
    );
  }

  Future<List<DashboardItem>?> loadItems() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return null;
    }

    final items = <DashboardItem>[];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final item = _itemFromJson(entry);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  Future<void> saveItems(List<DashboardItem> items) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final payload = items.map(_itemToJson).toList();
    await preferences.setString(storageKey, jsonEncode(payload));
  }

  String layoutSignature(List<DashboardItem> items) {
    return jsonEncode(items.map(_itemToSignatureJson).toList());
  }

  Map<String, dynamic> _itemToJson(DashboardItem item) {
    return <String, dynamic>{
      'id': item.id,
      'type': item.type.name,
      'title': item.title,
      'rect': <String, int>{
        'x': item.rect.x,
        'y': item.rect.y,
        'w': item.rect.w,
        'h': item.rect.h,
      },
      'minW': item.minW,
      'maxW': item.maxW,
      'minH': item.minH,
      'maxH': item.maxH,
      'accentColor': item.accentColor.value,
      'titleColor': item.titleColor?.value,
      'titleFontSize': item.titleFontSize,
      'titlePosition': item.titlePosition,
      'secondaryAccentColor': item.secondaryAccentColor?.value,
      'buttonShellColor': item.buttonShellColor?.value,
      'buttonInnerColor': item.buttonInnerColor?.value,
      'buttonBorderColor': item.buttonBorderColor?.value,
      'buttonBorderWidth': item.buttonBorderWidth,
      'valueLabelBorderWidth': item.valueLabelBorderWidth,
      'gaugeBorderWidth': item.gaugeBorderWidth,
      'sliderBorderWidth': item.sliderBorderWidth,
      'toggleBorderWidth': item.toggleBorderWidth,
      'value': item.value,
      'minValue': item.minValue,
      'maxValue': item.maxValue,
      'series': item.series,
      'unit': item.unit,
      'dataSource': item.dataSource,
      'dataKey': item.dataKey,
      'dataKeyLabel': item.dataKeyLabel,
      'bindingMode': item.bindingMode,
      'dataType': item.dataType,
      'stepValue': item.stepValue,
      'sendBehavior': item.sendBehavior,
      'enabled': item.enabled,
    };
  }

  Map<String, dynamic> _itemToSignatureJson(DashboardItem item) {
    return <String, dynamic>{
      'id': item.id,
      'type': item.type.name,
      'title': item.title,
      'rect': <String, int>{
        'x': item.rect.x,
        'y': item.rect.y,
        'w': item.rect.w,
        'h': item.rect.h,
      },
      'minW': item.minW,
      'maxW': item.maxW,
      'minH': item.minH,
      'maxH': item.maxH,
      'accentColor': item.accentColor.value,
      'titleColor': item.titleColor?.value,
      'titleFontSize': item.titleFontSize,
      'titlePosition': item.titlePosition,
      'secondaryAccentColor': item.secondaryAccentColor?.value,
      'buttonShellColor': item.buttonShellColor?.value,
      'buttonInnerColor': item.buttonInnerColor?.value,
      'buttonBorderColor': item.buttonBorderColor?.value,
      'buttonBorderWidth': item.buttonBorderWidth,
      'valueLabelBorderWidth': item.valueLabelBorderWidth,
      'gaugeBorderWidth': item.gaugeBorderWidth,
      'sliderBorderWidth': item.sliderBorderWidth,
      'toggleBorderWidth': item.toggleBorderWidth,
      'minValue': item.minValue,
      'maxValue': item.maxValue,
      'unit': item.unit,
      'dataSource': item.dataSource,
      'dataKey': item.dataKey,
      'dataKeyLabel': item.dataKeyLabel,
      'bindingMode': item.bindingMode,
      'dataType': item.dataType,
      'stepValue': item.stepValue,
      'sendBehavior': item.sendBehavior,
    };
  }

  DashboardItem? _itemFromJson(Map<String, dynamic> json) {
    var typeName = json['type']?.toString();
    if (typeName == 'chart') {
      typeName = DashboardItemType.toggle.name;
    }
    DashboardItemType? type;
    for (final value in DashboardItemType.values) {
      if (value.name == typeName) {
        type = value;
        break;
      }
    }
    if (type == null) {
      return null;
    }

    final rectJson = json['rect'];
    if (rectJson is! Map<String, dynamic>) {
      return null;
    }

    final x = (rectJson['x'] as num?)?.toInt();
    final y = (rectJson['y'] as num?)?.toInt();
    final w = (rectJson['w'] as num?)?.toInt();
    final h = (rectJson['h'] as num?)?.toInt();
    if (x == null || y == null || w == null || h == null) {
      return null;
    }

    final accentValue = (json['accentColor'] as num?)?.toInt();
    if (accentValue == null) {
      return null;
    }

    return DashboardItem(
      id: json['id']?.toString() ?? '',
      type: type,
      title: json['title']?.toString() ?? '',
      rect: GridRect(x: x, y: y, w: w, h: h),
      minW: (json['minW'] as num?)?.toInt() ?? 1,
      maxW: (json['maxW'] as num?)?.toInt() ?? 1,
      minH: (json['minH'] as num?)?.toInt() ?? 1,
      maxH: (json['maxH'] as num?)?.toInt() ?? 1,
      accentColor: Color(accentValue),
      titleColor: _optionalColor(json['titleColor']),
      titleFontSize: (json['titleFontSize'] as num?)?.toDouble(),
      titlePosition:
          json['titlePosition']?.toString() ?? DashboardItemTitlePosition.auto,
      secondaryAccentColor: _optionalColor(json['secondaryAccentColor']),
      buttonShellColor: _optionalColor(json['buttonShellColor']),
      buttonInnerColor: _optionalColor(json['buttonInnerColor']),
      buttonBorderColor: _optionalColor(json['buttonBorderColor']),
      buttonBorderWidth: (json['buttonBorderWidth'] as num?)?.toDouble(),
      valueLabelBorderWidth:
          (json['valueLabelBorderWidth'] as num?)?.toDouble(),
      gaugeBorderWidth: (json['gaugeBorderWidth'] as num?)?.toDouble(),
      sliderBorderWidth: (json['sliderBorderWidth'] as num?)?.toDouble(),
      toggleBorderWidth: (json['toggleBorderWidth'] as num?)?.toDouble(),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100,
      series: ((json['series'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<num>()
          .map((v) => v.toDouble())
          .toList(),
      unit: json['unit']?.toString(),
      dataSource: json['dataSource']?.toString(),
      dataKey: json['dataKey']?.toString(),
      dataKeyLabel: json['dataKeyLabel']?.toString(),
      bindingMode: json['bindingMode']?.toString() ?? 'read',
      dataType: json['dataType']?.toString() ?? 'number',
      stepValue: (json['stepValue'] as num?)?.toDouble() ?? 1,
      sendBehavior: json['sendBehavior']?.toString() ?? 'on_release',
      enabled: json['enabled'] == true,
    );
  }

  Color? _optionalColor(Object? value) {
    final intValue = (value as num?)?.toInt();
    if (intValue == null) {
      return null;
    }
    return Color(intValue);
  }

  String _normalizeDashboardTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return defaultDashboardTitle;
    }
    return trimmed;
  }
}
