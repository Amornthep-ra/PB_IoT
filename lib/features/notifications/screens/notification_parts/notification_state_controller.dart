part of '../notifications_screen.dart';

class _NotificationsScreenController extends ChangeNotifier {
  _NotificationsScreenController({
    required DashboardRuntimeController runtimeController,
    NotificationService? notificationService,
    DashboardBuilderLayoutStorageService? layoutStorage,
  }) : _runtimeController = runtimeController,
       _notificationService = notificationService ?? NotificationService(),
       _layoutStorage = layoutStorage ?? DashboardBuilderLayoutStorageService();

  final DashboardRuntimeController _runtimeController;
  final NotificationService _notificationService;
  final DashboardBuilderLayoutStorageService _layoutStorage;

  bool _isLoading = true;
  bool _isUpdatingEvents = false;
  List<AlertEventModel> _events = const <AlertEventModel>[];
  List<AlertEventModel> _historyEvents = const <AlertEventModel>[];
  List<AlertRuleModel> _rules = const <AlertRuleModel>[];
  Set<String> _availableWidgetIds = const <String>{};
  _AlertsPage _selectedPage = _AlertsPage.currentEvents;
  bool _isRulesExpanded = true;
  bool _didChooseRulesExpansion = false;

  bool get isLoading => _isLoading;
  bool get isUpdatingEvents => _isUpdatingEvents;
  List<AlertEventModel> get events => _events;
  List<AlertEventModel> get historyEvents => _historyEvents;
  List<AlertRuleModel> get rules => _rules;
  Set<String> get availableWidgetIds => _availableWidgetIds;
  _AlertsPage get selectedPage => _selectedPage;
  bool get isRulesExpanded => _isRulesExpanded;
  int get unreadCount => _events.where((event) => !event.isRead).length;

  Future<bool> shouldRequestNotificationPermission({
    required SharedPreferences preferences,
    required String promptSeenKey,
    required LocalAlertNotificationService localNotificationService,
  }) async {
    if (preferences.getBool(promptSeenKey) == true) {
      return false;
    }
    final notificationsEnabled = await localNotificationService
        .areNotificationsEnabled();
    return !notificationsEnabled;
  }

  void handleRuntimeChanged() {
    unawaited(loadData(showLoading: false));
  }

  Future<void> loadData({bool showLoading = true}) async {
    if (showLoading && !_isLoading) {
      _isLoading = true;
      notifyListeners();
    } else if (showLoading) {
      _isLoading = true;
    }

    final events = List<AlertEventModel>.from(
      await _notificationService.loadEvents(),
    )..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final historyEvents = List<AlertEventModel>.from(
      await _notificationService.loadHistoryEvents(),
    )..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final rules =
        List<AlertRuleModel>.from(await _notificationService.loadRules())
          ..sort((left, right) {
            final leftAt = left.updatedAt ?? left.createdAt;
            final rightAt = right.updatedAt ?? right.createdAt;
            return rightAt.compareTo(leftAt);
          });

    final items = await _layoutStorage.loadItems();
    final availableWidgetIds = (items ?? const <DashboardItem>[])
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    _events = List<AlertEventModel>.unmodifiable(events);
    _historyEvents = List<AlertEventModel>.unmodifiable(historyEvents);
    _rules = List<AlertRuleModel>.unmodifiable(rules);
    _availableWidgetIds = Set<String>.unmodifiable(availableWidgetIds);
    if (!_didChooseRulesExpansion) {
      _isRulesExpanded = rules.length <= 3;
    }
    _isLoading = false;
    notifyListeners();
  }

  void setSelectedPage(_AlertsPage page) {
    if (_selectedPage == page) {
      return;
    }
    _selectedPage = page;
    notifyListeners();
  }

  void toggleRulesExpanded() {
    _didChooseRulesExpansion = true;
    _isRulesExpanded = !_isRulesExpanded;
    notifyListeners();
  }

  Future<void> markEventRead(AlertEventModel event) async {
    if (_isUpdatingEvents || event.isRead) {
      return;
    }

    _isUpdatingEvents = true;
    _events = _events
        .map(
          (entry) =>
              entry.id == event.id ? entry.copyWith(isRead: true) : entry,
        )
        .toList(growable: false);
    _historyEvents = _historyEvents
        .map(
          (entry) =>
              entry.id == event.id ? entry.copyWith(isRead: true) : entry,
        )
        .toList(growable: false);
    notifyListeners();

    try {
      await _notificationService.markEventRead(event.id, isRead: true);
    } finally {
      _isUpdatingEvents = false;
      notifyListeners();
    }
  }

  Future<void> markAllEventsRead() async {
    if (_isUpdatingEvents || unreadCount == 0) {
      return;
    }

    _isUpdatingEvents = true;
    _events = _events
        .map((event) => event.isRead ? event : event.copyWith(isRead: true))
        .toList(growable: false);
    _historyEvents = _historyEvents
        .map((event) => event.isRead ? event : event.copyWith(isRead: true))
        .toList(growable: false);
    notifyListeners();

    try {
      await _notificationService.markAllEventsRead();
    } finally {
      _isUpdatingEvents = false;
      notifyListeners();
    }
  }

  bool canMutateEvents() => !_isUpdatingEvents;
  bool hasCurrentEvents() => _events.isNotEmpty;
  bool hasHistoryEvents() => _historyEvents.isNotEmpty;

  void removeCurrentEventsOptimistically() {
    _isUpdatingEvents = true;
    _events = const <AlertEventModel>[];
    notifyListeners();
  }

  Future<void> persistCurrentEventsCleared() async {
    try {
      await _notificationService.clearEvents();
    } finally {
      _isUpdatingEvents = false;
      notifyListeners();
    }
  }

  void removeHistoryEventOptimistically(AlertEventModel event) {
    _isUpdatingEvents = true;
    _historyEvents = _historyEvents
        .where((entry) => entry.id != event.id)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> persistHistoryEventDeleted(String eventId) async {
    try {
      await _notificationService.deleteHistoryEvent(eventId);
    } finally {
      _isUpdatingEvents = false;
      notifyListeners();
    }
  }

  void clearHistoryOptimistically() {
    _isUpdatingEvents = true;
    _historyEvents = const <AlertEventModel>[];
    notifyListeners();
  }

  Future<void> persistAllHistoryCleared() async {
    try {
      await _notificationService.clearHistoryEvents();
    } finally {
      _isUpdatingEvents = false;
      notifyListeners();
    }
  }

  Future<void> restoreHistory(List<AlertEventModel> history) async {
    await _notificationService.saveHistoryEvents(history);
    _historyEvents = List<AlertEventModel>.unmodifiable(history);
    notifyListeners();
  }

  Future<void> applyRulesSnapshot(List<AlertRuleModel> rules) async {
    _isUpdatingEvents = true;
    _rules = List<AlertRuleModel>.unmodifiable(rules);
    notifyListeners();

    try {
      await _notificationService.saveRules(rules);
      await _runtimeController.reloadAlertRules();
    } finally {
      _isUpdatingEvents = false;
      notifyListeners();
    }
  }

  Future<void> restoreRules(List<AlertRuleModel> rules) async {
    await _notificationService.saveRules(rules);
    await _runtimeController.reloadAlertRules();
    _rules = List<AlertRuleModel>.unmodifiable(rules);
    notifyListeners();
  }
}
