import 'alert_rule_model.dart';

class AlertEventModel {
  const AlertEventModel({
    required this.id,
    required this.ruleId,
    required this.ruleTitle,
    required this.widgetId,
    required this.widgetTitle,
    required this.message,
    required this.createdAt,
    this.severity = AlertRuleSeverity.warning,
    this.isRead = false,
    this.payload = const <String, dynamic>{},
  });

  final String id;
  final String ruleId;
  final String ruleTitle;
  final String widgetId;
  final String widgetTitle;
  final String message;
  final DateTime createdAt;
  final AlertRuleSeverity severity;
  final bool isRead;
  final Map<String, dynamic> payload;

  AlertEventModel copyWith({
    String? id,
    String? ruleId,
    String? ruleTitle,
    String? widgetId,
    String? widgetTitle,
    String? message,
    DateTime? createdAt,
    AlertRuleSeverity? severity,
    bool? isRead,
    Map<String, dynamic>? payload,
  }) {
    return AlertEventModel(
      id: id ?? this.id,
      ruleId: ruleId ?? this.ruleId,
      ruleTitle: ruleTitle ?? this.ruleTitle,
      widgetId: widgetId ?? this.widgetId,
      widgetTitle: widgetTitle ?? this.widgetTitle,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      severity: severity ?? this.severity,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }

  factory AlertEventModel.fromJson(Map<String, dynamic> json) {
    return AlertEventModel(
      id: json['id']?.toString() ?? '',
      ruleId: json['ruleId']?.toString() ?? '',
      ruleTitle: json['ruleTitle']?.toString() ?? 'Untitled rule',
      widgetId: json['widgetId']?.toString() ?? '',
      widgetTitle: json['widgetTitle']?.toString() ?? 'Unknown widget',
      message: json['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      severity: AlertRuleSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => AlertRuleSeverity.warning,
      ),
      isRead: json['isRead'] == true,
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ruleId': ruleId,
      'ruleTitle': ruleTitle,
      'widgetId': widgetId,
      'widgetTitle': widgetTitle,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'severity': severity.name,
      'isRead': isRead,
      'payload': payload,
    };
  }
}
