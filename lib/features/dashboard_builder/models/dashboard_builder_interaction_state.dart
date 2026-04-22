import 'package:flutter/material.dart';

import 'dashboard_item.dart';

enum DashboardBuilderResizeHandlePosition {
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  topLeft,
}

class DashboardBuilderInteractionState {
  List<DashboardItem>? previewItems;
  GridRect? previewRect;
  GridRect? lastValidRect;
  Offset? gestureStartGlobal;
  GridRect? gestureStartRect;
  String? movingItemId;
  String? resizingItemId;
  bool previewInvalid = false;
  DashboardBuilderResizeHandlePosition? activeResizeHandle;

  String? get activeGestureItemId => movingItemId ?? resizingItemId;

  void reset() {
    previewItems = null;
    previewRect = null;
    lastValidRect = null;
    gestureStartGlobal = null;
    gestureStartRect = null;
    movingItemId = null;
    resizingItemId = null;
    previewInvalid = false;
    activeResizeHandle = null;
  }

  void startMove({
    required String itemId,
    required Offset globalPosition,
    required GridRect rect,
    required List<DashboardItem> items,
  }) {
    movingItemId = itemId;
    resizingItemId = null;
    gestureStartGlobal = globalPosition;
    gestureStartRect = rect;
    lastValidRect = rect;
    previewRect = rect;
    previewItems = items;
    previewInvalid = false;
    activeResizeHandle = null;
  }

  void startResize({
    required String itemId,
    required Offset globalPosition,
    required GridRect rect,
    required List<DashboardItem> items,
    required DashboardBuilderResizeHandlePosition handle,
  }) {
    resizingItemId = itemId;
    movingItemId = null;
    gestureStartGlobal = globalPosition;
    gestureStartRect = rect;
    lastValidRect = rect;
    previewRect = rect;
    previewItems = items;
    previewInvalid = false;
    activeResizeHandle = handle;
  }
}
