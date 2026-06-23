import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../projects/services/project_state.dart';
import '../models/dashboard_item.dart';

class DashboardBuilderHistoryEntry {
  const DashboardBuilderHistoryEntry({
    required this.items,
    required this.selectedId,
    required this.selectedIds,
    required this.isMultiSelectMode,
  });

  final List<DashboardItem> items;
  final String? selectedId;
  final Set<String> selectedIds;
  final bool isMultiSelectMode;
}

class DashboardBuilderHistoryState {
  const DashboardBuilderHistoryState({
    required this.currentSignature,
    required this.undoStack,
    required this.redoStack,
  });

  final String currentSignature;
  final List<DashboardBuilderHistoryEntry> undoStack;
  final List<DashboardBuilderHistoryEntry> redoStack;
}

class DashboardBuilderDraftState {
  const DashboardBuilderDraftState({
    required this.currentSignature,
    required this.items,
  });

  final String currentSignature;
  final List<DashboardItem> items;
}

class DashboardBuilderLayoutStorageService {
  DashboardBuilderLayoutStorageService({
    SharedPreferences? preferences,
    this.storageKey = _defaultStorageKey,
    this.dashboardTitleStorageKey = _dashboardTitleStorageKey,
    this.dashboardHistoryStorageKey = _dashboardHistoryStorageKey,
    this.dashboardDraftStorageKey = _dashboardDraftStorageKey,
  }) : _preferences = preferences;

  static const String _defaultStorageKey = 'dashboard_builder_layout_v1';
  static const String _dashboardTitleStorageKey = 'dashboard_builder_title_v1';
  static const String _dashboardHistoryStorageKey =
      'dashboard_builder_history_v1';
  static const String _dashboardDraftStorageKey = 'dashboard_builder_draft_v1';
  static const String defaultDashboardTitle = 'Your Dashboard Name';

  final SharedPreferences? _preferences;
  final String storageKey;
  final String dashboardTitleStorageKey;
  final String dashboardHistoryStorageKey;
  final String dashboardDraftStorageKey;

  String get _effectiveStorageKey => _projectScopedKey(storageKey);
  String get _effectiveDashboardTitleStorageKey =>
      _projectScopedKey(dashboardTitleStorageKey);
  String get _effectiveDashboardHistoryStorageKey =>
      _projectScopedKey(dashboardHistoryStorageKey);
  String get _effectiveDashboardDraftStorageKey =>
      _projectScopedKey(dashboardDraftStorageKey);

  Future<String> loadDashboardTitle() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    return _normalizeDashboardTitle(
      preferences.getString(_effectiveDashboardTitleStorageKey),
    );
  }

  Future<void> saveDashboardTitle(String title) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setString(
      _effectiveDashboardTitleStorageKey,
      _normalizeDashboardTitle(title),
    );
  }

  Future<List<DashboardItem>?> loadItems() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(_effectiveStorageKey);
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
    await preferences.setString(_effectiveStorageKey, jsonEncode(payload));
  }

  Future<DashboardBuilderHistoryState?> loadBuilderHistory() async {
    try {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      final raw = preferences.getString(_effectiveDashboardHistoryStorageKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final currentSignature = decoded['currentSignature']?.toString();
      if (currentSignature == null || currentSignature.isEmpty) {
        return null;
      }

      return DashboardBuilderHistoryState(
        currentSignature: currentSignature,
        undoStack: _historyEntriesFromJson(decoded['undoStack']),
        redoStack: _historyEntriesFromJson(decoded['redoStack']),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBuilderHistory({
    required String currentSignature,
    required List<DashboardBuilderHistoryEntry> undoStack,
    required List<DashboardBuilderHistoryEntry> redoStack,
  }) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setString(
      _effectiveDashboardHistoryStorageKey,
      jsonEncode(<String, dynamic>{
        'currentSignature': currentSignature,
        'undoStack': undoStack.map(_historyEntryToJson).toList(),
        'redoStack': redoStack.map(_historyEntryToJson).toList(),
      }),
    );
  }

  Future<void> clearBuilderHistory() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_effectiveDashboardHistoryStorageKey);
  }

  Future<DashboardBuilderDraftState?> loadBuilderDraft() async {
    try {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      final raw = preferences.getString(_effectiveDashboardDraftStorageKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final currentSignature = decoded['currentSignature']?.toString();
      if (currentSignature == null || currentSignature.isEmpty) {
        return null;
      }

      final rawItems = decoded['items'];
      if (rawItems is! List<dynamic>) {
        return null;
      }

      final items = _itemsFromJsonList(rawItems);
      if (items.isEmpty && rawItems.isNotEmpty) {
        return null;
      }

      return DashboardBuilderDraftState(
        currentSignature: currentSignature,
        items: items,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBuilderDraft(List<DashboardItem> items) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setString(
      _effectiveDashboardDraftStorageKey,
      jsonEncode(<String, dynamic>{
        'currentSignature': layoutSignature(items),
        'items': items.map(_itemToJson).toList(),
      }),
    );
  }

  Future<void> clearBuilderDraft() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_effectiveDashboardDraftStorageKey);
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
      'accentColor': item.accentColor.toARGB32(),
      'titleColor': item.titleColor?.toARGB32(),
      'titleFontSize': item.titleFontSize,
      'titlePosition': item.titlePosition,
      'secondaryAccentColor': item.secondaryAccentColor?.toARGB32(),
      'buttonShellColor': item.buttonShellColor?.toARGB32(),
      'buttonInnerColor': item.buttonInnerColor?.toARGB32(),
      'buttonBorderColor': item.buttonBorderColor?.toARGB32(),
      'buttonBorderWidth': item.buttonBorderWidth,
      'valueLabelBorderWidth': item.valueLabelBorderWidth,
      'gaugeBorderWidth': item.gaugeBorderWidth,
      'sliderBorderWidth': item.sliderBorderWidth,
      'toggleBorderWidth': item.toggleBorderWidth,
      'glowColor': item.glowColor?.toARGB32(),
      'glowStrength': item.glowStrength,
      'glowBlur': item.glowBlur,
      'value': item.value,
      'minValue': item.minValue,
      'maxValue': item.maxValue,
      'series': item.type == DashboardItemType.trend
          ? const <double>[]
          : item.series,
      'unit': item.unit,
      'dataSource': item.dataSource,
      'dataKey': item.dataKey,
      'dataKeyLabel': item.dataKeyLabel,
      'bindingMode': item.bindingMode,
      'dataType': item.dataType,
      'stepValue': item.stepValue,
      'sendBehavior': item.sendBehavior,
      'enabled': item.enabled,
      'locked': item.locked,
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
      'accentColor': item.accentColor.toARGB32(),
      'titleColor': item.titleColor?.toARGB32(),
      'titleFontSize': item.titleFontSize,
      'titlePosition': item.titlePosition,
      'secondaryAccentColor': item.secondaryAccentColor?.toARGB32(),
      'buttonShellColor': item.buttonShellColor?.toARGB32(),
      'buttonInnerColor': item.buttonInnerColor?.toARGB32(),
      'buttonBorderColor': item.buttonBorderColor?.toARGB32(),
      'buttonBorderWidth': item.buttonBorderWidth,
      'valueLabelBorderWidth': item.valueLabelBorderWidth,
      'gaugeBorderWidth': item.gaugeBorderWidth,
      'sliderBorderWidth': item.sliderBorderWidth,
      'toggleBorderWidth': item.toggleBorderWidth,
      'glowColor': item.glowColor?.toARGB32(),
      'glowStrength': item.glowStrength,
      'glowBlur': item.glowBlur,
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
      'locked': item.locked,
    };
  }

  Map<String, dynamic> _historyEntryToJson(DashboardBuilderHistoryEntry entry) {
    return <String, dynamic>{
      'items': entry.items.map(_itemToJson).toList(),
      'selectedId': entry.selectedId,
      'selectedIds': entry.selectedIds.toList(),
      'isMultiSelectMode': entry.isMultiSelectMode,
    };
  }

  List<DashboardBuilderHistoryEntry> _historyEntriesFromJson(Object? value) {
    final rawEntries = value is List<dynamic> ? value : const <dynamic>[];
    final entries = <DashboardBuilderHistoryEntry>[];
    for (final rawEntry in rawEntries) {
      if (rawEntry is! Map<String, dynamic>) {
        continue;
      }

      final rawItems = rawEntry['items'];
      if (rawItems is! List<dynamic>) {
        continue;
      }

      final items = _itemsFromJsonList(rawItems);

      final rawSelectedIds = rawEntry['selectedIds'];
      entries.add(
        DashboardBuilderHistoryEntry(
          items: items,
          selectedId: rawEntry['selectedId']?.toString(),
          selectedIds: rawSelectedIds is List<dynamic>
              ? rawSelectedIds.map((value) => value.toString()).toSet()
              : <String>{},
          isMultiSelectMode: rawEntry['isMultiSelectMode'] == true,
        ),
      );
    }
    return entries;
  }

  List<DashboardItem> _itemsFromJsonList(List<dynamic> rawItems) {
    final items = <DashboardItem>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) {
        continue;
      }
      final item = _itemFromJson(rawItem);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
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
      titleColor: _optionalTitleColor(json['titleColor']),
      titleFontSize: (json['titleFontSize'] as num?)?.toDouble(),
      titlePosition:
          json['titlePosition']?.toString() ?? DashboardItemTitlePosition.auto,
      secondaryAccentColor: _optionalColor(json['secondaryAccentColor']),
      buttonShellColor: _optionalColor(json['buttonShellColor']),
      buttonInnerColor: _optionalColor(json['buttonInnerColor']),
      buttonBorderColor: _optionalColor(json['buttonBorderColor']),
      buttonBorderWidth: (json['buttonBorderWidth'] as num?)?.toDouble(),
      valueLabelBorderWidth: (json['valueLabelBorderWidth'] as num?)
          ?.toDouble(),
      gaugeBorderWidth: (json['gaugeBorderWidth'] as num?)?.toDouble(),
      sliderBorderWidth: (json['sliderBorderWidth'] as num?)?.toDouble(),
      toggleBorderWidth: (json['toggleBorderWidth'] as num?)?.toDouble(),
      glowColor: _optionalColor(json['glowColor']),
      glowStrength: (json['glowStrength'] as num?)?.toDouble(),
      glowBlur: (json['glowBlur'] as num?)?.toDouble(),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100,
      series: type == DashboardItemType.trend
          ? const <double>[]
          : ((json['series'] as List<dynamic>?) ?? const <dynamic>[])
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
      locked: json['locked'] == true,
    );
  }

  Color? _optionalColor(Object? value) {
    final intValue = (value as num?)?.toInt();
    if (intValue == null) {
      return null;
    }
    return Color(intValue);
  }

  Color? _optionalTitleColor(dynamic value) {
    final color = _optionalColor(value);

    if (color == null) {
      return null;
    }

    if (color.toARGB32() == const Color(0xFF15212B).toARGB32()) {
      return null;
    }

    return color;
  }

  String _normalizeDashboardTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return defaultDashboardTitle;
    }
    return trimmed;
  }

  String _projectScopedKey(String baseKey) {
    final projectId = ProjectState.current?.id.trim();
    if (projectId == null || projectId.isEmpty) {
      return baseKey;
    }
    return '${baseKey}_$projectId';
  }
}
