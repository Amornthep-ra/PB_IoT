import '../../dashboard_builder/models/dashboard_item.dart';
import '../models/device_snapshot_model.dart';
import '../models/widget_binding_model.dart';
import 'widget_binding_resolver.dart';

class DashboardItemRuntimeBinding {
  const DashboardItemRuntimeBinding({
    this.readBinding,
    this.writeBinding,
    this.bindingIdentity,
    this.writeTargetIdentity,
  });

  final WidgetBindingModel? readBinding;
  final WidgetBindingModel? writeBinding;
  final String? bindingIdentity;
  final String? writeTargetIdentity;

  bool get canRead => readBinding != null;
  bool get canWrite => writeBinding != null;

  static const List<String> supportedTopLevelReadKeys = <String>[
    'online',
    'updatedAt',
    'error',
  ];

  static const List<String> supportedStatusKeys = <String>[
    'temperature',
    'humidity',
    'soilMoisture',
    'pumpStatus',
    'waterLevel',
  ];

  static const List<String> supportedUnitKeys = <String>[
    'temperature',
    'humidity',
    'soilMoisture',
    'waterLevel',
    'soilThreshold',
  ];

  static const Map<String, String> _knownWriteKeyAliases = <String, String>{
    'control.pumpstatus': 'control.pumpStatus',
    'control.fanstatus': 'control.fanStatus',
    'control.automode': 'control.autoMode',
    'control.soilthreshold': 'control.soilThreshold',
  };

  static final RegExp _virtualPinPattern = RegExp(
    r'^V(\d+)$',
    caseSensitive: false,
  );

  factory DashboardItemRuntimeBinding.fromItem(DashboardItem item) {
    final normalizedMode = item.bindingMode.trim().toLowerCase();
    final valueType = resolveValueType(item);
    final rawKey = item.dataKey?.trim() ?? '';
    if (rawKey.isEmpty) {
      return const DashboardItemRuntimeBinding();
    }

    final pin = _extractExactVirtualPin(rawKey);
    final readKey = _normalizeSnapshotReadKey(rawKey);
    final writeKey = _normalizeWriteKey(rawKey);
    final writePin = pin ?? _extractVirtualPinFromReadKey(readKey);

    WidgetBindingModel? readBinding;
    WidgetBindingModel? writeBinding;

    if (normalizedMode != 'write') {
      if (pin != null) {
        readBinding = WidgetBindingModel(
          source: WidgetBindingSource.api,
          pin: pin,
          valueType: valueType,
        );
      } else if (readKey != null) {
        readBinding = WidgetBindingModel(
          source: WidgetBindingSource.api,
          readKey: readKey,
          valueType: valueType,
        );
      }
    }

    if (normalizedMode != 'read') {
      if (writeKey != null) {
        writeBinding = WidgetBindingModel(
          source: WidgetBindingSource.api,
          writeKey: writeKey,
          valueType: valueType,
        );
      } else if (writePin != null) {
        writeBinding = WidgetBindingModel(
          source: WidgetBindingSource.api,
          pin: writePin,
          valueType: valueType,
        );
      }
    }

    return DashboardItemRuntimeBinding(
      readBinding: readBinding,
      writeBinding: writeBinding,
      bindingIdentity: _normalizeBindingIdentity(rawKey),
      writeTargetIdentity: _normalizeWriteTargetIdentity(
        writeKey: writeKey,
        pin: writePin,
      ),
    );
  }

  static WidgetBindingValueType resolveValueType(DashboardItem item) {
    final normalizedType = item.dataType.trim().toLowerCase();
    if (normalizedType.contains('bool')) {
      return WidgetBindingValueType.boolean;
    }
    if (normalizedType.contains('number') ||
        normalizedType.contains('int') ||
        normalizedType.contains('float') ||
        normalizedType.contains('decimal')) {
      return WidgetBindingValueType.number;
    }

    return switch (item.type) {
      DashboardItemType.button ||
      DashboardItemType.toggle ||
      DashboardItemType.led => WidgetBindingValueType.boolean,
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel ||
      DashboardItemType.trend => WidgetBindingValueType.number,
    };
  }

  static String? normalizeBindingIdentity(String? rawKey) {
    return _normalizeBindingIdentity(rawKey?.trim() ?? '');
  }

  static String? canonicalizeBindingKey(String? rawKey) {
    final normalized = rawKey?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    return _extractExactVirtualPin(normalized) ??
        _normalizeSnapshotReadKey(normalized) ??
        _normalizeWriteKey(normalized);
  }

  static bool isVirtualPinBinding(String? rawKey) {
    return _extractExactVirtualPin(rawKey?.trim() ?? '') != null;
  }

  static String? canonicalReadKey(String? rawKey) {
    return _normalizeSnapshotReadKey(rawKey?.trim() ?? '');
  }

  static String? canonicalWriteKey(String? rawKey) {
    return _normalizeWriteKey(rawKey?.trim() ?? '');
  }

  static bool isSupportedBindingKey(
    String? rawKey, {
    bool allowRead = true,
    bool allowWrite = true,
  }) {
    final normalized = rawKey?.trim() ?? '';
    if (normalized.isEmpty) {
      return false;
    }
    if (_extractExactVirtualPin(normalized) != null) {
      return true;
    }
    if (allowRead && _normalizeSnapshotReadKey(normalized) != null) {
      return true;
    }
    if (allowWrite && _normalizeWriteKey(normalized) != null) {
      return true;
    }
    return false;
  }

  static List<String> supportedWriteKeys() {
    final keys = _knownWriteKeyAliases.values.toSet().toList()..sort();
    return List<String>.unmodifiable(keys);
  }

  static String? _normalizeBindingIdentity(String rawKey) {
    if (rawKey.isEmpty) {
      return null;
    }

    final pin = _extractExactVirtualPin(rawKey);
    if (pin != null) {
      return 'pin:$pin';
    }

    final readKey = _normalizeSnapshotReadKey(rawKey);
    final readPin = _extractVirtualPinFromReadKey(readKey);
    if (readPin != null) {
      return 'pin:$readPin';
    }

    final writeKey = _normalizeWriteKey(rawKey);
    if (writeKey != null) {
      return 'write:$writeKey';
    }

    return 'path:${rawKey.toUpperCase()}';
  }

  static String? _normalizeWriteTargetIdentity({
    required String? writeKey,
    required String? pin,
  }) {
    if (writeKey != null) {
      return 'write:$writeKey';
    }
    if (pin != null) {
      return 'pin:$pin';
    }
    return null;
  }

  static String? _extractExactVirtualPin(String rawKey) {
    final match = _virtualPinPattern.firstMatch(rawKey.trim());
    if (match == null) {
      return null;
    }
    return 'V${match.group(1)}';
  }

  static String? _normalizeWriteKey(String rawKey) {
    final normalized = rawKey.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return _knownWriteKeyAliases[normalized];
  }

  static String? _normalizeSnapshotReadKey(String rawKey) {
    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final lower = trimmed.toLowerCase();
    switch (lower) {
      case 'online':
        return 'online';
      case 'updatedat':
        return 'updatedAt';
      case 'error':
        return 'error';
    }

    if (lower.startsWith('status.')) {
      final suffix = trimmed.substring(trimmed.indexOf('.') + 1).trim();
      return suffix.isEmpty ? null : 'status.$suffix';
    }
    if (lower.startsWith('units.')) {
      final suffix = trimmed.substring(trimmed.indexOf('.') + 1).trim();
      return suffix.isEmpty ? null : 'units.$suffix';
    }
    if (lower.startsWith('virtualpins.')) {
      final suffix = trimmed.substring(trimmed.indexOf('.') + 1).trim();
      if (suffix.isEmpty) {
        return null;
      }
      final pin = _extractExactVirtualPin(suffix);
      return pin == null ? 'virtualPins.$suffix' : 'virtualPins.$pin';
    }

    return null;
  }

  static String? _extractVirtualPinFromReadKey(String? readKey) {
    if (readKey == null || !readKey.startsWith('virtualPins.')) {
      return null;
    }

    final suffix = readKey.substring('virtualPins.'.length).trim();
    return _extractExactVirtualPin(suffix);
  }
}

class DashboardItemRuntimeValueMapper {
  const DashboardItemRuntimeValueMapper._();

  static DashboardItem applySnapshotValue({
    required DashboardItem item,
    required DeviceSnapshotModel snapshot,
  }) {
    final binding = DashboardItemRuntimeBinding.fromItem(item);
    if (!binding.canRead) {
      return item;
    }

    final incoming = WidgetBindingResolver.resolveReadValue(
      snapshot: snapshot,
      binding: binding.readBinding,
    );
    return applyResolvedValue(item: item, incoming: incoming);
  }

  static DashboardItem applyResolvedValue({
    required DashboardItem item,
    required Object? incoming,
  }) {
    switch (item.type) {
      case DashboardItemType.button:
      case DashboardItemType.toggle:
      case DashboardItemType.led:
        final enabled = WidgetBindingResolver.coerceBool(incoming);
        if (enabled == null) {
          return item;
        }
        return item.copyWith(enabled: enabled, value: enabled ? 1.0 : 0.0);
      case DashboardItemType.slider:
      case DashboardItemType.stepH:
      case DashboardItemType.stepV:
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
      case DashboardItemType.trend:
        final numeric = WidgetBindingResolver.coerceDouble(incoming);
        if (numeric == null) {
          return item;
        }
        final clampedNumeric = numeric
            .clamp(item.minValue, item.maxValue)
            .toDouble();
        if (item.type == DashboardItemType.trend) {
          return item.copyWith(
            value: clampedNumeric,
            series: appendTrendSample(item.series, clampedNumeric),
          );
        }
        return item.copyWith(value: clampedNumeric);
    }
  }

  static List<double> appendTrendSample(
    List<double> currentSeries,
    double value,
  ) {
    const maxSamples = 30;
    if (currentSeries.isNotEmpty && currentSeries.last == value) {
      return currentSeries;
    }
    final next = <double>[...currentSeries, value];
    if (next.length <= maxSamples) {
      return List<double>.unmodifiable(next);
    }
    return List<double>.unmodifiable(next.sublist(next.length - maxSamples));
  }
}
