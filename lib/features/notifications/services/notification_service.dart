import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../projects/services/project_state.dart';
import '../models/alert_event_model.dart';
import '../models/alert_rule_model.dart';

class NotificationService {
  NotificationService({
    SharedPreferences? preferences,
    this.rulesStorageKey = _defaultRulesStorageKey,
    this.eventsStorageKey = _defaultEventsStorageKey,
    this.historyStorageKey = _defaultHistoryStorageKey,
  }) : _preferences = preferences;

  static const String _defaultRulesStorageKey = 'alerts_rules_v1';
  static const String _defaultEventsStorageKey = 'alerts_events_v1';
  static const String _defaultHistoryStorageKey = 'alerts_history_v1';

  final SharedPreferences? _preferences;
  final String rulesStorageKey;
  final String eventsStorageKey;
  final String historyStorageKey;

  String get _effectiveRulesStorageKey => _projectScopedKey(rulesStorageKey);
  String get _effectiveEventsStorageKey => _projectScopedKey(eventsStorageKey);
  String get _effectiveHistoryStorageKey =>
      _projectScopedKey(historyStorageKey);

  Future<List<AlertRuleModel>> loadRules() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(_effectiveRulesStorageKey);
    return _decodeRules(raw);
  }

  Future<void> saveRules(List<AlertRuleModel> rules) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final payload = rules.map((rule) => rule.toJson()).toList();
    await preferences.setString(_effectiveRulesStorageKey, jsonEncode(payload));
  }

  Future<List<AlertEventModel>> loadEvents() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(_effectiveEventsStorageKey);
    return _decodeEvents(raw);
  }

  Future<void> saveEvents(List<AlertEventModel> events) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final payload = events.map((event) => event.toJson()).toList();
    await preferences.setString(_effectiveEventsStorageKey, jsonEncode(payload));
  }

  Future<List<AlertEventModel>> loadHistoryEvents() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final historyRaw = preferences.getString(_effectiveHistoryStorageKey);
    final currentRaw = preferences.getString(_effectiveEventsStorageKey);

    final history = _decodeEvents(historyRaw);
    if (history.isNotEmpty) {
      return history;
    }

    final migrated = _decodeEvents(currentRaw);
    if (migrated.isNotEmpty) {
      await saveHistoryEvents(migrated);
    }
    return migrated;
  }

  Future<void> saveHistoryEvents(List<AlertEventModel> events) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final payload = events.map((event) => event.toJson()).toList();
    await preferences.setString(
      _effectiveHistoryStorageKey,
      jsonEncode(payload),
    );
  }

  Future<void> appendEvent(AlertEventModel event) async {
    final current = List<AlertEventModel>.from(await loadEvents());
    final history = List<AlertEventModel>.from(await loadHistoryEvents());
    final nextCurrent = <AlertEventModel>[event, ...current];
    final nextHistory = <AlertEventModel>[event, ...history];
    await saveEvents(nextCurrent);
    await saveHistoryEvents(nextHistory);
  }

  Future<void> markEventRead(
    String eventId, {
    bool isRead = true,
  }) async {
    final current = _updateReadFlag(
      events: List<AlertEventModel>.from(await loadEvents()),
      eventId: eventId,
      isRead: isRead,
    );
    final history = _updateReadFlag(
      events: List<AlertEventModel>.from(await loadHistoryEvents()),
      eventId: eventId,
      isRead: isRead,
    );
    await saveEvents(current);
    await saveHistoryEvents(history);
  }

  Future<void> markAllEventsRead() async {
    final current = List<AlertEventModel>.from(await loadEvents());
    final history = List<AlertEventModel>.from(await loadHistoryEvents());

    final nextCurrent = current
        .map((event) => event.isRead ? event : event.copyWith(isRead: true))
        .toList();
    final nextHistory = history
        .map((event) => event.isRead ? event : event.copyWith(isRead: true))
        .toList();

    await saveEvents(nextCurrent);
    await saveHistoryEvents(nextHistory);
  }

  Future<void> clearRules() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_effectiveRulesStorageKey);
  }

  Future<void> clearEvents() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_effectiveEventsStorageKey);
  }

  Future<void> clearHistoryEvents() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_effectiveHistoryStorageKey);
  }

  Future<void> deleteHistoryEvent(String eventId) async {
    final history = List<AlertEventModel>.from(await loadHistoryEvents());
    final nextHistory = history
        .where((event) => event.id != eventId)
        .toList(growable: false);
    await saveHistoryEvents(nextHistory);
  }

  List<AlertRuleModel> _decodeRules(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <AlertRuleModel>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return const <AlertRuleModel>[];
    }

    final rules = <AlertRuleModel>[];
    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      rules.add(AlertRuleModel.fromJson(Map<String, dynamic>.from(entry)));
    }
    return rules;
  }

  List<AlertEventModel> _decodeEvents(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <AlertEventModel>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return const <AlertEventModel>[];
    }

    final events = <AlertEventModel>[];
    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      events.add(AlertEventModel.fromJson(Map<String, dynamic>.from(entry)));
    }
    return events;
  }

  List<AlertEventModel> _updateReadFlag({
    required List<AlertEventModel> events,
    required String eventId,
    required bool isRead,
  }) {
    final index = events.indexWhere((event) => event.id == eventId);
    if (index < 0) {
      return events;
    }

    events[index] = events[index].copyWith(isRead: isRead);
    return events;
  }

  String _projectScopedKey(String baseKey) {
    final projectId = ProjectState.current?.id.trim();
    if (projectId == null || projectId.isEmpty) {
      return baseKey;
    }
    return '${baseKey}_$projectId';
  }
}
