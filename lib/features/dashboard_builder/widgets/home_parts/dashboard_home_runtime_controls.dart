part of '../dashboard_home_view.dart';

class _QueuedControlWrite {
  const _QueuedControlWrite({
    required this.binding,
    required this.targetIdentity,
    required this.value,
    required this.rollbackItems,
    required this.rollbackRevision,
  });

  final WidgetBindingModel binding;
  final String targetIdentity;
  final Object value;
  final List<DashboardItem> rollbackItems;
  final int rollbackRevision;

  _QueuedControlWrite copyWith({
    List<DashboardItem>? rollbackItems,
    int? rollbackRevision,
  }) {
    return _QueuedControlWrite(
      binding: binding,
      targetIdentity: targetIdentity,
      value: value,
      rollbackItems: rollbackItems ?? this.rollbackItems,
      rollbackRevision: rollbackRevision ?? this.rollbackRevision,
    );
  }
}

extension _DashboardHomeRuntimeControls on _DashboardHomeViewState {
  void _updateItemFromRenderer(DashboardItem nextItem) {
    final previousItem = _findItemById(nextItem.id);
    if (previousItem == null) {
      return;
    }
    if (!_shouldAcceptItemInteraction(previous: previousItem, next: nextItem)) {
      return;
    }

    final rollbackItems = List<DashboardItem>.unmodifiable(_items);
    final rollbackRevision = ++_controlWriteRevision;
    final nextItems = _syncItemsForSharedBinding(
      source: nextItem,
      items: _items,
    );

    unawaited(_runtimeController.updateRuntimeItems(nextItems));

    unawaited(
      _writeControlValueIfNeeded(
        previous: previousItem,
        next: nextItem,
        rollbackItems: rollbackItems,
        rollbackRevision: rollbackRevision,
      ),
    );
  }

  Object _serializeWidgetValue(DashboardItem item) {
    return switch (item.type) {
      DashboardItemType.button ||
      DashboardItemType.toggle ||
      DashboardItemType.led => item.enabled,
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel ||
      DashboardItemType.trend => item.value,
    };
  }

  List<DashboardItem> _syncItemsForSharedBinding({
    required DashboardItem source,
    required List<DashboardItem> items,
  }) {
    final bindingKey = DashboardItemRuntimeBinding.normalizeBindingIdentity(
      source.dataKey,
    );
    if (bindingKey == null) {
      return items.map((item) => item.id == source.id ? source : item).toList();
    }

    final serializedValue = _serializeWidgetValue(source);
    return items.map((item) {
      if (item.id == source.id) {
        return source;
      }

      final itemBindingKey =
          DashboardItemRuntimeBinding.normalizeBindingIdentity(item.dataKey);
      if (itemBindingKey != bindingKey) {
        return item;
      }

      return _copyItemWithSerializedValue(item, serializedValue);
    }).toList();
  }

  DashboardItem _copyItemWithSerializedValue(DashboardItem item, Object value) {
    return DashboardItemRuntimeValueMapper.applyResolvedValue(
      item: item,
      incoming: value,
    );
  }

  DashboardItem? _findItemById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  bool _isControlWidget(DashboardItemType type) {
    return type == DashboardItemType.button ||
        type == DashboardItemType.toggle ||
        type == DashboardItemType.slider ||
        type == DashboardItemType.stepH ||
        type == DashboardItemType.stepV;
  }

  bool _isMomentaryButton(DashboardItem item) {
    return item.type == DashboardItemType.button &&
        item.sendBehavior.trim().toLowerCase() == 'push';
  }

  Future<void> _writeControlValueIfNeeded({
    required DashboardItem previous,
    required DashboardItem next,
    required List<DashboardItem> rollbackItems,
    required int rollbackRevision,
  }) async {
    if (!_isControlWidget(next.type)) {
      return;
    }

    if (!_isWritableBindingMode(next.bindingMode)) {
      return;
    }

    if (!_hasControlValueChanged(previous: previous, next: next)) {
      return;
    }

    final runtimeBinding = DashboardItemRuntimeBinding.fromItem(next);
    final binding = runtimeBinding.writeBinding;
    final targetIdentity = runtimeBinding.writeTargetIdentity;
    if (binding == null || targetIdentity == null) {
      return;
    }

    final value = _extractControlValue(next);
    if (value == null) {
      return;
    }

    final writeKey = '${next.id}:$targetIdentity';
    final payload = _QueuedControlWrite(
      binding: binding,
      targetIdentity: targetIdentity,
      value: value,
      rollbackItems: rollbackItems,
      rollbackRevision: rollbackRevision,
    );

    final sendBehavior = next.sendBehavior.trim().toLowerCase();
    final shouldDebounce =
        next.type == DashboardItemType.slider && sendBehavior == 'on_drag';
    if (shouldDebounce) {
      _scheduleControlWriteDebounce(writeKey: writeKey, payload: payload);
      return;
    }

    _cancelControlWriteDebounce(writeKey);
    _enqueueOrSendControlWrite(writeKey: writeKey, payload: payload);
  }

  bool _hasControlValueChanged({
    required DashboardItem previous,
    required DashboardItem next,
  }) {
    switch (next.type) {
      case DashboardItemType.button:
      case DashboardItemType.toggle:
        return previous.enabled != next.enabled;
      case DashboardItemType.slider:
      case DashboardItemType.stepH:
      case DashboardItemType.stepV:
        return previous.value != next.value;
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
      case DashboardItemType.trend:
      case DashboardItemType.led:
        return false;
    }
  }

  bool _shouldAcceptItemInteraction({
    required DashboardItem previous,
    required DashboardItem next,
  }) {
    if (!_isControlWidget(next.type)) {
      return true;
    }
    if (!_hasControlValueChanged(previous: previous, next: next)) {
      return false;
    }

    final isMomentaryButtonPress =
        _isMomentaryButton(previous) && !previous.enabled && next.enabled;
    if (isMomentaryButtonPress) {
      return true;
    }

    final isMomentaryButtonRelease =
        _isMomentaryButton(previous) && previous.enabled && !next.enabled;
    if (isMomentaryButtonRelease) {
      _markControlInteraction(next);
      return true;
    }

    if (next.type == DashboardItemType.slider ||
        next.type == DashboardItemType.stepH ||
        next.type == DashboardItemType.stepV) {
      return true;
    }

    final interactionKey = _interactionKey(next);
    final now = DateTime.now();
    final previousAt = _recentControlInteractions[interactionKey];
    if (previousAt != null &&
        now.difference(previousAt) <
            _DashboardHomeViewState._controlTapCooldown) {
      return false;
    }
    _markControlInteraction(next);
    return true;
  }

  String _interactionKey(DashboardItem item) => '${item.id}:${item.type.name}';

  void _markControlInteraction(DashboardItem item) {
    _recentControlInteractions[_interactionKey(item)] = DateTime.now();
    unawaited(
      Future<void>.delayed(_DashboardHomeViewState._controlTapCooldown, () {
        _setStateSafely(() {});
      }),
    );
  }

  bool _isItemInteractionLocked(DashboardItem item) {
    if (!_isControlWidget(item.type)) {
      return false;
    }

    if (_isMomentaryButton(item) && item.enabled) {
      return false;
    }

    final writeTargetIdentity = DashboardItemRuntimeBinding.fromItem(
      item,
    ).writeTargetIdentity;
    if (writeTargetIdentity != null) {
      final writeKey = '${item.id}:$writeTargetIdentity';
      if (_controlWriteDebounceTimers.containsKey(writeKey) ||
          _controlWriteInFlight.contains(writeKey)) {
        return true;
      }
    }

    if (item.type == DashboardItemType.slider ||
        item.type == DashboardItemType.stepH ||
        item.type == DashboardItemType.stepV) {
      return false;
    }

    final interactionKey = _interactionKey(item);
    final previousAt = _recentControlInteractions[interactionKey];
    if (previousAt == null) {
      return false;
    }
    return DateTime.now().difference(previousAt) <
        _DashboardHomeViewState._controlTapCooldown;
  }

  bool _isWritableBindingMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    return normalized == 'write' || normalized == 'read_write';
  }

  Object? _extractControlValue(DashboardItem item) {
    switch (item.type) {
      case DashboardItemType.button:
      case DashboardItemType.toggle:
        return item.enabled;
      case DashboardItemType.slider:
      case DashboardItemType.stepH:
      case DashboardItemType.stepV:
        return item.value;
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
      case DashboardItemType.trend:
      case DashboardItemType.led:
        return null;
    }
  }

  void _scheduleControlWriteDebounce({
    required String writeKey,
    required _QueuedControlWrite payload,
  }) {
    _cancelControlWriteDebounce(writeKey);
    _controlWriteDebounceTimers[writeKey] = Timer(
      const Duration(seconds: 2),
      () {
        _controlWriteDebounceTimers.remove(writeKey);
        _enqueueOrSendControlWrite(writeKey: writeKey, payload: payload);
      },
    );
  }

  void _cancelControlWriteDebounce(String writeKey) {
    final timer = _controlWriteDebounceTimers.remove(writeKey);
    timer?.cancel();
  }

  void _enqueueOrSendControlWrite({
    required String writeKey,
    required _QueuedControlWrite payload,
  }) {
    if (_controlWriteInFlight.contains(writeKey)) {
      final activePayload = _controlWriteInFlightPayloads[writeKey];
      _queuedControlWrites[writeKey] = activePayload == null
          ? payload
          : payload.copyWith(rollbackItems: activePayload.rollbackItems);
      return;
    }
    unawaited(_sendControlWrite(writeKey: writeKey, payload: payload));
  }

  Future<void> _sendControlWrite({
    required String writeKey,
    required _QueuedControlWrite payload,
  }) async {
    _controlWriteInFlight.add(writeKey);
    _controlWriteInFlightPayloads[writeKey] = payload;
    _setStateSafely(() {});
    var shouldRollback = false;
    try {
      await _dashboardService.writeBindingValue(
        binding: payload.binding,
        value: payload.value,
      );
    } on DashboardServiceException catch (error) {
      if (!mounted) {
        return;
      }
      shouldRollback = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      shouldRollback = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ส่งคำสั่งไปยังอุปกรณ์ไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วลองใหม่',
          ),
        ),
      );
    } finally {
      _controlWriteInFlight.remove(writeKey);
      _controlWriteInFlightPayloads.remove(writeKey);
      final queued = _queuedControlWrites.remove(writeKey);
      _setStateSafely(() {});
      if (shouldRollback && queued == null) {
        await _rollbackControlWriteIfCurrent(payload);
      }
      if (queued != null) {
        _enqueueOrSendControlWrite(writeKey: writeKey, payload: queued);
      }
    }
  }

  Future<void> _rollbackControlWriteIfCurrent(
    _QueuedControlWrite payload,
  ) async {
    if (!mounted || payload.rollbackRevision != _controlWriteRevision) {
      return;
    }
    _controlWriteRevision += 1;
    await _runtimeController.updateRuntimeItems(payload.rollbackItems);
  }
}
