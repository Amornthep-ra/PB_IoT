import '../../dashboard_builder/models/dashboard_item.dart';

enum AlertRuleCondition {
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  equalTo,
  notEqualTo,
  isOn,
  isOff,
  becameOn,
  becameOff,
}

enum AlertRuleSeverity {
  info,
  warning,
  critical,
}

class AlertRuleModel {
  const AlertRuleModel({
    required this.id,
    required this.title,
    required this.widgetId,
    required this.widgetTitle,
    required this.widgetType,
    required this.dataKey,
    required this.dataType,
    required this.condition,
    required this.message,
    required this.createdAt,
    this.thresholdValue,
    this.enabled = true,
    this.severity = AlertRuleSeverity.warning,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String widgetId;
  final String widgetTitle;
  final DashboardItemType widgetType;
  final String dataKey;
  final String dataType;
  final AlertRuleCondition condition;
  final double? thresholdValue;
  final String message;
  final bool enabled;
  final AlertRuleSeverity severity;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AlertRuleModel copyWith({
    String? id,
    String? title,
    String? widgetId,
    String? widgetTitle,
    DashboardItemType? widgetType,
    String? dataKey,
    String? dataType,
    AlertRuleCondition? condition,
    double? thresholdValue,
    bool clearThresholdValue = false,
    String? message,
    bool? enabled,
    AlertRuleSeverity? severity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertRuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      widgetId: widgetId ?? this.widgetId,
      widgetTitle: widgetTitle ?? this.widgetTitle,
      widgetType: widgetType ?? this.widgetType,
      dataKey: dataKey ?? this.dataKey,
      dataType: dataType ?? this.dataType,
      condition: condition ?? this.condition,
      thresholdValue: clearThresholdValue
          ? null
          : (thresholdValue ?? this.thresholdValue),
      message: message ?? this.message,
      enabled: enabled ?? this.enabled,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AlertRuleModel.fromJson(Map<String, dynamic> json) {
    return AlertRuleModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled rule',
      widgetId: json['widgetId']?.toString() ?? '',
      widgetTitle: json['widgetTitle']?.toString() ?? 'Unknown widget',
      widgetType: DashboardItemType.values.firstWhere(
        (value) => value.name == json['widgetType'],
        orElse: () => DashboardItemType.valueLabel,
      ),
      dataKey: json['dataKey']?.toString() ?? '',
      dataType: json['dataType']?.toString() ?? 'number',
      condition: AlertRuleCondition.values.firstWhere(
        (value) => value.name == json['condition'],
        orElse: () => AlertRuleCondition.lessThan,
      ),
      thresholdValue: (json['thresholdValue'] as num?)?.toDouble(),
      message: json['message']?.toString() ?? '',
      enabled: json['enabled'] != false,
      severity: AlertRuleSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => AlertRuleSeverity.warning,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'widgetId': widgetId,
      'widgetTitle': widgetTitle,
      'widgetType': widgetType.name,
      'dataKey': dataKey,
      'dataType': dataType,
      'condition': condition.name,
      'thresholdValue': thresholdValue,
      'message': message,
      'enabled': enabled,
      'severity': severity.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
