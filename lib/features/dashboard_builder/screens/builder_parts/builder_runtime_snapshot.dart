part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderRuntimeSnapshot on _DashboardBuilderScreenState {
  void _startSnapshotPolling() {
    _snapshotPollTimer?.cancel();
    _snapshotPollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_refreshSnapshotFromServer()),
    );
  }

  Future<void> _refreshSnapshotFromServer() async {
    if (_isSnapshotRefreshing || _activeGestureItemId != null) {
      return;
    }

    _isSnapshotRefreshing = true;
    try {
      final snapshot = await _dashboardService.fetchRuntimeSnapshot();
      if (!mounted) {
        return;
      }
      _applySnapshotToItems(snapshot);
    } catch (_) {
      // Silent: dashboard should remain usable even if telemetry refresh fails.
    } finally {
      _isSnapshotRefreshing = false;
    }
  }

  void _applySnapshotToItems(DeviceSnapshotModel snapshot) {
    final nextItems = _items.map((item) {
      return DashboardItemRuntimeValueMapper.applySnapshotValue(
        item: item,
        snapshot: snapshot,
      );
    }).toList();

    var hasChanged = false;
    for (var i = 0; i < _items.length; i += 1) {
      if (_items[i].value != nextItems[i].value ||
          _items[i].enabled != nextItems[i].enabled ||
          _items[i].series.length != nextItems[i].series.length) {
        hasChanged = true;
        break;
      }
    }
    if (!hasChanged) {
      return;
    }

    _setRuntimeSnapshotState(() {
      _items = _normalizeItems(nextItems);
    });
  }
}
