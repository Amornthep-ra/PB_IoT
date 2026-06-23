part of '../dashboard_builder_screen.dart';

enum _AlertRuleDeleteChoice { deleteRules, disableRules, cancel }

extension _DashboardBuilderItemActions on _DashboardBuilderScreenState {
  DashboardItem? _findItemById(String? id, List<DashboardItem> items) {
    if (id == null) {
      return null;
    }
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<DashboardItem> _selectedItems(List<DashboardItem> items) {
    return items.where((item) => _selectedIds.contains(item.id)).toList();
  }

  void _setSingleSelection(String id) {
    _selectedId = id;
    _selectedIds
      ..clear()
      ..add(id);
  }

  void _toggleItemSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedId == id) {
        _selectedId = _selectedIds.isEmpty ? null : _selectedIds.last;
      }
      return;
    }

    _selectedIds.add(id);
    _selectedId = id;
  }

  void _exitSelectMode({String? keepSelectedId}) {
    _isMultiSelectMode = false;
    _selectedIds
      ..clear()
      ..addAll(keepSelectedId == null ? const <String>{} : {keepSelectedId});
    _selectedId = keepSelectedId;
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty && !_isMultiSelectMode) {
      return;
    }

    _setItemActionState(() {
      _exitSelectMode();
    });
  }

  void _removeSelectedItem() {
    if (_selectedIds.isEmpty) {
      return;
    }
    unawaited(_removeSelectedItemAsync());
  }

  Future<void> _removeSelectedItemAsync() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final selectedIds = Set<String>.from(_selectedIds);

    List<AlertRuleModel> allRules = const <AlertRuleModel>[];
    List<AlertRuleModel> dependentRules = const <AlertRuleModel>[];
    try {
      allRules = await _notificationService.loadRules();
      dependentRules = allRules
          .where((rule) => selectedIds.contains(rule.widgetId))
          .toList(growable: false);
    } catch (_) {
      // If alert rule storage is unavailable, fall back to plain deletion.
    }

    if (!mounted) {
      return;
    }

    _AlertRuleDeleteChoice? choice;
    if (dependentRules.isNotEmpty) {
      choice = await _confirmWidgetDeletionWithAlerts(dependentRules);
      if (choice == null || choice == _AlertRuleDeleteChoice.cancel) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    if (choice != null) {
      final dependentRuleIds = dependentRules.map((rule) => rule.id).toSet();
      List<AlertRuleModel> nextRules;
      switch (choice) {
        case _AlertRuleDeleteChoice.deleteRules:
          nextRules = allRules
              .where((rule) => !dependentRuleIds.contains(rule.id))
              .toList(growable: false);
          break;
        case _AlertRuleDeleteChoice.disableRules:
          nextRules = allRules
              .map(
                (rule) => dependentRuleIds.contains(rule.id) && rule.enabled
                    ? rule.copyWith(enabled: false, updatedAt: DateTime.now())
                    : rule,
              )
              .toList(growable: false);
          break;
        case _AlertRuleDeleteChoice.cancel:
          return;
      }
      try {
        await _notificationService.saveRules(nextRules);
      } catch (_) {
        // Non-fatal; widget deletion still proceeds.
      }
    }

    if (!mounted) {
      return;
    }

    _setItemActionState(() {
      _pushUndoSnapshot();
      _items = _items
          .where((element) => !selectedIds.contains(element.id))
          .toList();
      _exitSelectMode();
      _resetInteractionState();
    });
  }

  Future<_AlertRuleDeleteChoice?> _confirmWidgetDeletionWithAlerts(
    List<AlertRuleModel> affectedRules,
  ) {
    const accentColor = Color(0xFFCC5A4E);
    return showDialog<_AlertRuleDeleteChoice>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: _themePreset.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _themedBorderColor(0.82)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xF9FFFFFF),
                  offset: Offset(-8, -8),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: Color(0x1D9CA9B5),
                  offset: Offset(10, 12),
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: Color(0x14677E92),
                  offset: Offset(0, 18),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Widget มี Alert ผูกอยู่',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _sheetHeadlineColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Widget ที่เลือกถูกใช้โดย ${affectedRules.length} alert rule'
                  '${affectedRules.length > 1 ? 's' : ''} ด้านล่าง '
                  'เลือกวิธีจัดการก่อนลบ widget:',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: _themePreset.bodyColor,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final rule in affectedRules)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Icon(
                                    Icons.fiber_manual_record,
                                    size: 8,
                                    color: Color(0xFF97A3AF),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rule.title.isEmpty
                                            ? 'Untitled rule'
                                            : rule.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _sheetHeadlineColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${rule.widgetTitle}'
                                        '${rule.enabled ? '' : ' • disabled'}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: _themePreset.mutedTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DeleteWithAlertsActionButton(
                  label: 'ลบ widget และ alert rule ทั้งหมด',
                  description: 'ไม่มี rule ค้างในระบบ',
                  icon: Icons.delete_sweep_rounded,
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_AlertRuleDeleteChoice.deleteRules),
                ),
                const SizedBox(height: 10),
                _DeleteWithAlertsActionButton(
                  label: 'ลบ widget แต่เก็บ rule ไว้ (ปิดการทำงาน)',
                  description: 'เปิดใช้ใหม่ทีหลังได้จากหน้า Notifications',
                  icon: Icons.notifications_paused_outlined,
                  backgroundColor: const Color(0xFFE8EEF6),
                  foregroundColor: const Color(0xFF20303A),
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_AlertRuleDeleteChoice.disableRules),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(_AlertRuleDeleteChoice.cancel),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6E7A86),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSelectedItemSettings() {
    if (!_hasSingleSelection) {
      return;
    }
    final item = _findItemById(_selectedId, _items);
    if (item == null) {
      return;
    }

    _openWidgetSettings(item);
  }

  void _toggleMultiSelectMode() {
    _setItemActionState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode && _selectedIds.length > 1) {
        final keepId = _selectedId ?? _selectedIds.last;
        _selectedIds
          ..clear()
          ..add(keepId);
        _selectedId = keepId;
      }
    });
  }

  bool _canPlaceDuplicateRect({
    required DashboardItem item,
    required GridRect rect,
    required List<DashboardItem> items,
    required int columns,
    required double rowHeight,
  }) {
    if (rect.x < 0 || rect.y < 0) {
      return false;
    }
    if (rect.right > columns ||
        rect.bottom > _DashboardBuilderScreenState._maxRows) {
      return false;
    }

    return !items.any(
      (other) => _visualCollisionOverlaps(
        leftItem: item,
        leftRect: rect,
        rightItem: other,
        rightRect: other.rect,
        rowHeight: rowHeight,
      ),
    );
  }

  GridRect? _findNearbyDuplicateRect({
    required DashboardItem item,
    required List<DashboardItem> occupiedItems,
    required int columns,
    required double rowHeight,
  }) {
    final sourceRect = item.rect;

    final maxDistance = columns > _DashboardBuilderScreenState._maxRows
        ? columns
        : _DashboardBuilderScreenState._maxRows;
    for (var distance = 1; distance < maxDistance; distance++) {
      GridRect? found;
      final immediateCandidates = <GridRect>[
        sourceRect.copyWith(x: sourceRect.x + distance, y: sourceRect.y),
        sourceRect.copyWith(x: sourceRect.x, y: sourceRect.y + distance),
        sourceRect.copyWith(
          x: sourceRect.x + distance,
          y: sourceRect.y + distance,
        ),
        sourceRect.copyWith(x: sourceRect.x - distance, y: sourceRect.y),
        sourceRect.copyWith(x: sourceRect.x, y: sourceRect.y - distance),
        sourceRect.copyWith(
          x: sourceRect.x - distance,
          y: sourceRect.y + distance,
        ),
        sourceRect.copyWith(
          x: sourceRect.x + distance,
          y: sourceRect.y - distance,
        ),
        sourceRect.copyWith(
          x: sourceRect.x - distance,
          y: sourceRect.y - distance,
        ),
      ];

      for (final candidate in immediateCandidates) {
        if (_canPlaceDuplicateRect(
          item: item,
          rect: candidate,
          items: occupiedItems,
          columns: columns,
          rowHeight: rowHeight,
        )) {
          found = candidate;
          break;
        }
      }

      if (found != null) {
        return found;
      }
    }

    GridRect? bestRect;
    int? bestDistance;
    for (
      var y = 0;
      y <= _DashboardBuilderScreenState._maxRows - sourceRect.h;
      y++
    ) {
      for (var x = 0; x <= columns - sourceRect.w; x++) {
        final candidate = sourceRect.copyWith(x: x, y: y);
        if (!_canPlaceDuplicateRect(
          item: item,
          rect: candidate,
          items: occupiedItems,
          columns: columns,
          rowHeight: rowHeight,
        )) {
          continue;
        }

        final distance =
            (candidate.x - sourceRect.x).abs() +
            (candidate.y - sourceRect.y).abs();
        if (bestDistance == null || distance < bestDistance) {
          bestDistance = distance;
          bestRect = candidate;
        }
      }
    }

    return bestRect;
  }

  void _duplicateSelectedItems() {
    if (_selectedIds.isEmpty) {
      return;
    }

    final canvasWidth = _fallbackCanvasWidth();
    final columns = _columnsForWidth(canvasWidth);
    final cellWidth = DashboardGridMetrics.cellWidthFor(
      width: canvasWidth,
      columns: columns,
    );
    final rowHeight = DashboardGridMetrics.rowHeightFor(cellWidth);
    final selectedItems = _selectedItems(_items)
      ..sort((left, right) {
        final byY = left.rect.y.compareTo(right.rect.y);
        return byY != 0 ? byY : left.rect.x.compareTo(right.rect.x);
      });

    final duplicates = <DashboardItem>[];
    final nextItems = <DashboardItem>[..._items];
    final nextSelectedIds = <String>{};

    for (final item in selectedItems) {
      _itemSeed += 1;
      final duplicate = item.copyWith(id: '${item.type.name}-copy-$_itemSeed');
      final freeRect = _findNearbyDuplicateRect(
        item: duplicate,
        occupiedItems: [...nextItems, ...duplicates],
        columns: columns,
        rowHeight: rowHeight,
      );
      if (freeRect == null) {
        continue;
      }

      final placedDuplicate = duplicate.copyWith(rect: freeRect);
      duplicates.add(placedDuplicate);
      nextSelectedIds.add(placedDuplicate.id);
    }

    if (duplicates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีพื้นที่ว่างสำหรับคัดลอกวิดเจ็ต')),
      );
      return;
    }

    _setItemActionState(() {
      _pushUndoSnapshot();
      _items = _normalizeItems([..._items, ...duplicates]);
      _selectedIds
        ..clear()
        ..addAll(nextSelectedIds);
      _selectedId = duplicates.last.id;
      _isMultiSelectMode = nextSelectedIds.length > 1;
      _resetInteractionState();
    });
  }

  Future<void> _openWidgetSettings(DashboardItem item) async {
    if (!_isEditMode) {
      return;
    }

    final result = await Navigator.of(context).push<WidgetSettingsResult>(
      MaterialPageRoute<WidgetSettingsResult>(
        builder: (context) => Scaffold(
          backgroundColor: DashboardRuntimeTheme.backgroundColor,
          body: WidgetSettingsSheet(
            item: item,
            allItems: _items,
            isFullscreen: true,
          ),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final applyResult = DashboardSettingsService.applyResult(
      items: _items,
      itemId: item.id,
      result: result,
    );

    if (applyResult == null) {
      return;
    }

    _setItemActionState(() {
      _pushUndoSnapshot();
      _items = _normalizeItems(applyResult.items);
      _exitSelectMode(keepSelectedId: applyResult.selectedId);
      _resetInteractionState();
    });
  }

  Future<void> _openAddWidgetSheet() async {
    final type = await showModalBottomSheet<DashboardItemType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final shortestSide = mediaQuery.size.shortestSide;
        final initialChildSize = shortestSide >= 600 ? 0.44 : 0.72;
        final maxChildSize = shortestSide >= 600 ? 0.62 : 0.9;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: 0.32,
          maxChildSize: maxChildSize,
          builder: (context, scrollController) {
            return AddWidgetSheet(
              scrollController: scrollController,
              themePreset: _themePreset,
            );
          },
        );
      },
    );

    if (!mounted || type == null) {
      return;
    }

    _itemSeed += 1;
    final canvasWidth = _fallbackCanvasWidth();
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final columns = _columnsForWidth(canvasWidth);
    final placedItem = DashboardAddWidgetService.createPlacedItem(
      items: _items,
      type: type,
      seed: _itemSeed,
      columns: columns,
      maxRows: _DashboardBuilderScreenState._maxRows,
      buttonMinW: _DashboardBuilderScreenState._buttonMinW,
      buttonMaxW: _DashboardBuilderScreenState._buttonMaxW,
      buttonMinH: _DashboardBuilderScreenState._buttonMinH,
      buttonMaxH: _DashboardBuilderScreenState._buttonMaxH,
      buttonRectResolver: (title) => _defaultButtonRect(
        title: title,
        canvasWidth: canvasWidth,
        textScaler: textScaler,
        textDirection: textDirection,
      ),
    );

    if (placedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีพื้นที่ว่างสำหรับเพิ่มวิดเจ็ตตอนนี้'),
        ),
      );
      return;
    }

    _setItemActionState(() {
      _pushUndoSnapshot();
      _items = _normalizeItems(<DashboardItem>[..._items, placedItem]);
      _exitSelectMode();
      _resetInteractionState();
    });
  }
}
