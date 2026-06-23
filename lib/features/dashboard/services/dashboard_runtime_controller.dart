import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../dashboard_builder/models/dashboard_item.dart';
import '../../dashboard_builder/models/dashboard_theme_preset.dart';
import '../../dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import '../../projects/services/project_state.dart';
import '../../notifications/models/alert_event_model.dart';
import '../../notifications/models/alert_rule_model.dart';
import '../../notifications/services/local_alert_notification_service.dart';
import '../../notifications/services/notification_service.dart';
import '../models/device_snapshot_model.dart';
import 'dashboard_alert_evaluator.dart';
import 'dashboard_item_runtime_binding.dart';
import 'dashboard_polling_driver.dart';
import 'dashboard_snapshot_refresher.dart';
import 'dashboard_service.dart';
import 'dashboard_runtime_value_storage.dart';

typedef DashboardAlertNotificationCallback =
    Future<void> Function(AlertEventModel event);

class DashboardRuntimeController extends ChangeNotifier
    with WidgetsBindingObserver {
  DashboardRuntimeController({
    DashboardBuilderLayoutStorageService? layoutStorage,
    DashboardService? dashboardService,
    NotificationService? notificationService,
    DashboardSnapshotRefresher? snapshotRefresher,
    DashboardPollingDriver? pollingDriver,
    DashboardAlertEvaluator? alertEvaluator,
    DashboardAlertNotificationCallback? alertNotificationCallback,
  }) : _layoutStorage = layoutStorage ?? DashboardBuilderLayoutStorageService(),
       _dashboardService = dashboardService ?? DashboardService(),
       _notificationService = notificationService ?? NotificationService(),
       _snapshotRefresher =
           snapshotRefresher ??
           DashboardSnapshotRefresher(
             dashboardService: dashboardService ?? DashboardService(),
           ) {
    _pollingDriver =
        pollingDriver ??
        DashboardPollingDriver(
          pollInterval: _pollInterval,
          onPoll: refreshSnapshotFromServer,
        );
    _alertEvaluator = alertEvaluator ?? DashboardAlertEvaluator();
    _alertNotificationCallback =
        alertNotificationCallback ??
        LocalAlertNotificationService.instance.showAlertEventNotification;
  }

  static const Duration _pollInterval = Duration(seconds: 2);

  final DashboardBuilderLayoutStorageService _layoutStorage;
  final DashboardService _dashboardService;
  final NotificationService _notificationService;
  final DashboardSnapshotRefresher _snapshotRefresher;
  late final DashboardPollingDriver _pollingDriver;
  late final DashboardAlertEvaluator _alertEvaluator;
  late final DashboardAlertNotificationCallback _alertNotificationCallback;
  final DashboardRuntimeValueStorage _runtimeValueStorage =
      DashboardRuntimeValueStorage();

  List<DashboardItem> _items = const <DashboardItem>[];
  List<AlertRuleModel> _alertRules = const <AlertRuleModel>[];
  DeviceSnapshotModel? _snapshot;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _errorText;
  String _dashboardTitle = _resolveDashboardTitle();
  DashboardThemePreset _themePreset = dashboardThemePresets.first;

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
    _pollingDriver.dispose();
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
    if (_isLoading) {
      final shouldAllowForegroundPolling =
          state == AppLifecycleState.resumed ||
          state == AppLifecycleState.inactive;
      if (_pollingDriver.isForegroundPollingAllowed !=
          shouldAllowForegroundPolling) {
        _pollingDriver.handleLifecycleState(state);
      }
      return;
    }

    _pollingDriver.handleLifecycleState(state);
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
      final previousItems = List<DashboardItem>.from(_items);
      final result = await _snapshotRefresher.refresh();
      final snapshot = result.snapshot;
      if (snapshot != null) {
        final hydratedItems = _applySnapshotToItems(_items, snapshot);
        _snapshot = snapshot;
        _items = hydratedItems;
        _errorText = null;
        _notifyIfActive();
        await _evaluateAlertRules(
          previousItems: previousItems,
          nextItems: hydratedItems,
        );
        return;
      }

      _errorText = result.errorText;
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
    if (initialLoad) {
      _isLoading = true;
    }

    try {
      dashboardTitle = _resolveDashboardTitle();
      final storedItems = await _layoutStorage.loadItems();
      final alertRules = await _notificationService.loadRules();
      final snapshot = await _dashboardService.fetchRuntimeSnapshot();

      final nextItems = await _runtimeValueStorage.applyToItems(
        storedItems ?? const <DashboardItem>[],
      );
      await _runtimeValueStorage.pruneForItems(nextItems);
      final hydratedItems = _applySnapshotToItems(nextItems, snapshot);
      _dashboardTitle = dashboardTitle;
      _themePreset = dashboardThemePresets.first;
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
      _pollingDriver.start();
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
    final storedItems = await _layoutStorage.loadItems();
    final alertRules = await _notificationService.loadRules();
    final nextItems = await _runtimeValueStorage.applyToItems(
      storedItems ?? const <DashboardItem>[],
    );
    await _runtimeValueStorage.pruneForItems(nextItems);
    final snapshot = DeviceSnapshotModel(error: errorText);

    _dashboardTitle = dashboardTitle;
    _themePreset = dashboardThemePresets.first;
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
    _pollingDriver.start();
  }

  static String _resolveDashboardTitle() {
    final projectName = ProjectState.current?.name.trim() ?? '';
    if (projectName.isNotEmpty) {
      return projectName;
    }
    return DashboardBuilderLayoutStorageService.defaultDashboardTitle;
  }

  List<DashboardItem> _applySnapshotToItems(
    List<DashboardItem> items,
    DeviceSnapshotModel snapshot,
  ) {
    return items
        .map(
          (item) => DashboardItemRuntimeValueMapper.applySnapshotValue(
            item: item,
            snapshot: snapshot,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _evaluateAlertRules({
    required List<DashboardItem> previousItems,
    required List<DashboardItem> nextItems,
  }) async {
    final result = _alertEvaluator.evaluate(
      rules: _alertRules,
      previousItems: previousItems,
      nextItems: nextItems,
    );
    final eventsToAppend = result.newEvents;

    for (final event in eventsToAppend) {
      await _notificationService.appendEvent(event);
      await _alertNotificationCallback(event);
    }

    if (eventsToAppend.isNotEmpty) {
      _notifyIfActive();
    }
  }
}
