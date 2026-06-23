part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderHistory on _DashboardBuilderScreenState {
  _DashboardBuilderSnapshot _captureSnapshot() {
    return _DashboardBuilderSnapshot(
      items: List<DashboardItem>.from(_items),
      selectedId: _selectedId,
      selectedIds: Set<String>.from(_selectedIds),
      isMultiSelectMode: _isMultiSelectMode,
    );
  }

  _DashboardBuilderSnapshot _snapshotFromHistoryEntry(
    DashboardBuilderHistoryEntry entry,
  ) {
    final items = _normalizeItems(List<DashboardItem>.from(entry.items));
    final itemIds = items.map((item) => item.id).toSet();
    final selectedIds = entry.selectedIds
        .where((id) => itemIds.contains(id))
        .toSet();
    final selectedId =
        entry.selectedId != null && itemIds.contains(entry.selectedId)
        ? entry.selectedId
        : (selectedIds.isEmpty ? null : selectedIds.last);

    return _DashboardBuilderSnapshot(
      items: items,
      selectedId: selectedId,
      selectedIds: selectedIds,
      isMultiSelectMode: entry.isMultiSelectMode && selectedIds.length > 1,
    );
  }

  DashboardBuilderHistoryEntry _snapshotToHistoryEntry(
    _DashboardBuilderSnapshot snapshot,
  ) {
    return DashboardBuilderHistoryEntry(
      items: List<DashboardItem>.from(snapshot.items),
      selectedId: snapshot.selectedId,
      selectedIds: Set<String>.from(snapshot.selectedIds),
      isMultiSelectMode: snapshot.isMultiSelectMode,
    );
  }

  void _restoreHistoryStacks(DashboardBuilderHistoryState? history) {
    _undoStack
      ..clear()
      ..addAll(
        (history?.undoStack ?? const <DashboardBuilderHistoryEntry>[]).map(
          _snapshotFromHistoryEntry,
        ),
      );
    _redoStack
      ..clear()
      ..addAll(
        (history?.redoStack ?? const <DashboardBuilderHistoryEntry>[]).map(
          _snapshotFromHistoryEntry,
        ),
      );
  }

  void _trimHistoryStack(List<_DashboardBuilderSnapshot> stack) {
    if (stack.length <= _DashboardBuilderScreenState._maxHistoryEntries) {
      return;
    }
    stack.removeRange(
      0,
      stack.length - _DashboardBuilderScreenState._maxHistoryEntries,
    );
  }

  void _queuePersistBuilderHistory() {
    if (_isLayoutLoading) {
      return;
    }

    final currentSignature = _layoutStorage.layoutSignature(_items);
    final undoStack = _undoStack.map(_snapshotToHistoryEntry).toList();
    final redoStack = _redoStack.map(_snapshotToHistoryEntry).toList();
    _historyPersistQueue = _historyPersistQueue
        .catchError((_) {})
        .then(
          (_) => _layoutStorage.saveBuilderHistory(
            currentSignature: currentSignature,
            undoStack: undoStack,
            redoStack: redoStack,
          ),
        )
        .catchError((_) {
          // Silent: history persistence should never block editing.
        });
    unawaited(_historyPersistQueue);
  }

  void _queuePersistBuilderDraft() {
    if (_isLayoutLoading) {
      return;
    }

    final items = List<DashboardItem>.from(_items);
    _draftPersistQueue = _draftPersistQueue
        .catchError((_) {})
        .then((_) => _layoutStorage.saveBuilderDraft(items))
        .catchError((_) {
          // Silent: draft persistence should never interrupt editing.
        });
    unawaited(_draftPersistQueue);
  }

  void _pushUndoSnapshot() {
    _undoStack.add(_captureSnapshot());
    _trimHistoryStack(_undoStack);
    _redoStack.clear();
    unawaited(Future<void>.microtask(_queuePersistBuilderHistory));
    unawaited(Future<void>.microtask(_queuePersistBuilderDraft));
  }

  void _restoreSnapshot(_DashboardBuilderSnapshot snapshot) {
    _items = _normalizeItems(List<DashboardItem>.from(snapshot.items));
    _selectedId = snapshot.selectedId;
    _selectedIds
      ..clear()
      ..addAll(snapshot.selectedIds);
    _isMultiSelectMode = snapshot.isMultiSelectMode;
    _resetInteractionState();
  }

  void _undo() {
    if (_undoStack.isEmpty) {
      return;
    }

    _setHistoryState(() {
      _redoStack.add(_captureSnapshot());
      _trimHistoryStack(_redoStack);
      _restoreSnapshot(_undoStack.removeLast());
    });
    _queuePersistBuilderHistory();
    _queuePersistBuilderDraft();
  }

  void _redo() {
    if (_redoStack.isEmpty) {
      return;
    }

    _setHistoryState(() {
      _undoStack.add(_captureSnapshot());
      _trimHistoryStack(_undoStack);
      _restoreSnapshot(_redoStack.removeLast());
    });
    _queuePersistBuilderHistory();
    _queuePersistBuilderDraft();
  }
}
