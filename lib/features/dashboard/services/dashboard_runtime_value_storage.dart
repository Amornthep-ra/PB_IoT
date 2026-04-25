import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard_builder/models/dashboard_item.dart';
import '../../projects/services/project_state.dart';

class DashboardRuntimeValueStorage {
  DashboardRuntimeValueStorage({SharedPreferences? preferences})
    : _preferences = preferences;

  static const String _storageKey = 'dashboard_runtime_values_v1';

  final SharedPreferences? _preferences;

  String get _effectiveStorageKey {
    final projectId = ProjectState.current?.id.trim();
    if (projectId == null || projectId.isEmpty) {
      return _storageKey;
    }
    return '${_storageKey}_$projectId';
  }

  Future<List<DashboardItem>> applyToItems(List<DashboardItem> items) async {
    final storedValues = await loadValues();
    if (storedValues.isEmpty) {
      return items;
    }

    return items
        .map((item) {
          final storedValue = storedValues[item.id];
          if (storedValue == null) {
            return item;
          }

          return switch (item.type) {
            DashboardItemType.button ||
            DashboardItemType.toggle => item.copyWith(
              enabled: storedValue.enabled,
              value: storedValue.enabled ? 1.0 : 0.0,
            ),
            DashboardItemType.slider ||
            DashboardItemType.gauge ||
            DashboardItemType.valueLabel => item.copyWith(
              value: storedValue.value,
            ),
          };
        })
        .toList(growable: false);
  }

  Future<void> saveFromItems(List<DashboardItem> items) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};

    for (final item in items) {
      if (!_shouldPersist(item)) {
        continue;
      }

      payload[item.id] = <String, dynamic>{
        'type': item.type.name,
        'value': item.value,
        'enabled': item.enabled,
      };
    }

    await preferences.setString(_effectiveStorageKey, jsonEncode(payload));
  }

  Future<void> pruneForItems(List<DashboardItem> items) async {
    final storedValues = await loadValues();
    if (storedValues.isEmpty) {
      return;
    }

    final activeIds = items.map((item) => item.id).toSet();
    final filteredEntries = <String, _StoredRuntimeValue>{};
    for (final entry in storedValues.entries) {
      if (activeIds.contains(entry.key)) {
        filteredEntries[entry.key] = entry.value;
      }
    }

    final preferences = _preferences ?? await SharedPreferences.getInstance();
    if (filteredEntries.isEmpty) {
      await preferences.remove(_effectiveStorageKey);
      return;
    }

    final payload = <String, dynamic>{};
    for (final entry in filteredEntries.entries) {
      payload[entry.key] = <String, dynamic>{
        'type': entry.value.type.name,
        'value': entry.value.value,
        'enabled': entry.value.enabled,
      };
    }
    await preferences.setString(_effectiveStorageKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_effectiveStorageKey);
  }

  Future<Map<String, _StoredRuntimeValue>> loadValues() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(_effectiveStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <String, _StoredRuntimeValue>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const <String, _StoredRuntimeValue>{};
    }

    final values = <String, _StoredRuntimeValue>{};
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        continue;
      }

      final typeName = value['type']?.toString();
      final type = DashboardItemType.values.where(
        (item) => item.name == typeName,
      );
      if (type.isEmpty) {
        continue;
      }

      values[entry.key] = _StoredRuntimeValue(
        type: type.first,
        value: (value['value'] as num?)?.toDouble() ?? 0,
        enabled: value['enabled'] == true,
      );
    }

    return values;
  }

  bool _shouldPersist(DashboardItem item) {
    switch (item.type) {
      case DashboardItemType.button:
      case DashboardItemType.toggle:
      case DashboardItemType.slider:
        final bindingMode = item.bindingMode.trim().toLowerCase();
        return bindingMode == 'write' || bindingMode == 'read_write';
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
        final bindingKey = item.dataKey?.trim();
        return bindingKey != null && bindingKey.isNotEmpty;
    }
  }
}

class _StoredRuntimeValue {
  const _StoredRuntimeValue({
    required this.type,
    required this.value,
    required this.enabled,
  });

  final DashboardItemType type;
  final double value;
  final bool enabled;
}
