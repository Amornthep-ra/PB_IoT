enum AppEventSeverity {
  info,
  warning,
  critical,
}

class AppEventModel {
  const AppEventModel({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.message,
    this.deviceId,
    this.severity = AppEventSeverity.info,
    this.isRead = false,
    this.payload = const <String, dynamic>{},
  });

  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  final String? message;
  final String? deviceId;
  final AppEventSeverity severity;
  final bool isRead;
  final Map<String, dynamic> payload;

  factory AppEventModel.fromJson(Map<String, dynamic> json) {
    return AppEventModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'unknown',
      title: json['title']?.toString() ?? 'Untitled event',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      message: json['message']?.toString(),
      deviceId: json['deviceId']?.toString(),
      severity: AppEventSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => AppEventSeverity.info,
      ),
      isRead: json['isRead'] == true,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
      'deviceId': deviceId,
      'severity': severity.name,
      'isRead': isRead,
      'payload': payload,
    };
  }
}
