import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alert_event_model.dart';

class LocalAlertNotificationService {
  LocalAlertNotificationService._();

  static final LocalAlertNotificationService instance =
      LocalAlertNotificationService._();

  static const AndroidNotificationChannel _alertsChannel =
      AndroidNotificationChannel(
        'princebot_alerts',
        'PrinceBot Alerts',
        description: 'Notifications for triggered alert rules.',
        importance: Importance.high,
      );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isAvailable = true;
  Future<void>? _initializeFuture;

  Future<void> initialize() async {
    if (!_isAvailable) {
      return;
    }
    if (_isInitialized) {
      return;
    }
    if (_initializeFuture != null) {
      await _initializeFuture;
      return;
    }

    _initializeFuture = _initializeInternal();
    try {
      await _initializeFuture;
    } finally {
      _initializeFuture = null;
    }
  }

  Future<void> showAlertEventNotification(AlertEventModel event) async {
    if (!_isAvailable) {
      return;
    }
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (_) {
        return;
      }
    }

    if (!_isInitialized) {
      return;
    }

    final notificationTitle = _alertEventTitle(event);
    final androidDetails = AndroidNotificationDetails(
      _alertsChannel.id,
      _alertsChannel.name,
      channelDescription: _alertsChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_alert',
      largeIcon: const DrawableResourceAndroidBitmap('logo_app_large'),
      styleInformation: BigTextStyleInformation(event.message),
    );

    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _notificationIdFromEvent(event.id),
      notificationTitle,
      event.message,
      details,
      payload: event.id,
    );
  }

  String _alertEventTitle(AlertEventModel event) {
    final dataKey = event.payload['dataKey']?.toString().trim() ?? '';
    if (dataKey.isEmpty) {
      return event.ruleTitle;
    }
    if (event.ruleTitle.toLowerCase().contains('(${dataKey.toLowerCase()})')) {
      return event.ruleTitle;
    }
    return '${event.ruleTitle} ($dataKey)';
  }

  int _notificationIdFromEvent(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }

  Future<void> _initializeInternal() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_alert'),
      );

      await _plugin.initialize(initializationSettings);

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_alertsChannel);
      await androidPlugin?.requestNotificationsPermission();

      _isInitialized = true;
    } catch (_) {
      _isAvailable = false;
      rethrow;
    }
  }
}
