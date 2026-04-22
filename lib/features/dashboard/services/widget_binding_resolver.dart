import '../models/device_snapshot_model.dart';
import '../models/widget_binding_model.dart';

class WidgetBindingResolver {
  const WidgetBindingResolver._();

  static Object? resolveReadValue({
    required DeviceSnapshotModel snapshot,
    WidgetBindingModel? binding,
  }) {
    if (binding == null) {
      return null;
    }

    if (binding.readKey != null && binding.readKey!.trim().isNotEmpty) {
      final fromReadKey = _resolvePath(snapshot, binding.readKey!);
      if (fromReadKey != null) {
        return fromReadKey;
      }
    }

    if (binding.pin != null && binding.pin!.trim().isNotEmpty) {
      return snapshot.virtualPins[binding.pin!.trim()];
    }

    return null;
  }

  static bool resolveBool({
    required DeviceSnapshotModel snapshot,
    WidgetBindingModel? binding,
    bool fallback = false,
  }) {
    final value = resolveReadValue(snapshot: snapshot, binding: binding);
    return coerceBool(value) ?? fallback;
  }

  static double resolveNumber({
    required DeviceSnapshotModel snapshot,
    WidgetBindingModel? binding,
    double fallback = 0,
  }) {
    final value = resolveReadValue(snapshot: snapshot, binding: binding);
    return coerceDouble(value) ?? fallback;
  }

  static String resolveUnit({
    required DeviceSnapshotModel snapshot,
    WidgetBindingModel? binding,
    String fallback = '',
  }) {
    final readKey = binding?.readKey?.trim();
    if (readKey == null || readKey.isEmpty) {
      return fallback;
    }

    if (readKey.startsWith('units.')) {
      final raw = _resolvePath(snapshot, readKey)?.toString().trim() ?? '';
      return raw.isEmpty ? fallback : raw;
    }

    if (!readKey.startsWith('status.')) {
      return fallback;
    }

    final segments = readKey.split('.');
    if (segments.length < 2) {
      return fallback;
    }

    final key = segments[1].trim();
    if (key.isEmpty) {
      return fallback;
    }

    final raw = snapshot.units[key]?.toString().trim() ?? '';
    return raw.isEmpty ? fallback : raw;
  }

  static bool? coerceBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) {
      return null;
    }
    if (text == 'true' || text == '1' || text == 'on' || text == 'online') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'off' || text == 'offline') {
      return false;
    }
    return null;
  }

  static double? coerceDouble(Object? value) {
    if (value is bool) {
      return value ? 1.0 : 0.0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  static Object? _resolvePath(DeviceSnapshotModel snapshot, String rawPath) {
    final path = rawPath.trim();
    if (path.isEmpty) {
      return null;
    }

    if (path == 'online') {
      return snapshot.online;
    }
    if (path == 'updatedAt') {
      return snapshot.updatedAt?.toIso8601String();
    }
    if (path == 'error') {
      return snapshot.error;
    }

    final segments = path.split('.');
    if (segments.isEmpty) {
      return null;
    }

    switch (segments.first) {
      case 'status':
        return _resolveFromMap(snapshot.status, segments.skip(1));
      case 'units':
        return _resolveFromMap(snapshot.units, segments.skip(1));
      case 'virtualPins':
        return _resolveFromMap(snapshot.virtualPins, segments.skip(1));
      default:
        return null;
    }
  }

  static Object? _resolveFromMap(
    Map<String, dynamic> source,
    Iterable<String> segments,
  ) {
    Object? current = source;
    for (final segment in segments) {
      if (current is Map<String, dynamic>) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}
