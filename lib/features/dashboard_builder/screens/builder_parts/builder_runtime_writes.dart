part of '../dashboard_builder_screen.dart';

class _QueuedControlWrite {
  const _QueuedControlWrite({
    required this.binding,
    required this.targetIdentity,
    required this.value,
  });

  final WidgetBindingModel binding;
  final String targetIdentity;
  final Object value;
}

extension _DashboardBuilderRuntimeWrites on _DashboardBuilderScreenState {
  void _updateItemFromRenderer(DashboardItem nextItem) {
    final previousItem = _findItemById(nextItem.id, _items);
    _setRuntimeWriteState(() {
      _items = _normalizeItems(
        _syncItemsForSharedBinding(source: nextItem, items: _items),
      );
    });

    if (!_isEditMode && previousItem != null) {
      unawaited(
        _writeControlValueIfNeeded(previous: previousItem, next: nextItem),
      );
    }
  }

  Future<void> _writeControlValueIfNeeded({
    required DashboardItem previous,
    required DashboardItem next,
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
      _queuedControlWrites[writeKey] = payload;
      return;
    }
    unawaited(_sendControlWrite(writeKey: writeKey, payload: payload));
  }

  Future<void> _sendControlWrite({
    required String writeKey,
    required _QueuedControlWrite payload,
  }) async {
    _controlWriteInFlight.add(writeKey);
    try {
      await _dashboardService.writeBindingValue(
        binding: payload.binding,
        value: payload.value,
      );
    } on DashboardServiceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถส่งค่าจากวิดเจ็ตได้ในขณะนี้')),
      );
    } finally {
      _controlWriteInFlight.remove(writeKey);
      final queued = _queuedControlWrites.remove(writeKey);
      if (queued != null) {
        _enqueueOrSendControlWrite(writeKey: writeKey, payload: queued);
      }
    }
  }

  bool _isControlWidget(DashboardItemType type) {
    return type == DashboardItemType.button ||
        type == DashboardItemType.toggle ||
        type == DashboardItemType.slider ||
        type == DashboardItemType.stepH ||
        type == DashboardItemType.stepV;
  }

  bool _isWritableBindingMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    return normalized == 'write' || normalized == 'read_write';
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
}
