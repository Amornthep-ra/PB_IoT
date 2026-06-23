part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderGestures on _DashboardBuilderScreenState {
  void _startMove(DashboardItem item, Offset globalPosition) {
    if (!_isEditMode || item.locked) {
      return;
    }

    _setGestureState(() {
      _setSingleSelection(item.id);
      _interactionState.startMove(
        itemId: item.id,
        globalPosition: globalPosition,
        rect: item.rect,
        items: _items,
      );
      _startGestureAutoScroll(globalPosition);
    });
  }

  void _updateMove({
    required DashboardItem item,
    required Offset globalPosition,
    required int columns,
    required double stepX,
    required double stepY,
  }) {
    if (item.locked) {
      return;
    }

    final startGlobal = _gestureStartGlobal;
    final startRect = _gestureStartRect;
    if (startGlobal == null || startRect == null) {
      return;
    }

    _trackGesturePointer(globalPosition);
    final scrollDelta =
        (_canvasScrollController.hasClients
            ? _canvasScrollController.offset
            : 0) -
        _gestureStartScrollOffset;
    final delta = (globalPosition - startGlobal) + Offset(0, scrollDelta);
    final candidate = startRect.copyWith(
      x: startRect.x + (delta.dx / stepX).round(),
      y: startRect.y + (delta.dy / stepY).round(),
    );

    _applyPreview(
      item: item,
      candidate: candidate,
      columns: columns,
      rowHeight: stepY,
    );
  }

  void _startDirectMove(DashboardItem item, Offset globalPosition) {
    if (!_isEditMode ||
        item.locked ||
        _isMultiSelectMode ||
        !_hasSingleSelection ||
        !_selectedIds.contains(item.id)) {
      return;
    }

    _startMove(item, globalPosition);
  }

  void _startResize(
    DashboardItem item,
    Offset globalPosition, {
    required DashboardBuilderResizeHandlePosition handle,
  }) {
    if (!_isEditMode || item.locked) {
      return;
    }

    _setGestureState(() {
      _setSingleSelection(item.id);
      _interactionState.startResize(
        itemId: item.id,
        globalPosition: globalPosition,
        rect: item.rect,
        items: _items,
        handle: handle,
      );
      _startGestureAutoScroll(globalPosition);
    });
  }

  void _updateResize({
    required DashboardItem item,
    required Offset globalPosition,
    required int columns,
    required double stepX,
    required double stepY,
  }) {
    if (item.locked) {
      return;
    }

    final startGlobal = _gestureStartGlobal;
    final startRect = _gestureStartRect;
    final handle = _activeResizeHandle;
    if (startGlobal == null || startRect == null || handle == null) {
      return;
    }

    _trackGesturePointer(globalPosition);
    final delta = globalPosition - startGlobal;
    final gridDx = (delta.dx / stepX).round();
    final gridDy = (delta.dy / stepY).round();

    var nextX = startRect.x;
    var nextY = startRect.y;
    var nextW = startRect.w;
    var nextH = startRect.h;

    switch (handle) {
      case DashboardBuilderResizeHandlePosition.top:
        final anchoredBottom = startRect.bottom;
        final minTop = (anchoredBottom - item.maxH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows - item.minH,
        );
        final maxTop = (anchoredBottom - item.minH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows - item.minH,
        );
        nextY = (startRect.y + gridDy).clamp(minTop, maxTop);
        nextH = anchoredBottom - nextY;
        break;
      case DashboardBuilderResizeHandlePosition.topRight:
        final anchoredBottom = startRect.bottom;
        final minTop = (anchoredBottom - item.maxH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows - item.minH,
        );
        final maxTop = (anchoredBottom - item.minH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows - item.minH,
        );
        nextY = (startRect.y + gridDy).clamp(minTop, maxTop);
        nextH = anchoredBottom - nextY;
        final desiredRight = startRect.right + gridDx;
        final minRight = startRect.x + item.minW;
        final maxRight = (startRect.x + item.maxW).clamp(0, columns);
        nextW = desiredRight.clamp(minRight, maxRight) - startRect.x;
        break;
      case DashboardBuilderResizeHandlePosition.right:
        final desiredRight = startRect.right + gridDx;
        final minRight = startRect.x + item.minW;
        final maxRight = (startRect.x + item.maxW).clamp(0, columns);
        nextW = desiredRight.clamp(minRight, maxRight) - startRect.x;
        break;
      case DashboardBuilderResizeHandlePosition.bottomRight:
        final desiredRight = startRect.right + gridDx;
        final minRight = startRect.x + item.minW;
        final maxRight = (startRect.x + item.maxW).clamp(0, columns);
        nextW = desiredRight.clamp(minRight, maxRight) - startRect.x;
        final desiredBottom = startRect.bottom + gridDy;
        final minBottom = startRect.y + item.minH;
        final maxBottom = (startRect.y + item.maxH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows,
        );
        nextH = desiredBottom.clamp(minBottom, maxBottom) - startRect.y;
        break;
      case DashboardBuilderResizeHandlePosition.bottom:
        final desiredBottom = startRect.bottom + gridDy;
        final minBottom = startRect.y + item.minH;
        final maxBottom = (startRect.y + item.maxH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows,
        );
        nextH = desiredBottom.clamp(minBottom, maxBottom) - startRect.y;
        break;
      case DashboardBuilderResizeHandlePosition.bottomLeft:
        final desiredBottom = startRect.bottom + gridDy;
        final minBottom = startRect.y + item.minH;
        final maxBottom = (startRect.y + item.maxH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows,
        );
        nextH = desiredBottom.clamp(minBottom, maxBottom) - startRect.y;
        final anchoredRight = startRect.right;
        final minLeft = (anchoredRight - item.maxW).clamp(
          0,
          columns - item.minW,
        );
        final maxLeft = (anchoredRight - item.minW).clamp(
          0,
          columns - item.minW,
        );
        nextX = (startRect.x + gridDx).clamp(minLeft, maxLeft);
        nextW = anchoredRight - nextX;
        break;
      case DashboardBuilderResizeHandlePosition.left:
        final anchoredRight = startRect.right;
        final minLeft = (anchoredRight - item.maxW).clamp(
          0,
          columns - item.minW,
        );
        final maxLeft = (anchoredRight - item.minW).clamp(
          0,
          columns - item.minW,
        );
        nextX = (startRect.x + gridDx).clamp(minLeft, maxLeft);
        nextW = anchoredRight - nextX;
        break;
      case DashboardBuilderResizeHandlePosition.topLeft:
        final anchoredBottom = startRect.bottom;
        final minTop = (anchoredBottom - item.maxH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows - item.minH,
        );
        final maxTop = (anchoredBottom - item.minH).clamp(
          0,
          _DashboardBuilderScreenState._maxRows - item.minH,
        );
        nextY = (startRect.y + gridDy).clamp(minTop, maxTop);
        nextH = anchoredBottom - nextY;
        final anchoredRight = startRect.right;
        final minLeft = (anchoredRight - item.maxW).clamp(
          0,
          columns - item.minW,
        );
        final maxLeft = (anchoredRight - item.minW).clamp(
          0,
          columns - item.minW,
        );
        nextX = (startRect.x + gridDx).clamp(minLeft, maxLeft);
        nextW = anchoredRight - nextX;
        break;
    }

    final candidate = startRect.copyWith(
      x: nextX,
      y: nextY,
      w: nextW,
      h: nextH,
    );

    _applyPreview(
      item: item,
      candidate: candidate,
      columns: columns,
      rowHeight: stepY,
    );
  }

  void _applyPreview({
    required DashboardItem item,
    required GridRect candidate,
    required int columns,
    required double rowHeight,
  }) {
    final constrainedCandidate = switch (item.type) {
      DashboardItemType.gauge => _clampGaugeRectToAspect(
        item: item,
        rect: candidate,
      ),
      DashboardItemType.toggle => _clampToggleRectToAspect(
        item: item,
        rect: candidate,
      ),
      _ => candidate,
    };

    if (item.type == DashboardItemType.button &&
        !_buttonRectFitsItem(item: item, rect: constrainedCandidate)) {
      _setGestureState(() {
        _previewRect = _lastValidRect ?? item.rect;
        _previewInvalid = false;
        _interactionState.syncPreviewChanged(_lastValidRect ?? item.rect);
      });
      return;
    }

    final previewRect = DashboardLayoutEngine.clampRect(
      item: item,
      rect: constrainedCandidate,
      columns: columns,
      maxRows: _DashboardBuilderScreenState._maxRows,
    );
    final hasOverlap = _items.any(
      (other) =>
          other.id != item.id &&
          _visualCollisionOverlaps(
            leftItem: item,
            leftRect: previewRect,
            rightItem: other,
            rightRect: other.rect,
            rowHeight: rowHeight,
          ),
    );

    if (hasOverlap) {
      _setGestureState(() {
        _previewRect = previewRect;
        _previewInvalid = true;
        _interactionState.syncPreviewChanged(_lastValidRect ?? item.rect);
      });
      return;
    }

    final nextItems = _items
        .map(
          (other) =>
              other.id == item.id ? other.copyWith(rect: previewRect) : other,
        )
        .toList();

    _setGestureState(() {
      _previewItems = nextItems;
      _previewRect = previewRect;
      _lastValidRect = previewRect;
      _previewInvalid = false;
      _interactionState.syncPreviewChanged(previewRect);
    });
  }

  void _finishGesture() {
    final activeId = _activeGestureItemId;
    final lastValidRect = _lastValidRect;
    final previewChanged = _interactionState.previewChanged;
    final startRect = _gestureStartRect;
    _stopGestureAutoScroll();
    if (activeId == null) {
      return;
    }

    if (previewChanged && _previewItems != null && !_previewInvalid) {
      _setGestureState(() {
        _pushUndoSnapshot();
        _items = _normalizeItems(_previewItems!);
      });
    } else if (previewChanged &&
        lastValidRect != null &&
        startRect != null &&
        (lastValidRect.x != startRect.x ||
            lastValidRect.y != startRect.y ||
            lastValidRect.w != startRect.w ||
            lastValidRect.h != startRect.h)) {
      final item = _findItemById(activeId, _items);
      if (item != null) {
        _setGestureState(() {
          _pushUndoSnapshot();
          _items = _normalizeItems(
            _items
                .map(
                  (element) => element.id == activeId
                      ? element.copyWith(rect: lastValidRect)
                      : element,
                )
                .toList(),
          );
        });
      }
    }

    _setGestureState(() {
      _resetInteractionState();
    });
  }

  void _startGestureAutoScroll(Offset globalPosition) {
    _gestureStartScrollOffset = _canvasScrollController.hasClients
        ? _canvasScrollController.offset
        : 0;
    _lastGestureGlobalPosition = globalPosition;
    _dragAutoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (
      _,
    ) {
      if (!mounted || _activeGestureItemId == null) {
        _stopGestureAutoScroll();
        return;
      }
      final pointer = _lastGestureGlobalPosition;
      if (pointer == null) {
        return;
      }
      if (_applyDragAutoScroll(pointer)) {
        _syncActiveGesturePreview(pointer);
      }
    });
  }

  void _trackGesturePointer(Offset globalPosition) {
    _lastGestureGlobalPosition = globalPosition;
    _applyDragAutoScroll(globalPosition);
  }

  void _stopGestureAutoScroll() {
    _dragAutoScrollTimer?.cancel();
    _dragAutoScrollTimer = null;
    _lastGestureGlobalPosition = null;
    _gestureStartScrollOffset = 0;
  }

  bool _applyDragAutoScroll(Offset globalPosition) {
    if (!_canvasScrollController.hasClients) {
      return false;
    }
    final context = _canvasViewportKey.currentContext;
    if (context == null) {
      return false;
    }
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) {
      return false;
    }
    final localPosition = renderBox.globalToLocal(globalPosition);
    final viewportHeight = renderBox.size.height;
    if (viewportHeight <= 0) {
      return false;
    }

    double delta = 0;
    if (localPosition.dy <
        _DashboardBuilderScreenState._dragAutoScrollEdgeThreshold) {
      final factor =
          ((_DashboardBuilderScreenState._dragAutoScrollEdgeThreshold -
                      localPosition.dy) /
                  _DashboardBuilderScreenState._dragAutoScrollEdgeThreshold)
              .clamp(0.0, 1.0);
      delta = -_DashboardBuilderScreenState._dragAutoScrollMaxStep * factor;
    } else if (localPosition.dy >
        viewportHeight -
            _DashboardBuilderScreenState._dragAutoScrollEdgeThreshold) {
      final factor =
          ((localPosition.dy -
                      (viewportHeight -
                          _DashboardBuilderScreenState
                              ._dragAutoScrollEdgeThreshold)) /
                  _DashboardBuilderScreenState._dragAutoScrollEdgeThreshold)
              .clamp(0.0, 1.0);
      delta = _DashboardBuilderScreenState._dragAutoScrollMaxStep * factor;
    }

    if (delta.abs() < 0.5) {
      return false;
    }

    final position = _canvasScrollController.position;
    final nextOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((nextOffset - position.pixels).abs() < 0.5) {
      return false;
    }

    _canvasScrollController.jumpTo(nextOffset);
    return true;
  }

  void _syncActiveGesturePreview(Offset globalPosition) {
    final activeId = _activeGestureItemId;
    if (activeId == null) {
      return;
    }
    final item = _findItemById(activeId, _items);
    if (item == null) {
      return;
    }
    if (_activeResizeHandle != null) {
      _updateResize(
        item: item,
        globalPosition: globalPosition,
        columns: _latestCanvasColumns,
        stepX: _latestStepX,
        stepY: _latestStepY,
      );
      return;
    }
    _updateMove(
      item: item,
      globalPosition: globalPosition,
      columns: _latestCanvasColumns,
      stepX: _latestStepX,
      stepY: _latestStepY,
    );
  }
}
