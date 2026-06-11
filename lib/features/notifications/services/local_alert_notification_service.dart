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
  Future<void>? _initializeFuture;

  Future<void> initialize() async {
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
    final details = _notificationDetails(event.message);
    try {
      await _plugin.show(
        _notificationIdFromEvent(event.id),
        notificationTitle,
        event.message,
        details,
        payload: event.id,
      );
    } catch (_) {}
  }

  Future<bool> showTestAlertNotification({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (_) {
        return false;
      }
    }

    if (!_isInitialized) {
      return false;
    }

    final details = _notificationDetails(message);
    try {
      await _plugin.show(
        DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
        title,
        message,
        details,
        payload: 'test_alert',
      );
      return true;
    } catch (_) {
      return false;
    }
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

  NotificationDetails _notificationDetails(String message) {
    final androidDetails = AndroidNotificationDetails(
      _alertsChannel.id,
      _alertsChannel.name,
      channelDescription: _alertsChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_alert',
      largeIcon: const DrawableResourceAndroidBitmap('princebot_logo_full'),
      styleInformation: BigTextStyleInformation(message),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      threadIdentifier: 'princebot_alerts',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  Future<void> _initializeInternal() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_alert'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
          defaultPresentBanner: true,
          defaultPresentList: true,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
          defaultPresentBanner: true,
          defaultPresentList: true,
        ),
      );

      await _plugin.initialize(initializationSettings);

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_alertsChannel);

      _isInitialized = true;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidEnabled = await androidPlugin?.areNotificationsEnabled();
    if (androidEnabled != null) {
      return androidEnabled;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosPermissions = await iosPlugin?.checkPermissions();
    if (iosPermissions != null) {
      return iosPermissions.isEnabled;
    }

    final macosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final macosPermissions = await macosPlugin?.checkPermissions();
    return macosPermissions?.isEnabled ?? true;
  }

  Future<bool> requestNotificationsPermission() async {
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();
    if (androidGranted != null) {
      return androidGranted;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      return iosGranted;
    }

    final macosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    return await macosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
  }
}
