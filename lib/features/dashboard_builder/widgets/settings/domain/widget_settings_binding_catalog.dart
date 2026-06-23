import '../../../models/dashboard_item.dart';
import '../../../../dashboard/services/dashboard_item_runtime_binding.dart';

enum WidgetSettingsBindingSourceGroup {
  virtualPin,
  deviceStatus,
  deviceState,
  control,
}

class WidgetSettingsBindingEntry {
  const WidgetSettingsBindingEntry({
    required this.key,
    required this.name,
    required this.dataType,
    required this.rangeLabel,
    required this.description,
    required this.recommendedFor,
    required this.group,
    this.defaultValue,
    this.minValue,
    this.maxValue,
    this.unit,
  });

  final String key;
  final String name;
  final String dataType;
  final String rangeLabel;
  final String description;
  final List<DashboardItemType> recommendedFor;
  final WidgetSettingsBindingSourceGroup group;
  final double? defaultValue;
  final double? minValue;
  final double? maxValue;
  final String? unit;
}

class WidgetSettingsCustomBindingEntry {
  const WidgetSettingsCustomBindingEntry({
    required this.key,
    required this.name,
    required this.dataType,
    required this.unit,
    this.defaultValue,
    this.minValue,
    this.maxValue,
  });

  final String key;
  final String name;
  final String dataType;
  final String unit;
  final double? defaultValue;
  final double? minValue;
  final double? maxValue;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'name': name,
      'dataType': dataType,
      'unit': unit,
      'defaultValue': defaultValue,
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }

  factory WidgetSettingsCustomBindingEntry.fromJson(Map<String, dynamic> json) {
    return WidgetSettingsCustomBindingEntry(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dataType: json['dataType']?.toString() ?? 'number',
      unit: json['unit']?.toString() ?? '',
      defaultValue: (json['defaultValue'] as num?)?.toDouble(),
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
    );
  }
}

class WidgetSettingsBindingCatalog {
  const WidgetSettingsBindingCatalog._();

  static const List<WidgetSettingsBindingEntry> entries =
      <WidgetSettingsBindingEntry>[
        WidgetSettingsBindingEntry(
          key: 'V0',
          name: 'V0',
          dataType: 'bool',
          rangeLabel: '0-1',
          description: '0 = Off, 1 = On',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.button,
            DashboardItemType.toggle,
          ],
          group: WidgetSettingsBindingSourceGroup.virtualPin,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        WidgetSettingsBindingEntry(
          key: 'V1',
          name: 'V1',
          dataType: 'integer',
          rangeLabel: '0-1',
          description: '0 = Off, 1 = On',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.toggle,
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
            DashboardItemType.led,
          ],
          group: WidgetSettingsBindingSourceGroup.virtualPin,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        WidgetSettingsBindingEntry(
          key: 'V2',
          name: 'V2',
          dataType: 'integer',
          rangeLabel: '0-1000000',
          description: 'ค่าระยะเวลาเป็นวินาทีแบบจำนวนเต็ม',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.slider,
            DashboardItemType.stepH,
            DashboardItemType.stepV,
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
            DashboardItemType.trend,
          ],
          group: WidgetSettingsBindingSourceGroup.virtualPin,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1000000,
        ),
        WidgetSettingsBindingEntry(
          key: 'V3',
          name: 'V3',
          dataType: 'number',
          rangeLabel: '0-100',
          description: 'ค่าอุณหภูมิ',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.gauge,
            DashboardItemType.valueLabel,
            DashboardItemType.trend,
          ],
          group: WidgetSettingsBindingSourceGroup.virtualPin,
          defaultValue: 0,
          minValue: 0,
          maxValue: 100,
          unit: '°C',
        ),
        WidgetSettingsBindingEntry(
          key: 'status.temperature',
          name: 'temperature',
          dataType: 'number',
          rangeLabel: '0-100',
          description: 'อุณหภูมิจากสถานะอุปกรณ์',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
            DashboardItemType.trend,
          ],
          group: WidgetSettingsBindingSourceGroup.deviceStatus,
          defaultValue: 0,
          minValue: 0,
          maxValue: 100,
          unit: '°C',
        ),
        WidgetSettingsBindingEntry(
          key: 'status.humidity',
          name: 'humidity',
          dataType: 'number',
          rangeLabel: '0-100',
          description: 'ความชื้นจากสถานะอุปกรณ์',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
            DashboardItemType.trend,
          ],
          group: WidgetSettingsBindingSourceGroup.deviceStatus,
          defaultValue: 0,
          minValue: 0,
          maxValue: 100,
          unit: '%',
        ),
        WidgetSettingsBindingEntry(
          key: 'status.soilMoisture',
          name: 'soilMoisture',
          dataType: 'number',
          rangeLabel: '0-100',
          description: 'ความชื้นดินจากสถานะอุปกรณ์',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
            DashboardItemType.trend,
          ],
          group: WidgetSettingsBindingSourceGroup.deviceStatus,
          defaultValue: 0,
          minValue: 0,
          maxValue: 100,
          unit: '%',
        ),
        WidgetSettingsBindingEntry(
          key: 'status.pumpStatus',
          name: 'pumpStatus',
          dataType: 'bool',
          rangeLabel: '0-1',
          description: 'สถานะปั๊มจากอุปกรณ์',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.button,
            DashboardItemType.toggle,
            DashboardItemType.led,
            DashboardItemType.valueLabel,
          ],
          group: WidgetSettingsBindingSourceGroup.deviceStatus,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        WidgetSettingsBindingEntry(
          key: 'status.waterLevel',
          name: 'waterLevel',
          dataType: 'number',
          rangeLabel: '0-100',
          description: 'ระดับน้ำจากสถานะอุปกรณ์',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
            DashboardItemType.trend,
          ],
          group: WidgetSettingsBindingSourceGroup.deviceStatus,
          defaultValue: 0,
          minValue: 0,
          maxValue: 100,
          unit: '%',
        ),
        WidgetSettingsBindingEntry(
          key: 'online',
          name: 'online',
          dataType: 'bool',
          rangeLabel: '0-1',
          description: 'สถานะการเชื่อมต่ออุปกรณ์',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.led,
            DashboardItemType.toggle,
            DashboardItemType.valueLabel,
          ],
          group: WidgetSettingsBindingSourceGroup.deviceState,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        WidgetSettingsBindingEntry(
          key: 'updatedAt',
          name: 'updatedAt',
          dataType: 'string',
          rangeLabel: '',
          description: 'เวลาที่อุปกรณ์อัปเดตล่าสุด',
          recommendedFor: <DashboardItemType>[DashboardItemType.valueLabel],
          group: WidgetSettingsBindingSourceGroup.deviceState,
        ),
        WidgetSettingsBindingEntry(
          key: 'error',
          name: 'error',
          dataType: 'string',
          rangeLabel: '',
          description: 'ข้อความข้อผิดพลาดล่าสุด',
          recommendedFor: <DashboardItemType>[DashboardItemType.valueLabel],
          group: WidgetSettingsBindingSourceGroup.deviceState,
        ),
        WidgetSettingsBindingEntry(
          key: 'control.autoMode',
          name: 'autoMode',
          dataType: 'bool',
          rangeLabel: '0-1',
          description: 'สั่งเปิดหรือปิดโหมดอัตโนมัติ',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.button,
            DashboardItemType.toggle,
          ],
          group: WidgetSettingsBindingSourceGroup.control,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        WidgetSettingsBindingEntry(
          key: 'control.pumpStatus',
          name: 'pumpStatus',
          dataType: 'bool',
          rangeLabel: '0-1',
          description: 'สั่งปั๊มน้ำโดยตรง',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.button,
            DashboardItemType.toggle,
          ],
          group: WidgetSettingsBindingSourceGroup.control,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        WidgetSettingsBindingEntry(
          key: 'control.fanStatus',
          name: 'fanStatus',
          dataType: 'bool',
          rangeLabel: '0-1',
          description: 'สั่งพัดลมโดยตรง',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.button,
            DashboardItemType.toggle,
          ],
          group: WidgetSettingsBindingSourceGroup.control,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        WidgetSettingsBindingEntry(
          key: 'control.soilThreshold',
          name: 'soilThreshold',
          dataType: 'number',
          rangeLabel: '0-100',
          description: 'ตั้งค่าเกณฑ์ความชื้นดิน',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.slider,
            DashboardItemType.stepH,
            DashboardItemType.stepV,
            DashboardItemType.valueLabel,
          ],
          group: WidgetSettingsBindingSourceGroup.control,
          defaultValue: 0,
          minValue: 0,
          maxValue: 100,
          unit: '%',
        ),
      ];

  static WidgetSettingsBindingEntry? entryFor(String key) {
    final normalizedKey = canonicalBindingKey(key);
    if (normalizedKey == null) {
      return null;
    }
    for (final entry in entries) {
      if (entry.key == normalizedKey) {
        return entry;
      }
    }
    return null;
  }

  static bool isCatalogKey(String key) => entryFor(key) != null;

  static String? canonicalBindingKey(String raw) {
    return DashboardItemRuntimeBinding.canonicalizeBindingKey(raw);
  }

  static String? normalizeVPinKey(String raw) {
    final match = RegExp(r'^V(\d{1,3})$').firstMatch(raw.trim().toUpperCase());
    if (match == null) {
      return null;
    }
    final index = int.tryParse(match.group(1)!);
    if (index == null || index < 0 || index > 255) {
      return null;
    }
    return 'V$index';
  }

  static int compareBindingKeys(String left, String right) {
    final leftVPin = normalizeVPinKey(left);
    final rightVPin = normalizeVPinKey(right);
    if (leftVPin != null && rightVPin != null) {
      final leftIndex = int.tryParse(leftVPin.replaceFirst('V', '')) ?? 0;
      final rightIndex = int.tryParse(rightVPin.replaceFirst('V', '')) ?? 0;
      return leftIndex.compareTo(rightIndex);
    }
    if (leftVPin != null) {
      return -1;
    }
    if (rightVPin != null) {
      return 1;
    }
    return left.toLowerCase().compareTo(right.toLowerCase());
  }

  static String sourceGroupLabel(WidgetSettingsBindingSourceGroup group) {
    return switch (group) {
      WidgetSettingsBindingSourceGroup.virtualPin => 'Virtual Pin',
      WidgetSettingsBindingSourceGroup.deviceStatus => 'Device Status',
      WidgetSettingsBindingSourceGroup.deviceState => 'Device State',
      WidgetSettingsBindingSourceGroup.control => 'Control',
    };
  }

  static String sourceLabelForKey(String key) {
    final catalogEntry = entryFor(key);
    if (catalogEntry != null) {
      return '${sourceGroupLabel(catalogEntry.group)} / ${catalogEntry.name}';
    }

    final normalizedKey = canonicalBindingKey(key) ?? key.trim();
    if (DashboardItemRuntimeBinding.isVirtualPinBinding(normalizedKey)) {
      return 'Virtual Pin / ${normalizedKey.toUpperCase()}';
    }

    final readKey = DashboardItemRuntimeBinding.canonicalReadKey(normalizedKey);
    if (readKey != null) {
      if (readKey.startsWith('status.')) {
        return 'Device Status / ${readKey.substring('status.'.length)}';
      }
      if (readKey.startsWith('units.')) {
        return 'Advanced / $readKey';
      }
      return 'Device State / $readKey';
    }

    final writeKey = DashboardItemRuntimeBinding.canonicalWriteKey(
      normalizedKey,
    );
    if (writeKey != null) {
      return 'Control / ${writeKey.substring(writeKey.indexOf('.') + 1)}';
    }

    return 'Advanced / $normalizedKey';
  }

  static String normalizeBindingMode(String raw) {
    const allowed = <String>{'read', 'write', 'read_write'};
    final normalized = raw.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'read';
  }

  static String normalizeDataType(String raw) {
    const allowed = <String>{'number', 'integer', 'bool', 'string'};
    final normalized = raw.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'number';
  }

  static String normalizeSendBehavior(String raw) {
    const allowed = <String>{'on_release', 'on_drag', 'push', 'switch'};
    final normalized = raw.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'on_release';
  }

  static String normalizeButtonMode(String raw) {
    final normalized = normalizeSendBehavior(raw);
    return normalized == 'push' ? 'push' : 'switch';
  }

  static double coerceByDataType({
    required double value,
    required String dataType,
  }) {
    switch (normalizeDataType(dataType)) {
      case 'bool':
        return value >= 0.5 ? 1.0 : 0.0;
      case 'integer':
        return value.roundToDouble();
      case 'number':
      case 'string':
        return value;
    }
    return value;
  }
}
