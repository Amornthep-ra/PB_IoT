import '../../dashboard_builder/models/dashboard_item.dart';
import '../../notifications/models/alert_event_model.dart';
import '../../notifications/models/alert_rule_model.dart';

class DashboardAlertEvaluationResult {
  const DashboardAlertEvaluationResult({required this.newEvents});

  final List<AlertEventModel> newEvents;
}

class DashboardAlertEvaluator {
  final Map<String, bool> _activeRuleStates = <String, bool>{};

  DashboardAlertEvaluationResult evaluate({
    required List<AlertRuleModel> rules,
    required List<DashboardItem> previousItems,
    required List<DashboardItem> nextItems,
  }) {
    if (rules.isEmpty) {
      _activeRuleStates.clear();
      return const DashboardAlertEvaluationResult(
        newEvents: <AlertEventModel>[],
      );
    }

    final previousById = <String, DashboardItem>{
      for (final item in previousItems) item.id: item,
    };
    final nextById = <String, DashboardItem>{
      for (final item in nextItems) item.id: item,
    };
    final currentRuleIds = <String>{for (final rule in rules) rule.id};
    _activeRuleStates.removeWhere(
      (ruleId, _) => !currentRuleIds.contains(ruleId),
    );

    final eventsToAppend = <AlertEventModel>[];

    for (final rule in rules) {
      if (!rule.enabled) {
        _activeRuleStates[rule.id] = false;
        continue;
      }

      final nextItem = nextById[rule.widgetId];
      if (nextItem == null) {
        _activeRuleStates[rule.id] = false;
        continue;
      }

      final previousItem = previousById[rule.widgetId];
      final isActiveNow = _doesRuleMatch(
        rule: rule,
        previousItem: previousItem,
        nextItem: nextItem,
      );
      final wasActiveBefore = _activeRuleStates[rule.id] == true;

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

      _activeRuleStates[rule.id] = isActiveNow;
    }

    return DashboardAlertEvaluationResult(
      newEvents: List<AlertEventModel>.unmodifiable(eventsToAppend),
    );
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
      DashboardItemType.valueLabel ||
      DashboardItemType.trend => item.value,
      DashboardItemType.button ||
      DashboardItemType.toggle ||
      DashboardItemType.led => item.enabled ? 1 : 0,
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
      DashboardItemType.valueLabel ||
      DashboardItemType.trend => _coerceBool(item.value),
      DashboardItemType.led => item.enabled,
    };
  }

  Object _serializeWidgetValue(DashboardItem item) {
    return switch (item.type) {
      DashboardItemType.button || DashboardItemType.toggle => item.enabled,
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel ||
      DashboardItemType.trend => item.value,
      DashboardItemType.led => item.enabled,
    };
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
    if (text == '1' || text == 'true' || text == 'on' || text == 'online') {
      return true;
    }
    if (text == '0' || text == 'false' || text == 'off' || text == 'offline') {
      return false;
    }
    return null;
  }
}
