import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../services/auth_service.dart';
import '../../../services/profile_avatar_preset_storage.dart';
import '../../../services/session_snapshot_storage.dart';
import '../../../services/session_state.dart';
import '../../dashboard_builder/models/dashboard_item.dart';
import '../../dashboard_builder/models/dashboard_theme_preset.dart';
import '../../dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import '../../projects/services/project_state.dart';
import '../../notifications/models/alert_event_model.dart';
import '../../notifications/models/alert_rule_model.dart';
import '../../notifications/services/local_alert_notification_service.dart';
import '../../notifications/services/notification_service.dart';
import '../models/device_snapshot_model.dart';
import 'dashboard_service.dart';
import 'dashboard_runtime_value_storage.dart';

class DashboardRuntimeController extends ChangeNotifier
    with WidgetsBindingObserver {
  DashboardRuntimeController({
    DashboardBuilderLayoutStorageService? layoutStorage,
    DashboardService? dashboardService,
    NotificationService? notificationService,
  }) : _layoutStorage = layoutStorage ?? DashboardBuilderLayoutStorageService(),
       _dashboardService = dashboardService ?? DashboardService(),
       _notificationService = notificationService ?? NotificationService();

  static const Duration _pollInterval = Duration(seconds: 2);
  static const Duration _sessionRecoveryThrottle = Duration(seconds: 60);

  final DashboardBuilderLayoutStorageService _layoutStorage;
  final DashboardService _dashboardService;
  final NotificationService _notificationService;
  final DashboardRuntimeValueStorage _runtimeValueStorage =
      DashboardRuntimeValueStorage();
  final AuthService _authService = AuthService();
  final Map<String, bool> _alertRuleActiveStates = <String, bool>{};

  List<DashboardItem> _items = const <DashboardItem>[];
  List<AlertRuleModel> _alertRules = const <AlertRuleModel>[];
  Timer? _pollTimer;
  DeviceSnapshotModel? _snapshot;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isAppInForeground = true;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isRecoveringSession = false;
  String? _errorText;
  String _dashboardTitle = _resolveDashboardTitle();
  DashboardThemePreset _themePreset = dashboardThemePresets.first;
  DateTime? _lastSessionRecoveryAttemptAt;

  List<DashboardItem> get items => List<DashboardItem>.unmodifiable(_items);
  DeviceSnapshotModel? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorText => _errorText;
  String get dashboardTitle => _dashboardTitle;
  DashboardThemePreset get themePreset => _themePreset;

  /// Cross-screen signal used to request that the dashboard view scroll to
  /// and flash-highlight a specific widget (identified by [DashboardItem.id]).
  /// Consumers call [requestHighlightItem]; listeners on this notifier react
  /// to the new id and then call [consumeHighlightRequest] once handled.
  final ValueNotifier<String?> highlightItemIdNotifier = ValueNotifier<String?>(
    null,
  );

  void requestHighlightItem(String itemId) {
    highlightItemIdNotifier.value = itemId;
  }

  void consumeHighlightRequest() {
    highlightItemIdNotifier.value = null;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _loadRuntimeData(initialLoad: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    highlightItemIdNotifier.dispose();
    _isDisposed = true;
    super.dispose();
  }

  void _notifyIfActive() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldPoll =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (_isAppInForeground == shouldPoll) {
      return;
    }

    _isAppInForeground = shouldPoll;
    if (!shouldPoll) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    if (!_isLoading) {
      _startPolling();
      unawaited(refreshSnapshotFromServer());
    }
  }

  Future<void> reloadFromStorageAndSnapshot() async {
    await _loadRuntimeData(initialLoad: false);
  }

  Future<void> reloadAlertRules() async {
    _alertRules = List<AlertRuleModel>.unmodifiable(
      await _notificationService.loadRules(),
    );
    _notifyIfActive();
  }

  Future<void> refreshSnapshotFromServer() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    try {
      final refreshError = await _tryRefreshSnapshot();
      if (refreshError == null) {
        return;
      }

      final recovered = await _recoverSessionAndRetrySnapshot();
      if (recovered) {
        return;
      }

      _errorText = refreshError;
      _notifyIfActive();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> updateRuntimeItems(List<DashboardItem> nextItems) async {
    final previousItems = List<DashboardItem>.from(_items);
    _items = List<DashboardItem>.unmodifiable(nextItems);
    _notifyIfActive();
    await _runtimeValueStorage.saveFromItems(_items);
    await _evaluateAlertRules(previousItems: previousItems, nextItems: _items);
  }

  Future<void> _loadRuntimeData({required bool initialLoad}) async {
    String dashboardTitle =
        DashboardBuilderLayoutStorageService.defaultDashboardTitle;
    var themePreset = dashboardThemePresets.first;
    if (initialLoad) {
      _isLoading = true;
    }

    try {
      dashboardTitle = _resolveDashboardTitle();
      themePreset = await _layoutStorage.loadDashboardThemePreset();
      final storedItems = await _layoutStorage.loadItems();
      final alertRules = await _notificationService.loadRules();
      final snapshot = await _dashboardService.fetchRuntimeSnapshot();

      final nextItems = await _runtimeValueStorage.applyToItems(
        storedItems ?? const <DashboardItem>[],
      );
      await _runtimeValueStorage.pruneForItems(nextItems);
      final hydratedItems = _applySnapshotToItems(nextItems, snapshot);
      _dashboardTitle = dashboardTitle;
      _themePreset = themePreset;
      _items = hydratedItems;
      _snapshot = snapshot;
      _alertRules = List<AlertRuleModel>.unmodifiable(alertRules);
      _errorText = null;
      _isLoading = false;
      _notifyIfActive();
      await _evaluateAlertRules(
        previousItems: const <DashboardItem>[],
        nextItems: hydratedItems,
      );
      if (_isAppInForeground) {
        _startPolling();
      }
    } on DashboardServiceException catch (error) {
      await _loadOfflineRuntimeFallback(
        dashboardTitle: dashboardTitle,
        errorText: error.message,
      );
    } catch (_) {
      await _loadOfflineRuntimeFallback(
        dashboardTitle: dashboardTitle,
        errorText: initialLoad
            ? 'ไม่สามารถโหลดข้อมูล Dashboard ได้ในขณะนี้'
            : 'ไม่สามารถรีเฟรชข้อมูล Dashboard ได้ในขณะนี้',
      );
    }
  }

  Future<void> _loadOfflineRuntimeFallback({
    required String dashboardTitle,
    required String errorText,
  }) async {
    final themePreset = await _layoutStorage.loadDashboardThemePreset();
    final storedItems = await _layoutStorage.loadItems();
    final alertRules = await _notificationService.loadRules();
    final nextItems = await _runtimeValueStorage.applyToItems(
      storedItems ?? const <DashboardItem>[],
    );
    await _runtimeValueStorage.pruneForItems(nextItems);
    final snapshot = DeviceSnapshotModel(error: errorText);

    _dashboardTitle = dashboardTitle;
    _themePreset = themePreset;
    _items = nextItems;
    _snapshot = snapshot;
    _alertRules = List<AlertRuleModel>.unmodifiable(alertRules);
    _errorText = errorText;
    _isLoading = false;
    _notifyIfActive();
    await _evaluateAlertRules(
      previousItems: const <DashboardItem>[],
      nextItems: nextItems,
    );
    if (_isAppInForeground) {
      _startPolling();
    }
  }

  static String _resolveDashboardTitle() {
    final projectName = ProjectState.current?.name.trim() ?? '';
    if (projectName.isNotEmpty) {
      return projectName;
    }
    return DashboardBuilderLayoutStorageService.defaultDashboardTitle;
  }

  void _startPolling() {
    if (!_isAppInForeground) {
      return;
    }
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => unawaited(refreshSnapshotFromServer()),
    );
  }

  Future<String?> _tryRefreshSnapshot() async {
    try {
      final previousItems = List<DashboardItem>.from(_items);
      final snapshot = await _dashboardService.fetchRuntimeSnapshot();
      final hydratedItems = _applySnapshotToItems(_items, snapshot);
      _snapshot = snapshot;
      _items = hydratedItems;
      _errorText = null;
      _notifyIfActive();
      await _evaluateAlertRules(
        previousItems: previousItems,
        nextItems: hydratedItems,
      );
      return null;
    } on DashboardServiceException catch (error) {
      return error.message;
    } catch (_) {
      return 'ไม่สามารถรีเฟรชข้อมูล Dashboard ได้ในขณะนี้';
    }
  }

  Future<bool> _recoverSessionAndRetrySnapshot() async {
    final currentSession = SessionState.current;
    if (currentSession?.isOfflineMode != true) {
      return false;
    }
    if (_isRecoveringSession) {
      return false;
    }

    final now = DateTime.now();
    final lastAttemptAt = _lastSessionRecoveryAttemptAt;
    if (lastAttemptAt != null &&
        now.difference(lastAttemptAt) < _sessionRecoveryThrottle) {
      return false;
    }

    _isRecoveringSession = true;
    _lastSessionRecoveryAttemptAt = now;

    try {
      final refreshedSession = await _authService.fetchCurrentSession();
      if (refreshedSession == null) {
        return false;
      }

      var mergedSession = refreshedSession.copyWith(
        token: refreshedSession.token.trim().isNotEmpty
            ? refreshedSession.token
            : currentSession?.token,
        displayName: refreshedSession.displayName.trim().isNotEmpty
            ? refreshedSession.displayName
            : currentSession?.displayName,
      );
      mergedSession = await ProfileAvatarPresetStorage.applyStoredAvatar(
        mergedSession,
      );

      final synchronizedSession = mergedSession.copyWith(
        cachedProfileImagePath: '',
        isOfflineMode: false,
      );
      SessionState.current = synchronizedSession;
      await SessionSnapshotStorage.save(synchronizedSession);

      return await _tryRefreshSnapshot() == null;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRecoveringSession = false;
    }
  }

  List<DashboardItem> _applySnapshotToItems(
    List<DashboardItem> items,
    DeviceSnapshotModel snapshot,
  ) {
    return items
        .map((item) {
          final pin = _extractVirtualPin(item.dataKey);
          if (pin == null) {
            return item;
          }

          final mode = item.bindingMode.trim().toLowerCase();
          if (mode == 'write') {
            return item;
          }

          if (!snapshot.virtualPins.containsKey(pin)) {
            return item;
          }

          final incoming = snapshot.virtualPins[pin];
          switch (item.type) {
            case DashboardItemType.button:
            case DashboardItemType.toggle:
              final enabled = _coerceBool(incoming);
              if (enabled == null) {
                return item;
              }
              return item.copyWith(
                enabled: enabled,
                value: enabled ? 1.0 : 0.0,
              );
            case DashboardItemType.slider:
            case DashboardItemType.stepH:
            case DashboardItemType.stepV:
            case DashboardItemType.gauge:
            case DashboardItemType.valueLabel:
              final numeric = _coerceDouble(incoming);
              if (numeric == null) {
                return item;
              }
              final clampedNumeric = numeric
                  .clamp(item.minValue, item.maxValue)
                  .toDouble();
              return item.copyWith(value: clampedNumeric);
          }
        })
        .toList(growable: false);
  }

  Future<void> _evaluateAlertRules({
    required List<DashboardItem> previousItems,
    required List<DashboardItem> nextItems,
  }) async {
    if (_alertRules.isEmpty) {
      return;
    }

    final previousById = <String, DashboardItem>{
      for (final item in previousItems) item.id: item,
    };
    final nextById = <String, DashboardItem>{
      for (final item in nextItems) item.id: item,
    };
    final eventsToAppend = <AlertEventModel>[];

    for (final rule in _alertRules) {
      if (!rule.enabled) {
        _alertRuleActiveStates[rule.id] = false;
        continue;
      }

      final nextItem = nextById[rule.widgetId];
      if (nextItem == null) {
        _alertRuleActiveStates[rule.id] = false;
        continue;
      }

      final previousItem = previousById[rule.widgetId];
      final isActiveNow = _doesRuleMatch(
        rule: rule,
        previousItem: previousItem,
        nextItem: nextItem,
      );
      final wasActiveBefore = _alertRuleActiveStates[rule.id] == true;

      if (isActiveNow && !wasActiveBefore) {
        eventsToAppend.add(
          AlertEventModel(
            id: 'event_${rule.id}_${DateTime.now().microsecondsSinceEpoch}',
            ruleId: rule.id,
            ruleTitle: rule.title,
            widgetId: rule.widgetId,
            widgetTitle: rule.widgetTitle,
            message: rule.message,
            createdAt: DateTime.now(),
            severity: rule.severity,
            payload: <String, dynamic>{
              'widgetType': rule.widgetType.name,
              'dataKey': rule.dataKey,
              'value': _serializeWidgetValue(nextItem),
            },
          ),
        );
      }

      _alertRuleActiveStates[rule.id] = isActiveNow;
    }

    for (final event in eventsToAppend) {
      await _notificationService.appendEvent(event);
      await LocalAlertNotificationService.instance.showAlertEventNotification(
        event,
      );
    }

    if (eventsToAppend.isNotEmpty) {
      _notifyIfActive();
    }
  }

  bool _doesRuleMatch({
    required AlertRuleModel rule,
    required DashboardItem? previousItem,
    required DashboardItem nextItem,
  }) {
    switch (rule.condition) {
      case AlertRuleCondition.lessThan:
      case AlertRuleCondition.lessThanOrEqual:
      case AlertRuleCondition.greaterThan:
      case AlertRuleCondition.greaterThanOrEqual:
      case AlertRuleCondition.equalTo:
      case AlertRuleCondition.notEqualTo:
        final currentValue = _numericValueForItem(nextItem);
        final threshold = rule.thresholdValue;
        if (currentValue == null || threshold == null) {
          return false;
        }
        return switch (rule.condition) {
          AlertRuleCondition.lessThan => currentValue < threshold,
          AlertRuleCondition.lessThanOrEqual => currentValue <= threshold,
          AlertRuleCondition.greaterThan => currentValue > threshold,
          AlertRuleCondition.greaterThanOrEqual => currentValue >= threshold,
          AlertRuleCondition.equalTo => currentValue == threshold,
          AlertRuleCondition.notEqualTo => currentValue != threshold,
          _ => false,
        };
      case AlertRuleCondition.isOn:
        return _boolValueForItem(nextItem) == true;
      case AlertRuleCondition.isOff:
        return _boolValueForItem(nextItem) == false;
      case AlertRuleCondition.becameOn:
        return _boolValueForItem(previousItem) != true &&
            _boolValueForItem(nextItem) == true;
      case AlertRuleCondition.becameOff:
        return _boolValueForItem(previousItem) != false &&
            _boolValueForItem(nextItem) == false;
    }
  }

  double? _numericValueForItem(DashboardItem? item) {
    if (item == null) {
      return null;
    }
    return switch (item.type) {
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => item.value,
      DashboardItemType.button ||
      DashboardItemType.toggle => item.enabled ? 1 : 0,
    };
  }

  bool? _boolValueForItem(DashboardItem? item) {
    if (item == null) {
      return null;
    }
    return switch (item.type) {
      DashboardItemType.button || DashboardItemType.toggle => item.enabled,
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => _coerceBool(item.value),
    };
  }

  Object _serializeWidgetValue(DashboardItem item) {
    return switch (item.type) {
      DashboardItemType.button || DashboardItemType.toggle => item.enabled,
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => item.value,
    };
  }

  String? _extractVirtualPin(String? rawKey) {
    final value = rawKey?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final match = RegExp(r'V\d+', caseSensitive: false).firstMatch(value);
    return match?.group(0)?.toUpperCase();
  }

  bool? _coerceBool(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw >= 0.5;
    }
    final text = raw.toString().trim().toLowerCase();
    if (text == '1' || text == 'true' || text == 'on') {
      return true;
    }
    if (text == '0' || text == 'false' || text == 'off') {
      return false;
    }
    return null;
  }

  double? _coerceDouble(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is bool) {
      return raw ? 1.0 : 0.0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString().trim());
  }
}
