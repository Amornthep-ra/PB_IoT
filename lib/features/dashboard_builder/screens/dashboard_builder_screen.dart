import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../theme/app_theme.dart';
import '../../dashboard/models/widget_binding_model.dart';
import '../../dashboard/models/device_snapshot_model.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/services/dashboard_runtime_value_storage.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../../notifications/models/alert_rule_model.dart';
import '../../notifications/services/notification_service.dart';
import '../models/dashboard_builder_interaction_state.dart';
import '../models/dashboard_item.dart';
import '../models/dashboard_theme_preset.dart';
import '../models/widget_settings_result.dart';
import '../services/dashboard_add_widget_service.dart';
import '../services/dashboard_builder_layout_storage_service.dart';
import '../services/dashboard_layout_engine.dart';
import '../services/dashboard_settings_service.dart';
import '../widgets/add_widget_sheet.dart';
import '../widgets/dashboard_grid_painter.dart';
import '../widgets/dashboard_item_renderer.dart';
import '../widgets/smart_slider_widget.dart';
import '../widgets/widget_shell_layout.dart';
import '../widgets/widget_settings_sheet.dart';

enum _AlertRuleDeleteChoice { deleteRules, disableRules, cancel }

class _DeleteWithAlertsActionButton extends StatelessWidget {
  const _DeleteWithAlertsActionButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: foregroundColor.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBuilderSnapshot {
  const _DashboardBuilderSnapshot({
    required this.items,
    required this.selectedId,
    required this.selectedIds,
    required this.isMultiSelectMode,
  });

  final List<DashboardItem> items;
  final String? selectedId;
  final Set<String> selectedIds;
  final bool isMultiSelectMode;
}

class _BuilderActionTone {
  const _BuilderActionTone({
    required this.background,
    required this.foreground,
    required this.glow,
  });

  final Color background;
  final Color foreground;
  final Color glow;
}

const _BuilderActionTone _undoActionTone = _BuilderActionTone(
  background: Color(0xFFF0ECFB),
  foreground: Color(0xFF7A64BE),
  glow: Color(0xFFC3B2EE),
);

const _BuilderActionTone _redoActionTone = _BuilderActionTone(
  background: Color(0xFFE7F4FF),
  foreground: Color(0xFF5A8EC7),
  glow: Color(0xFFAFD0F0),
);

const _BuilderActionTone _duplicateActionTone = _BuilderActionTone(
  background: Color(0xFFEAF7E3),
  foreground: Color(0xFF67984F),
  glow: Color(0xFFB8D89E),
);

const _BuilderActionTone _selectionActionTone = _BuilderActionTone(
  background: Color(0xFFE4F6F7),
  foreground: Color(0xFF4399A0),
  glow: Color(0xFFA6DDE0),
);

const _BuilderActionTone _settingsActionTone = _BuilderActionTone(
  background: Color(0xFFFFF1DC),
  foreground: Color(0xFFBF8741),
  glow: Color(0xFFF0CA8D),
);

const _BuilderActionTone _deleteActionTone = _BuilderActionTone(
  background: Color(0xFFFFE9EC),
  foreground: Color(0xFFD46B7B),
  glow: Color(0xFFF0B1BC),
);

class _QueuedControlWrite {
  const _QueuedControlWrite({
    required this.pin,
    required this.value,
    required this.valueType,
  });

  final String pin;
  final Object value;
  final WidgetBindingValueType valueType;
}

enum _LeaveAction { cancel, discard, save }

class DashboardBuilderScreen extends StatefulWidget {
  const DashboardBuilderScreen({super.key});

  @override
  State<DashboardBuilderScreen> createState() => _DashboardBuilderScreenState();
}

class _DashboardBuilderScreenState extends State<DashboardBuilderScreen> {
  static const double _gridGap = 0;
  static const int _maxRows = 72;
  static const double _canvasHorizontalPadding = 0;
  static const double _canvasTopPadding = 0;
  static const double _canvasBottomScrollPadding = 32;
  static const double _editModeViewportInset = 0;
  static const int _editModeExtraCanvasRows = 10;
  static const double _dragAutoScrollEdgeThreshold = 96;
  static const double _dragAutoScrollMaxStep = 24;
  static const double _targetCellSize = 14;
  static const double _sliderCompactCollisionCellThreshold = 22;
  static const int _minColumns = 18;
  static const int _maxColumns = 26;
  static const int _maxHistoryEntries = 60;
  static const int _buttonMinW = 3;
  static const int _buttonMaxW = 32;
  static const int _buttonMinH = 3;
  static const int _buttonMaxH = 24;
  static const double _gaugeMinAspectRatio = 0.8;
  static const double _gaugeMaxAspectRatio = 1.25;
  static const double _toggleMinAspectRatio = 1.5;
  static const double _toggleMaxAspectRatio = 4.5;

  late List<DashboardItem> _items;
  String? _selectedId;
  final Set<String> _selectedIds = <String>{};
  final bool _isEditMode = true;
  bool _isMultiSelectMode = false;
  final List<_DashboardBuilderSnapshot> _undoStack =
      <_DashboardBuilderSnapshot>[];
  final List<_DashboardBuilderSnapshot> _redoStack =
      <_DashboardBuilderSnapshot>[];
  final DashboardBuilderInteractionState _interactionState =
      DashboardBuilderInteractionState();
  final DashboardBuilderLayoutStorageService _layoutStorage =
      DashboardBuilderLayoutStorageService();
  final NotificationService _notificationService = NotificationService();
  final DashboardRuntimeValueStorage _runtimeValueStorage =
      DashboardRuntimeValueStorage();
  final DashboardService _dashboardService = DashboardService();
  final ScrollController _canvasScrollController = ScrollController();
  final GlobalKey _canvasViewportKey = GlobalKey();
  final Map<String, Timer> _controlWriteDebounceTimers = <String, Timer>{};
  final Set<String> _controlWriteInFlight = <String>{};
  final Map<String, _QueuedControlWrite> _queuedControlWrites =
      <String, _QueuedControlWrite>{};
  Future<void> _historyPersistQueue = Future<void>.value();
  Future<void> _draftPersistQueue = Future<void>.value();
  Timer? _snapshotPollTimer;
  Timer? _dragAutoScrollTimer;
  bool _isSnapshotRefreshing = false;
  int _itemSeed = 0;
  bool _isLayoutLoading = true;
  bool _isLayoutSaving = false;
  String _savedLayoutSignature = '[]';
  DashboardThemePreset _themePreset = dashboardThemePresets.first;
  DashboardThemePreset? _customThemePreset;
  List<DashboardItem>? _pendingDraftItems;
  DashboardBuilderHistoryState? _pendingDraftHistory;
  double _gestureStartScrollOffset = 0;
  Offset? _lastGestureGlobalPosition;
  int _latestCanvasColumns = _minColumns;
  double _latestStepX = 1;
  double _latestStepY = 1;
  String? get _activeGestureItemId => _interactionState.activeGestureItemId;
  List<DashboardItem>? get _previewItems => _interactionState.previewItems;
  set _previewItems(List<DashboardItem>? value) =>
      _interactionState.previewItems = value;
  GridRect? get _previewRect => _interactionState.previewRect;
  set _previewRect(GridRect? value) => _interactionState.previewRect = value;
  GridRect? get _lastValidRect => _interactionState.lastValidRect;
  set _lastValidRect(GridRect? value) =>
      _interactionState.lastValidRect = value;
  Offset? get _gestureStartGlobal => _interactionState.gestureStartGlobal;
  GridRect? get _gestureStartRect => _interactionState.gestureStartRect;
  bool get _previewInvalid => _interactionState.previewInvalid;
  set _previewInvalid(bool value) => _interactionState.previewInvalid = value;
  DashboardBuilderResizeHandlePosition? get _activeResizeHandle =>
      _interactionState.activeResizeHandle;
  bool get _hasSelection => _selectedIds.isNotEmpty;
  bool get _hasSingleSelection => _selectedIds.length == 1;
  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _items = _normalizeItems(_buildInitialItems());
    unawaited(_loadLayoutFromStorage());
    _startSnapshotPolling();
    unawaited(_refreshSnapshotFromServer());
  }

  @override
  void dispose() {
    for (final timer in _controlWriteDebounceTimers.values) {
      timer.cancel();
    }
    _controlWriteDebounceTimers.clear();
    _queuedControlWrites.clear();
    _snapshotPollTimer?.cancel();
    _dragAutoScrollTimer?.cancel();
    _canvasScrollController.dispose();
    super.dispose();
  }

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
      final pin = _extractVirtualPin(item.dataKey);
      if (pin == null) {
        return item;
      }

      final mode = item.bindingMode.trim().toLowerCase();
      if (mode == 'write') {
        return item;
      }

      if (!snapshot.virtualPins.containsKey(pin)) {
        return item;
      }

      final incoming = snapshot.virtualPins[pin];
      switch (item.type) {
        case DashboardItemType.button:
        case DashboardItemType.toggle:
          final enabled = _coerceBool(incoming);
          if (enabled == null) {
            return item;
          }
          return item.copyWith(enabled: enabled, value: enabled ? 1.0 : 0.0);
        case DashboardItemType.slider:
        case DashboardItemType.gauge:
        case DashboardItemType.valueLabel:
          final numeric = _coerceDouble(incoming);
          if (numeric == null) {
            return item;
          }
          return item.copyWith(
            value: numeric.clamp(item.minValue, item.maxValue).toDouble(),
          );
      }
    }).toList();

    var hasChanged = false;
    for (var i = 0; i < _items.length; i += 1) {
      if (_items[i].value != nextItems[i].value ||
          _items[i].enabled != nextItems[i].enabled) {
        hasChanged = true;
        break;
      }
    }
    if (!hasChanged) {
      return;
    }

    setState(() {
      _items = _normalizeItems(nextItems);
    });
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
    if (text == '1' || text == 'true' || text == 'on') {
      return true;
    }
    if (text == '0' || text == 'false' || text == 'off') {
      return false;
    }
    return null;
  }

  double? _coerceDouble(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is bool) {
      return raw ? 1.0 : 0.0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString().trim());
  }

  List<DashboardItem> _buildInitialItems() {
    return const <DashboardItem>[];
  }

  bool get _hasUnsavedChanges =>
      _layoutStorage.layoutSignature(_items) != _savedLayoutSignature;

  Future<void> _loadLayoutFromStorage() async {
    try {
      final storedItems = await _layoutStorage.loadItems();
      final storedThemePreset = await _layoutStorage.loadDashboardThemePreset();
      final storedCustomThemePreset =
          storedThemePreset.name == customDashboardThemeName
          ? storedThemePreset
          : null;
      final storedDraft = await _layoutStorage.loadBuilderDraft();

      final runtimeResolvedItems = await _runtimeValueStorage.applyToItems(
        storedItems ?? _buildInitialItems(),
      );
      final storedHistory = await _layoutStorage.loadBuilderHistory();
      await _runtimeValueStorage.pruneForItems(runtimeResolvedItems);
      final resolvedItems = _normalizeItems(runtimeResolvedItems);
      final currentSignature = _layoutStorage.layoutSignature(resolvedItems);
      final restoredHistory =
          storedHistory?.currentSignature == currentSignature
          ? storedHistory
          : null;
      final draftItems = storedDraft == null
          ? null
          : _normalizeItems(List<DashboardItem>.from(storedDraft.items));
      final hasRestorableDraft =
          storedDraft != null &&
          draftItems != null &&
          storedDraft.currentSignature != currentSignature &&
          storedDraft.currentSignature ==
              _layoutStorage.layoutSignature(draftItems);
      setState(() {
        _items = resolvedItems;
        _themePreset = storedThemePreset;
        _customThemePreset = storedCustomThemePreset;
        _restoreHistoryStacks(restoredHistory);
        _pendingDraftItems = hasRestorableDraft ? draftItems : null;
        _pendingDraftHistory = hasRestorableDraft
            ? (storedHistory?.currentSignature == storedDraft.currentSignature
                  ? storedHistory
                  : null)
            : null;
        _isLayoutLoading = false;
        _savedLayoutSignature = currentSignature;
        _syncItemSeedFromItems();
      });
      if (hasRestorableDraft) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_promptRestoreDraft());
        });
      } else if (storedDraft != null) {
        unawaited(_layoutStorage.clearBuilderDraft());
        unawaited(_layoutStorage.clearBuilderHistory());
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLayoutLoading = false;
        _savedLayoutSignature = _layoutStorage.layoutSignature(_items);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถโหลดเลย์เอาต์ที่บันทึกไว้ได้')),
      );
    }
  }

  Future<void> _saveLayout({bool showFeedback = true}) async {
    if (_isLayoutSaving) {
      return;
    }
    setState(() {
      _isLayoutSaving = true;
    });

    try {
      await _layoutStorage.saveItems(_items);
      await _draftPersistQueue.catchError((_) {});
      await _layoutStorage.clearBuilderDraft();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingDraftItems = null;
        _pendingDraftHistory = null;
        _savedLayoutSignature = _layoutStorage.layoutSignature(_items);
      });
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกเลย์เอาต์เรียบร้อย')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถบันทึกเลย์เอาต์ได้ในขณะนี้')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLayoutSaving = false;
        });
      }
    }
  }

  Future<bool> _confirmDiscardUnsavedChanges() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final compact = mediaQuery.size.width < 380;
        final horizontalInset = compact ? 18.0 : 24.0;
        final titleFontSize = compact ? 17.0 : 18.0;
        final bodyFontSize = compact ? 13.0 : 14.0;
        final actionHorizontalPadding = compact ? 10.0 : 12.0;
        final saveHorizontalPadding = compact ? 20.0 : 24.0;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: 24,
          ),
          backgroundColor: _themePreset.cardColor,
          surfaceTintColor: Colors.transparent,
          titlePadding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            compact ? 20 : 24,
            compact ? 18 : 24,
            8,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            0,
            compact ? 18 : 24,
            0,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.fromLTRB(
            compact ? 16 : 24,
            12,
            compact ? 16 : 24,
            compact ? 16 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.78)),
          ),
          title: Text(
            'You have unsaved changes.',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: _themePreset.headlineColor,
              fontWeight: FontWeight.w700,
              fontSize: titleFontSize,
              height: 1.18,
            ),
          ),
          content: Text(
            'คุณมีการเปลี่ยนแปลง widget ที่ยังไม่ได้บันทึก ต้องการบันทึกก่อนออกจากหน้านี้หรือไม่?',
            textAlign: TextAlign.center,
            maxLines: 3,
            style: TextStyle(
              color: DashboardRuntimeTheme.labelTextColor,
              fontSize: bodyFontSize,
              height: 1.4,
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC96868),
                foregroundColor: const Color(0xFFFFFBFB),
                padding: EdgeInsets.symmetric(
                  horizontal: actionHorizontalPadding,
                  vertical: 12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => Navigator.pop(context, _LeaveAction.cancel),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: actionHorizontalPadding,
                  vertical: 12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pop(context, _LeaveAction.discard),
              child: const Text(
                'ไม่บันทึก',
                style: TextStyle(color: Color(0xFFC96C78)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: DashboardRuntimeTheme.buttonStartColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: saveHorizontalPadding,
                  vertical: 12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => Navigator.pop(context, _LeaveAction.save),
              child: const Text(
                'บันทึก',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    switch (action) {
      case _LeaveAction.save:
        await _saveLayout(showFeedback: false);
        return !_hasUnsavedChanges;
      case _LeaveAction.discard:
        await _draftPersistQueue.catchError((_) {});
        await _layoutStorage.clearBuilderDraft();
        await _layoutStorage.clearBuilderHistory();
        return true;
      case _LeaveAction.cancel:
      case null:
        return false;
    }
  }

  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop) {
      return;
    }
    final shouldLeave = await _confirmDiscardUnsavedChanges();
    if (!mounted || !shouldLeave) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _promptRestoreDraft() async {
    final draftItems = _pendingDraftItems;
    if (!mounted || draftItems == null || _isLayoutLoading) {
      return;
    }

    final restoreDraft = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _themePreset.cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.78)),
          ),
          title: Text(
            'Restore draft?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _themePreset.headlineColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'An autosaved dashboard draft was found. Restore it or discard the draft and keep the saved layout.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DashboardRuntimeTheme.labelTextColor,
              height: 1.35,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Discard',
                style: TextStyle(color: Color(0xFFC96C78)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardRuntimeTheme.buttonStartColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Restore',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (restoreDraft == true) {
      setState(() {
        _items = _normalizeItems(draftItems);
        _restoreHistoryStacks(_pendingDraftHistory);
        _pendingDraftItems = null;
        _pendingDraftHistory = null;
        _syncItemSeedFromItems();
      });
      _queuePersistBuilderDraft();
      _queuePersistBuilderHistory();
      return;
    }

    setState(() {
      _pendingDraftItems = null;
      _pendingDraftHistory = null;
    });
    await _layoutStorage.clearBuilderDraft();
    await _layoutStorage.clearBuilderHistory();
  }

  void _syncItemSeedFromItems() {
    var maxSeed = _itemSeed;
    final suffixPattern = RegExp(r'-(\d+)$');
    for (final item in _items) {
      final match = suffixPattern.firstMatch(item.id);
      if (match == null) {
        continue;
      }
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > maxSeed) {
        maxSeed = parsed;
      }
    }
    _itemSeed = maxSeed;
  }

  int _columnsForWidth(double width) {
    final rawColumns = ((width + _gridGap) / (_targetCellSize + _gridGap))
        .floor();
    return rawColumns.clamp(_minColumns, _maxColumns);
  }

  GridRect _effectiveCollisionRect({
    required DashboardItem item,
    required GridRect rect,
    required double rowHeight,
  }) {
    if (item.type != DashboardItemType.slider ||
        rowHeight < _sliderCompactCollisionCellThreshold ||
        rect.h <= 1) {
      return rect;
    }

    const itemVisualInset = 2.0;
    final pixelWidth = (rect.w * rowHeight) + ((rect.w - 1) * _gridGap);
    final pixelHeight = (rect.h * rowHeight) + ((rect.h - 1) * _gridGap);
    final contentWidth = math.max(0.0, pixelWidth - (itemVisualInset * 2));
    final contentHeight = math.max(0.0, pixelHeight - (itemVisualInset * 2));
    final layout = buildSliderShellLayout(
      width: contentWidth,
      height: contentHeight,
      desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
      shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
    );
    final topInset = itemVisualInset + layout.shellTopInset;
    final compactTopRows = (topInset / rowHeight)
        .floor()
        .clamp(0, rect.h - 1)
        .toInt();
    if (compactTopRows <= 0) {
      return rect;
    }

    return rect.copyWith(
      y: rect.y + compactTopRows,
      h: rect.h - compactTopRows,
    );
  }

  bool _visualCollisionOverlaps({
    required DashboardItem leftItem,
    required GridRect leftRect,
    required DashboardItem rightItem,
    required GridRect rightRect,
    required double rowHeight,
  }) {
    return DashboardLayoutEngine.overlaps(
      _effectiveCollisionRect(
        item: leftItem,
        rect: leftRect,
        rowHeight: rowHeight,
      ),
      _effectiveCollisionRect(
        item: rightItem,
        rect: rightRect,
        rowHeight: rowHeight,
      ),
    );
  }

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
    if (stack.length <= _maxHistoryEntries) {
      return;
    }
    stack.removeRange(0, stack.length - _maxHistoryEntries);
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

    setState(() {
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

    setState(() {
      _undoStack.add(_captureSnapshot());
      _trimHistoryStack(_undoStack);
      _restoreSnapshot(_redoStack.removeLast());
    });
    _queuePersistBuilderHistory();
    _queuePersistBuilderDraft();
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

  bool _canResizeHorizontally(DashboardItem item) => item.minW != item.maxW;

  bool _canResizeVertically(DashboardItem item) => item.minH != item.maxH;

  BoxDecoration get _pageDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[_themePreset.pageStart, _themePreset.pageEnd],
    ),
  );

  BoxDecoration get _canvasDecoration => AppGlassTheme.surfaceDecoration(
    radius: 34,
    borderAlpha: 0.62,
    colors: _themePreset.canvasColors,
    shadows: AppGlassTheme.shadowLg,
  );

  GridRect _defaultButtonRect({
    required String title,
    required double canvasWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final normalizedTitle = title.trim().isEmpty ? 'Button' : title.trim();
    final minimumRect = _minimumButtonRect(
      title: normalizedTitle,
      canvasWidth: canvasWidth,
      textScaler: textScaler,
      textDirection: textDirection,
    );
    final columns = _columnsForWidth(canvasWidth);
    final cellWidth = (canvasWidth - (_gridGap * (columns - 1))) / columns;
    final rowHeight = cellWidth;

    for (
      var gridW = minimumRect.w > 12 ? minimumRect.w : 12;
      gridW <= 20;
      gridW += 1
    ) {
      for (
        var gridH = minimumRect.h > 6 ? minimumRect.h : 6;
        gridH <= 10;
        gridH += 1
      ) {
        if (_buttonContentFits(
          title: normalizedTitle,
          gridW: gridW,
          gridH: gridH,
          cellWidth: cellWidth,
          rowHeight: rowHeight,
          textScaler: textScaler,
          textDirection: textDirection,
        )) {
          return GridRect(x: 0, y: 0, w: gridW, h: gridH);
        }
      }
    }

    return minimumRect;
  }

  double _fallbackCanvasWidth() {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return 360;
    }

    return (mediaQuery.size.width - 32).clamp(240.0, double.infinity);
  }

  GridRect _minimumButtonRect({
    required String title,
    double? canvasWidth,
    TextScaler? textScaler,
    TextDirection? textDirection,
  }) {
    final effectiveCanvasWidth = canvasWidth ?? _fallbackCanvasWidth();
    final effectiveTextScaler =
        textScaler ??
        MediaQuery.maybeTextScalerOf(context) ??
        TextScaler.noScaling;
    final effectiveTextDirection =
        textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;
    final normalizedTitle = title.trim().isEmpty ? 'Button' : title.trim();
    final columns = _columnsForWidth(effectiveCanvasWidth);
    final cellWidth =
        (effectiveCanvasWidth - (_gridGap * (columns - 1))) / columns;
    final rowHeight = cellWidth;
    GridRect? bestRect;

    for (var gridW = _buttonMinW; gridW <= _buttonMaxW; gridW += 1) {
      for (var gridH = _buttonMinH; gridH <= _buttonMaxH; gridH += 1) {
        if (!_buttonContentFits(
          title: normalizedTitle,
          gridW: gridW,
          gridH: gridH,
          cellWidth: cellWidth,
          rowHeight: rowHeight,
          textScaler: effectiveTextScaler,
          textDirection: effectiveTextDirection,
        )) {
          continue;
        }

        final candidate = GridRect(x: 0, y: 0, w: gridW, h: gridH);
        if (bestRect == null) {
          bestRect = candidate;
          continue;
        }

        final candidateArea = candidate.w * candidate.h;
        final bestArea = bestRect.w * bestRect.h;
        final isBetter =
            candidateArea < bestArea ||
            (candidateArea == bestArea && candidate.h < bestRect.h) ||
            (candidateArea == bestArea &&
                candidate.h == bestRect.h &&
                candidate.w < bestRect.w);
        if (isBetter) {
          bestRect = candidate;
        }
      }
    }

    return bestRect ?? const GridRect(x: 0, y: 0, w: 14, h: 8);
  }

  bool _buttonRectFitsItem({
    required DashboardItem item,
    required GridRect rect,
    double? canvasWidth,
    TextScaler? textScaler,
    TextDirection? textDirection,
  }) {
    final effectiveCanvasWidth = canvasWidth ?? _fallbackCanvasWidth();
    final effectiveTextScaler =
        textScaler ??
        MediaQuery.maybeTextScalerOf(context) ??
        TextScaler.noScaling;
    final effectiveTextDirection =
        textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;
    final columns = _columnsForWidth(effectiveCanvasWidth);
    final cellWidth =
        (effectiveCanvasWidth - (_gridGap * (columns - 1))) / columns;
    final rowHeight = cellWidth;

    return _buttonContentFits(
      title: item.title,
      gridW: rect.w,
      gridH: rect.h,
      cellWidth: cellWidth,
      rowHeight: rowHeight,
      textScaler: effectiveTextScaler,
      textDirection: effectiveTextDirection,
    );
  }

  GridRect _clampGaugeRectToAspect({
    required DashboardItem item,
    required GridRect rect,
  }) {
    if (item.type != DashboardItemType.gauge) {
      return rect;
    }

    var w = rect.w.clamp(item.minW, item.maxW);
    var h = rect.h.clamp(item.minH, item.maxH);
    if (w <= 0 || h <= 0) {
      return rect;
    }

    for (var i = 0; i < 3; i += 1) {
      final ratio = w / h;
      if (ratio > _gaugeMaxAspectRatio) {
        w = (h * _gaugeMaxAspectRatio).round().clamp(item.minW, item.maxW);
        continue;
      }
      if (ratio < _gaugeMinAspectRatio) {
        h = (w / _gaugeMinAspectRatio).round().clamp(item.minH, item.maxH);
        continue;
      }
      break;
    }

    return rect.copyWith(w: w, h: h);
  }

  GridRect _clampToggleRectToAspect({
    required DashboardItem item,
    required GridRect rect,
  }) {
    if (item.type != DashboardItemType.toggle) {
      return rect;
    }

    var w = rect.w.clamp(item.minW, item.maxW);
    var h = rect.h.clamp(item.minH, item.maxH);
    if (w <= 0 || h <= 0) {
      return rect;
    }

    for (var i = 0; i < 3; i += 1) {
      final ratio = w / h;
      if (ratio < _toggleMinAspectRatio) {
        w = (h * _toggleMinAspectRatio).round().clamp(item.minW, item.maxW);
        continue;
      }
      if (ratio > _toggleMaxAspectRatio) {
        h = (w / _toggleMaxAspectRatio).round().clamp(item.minH, item.maxH);
        continue;
      }
      break;
    }

    return rect.copyWith(w: w, h: h);
  }

  bool _buttonContentFits({
    required String title,
    required int gridW,
    required int gridH,
    required double cellWidth,
    required double rowHeight,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final pixelWidth = (gridW * cellWidth) + ((gridW - 1) * _gridGap);
    final pixelHeight = (gridH * rowHeight) + ((gridH - 1) * _gridGap);
    const titleFontSize = 8.0;
    final shortestSide = pixelWidth < pixelHeight ? pixelWidth : pixelHeight;
    final area = pixelWidth * pixelHeight;
    final shellPadding = shortestSide >= 156 || area >= 36000
        ? 7.0
        : shortestSide >= 108 || area >= 18000
        ? 6.5
        : 6.0;
    const innerInset = 4.0;
    final contentWidth = pixelWidth - (shellPadding * 2);
    final contentHeight = pixelHeight - (shellPadding * 2);

    if (contentWidth <= 0 || contentHeight <= 0) {
      return false;
    }

    final controlAreaHeight = contentHeight;
    if (controlAreaHeight <= 0) {
      return false;
    }

    final rawControlWidth = contentWidth - (innerInset * 2);
    final controlWidth = rawControlWidth > 0 ? rawControlWidth : 0.0;
    final rawControlHeight = controlAreaHeight - (innerInset * 2);
    final controlHeight = rawControlHeight > 0 ? rawControlHeight : 0.0;
    final baseIconSize = shortestSide >= 156 || area >= 36000
        ? 24.0
        : shortestSide >= 108 || area >= 18000
        ? 22.0
        : 20.0;
    final showStatus = controlHeight >= 54 && controlWidth >= 78;
    final statusFontSize = shortestSide >= 156 || area >= 36000
        ? 14.0
        : shortestSide >= 108 || area >= 18000
        ? 13.0
        : 12.0;
    final statusGap = showStatus
        ? (controlHeight * 0.05).clamp(3.0, 10.0).toDouble()
        : 0.0;
    final maxIconFromHeight = showStatus
        ? controlHeight - statusFontSize - statusGap - 12
        : controlHeight - 12;
    final maxIconFromWidth = controlWidth - 16;
    final maxSafeIconSize = maxIconFromHeight < maxIconFromWidth
        ? maxIconFromHeight
        : maxIconFromWidth;
    final iconSize = maxSafeIconSize <= 0
        ? 0.0
        : (baseIconSize < maxSafeIconSize
              ? baseIconSize
              : maxSafeIconSize.clamp(14.0, 26.0).toDouble());

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: 1,
    )..layout(maxWidth: contentWidth);

    final statusPainter = TextPainter(
      text: TextSpan(
        text: 'OFF',
        style: TextStyle(
          fontSize: statusFontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: 1,
    )..layout(maxWidth: controlWidth);

    final requiredControlHeight = showStatus
        ? iconSize + statusGap + statusPainter.height + 12
        : iconSize + 12;
    final requiredControlWidth = showStatus
        ? (iconSize > statusPainter.width ? iconSize : statusPainter.width) + 16
        : iconSize + 16;

    final titleFitsHeader =
        titlePainter.width <= pixelWidth && pixelWidth >= 36;
    final controlFits =
        requiredControlHeight <= controlHeight &&
        requiredControlWidth <= controlWidth;

    return titleFitsHeader && controlFits;
  }

  DashboardItem _normalizeItem(DashboardItem item) {
    if (item.type == DashboardItemType.button) {
      final minimumRect = _minimumButtonRect(title: item.title);
      return item.copyWith(
        minW: minimumRect.w,
        minH: minimumRect.h,
        maxH: _buttonMaxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minimumRect.w, _buttonMaxW),
          h: item.rect.h.clamp(minimumRect.h, _buttonMaxH),
        ),
      );
    }

    if (item.type == DashboardItemType.gauge) {
      return item.copyWith(
        rect: _clampGaugeRectToAspect(item: item, rect: item.rect),
      );
    }

    if (item.type == DashboardItemType.toggle) {
      const minW = 6;
      const maxW = 18;
      const minH = 3;
      const maxH = 8;
      final clampedRect = _clampToggleRectToAspect(item: item, rect: item.rect);
      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: clampedRect.x,
          y: clampedRect.y,
          w: clampedRect.w.clamp(minW, maxW),
          h: clampedRect.h.clamp(minH, maxH),
        ),
      );
    }

    if (item.type == DashboardItemType.slider) {
      const minW = 10;
      const maxW = 28;
      const minH = 4;
      const maxH = 4;
      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minW, maxW),
          h: item.rect.h.clamp(minH, maxH),
        ),
      );
    }

    return item;
  }

  List<DashboardItem> _normalizeItems(List<DashboardItem> items) {
    return items.map(_normalizeItem).toList();
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

    setState(() {
      _exitSelectMode();
    });
  }

  void _resetInteractionState() {
    _interactionState.reset();
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

    setState(() {
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
              color: const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
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
                          color: Color(0xFF20303A),
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
                    color: Color(0xFF667587),
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
                                          color: Color(0xFF20303A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${rule.widgetTitle}'
                                        '${rule.enabled ? '' : ' • disabled'}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF7B8895),
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

  void _updateItemFromRenderer(DashboardItem nextItem) {
    final previousItem = _findItemById(nextItem.id, _items);
    setState(() {
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

    final pin = _extractVirtualPin(next.dataKey);
    if (pin == null) {
      return;
    }

    final value = _extractControlValue(next);
    if (value == null) {
      return;
    }

    final writeKey = '${next.id}:$pin';
    final payload = _QueuedControlWrite(
      pin: pin,
      value: value,
      valueType: _resolveBindingValueType(next),
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
        binding: WidgetBindingModel(
          source: WidgetBindingSource.api,
          pin: payload.pin,
          valueType: payload.valueType,
        ),
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
        type == DashboardItemType.slider;
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
        return previous.value != next.value;
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
        return false;
    }
  }

  String? _extractVirtualPin(String? rawKey) {
    final value = rawKey?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final match = RegExp(r'V\d+', caseSensitive: false).firstMatch(value);
    return match?.group(0)?.toUpperCase();
  }

  Object? _extractControlValue(DashboardItem item) {
    switch (item.type) {
      case DashboardItemType.button:
      case DashboardItemType.toggle:
        return item.enabled;
      case DashboardItemType.slider:
        return item.value;
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
        return null;
    }
  }

  Object _serializeWidgetValue(DashboardItem item) {
    return switch (item.type) {
      DashboardItemType.button || DashboardItemType.toggle => item.enabled,
      DashboardItemType.slider ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => item.value,
    };
  }

  WidgetBindingValueType _resolveBindingValueType(DashboardItem item) {
    final normalizedType = item.dataType.trim().toLowerCase();
    if (normalizedType.contains('bool')) {
      return WidgetBindingValueType.boolean;
    }
    if (normalizedType.contains('number') ||
        normalizedType.contains('int') ||
        normalizedType.contains('float') ||
        normalizedType.contains('decimal')) {
      return WidgetBindingValueType.number;
    }

    return switch (item.type) {
      DashboardItemType.button ||
      DashboardItemType.toggle => WidgetBindingValueType.boolean,
      DashboardItemType.slider ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => WidgetBindingValueType.number,
    };
  }

  List<DashboardItem> _syncItemsForSharedBinding({
    required DashboardItem source,
    required List<DashboardItem> items,
  }) {
    final bindingKey = _normalizedBindingKey(source.dataKey);
    if (bindingKey == null) {
      return items.map((item) => item.id == source.id ? source : item).toList();
    }

    final serializedValue = _serializeWidgetValue(source);
    return items.map((item) {
      if (item.id == source.id) {
        return source;
      }

      final itemBindingKey = _normalizedBindingKey(item.dataKey);
      if (itemBindingKey != bindingKey) {
        return item;
      }

      return _copyItemWithSerializedValue(item, serializedValue);
    }).toList();
  }

  DashboardItem _copyItemWithSerializedValue(DashboardItem item, Object value) {
    switch (item.type) {
      case DashboardItemType.button:
      case DashboardItemType.toggle:
        final enabled = _coerceBool(value);
        if (enabled == null) {
          return item;
        }
        return item.copyWith(enabled: enabled, value: enabled ? 1.0 : 0.0);
      case DashboardItemType.slider:
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
        final numeric = _coerceDouble(value);
        if (numeric == null) {
          return item;
        }
        return item.copyWith(
          value: numeric.clamp(item.minValue, item.maxValue).toDouble(),
        );
    }
  }

  String? _normalizedBindingKey(String? rawKey) {
    final key = rawKey?.trim();
    if (key == null || key.isEmpty) {
      return null;
    }
    return key.toUpperCase();
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

  Future<void> _openEditModeInfoSheet() async {
    const rows = <MapEntry<String, String>>[
      MapEntry(
        'เพิ่มวิดเจ็ต',
        'แตะปุ่ม + ตรงกลางด้านล่างเพื่อเพิ่ม widget ใหม่ลงบนพื้นที่ว่าง dashboard',
      ),
      MapEntry(
        'เลือกวิดเจ็ต',
        'แตะ widget หนึ่งครั้งเพื่อเลือก และเปิดปุ่ม Settings หรือ Delete',
      ),
      MapEntry('ย้ายวิดเจ็ต', 'กดค้างบน widget แล้วลากไปตำแหน่งใหม่บน grid'),
      MapEntry(
        'ปรับขนาด',
        'เลือก widget แล้วลากจุดจับรอบกรอบเพื่อปรับขนาดความกว้างและความสูง',
      ),
      MapEntry(
        'เลือกหลายวิดเจ็ต',
        'ใช้ปุ่ม Select ด้านล่างเพื่อเข้าโหมดเลือกหลายชิ้น แล้วแตะเลือก widget หลายตัวได้',
      ),
      MapEntry(
        'คัดลอกวิดเจ็ต',
        'เลือก widget แล้วกด Duplicate เพื่อสร้างสำเนาใกล้ตำแหน่งเดิม',
      ),
      MapEntry(
        'ตั้งค่าวิดเจ็ต',
        'กด Settings เพื่อแก้ Data Key, title, style และค่าต่างๆ ของ widget',
      ),
      MapEntry(
        'บันทึกเลย์เอาต์',
        'เมื่อจัดวางเสร็จแล้วกด บันทึก ด้านบนเพื่อบันทึก layout ล่าสุด',
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: DecoratedBox(
              decoration: DashboardRuntimeTheme.cardDecoration(radius: 28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: AppGlassTheme.surfaceDecoration(
                                radius: 15,
                                borderAlpha: 0.34,
                                colors: <Color>[
                                  Colors.white.withValues(alpha: 0.62),
                                  const Color(
                                    0xFFEAF3FF,
                                  ).withValues(alpha: 0.26),
                                ],
                                shadows: const <BoxShadow>[],
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: DashboardRuntimeTheme.labelTextColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'คู่มือโหมดแก้ไข',
                                style: TextStyle(
                                  color: _themePreset.headlineColor,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'วิธีใช้งานหน้าโหมดแก้ไขและการจัดการ widget',
                                style: TextStyle(
                                  color: _themePreset.mutedTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: AppGlassTheme.surfaceDecoration(
                                    radius: 15,
                                    borderAlpha: 0.3,
                                    colors: <Color>[
                                      Colors.white.withValues(alpha: 0.54),
                                      const Color(
                                        0xFFF2F6FB,
                                      ).withValues(alpha: 0.2),
                                    ],
                                    shadows: const <BoxShadow>[],
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: _themePreset.mutedTextColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final row in rows)
                              _BuilderInfoRow(label: row.key, value: row.value),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleMultiSelectMode() {
    setState(() {
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
    if (rect.right > columns || rect.bottom > _maxRows) {
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

    final maxDistance = columns > _maxRows ? columns : _maxRows;
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
    for (var y = 0; y <= _maxRows - sourceRect.h; y++) {
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

    final canvasWidth = MediaQuery.of(context).size.width - 32;
    final columns = _columnsForWidth(canvasWidth);
    final rowHeight = (canvasWidth - (_gridGap * (columns - 1))) / columns;
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

    setState(() {
      _pushUndoSnapshot();
      _items = _normalizeItems([..._items, ...duplicates]);
      _exitSelectMode(keepSelectedId: duplicates.last.id);
      _resetInteractionState();
    });
  }

  Widget _buildSaveAction() {
    final canSave = !_isLayoutLoading && !_isLayoutSaving && _hasUnsavedChanges;
    return Tooltip(
      message: canSave ? 'บันทึกเลย์เอาต์' : 'ไม่มีการเปลี่ยนแปลงให้บันทึก',
      child: DecoratedBox(
        decoration: canSave
            ? AppGlassTheme.accentDecoration(
                radius: 999,
                borderColor: DashboardRuntimeTheme.surfaceBorderFocusColor,
                colors: const <Color>[
                  DashboardRuntimeTheme.buttonStartColor,
                  DashboardRuntimeTheme.buttonEndColor,
                ],
                glowColor: DashboardRuntimeTheme.buttonGlowColor,
              )
            : AppGlassTheme.surfaceDecoration(
                radius: 999,
                borderAlpha: 0.60,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.54),
                  const Color(0xFFF0F4F8).withValues(alpha: 0.30),
                ],
                shadows: const <BoxShadow>[],
              ),
        child: TextButton.icon(
          onPressed: canSave ? () => _saveLayout() : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            foregroundColor: canSave
                ? Colors.white
                : _themePreset.mutedTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            backgroundColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: _isLayoutSaving
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save_rounded, size: 13),
          label: const Text(
            'บันทึก',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Future<void> _openThemeAction() async {
    final selectedPresetName = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const outerHorizontalPadding = 28.0;
              const sheetHorizontalPadding = 36.0;
              const tileGap = 8.0;
              final tileWidth =
                  (constraints.maxWidth -
                      outerHorizontalPadding -
                      sheetHorizontalPadding -
                      (tileGap * 2)) /
                  3;

              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                child: DecoratedBox(
                  decoration: DashboardRuntimeTheme.cardDecoration(radius: 28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: AppGlassTheme.surfaceDecoration(
                                    radius: 15,
                                    borderAlpha: 0.34,
                                    colors: <Color>[
                                      Colors.white.withValues(alpha: 0.62),
                                      const Color(
                                        0xFFEAF3FF,
                                      ).withValues(alpha: 0.26),
                                    ],
                                    shadows: const <BoxShadow>[],
                                  ),
                                  child: Icon(
                                    Icons.palette_rounded,
                                    color: DashboardRuntimeTheme.labelTextColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dashboard Theme',
                                style: TextStyle(
                                  color: _themePreset.headlineColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: DashboardRuntimeTheme.labelTextColor,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: tileGap,
                          runSpacing: tileGap,
                          children: [
                            for (final preset in dashboardThemePresets)
                              _buildThemePresetTile(
                                context,
                                preset,
                                width: tileWidth,
                              ),
                            _buildCustomThemeTile(context, width: tileWidth),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selectedPresetName == null) {
      return;
    }

    final selectedPreset = selectedPresetName == customDashboardThemeName
        ? await _openCustomThemeEditor()
        : dashboardThemePresetByName(selectedPresetName);
    if (!mounted || selectedPreset == null) {
      return;
    }

    setState(() {
      _themePreset = selectedPreset;

      if (selectedPreset.name == customDashboardThemeName) {
        _customThemePreset = selectedPreset;
      }
    });

    try {
      await _layoutStorage.saveDashboardThemePreset(selectedPreset);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save dashboard theme.')),
      );
    }
  }

  Widget _buildThemeAction() {
    final canOpenTheme = _isEditMode && !_isLayoutLoading;
    return DecoratedBox(
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 999,
        borderAlpha: canOpenTheme ? 0.66 : 0.56,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: canOpenTheme ? 0.62 : 0.46),
          const Color(0xFFEAF2F8).withValues(alpha: canOpenTheme ? 0.34 : 0.22),
        ],
        shadows: const <BoxShadow>[],
      ),
      child: Semantics(
        button: true,
        enabled: canOpenTheme,
        label: 'เปลี่ยนธีม',
        child: IconButton(
          onPressed: canOpenTheme ? _openThemeAction : null,
          icon: Icon(
            Icons.palette_rounded,
            size: 17,
            color: canOpenTheme
                ? _themePreset.headlineColor
                : _themePreset.mutedTextColor,
          ),
          padding: const EdgeInsets.all(7),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          splashRadius: 18,
          tooltip: 'เปลี่ยนธีม',
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildThemePresetTile(
    BuildContext context,
    DashboardThemePreset preset, {
    required double width,
  }) {
    final isSelected = preset.name == _themePreset.name;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pop(preset.name),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? DashboardRuntimeTheme.surfaceBorderFocusColor
                  : DashboardRuntimeTheme.surfaceBorderColor,
              width: isSelected ? 1.6 : 1,
            ),
            color: _themePreset.surfaceColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  height: 46,
                  child: Column(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[preset.pageStart, preset.pageEnd],
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: preset.canvasColors,
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _themePreset.headlineColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: DashboardRuntimeTheme.surfaceBorderFocusColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomThemeTile(BuildContext context, {required double width}) {
    final isSelected = _themePreset.name == customDashboardThemeName;
    final previewPreset = _customThemePreset ?? _themePreset;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pop(customDashboardThemeName),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? DashboardRuntimeTheme.surfaceBorderFocusColor
                  : DashboardRuntimeTheme.surfaceBorderColor,
              width: isSelected ? 1.6 : 1,
            ),
            color: _themePreset.surfaceColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: <Color>[
                      previewPreset.canvasColors.first,
                      previewPreset.gridColor.withValues(alpha: 0.78),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customDashboardThemeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _themePreset.headlineColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: DashboardRuntimeTheme.surfaceBorderFocusColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DashboardThemePreset?> _openCustomThemeEditor() async {
    final initialPreset = _customThemePreset ?? _themePreset;

    var canvasColor = initialPreset.canvasColors.first.withAlpha(255);
    var gridColor = initialPreset.gridColor.withAlpha(255);

    return showModalBottomSheet<DashboardThemePreset>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final draftPreset = dashboardCustomThemePreset(
              canvasColor: canvasColor,
              gridColor: gridColor,
            );

            Future<void> pickColor({
              required String title,
              required Color initialColor,
              required ValueChanged<Color> onPicked,
            }) async {
              final nextColor = await _openThemeColorPicker(
                context: context,
                title: title,
                initialColor: initialColor,
              );
              if (nextColor == null) {
                return;
              }
              setSheetState(() => onPicked(nextColor));
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: DecoratedBox(
                  decoration: DashboardRuntimeTheme.cardDecoration(radius: 28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Custom Theme',
                                style: TextStyle(
                                  color: _themePreset.headlineColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: DashboardRuntimeTheme.labelTextColor,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 96,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: draftPreset.canvasColors,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: DashboardGridPainter(
                                      columns: 8,
                                      rows: 4,
                                      gap: 0,
                                      lineColor: draftPreset.gridColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildCustomColorRow(
                          label: 'Canvas',
                          color: canvasColor,
                          onTap: () => pickColor(
                            title: 'Canvas Color',
                            initialColor: canvasColor,
                            onPicked: (color) => canvasColor = color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCustomColorRow(
                          label: 'Grid',
                          color: gridColor,
                          onTap: () => pickColor(
                            title: 'Grid Color',
                            initialColor: gridColor,
                            onPicked: (color) => gridColor = color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: AppGlassTheme.accentDecoration(
                              radius: 16,
                              borderColor:
                                  DashboardRuntimeTheme.surfaceBorderFocusColor,
                              colors: const <Color>[
                                DashboardRuntimeTheme.buttonStartColor,
                                DashboardRuntimeTheme.buttonEndColor,
                              ],
                              glowColor: DashboardRuntimeTheme.buttonGlowColor,
                            ),
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(draftPreset),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomColorRow({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardRuntimeTheme.surfaceBorderColor),
            color: _themePreset.surfaceColor,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _themePreset.headlineColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DashboardRuntimeTheme.labelTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Color?> _openThemeColorPicker({
    required BuildContext context,
    required String title,
    required Color initialColor,
  }) async {
    var draftColor = initialColor;
    return showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: DecoratedBox(
                  decoration: DashboardRuntimeTheme.cardDecoration(radius: 28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: _themePreset.headlineColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: ColorPicker(
                            pickerColor: draftColor,
                            onColorChanged: (color) {
                              setSheetState(() {
                                draftColor = color.withAlpha(255);
                              });
                            },
                            enableAlpha: false,
                            displayThumbColor: true,
                            portraitOnly: true,
                            labelTypes: const <ColorLabelType>[],
                            pickerAreaHeightPercent: 0.72,
                            hexInputBar: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(draftColor),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoAction() {
    final canOpenInfo = _isEditMode;
    return DecoratedBox(
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 999,
        borderAlpha: canOpenInfo ? 0.66 : 0.56,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: canOpenInfo ? 0.62 : 0.46),
          const Color(0xFFEAF2F8).withValues(alpha: canOpenInfo ? 0.34 : 0.22),
        ],
        shadows: const <BoxShadow>[],
      ),
      child: Semantics(
        button: true,
        enabled: canOpenInfo,
        label: 'วิธีใช้งาน',
        child: IconButton(
          onPressed: canOpenInfo ? _openEditModeInfoSheet : null,
          icon: Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: canOpenInfo
                ? _themePreset.headlineColor
                : _themePreset.mutedTextColor,
          ),
          padding: const EdgeInsets.all(7),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          splashRadius: 18,
          tooltip: 'วิธีใช้งาน',
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedWidgetInspector(DashboardItem item) {
    final pin = item.dataKey?.trim();

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: 22,
                    borderAlpha: 0.54,
                    colors: <Color>[
                      const Color(0xFFFFFFFF).withValues(alpha: 0.74),
                      const Color(0xFFF3FAF7).withValues(alpha: 0.42),
                    ],
                    shadows: AppGlassTheme.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _InspectorPill(
                              label: pin == null || pin.isEmpty
                                  ? 'V Pin: No pin'
                                  : 'V Pin: $pin',
                              muted: pin == null || pin.isEmpty,
                              themePreset: _themePreset,
                            ),
                            _InspectorPill(
                              label: 'Size: ${item.rect.w}x${item.rect.h}',
                              themePreset: _themePreset,
                            ),
                            _InspectorPill(
                              label: 'x:${item.rect.x} y:${item.rect.y}',
                              themePreset: _themePreset,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedWidgetInspectorSlot(DashboardItem? item) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 210),
      reverseDuration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ClipRect(
          child: SizeTransition(
            sizeFactor: curvedAnimation,
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            ),
          ),
        );
      },
      child: item == null
          ? const SizedBox.shrink(key: ValueKey('empty-inspector'))
          : KeyedSubtree(
              key: const ValueKey('visible-inspector'),
              child: _buildSelectedWidgetInspector(item),
            ),
    );
  }

  Widget _buildFloatingControls() {
    const accentLineColor = DashboardRuntimeTheme.surfaceBorderFocusColor;
    final outerRingColor = _themePreset.cardColor;
    const baseAddButtonSize = 74.0;
    const baseSecondaryButtonSize = 40.0;
    const baseSecondaryGap = 8.0;
    const baseGroupGap = 12.0;
    final mediaQuery = MediaQuery.of(context);
    final availableWidth =
        mediaQuery.size.width - mediaQuery.padding.horizontal - 24;
    const baseButtonCount = 7;
    const baseGapCount = 4;
    final baseRequiredWidth =
        baseAddButtonSize +
        (baseSecondaryButtonSize * (baseButtonCount - 1)) +
        (baseSecondaryGap * 2) +
        (baseGroupGap * baseGapCount);
    final controlsScale = (availableWidth / baseRequiredWidth)
        .clamp(0.78, 1.0)
        .toDouble();
    final addButtonSize = (baseAddButtonSize * controlsScale)
        .clamp(58.0, baseAddButtonSize)
        .toDouble();
    final secondaryButtonSize = (baseSecondaryButtonSize * controlsScale)
        .clamp(32.0, baseSecondaryButtonSize)
        .toDouble();
    final secondaryGap = (baseSecondaryGap * controlsScale)
        .clamp(4.0, baseSecondaryGap)
        .toDouble();
    final groupGap = (baseGroupGap * controlsScale)
        .clamp(6.0, baseGroupGap)
        .toDouble();
    final actionIconSize = (18.0 * controlsScale).clamp(15.0, 18.0).toDouble();
    final baseAlwaysVisibleReserve =
        groupGap + (secondaryButtonSize * 1) + (secondaryGap * 0);
    final selectionReserve =
        groupGap + (secondaryButtonSize * 2) + secondaryGap;
    final leftReserve = baseAlwaysVisibleReserve + selectionReserve;
    final rightReserve = baseAlwaysVisibleReserve + selectionReserve;
    final contextActionOpacity = _hasSelection ? 1.0 : 0.0;
    final contextActionScale = _hasSelection ? 1.0 : 0.88;

    return Transform.translate(
      offset: const Offset(0, 6),
      child: SizedBox(
        width: addButtonSize + leftReserve + rightReserve,
        height: addButtonSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Semantics(
              button: true,
              label: 'เพิ่มวิดเจ็ต',
              child: Tooltip(
                message: 'เพิ่มวิดเจ็ต',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openAddWidgetSheet,
                  child: SizedBox(
                    width: addButtonSize,
                    height: addButtonSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: addButtonSize,
                          height: addButtonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DashboardRuntimeTheme.shadowLightColor,
                                blurRadius: 12,
                              ),
                              BoxShadow(
                                color: accentLineColor.withValues(alpha: 0.14),
                                blurRadius: 16,
                                spreadRadius: 0.2,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: addButtonSize * 0.84,
                          height: addButtonSize * 0.84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: outerRingColor,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.78),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: DashboardRuntimeTheme.shadowLightColor,
                                blurRadius: 6,
                              ),
                              BoxShadow(
                                color: DashboardRuntimeTheme.shadowDarkColor,
                                blurRadius: 10,
                                offset: Offset(4, 6),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: addButtonSize * 0.73,
                          height: addButtonSize * 0.73,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                DashboardRuntimeTheme.buttonStartColor,
                                DashboardRuntimeTheme.buttonEndColor,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.34),
                              width: 0.9,
                            ),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: (addButtonSize * 0.4).clamp(22.0, 30.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right:
                  ((addButtonSize + (leftReserve + rightReserve)) / 2) +
                  (addButtonSize / 2) +
                  groupGap,
              bottom: 8,
              child: _BuilderActionButton(
                icon: Icons.undo_rounded,
                onPressed: _canUndo ? _undo : () {},
                tooltip: 'Undo',
                backgroundColor: _canUndo
                    ? _undoActionTone.background
                    : _themePreset.surfaceColor,
                foregroundColor: _canUndo
                    ? _undoActionTone.foreground
                    : const Color(0xFF9DA6B3),
                size: secondaryButtonSize,
                iconSize: actionIconSize,
                glowColor: _canUndo
                    ? _undoActionTone.glow
                    : DashboardRuntimeTheme.surfaceBorderColor,
                glowScale: _canUndo ? 1.1 : 0.7,
              ),
            ),
            Positioned(
              left:
                  ((addButtonSize + (leftReserve + rightReserve)) / 2) +
                  (addButtonSize / 2) +
                  groupGap,
              bottom: 8,
              child: _BuilderActionButton(
                icon: Icons.redo_rounded,
                onPressed: _canRedo ? _redo : () {},
                tooltip: 'Redo',
                backgroundColor: _canRedo
                    ? _redoActionTone.background
                    : _themePreset.surfaceColor,
                foregroundColor: _canRedo
                    ? _redoActionTone.foreground
                    : const Color(0xFF9DA6B3),
                size: secondaryButtonSize,
                iconSize: actionIconSize,
                glowColor: _canRedo
                    ? _redoActionTone.glow
                    : DashboardRuntimeTheme.surfaceBorderColor,
                glowScale: _canRedo ? 1.1 : 0.7,
              ),
            ),
            Positioned(
              right:
                  ((addButtonSize + (leftReserve + rightReserve)) / 2) +
                  (addButtonSize / 2) +
                  groupGap +
                  secondaryButtonSize +
                  secondaryGap,
              bottom: 8,
              child: IgnorePointer(
                ignoring: !_hasSelection,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  opacity: contextActionOpacity,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    scale: contextActionScale,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BuilderActionButton(
                          icon: Icons.copy_all_rounded,
                          onPressed: _duplicateSelectedItems,
                          tooltip: 'Duplicate',
                          backgroundColor: _duplicateActionTone.background,
                          foregroundColor: _duplicateActionTone.foreground,
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: _duplicateActionTone.glow,
                        ),
                        SizedBox(width: secondaryGap),
                        _BuilderActionButton(
                          icon: _isMultiSelectMode
                              ? Icons.library_add_check_rounded
                              : Icons.select_all_rounded,
                          onPressed: _toggleMultiSelectMode,
                          tooltip: _isMultiSelectMode ? 'Selecting' : 'Select',
                          backgroundColor: _isMultiSelectMode
                              ? _selectionActionTone.background
                              : const Color(0xFFF0F8F8),
                          foregroundColor: _isMultiSelectMode
                              ? _selectionActionTone.foreground
                              : const Color(0xFF789C98),
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: _isMultiSelectMode
                              ? _selectionActionTone.glow
                              : DashboardRuntimeTheme.surfaceBorderColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left:
                  ((addButtonSize + (leftReserve + rightReserve)) / 2) +
                  (addButtonSize / 2) +
                  groupGap +
                  secondaryButtonSize +
                  secondaryGap,
              bottom: 8,
              child: IgnorePointer(
                ignoring: !_hasSelection,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  opacity: contextActionOpacity,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    scale: contextActionScale,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BuilderActionButton(
                          icon: Icons.settings_rounded,
                          onPressed: _hasSingleSelection
                              ? _openSelectedItemSettings
                              : () {},
                          tooltip: 'Settings',
                          backgroundColor: _hasSingleSelection
                              ? _settingsActionTone.background
                              : const Color(0xFFFBF4EA),
                          foregroundColor: _hasSingleSelection
                              ? _settingsActionTone.foreground
                              : const Color(0xFF9D8961),
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: _hasSingleSelection
                              ? _settingsActionTone.glow
                              : DashboardRuntimeTheme.surfaceBorderColor,
                        ),
                        SizedBox(width: secondaryGap),
                        _BuilderActionButton(
                          icon: Icons.delete_outline_rounded,
                          onPressed: _removeSelectedItem,
                          tooltip: 'Delete',
                          backgroundColor: _deleteActionTone.background,
                          foregroundColor: _deleteActionTone.foreground,
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: _deleteActionTone.glow,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final titleFontSize = maxWidth < 360 ? 18.0 : 22.0;
        final bodyFontSize = maxWidth < 360 ? 13.0 : 14.0;
        final topBottomPadding = maxHeight < 560 ? 20.0 : 30.0;

        return Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              30,
              topBottomPadding,
              30,
              topBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เพิ่มวิดเจ็ตเพื่อเริ่มใช้งาน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                    color: _themePreset.headlineColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'แตะปุ่ม + หรือลากและวางวิดเจ็ต\nเพื่อสร้างแดชบอร์ดของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    height: 1.3,
                    color: const Color.fromARGB(
                      255,
                      0,
                      0,
                      0,
                    ).withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassEmptyState() {
    assert(() {
      _buildEmptyState;
      return true;
    }());
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final titleFontSize = maxWidth < 360 ? 18.0 : 22.0;
        final bodyFontSize = maxWidth < 360 ? 13.0 : 14.0;
        final topBottomPadding = maxHeight < 560 ? 20.0 : 30.0;

        return Align(
          alignment: const Alignment(0, 0.78),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              30,
              topBottomPadding,
              30,
              topBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                      decoration: AppGlassTheme.surfaceDecoration(
                        radius: 28,
                        borderAlpha: 0.64,
                        colors: <Color>[
                          const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                          const Color(0xFFF4FBF7).withValues(alpha: 0.42),
                        ],
                        shadows: AppGlassTheme.shadowMd,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'เริ่มจัดวางวิดเจ็ตในโหมดแก้ไข',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                              color: _themePreset.headlineColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'แตะปุ่ม + เพื่อเพิ่มวิดเจ็ต แล้วลากจัดวางบนพื้นที่นี้',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: bodyFontSize,
                              height: 1.35,
                              color: _themePreset.mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 116,
                  child: Stack(
                    children: [
                      Align(
                        alignment: const Alignment(-0.58, 0),
                        child: SizedBox(
                          width: 116,
                          height: 116,
                          child: Image.asset(
                            'assets/icons/mascot/mascot_editMode.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(0.58, 0),
                        child: SizedBox(
                          width: 116,
                          height: 116,
                          child: Image.asset(
                            'assets/icons/mascot/mascot_editMode2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    setState(() {
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
        final initialChildSize = shortestSide >= 600 ? 0.56 : 0.62;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: 0.32,
          maxChildSize: initialChildSize,
          builder: (context, scrollController) {
            return AddWidgetSheet(scrollController: scrollController);
          },
        );
      },
    );

    if (!mounted || type == null) {
      return;
    }

    _itemSeed += 1;
    final canvasWidth = MediaQuery.of(context).size.width - 32;
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final columns = _columnsForWidth(canvasWidth);
    final placedItem = DashboardAddWidgetService.createPlacedItem(
      items: _items,
      type: type,
      seed: _itemSeed,
      columns: columns,
      maxRows: _maxRows,
      buttonMinW: _buttonMinW,
      buttonMaxW: _buttonMaxW,
      buttonMinH: _buttonMinH,
      buttonMaxH: _buttonMaxH,
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

    setState(() {
      _pushUndoSnapshot();
      _items = _normalizeItems(<DashboardItem>[..._items, placedItem]);
      _exitSelectMode();
      _resetInteractionState();
    });
  }

  void _startMove(DashboardItem item, Offset globalPosition) {
    if (!_isEditMode || item.locked) {
      return;
    }

    setState(() {
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

  void _startResize(
    DashboardItem item,
    Offset globalPosition, {
    required DashboardBuilderResizeHandlePosition handle,
  }) {
    if (!_isEditMode || item.locked) {
      return;
    }

    setState(() {
      _setSingleSelection(item.id);
      _interactionState.startResize(
        itemId: item.id,
        globalPosition: globalPosition,
        rect: item.rect,
        items: _items,
        handle: handle,
      );
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
          _maxRows - item.minH,
        );
        final maxTop = (anchoredBottom - item.minH).clamp(
          0,
          _maxRows - item.minH,
        );
        nextY = (startRect.y + gridDy).clamp(minTop, maxTop);
        nextH = anchoredBottom - nextY;
        break;
      case DashboardBuilderResizeHandlePosition.topRight:
        final anchoredBottom = startRect.bottom;
        final minTop = (anchoredBottom - item.maxH).clamp(
          0,
          _maxRows - item.minH,
        );
        final maxTop = (anchoredBottom - item.minH).clamp(
          0,
          _maxRows - item.minH,
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
        final maxBottom = (startRect.y + item.maxH).clamp(0, _maxRows);
        nextH = desiredBottom.clamp(minBottom, maxBottom) - startRect.y;
        break;
      case DashboardBuilderResizeHandlePosition.bottom:
        final desiredBottom = startRect.bottom + gridDy;
        final minBottom = startRect.y + item.minH;
        final maxBottom = (startRect.y + item.maxH).clamp(0, _maxRows);
        nextH = desiredBottom.clamp(minBottom, maxBottom) - startRect.y;
        break;
      case DashboardBuilderResizeHandlePosition.bottomLeft:
        final desiredBottom = startRect.bottom + gridDy;
        final minBottom = startRect.y + item.minH;
        final maxBottom = (startRect.y + item.maxH).clamp(0, _maxRows);
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
          _maxRows - item.minH,
        );
        final maxTop = (anchoredBottom - item.minH).clamp(
          0,
          _maxRows - item.minH,
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
      setState(() {
        _previewRect = _lastValidRect ?? item.rect;
        _previewInvalid = false;
      });
      return;
    }

    final previewRect = DashboardLayoutEngine.clampRect(
      item: item,
      rect: constrainedCandidate,
      columns: columns,
      maxRows: _maxRows,
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
      setState(() {
        _previewRect = previewRect;
        _previewInvalid = true;
      });
      return;
    }

    final nextItems = _items
        .map(
          (other) =>
              other.id == item.id ? other.copyWith(rect: previewRect) : other,
        )
        .toList();

    setState(() {
      _previewItems = nextItems;
      _previewRect = previewRect;
      _lastValidRect = previewRect;
      _previewInvalid = false;
    });
  }

  void _finishGesture() {
    final activeId = _activeGestureItemId;
    final lastValidRect = _lastValidRect;
    _stopGestureAutoScroll();
    if (activeId == null) {
      return;
    }

    if (_previewItems != null && !_previewInvalid) {
      setState(() {
        _pushUndoSnapshot();
        _items = _normalizeItems(_previewItems!);
      });
    } else if (lastValidRect != null) {
      final item = _findItemById(activeId, _items);
      if (item != null) {
        setState(() {
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

    setState(() {
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
    if (localPosition.dy < _dragAutoScrollEdgeThreshold) {
      final factor =
          ((_dragAutoScrollEdgeThreshold - localPosition.dy) /
                  _dragAutoScrollEdgeThreshold)
              .clamp(0.0, 1.0);
      delta = -_dragAutoScrollMaxStep * factor;
    } else if (localPosition.dy >
        viewportHeight - _dragAutoScrollEdgeThreshold) {
      final factor =
          ((localPosition.dy -
                      (viewportHeight - _dragAutoScrollEdgeThreshold)) /
                  _dragAutoScrollEdgeThreshold)
              .clamp(0.0, 1.0);
      delta = _dragAutoScrollMaxStep * factor;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        unawaited(_handlePopInvoked(didPop));
      },
      child: Scaffold(
        backgroundColor: DashboardRuntimeTheme.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: _themePreset.headlineColor,
          toolbarHeight: 54,
          titleSpacing: 20,
          title: Text(
            'โหมดแก้ไข',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _themePreset.headlineColor,
            ),
          ),
          flexibleSpace: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: AppGlassTheme.surfaceDecoration(
                      radius: 22,
                      borderAlpha: 0.60,
                      colors: <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.72),
                        const Color(0xFFF4FBF7).withValues(alpha: 0.42),
                      ],
                      shadows: AppGlassTheme.shadowMd,
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            _buildSaveAction(),
            const SizedBox(width: 5),
            _buildThemeAction(),
            const SizedBox(width: 5),
            _buildInfoAction(),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: _isEditMode ? _buildFloatingControls() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: _isLayoutLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DashboardRuntimeTheme.buttonEndColor,
                ),
              )
            : DecoratedBox(
                decoration: _pageDecoration,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewportInset = _isEditMode
                        ? _editModeViewportInset
                        : 0.0;
                    final canvasWidth =
                        constraints.maxWidth -
                        (_canvasHorizontalPadding * 2) -
                        (viewportInset * 2);
                    final columns = _columnsForWidth(canvasWidth);
                    final cellWidth =
                        (canvasWidth - (_gridGap * (columns - 1))) / columns;
                    final rowHeight = cellWidth;
                    final stepX = cellWidth + _gridGap;
                    final stepY = rowHeight + _gridGap;
                    _latestCanvasColumns = columns;
                    _latestStepX = stepX;
                    _latestStepY = stepY;
                    final sourceItems = _previewItems ?? _items;
                    final previewRect = _previewRect;
                    final activePreviewItem = _findItemById(
                      _activeGestureItemId,
                      sourceItems,
                    );
                    final activeItems = <DashboardItem>[
                      ...sourceItems.where(
                        (item) => item.id != _activeGestureItemId,
                      ),
                      ...sourceItems
                          .where((item) => item.id == _activeGestureItemId)
                          .map(
                            (item) => previewRect == null
                                ? item
                                : item.copyWith(rect: previewRect),
                          ),
                    ];
                    final maxBottom = activeItems.fold<int>(
                      0,
                      (current, item) => item.rect.bottom > current
                          ? item.rect.bottom
                          : current,
                    );
                    final viewportCanvasHeight =
                        (constraints.maxHeight -
                                _canvasTopPadding -
                                _canvasBottomScrollPadding)
                            .clamp(0.0, double.infinity);
                    final bottomReserveRows = _isEditMode
                        ? ((84 + _gridGap) / (rowHeight + _gridGap)).ceil()
                        : 0;
                    final minVisibleRows =
                        ((viewportCanvasHeight + _gridGap) /
                                (rowHeight + _gridGap))
                            .ceil();
                    final targetRows = math.max(
                      minVisibleRows,
                      maxBottom +
                          bottomReserveRows +
                          (_isEditMode ? _editModeExtraCanvasRows : 0),
                    );
                    final rows = targetRows.clamp(6, _maxRows);
                    final contentHeight =
                        (rows * rowHeight) + ((rows - 1) * _gridGap);
                    final canvasHeight = contentHeight < viewportCanvasHeight
                        ? viewportCanvasHeight
                        : contentHeight;
                    final hasItems = activeItems.isNotEmpty;
                    final showEmptyState = !hasItems;
                    final selectedInspectorItem =
                        _isEditMode &&
                            _hasSingleSelection &&
                            !_isMultiSelectMode &&
                            _activeGestureItemId == null &&
                            _previewRect == null
                        ? _findItemById(_selectedId, _items)
                        : null;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: SingleChildScrollView(
                            key: _canvasViewportKey,
                            controller: _canvasScrollController,
                            physics: _activeResizeHandle != null
                                ? const NeverScrollableScrollPhysics()
                                : const ClampingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              _canvasHorizontalPadding + viewportInset,
                              _canvasTopPadding + viewportInset,
                              _canvasHorizontalPadding + viewportInset,
                              _canvasBottomScrollPadding + viewportInset,
                            ),
                            child: DecoratedBox(
                              decoration: _canvasDecoration,
                              child: SizedBox(
                                height: canvasHeight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _isEditMode ? _clearSelection : null,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(34),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0.03,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_isEditMode || !hasItems)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Opacity(
                                              opacity: 0.86,
                                              child: CustomPaint(
                                                painter: DashboardGridPainter(
                                                  columns: columns,
                                                  rows: rows,
                                                  gap: _gridGap,
                                                  lineColor:
                                                      _themePreset.gridColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (showEmptyState)
                                        Positioned.fill(
                                          child: _buildGlassEmptyState(),
                                        ),
                                      if (activePreviewItem != null &&
                                          previewRect != null)
                                        _buildPreviewOverlay(
                                          activeItem: activePreviewItem,
                                          rect: previewRect,
                                          cellWidth: cellWidth,
                                          rowHeight: rowHeight,
                                          stepX: stepX,
                                          stepY: stepY,
                                        ),
                                      for (final item in activeItems)
                                        _buildPositionedItem(
                                          item: item,
                                          columns: columns,
                                          cellWidth: cellWidth,
                                          rowHeight: rowHeight,
                                          stepX: stepX,
                                          stepY: stepY,
                                          isSelected: _selectedIds.contains(
                                            item.id,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildSelectedWidgetInspectorSlot(
                            selectedInspectorItem,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildPositionedItem({
    required DashboardItem item,
    required int columns,
    required double cellWidth,
    required double rowHeight,
    required double stepX,
    required double stepY,
    required bool isSelected,
  }) {
    const handleExtent = 64.0;
    const handleInset = handleExtent / 2;
    const itemVisualInset = 2.0;
    final left = item.rect.x * stepX;
    final top = item.rect.y * stepY;
    final width = (item.rect.w * cellWidth) + ((item.rect.w - 1) * _gridGap);
    final height = (item.rect.h * rowHeight) + ((item.rect.h - 1) * _gridGap);
    final contentWidth = math.max(0.0, width - (itemVisualInset * 2));
    final contentHeight = math.max(0.0, height - (itemVisualInset * 2));
    final isActiveGestureItem = _activeGestureItemId == item.id;
    final isBeingResized = isActiveGestureItem && _activeResizeHandle != null;
    final isBeingDragged = isActiveGestureItem;
    final isLocked = item.locked;
    final showSelectionChrome = _isEditMode && isSelected;
    final showHandles =
        _isEditMode &&
        isSelected &&
        _hasSingleSelection &&
        !_isMultiSelectMode &&
        !isBeingDragged &&
        !isLocked;
    final canResizeHorizontally = _canResizeHorizontally(item);
    final canResizeVertically = _canResizeVertically(item);
    final showTopHandle = showHandles && canResizeVertically;
    final showRightHandle = showHandles && canResizeHorizontally;
    final showBottomHandle = showHandles && canResizeVertically;
    final showLeftHandle = showHandles && canResizeHorizontally;
    final showTopLeftHandle =
        showHandles && canResizeHorizontally && canResizeVertically;
    final showTopRightHandle =
        showHandles && canResizeHorizontally && canResizeVertically;
    final showBottomRightHandle =
        showHandles && canResizeHorizontally && canResizeVertically;
    final showBottomLeftHandle =
        showHandles && canResizeHorizontally && canResizeVertically;
    final outlineColor = _previewInvalid
        ? const Color(0xFFD16A6A)
        : const Color(0xFF6CBF98);
    final outlineStartColor = _previewInvalid
        ? const Color(0xFFF3A39D)
        : const Color(0xFF9ED8BC);
    final outlineEndColor = _previewInvalid
        ? const Color(0xFFD16A6A)
        : const Color(0xFF4FA887);
    final haloColor = _previewInvalid
        ? const Color(0xFFF3B6B6)
        : const Color(0xFFCBEFDE);
    final ambientColor = _previewInvalid
        ? const Color(0xFFE59D9D)
        : const Color(0xFFA8DCC4);
    final usesSliderShellHighlight = item.type == DashboardItemType.slider;
    final usesCompactSliderHitbox =
        usesSliderShellHighlight &&
        rowHeight >= _sliderCompactCollisionCellThreshold;
    final sliderLayout = usesSliderShellHighlight
        ? buildSliderShellLayout(
            width: contentWidth,
            height: contentHeight,
            desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
            shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
          )
        : null;
    final shellHighlightInset =
        item.type == DashboardItemType.toggle ||
            item.type == DashboardItemType.gauge
        ? 2.0
        : 0.0;
    final sliderVisualBottomInset = usesSliderShellHighlight
        ? itemVisualInset + sliderLayout!.shellBottomInset
        : 0.0;
    final sliderVisualTopInset = usesSliderShellHighlight
        ? itemVisualInset + sliderLayout!.shellTopInset
        : 0.0;
    final sliderVisualHorizontalInset = usesSliderShellHighlight
        ? itemVisualInset
        : 0.0;
    final selectionHorizontalInset =
        item.type == DashboardItemType.slider ||
            item.type == DashboardItemType.valueLabel
        ? itemVisualInset
        : sliderVisualHorizontalInset;
    final selectionTopInset =
        item.type == DashboardItemType.slider ||
            item.type == DashboardItemType.valueLabel
        ? itemVisualInset +
              (item.type == DashboardItemType.slider
                  ? sliderLayout!.shellTopInset
                  : 0.0)
        : sliderVisualTopInset;
    final selectionBottomInset =
        item.type == DashboardItemType.slider ||
            item.type == DashboardItemType.valueLabel
        ? itemVisualInset +
              (item.type == DashboardItemType.slider
                  ? sliderLayout!.shellBottomInset
                  : 0.0)
        : sliderVisualBottomInset;
    final selectionLeft =
        handleInset + shellHighlightInset + selectionHorizontalInset;
    final selectionTop = handleInset + shellHighlightInset + selectionTopInset;
    final selectionWidth =
        width - (shellHighlightInset * 2) - (selectionHorizontalInset * 2);
    final selectionHeight =
        (height - selectionBottomInset - selectionTopInset) -
        (shellHighlightInset * 2);
    final selectionCenterX = selectionLeft + (selectionWidth / 2);
    final selectionCenterY = selectionTop + (selectionHeight / 2);
    final highlightRadius = item.type == DashboardItemType.button
        ? math.max(0.0, math.min(width, height) / 2)
        : item.type == DashboardItemType.toggle
        ? math.max(0.0, (height / 2) - shellHighlightInset)
        : 24.0;
    final positionAnimationCurve = isBeingResized
        ? Curves.linear
        : isBeingDragged
        ? Curves.easeOutCubic
        : Curves.easeOutBack;
    final positionAnimationDuration = isBeingResized
        ? Duration.zero
        : isBeingDragged
        ? const Duration(milliseconds: 140)
        : const Duration(milliseconds: 220);
    final dragScale = isBeingDragged
        ? item.type == DashboardItemType.button
              ? 1.0
              : 1.04
        : 1.0;
    final dragGlowShadows = isBeingResized
        ? <BoxShadow>[]
        : <BoxShadow>[
            BoxShadow(
              color: const Color(
                0xFF08110C,
              ).withValues(alpha: isBeingDragged ? 0.18 : 0.06),
              blurRadius: isBeingDragged ? 18 : 8,
              offset: Offset(0, isBeingDragged ? 12 : 3),
            ),
            BoxShadow(
              color: ambientColor.withValues(
                alpha: isBeingDragged ? 0.06 : 0.010,
              ),
              blurRadius: isBeingDragged ? 12 : 5,
              spreadRadius: isBeingDragged ? 0.2 : 0,
            ),
            BoxShadow(
              color: haloColor.withValues(
                alpha: isBeingDragged ? 0.035 : 0.006,
              ),
              blurRadius: isBeingDragged ? 10 : 3,
              spreadRadius: isBeingDragged ? 0.08 : 0,
            ),
          ];

    return AnimatedPositioned(
      duration: positionAnimationDuration,
      curve: positionAnimationCurve,
      key: ValueKey(item.id),
      left: left - handleInset,
      top: top - handleInset,
      width: width + handleExtent,
      height: height + handleExtent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: handleInset,
            top: handleInset,
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_isEditMode &&
                    usesSliderShellHighlight &&
                    !usesCompactSliderHitbox)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: math.min(0.0, sliderLayout!.titleTop),
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPressStart: isLocked
                          ? null
                          : (details) {
                              _startMove(item, details.globalPosition);
                            },
                      onLongPressMoveUpdate: isLocked
                          ? null
                          : (details) => _updateMove(
                              item: item,
                              globalPosition: details.globalPosition,
                              columns: columns,
                              stepX: stepX,
                              stepY: stepY,
                            ),
                      onLongPressEnd: isLocked ? null : (_) => _finishGesture(),
                      onLongPressCancel: isLocked ? null : _finishGesture,
                    ),
                  ),
                Positioned.fill(
                  child: usesCompactSliderHitbox
                      ? IgnorePointer(
                          child: AnimatedScale(
                            duration: positionAnimationDuration,
                            curve: positionAnimationCurve,
                            scale: isBeingResized ? 1.0 : dragScale,
                            child: AnimatedContainer(
                              duration: isBeingResized
                                  ? Duration.zero
                                  : const Duration(milliseconds: 140),
                              curve: isBeingResized
                                  ? Curves.linear
                                  : Curves.easeOut,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  highlightRadius,
                                ),
                                border: null,
                                boxShadow: showSelectionChrome
                                    ? (usesSliderShellHighlight ||
                                              item.type ==
                                                  DashboardItemType.button)
                                          ? null
                                          : (dragGlowShadows.isEmpty
                                                ? null
                                                : dragGlowShadows)
                                    : null,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: AnimatedOpacity(
                                        duration: isBeingResized
                                            ? Duration.zero
                                            : const Duration(milliseconds: 120),
                                        opacity: isBeingResized
                                            ? 1
                                            : isBeingDragged
                                            ? 0.92
                                            : 1,
                                        child: RepaintBoundary(
                                          child: isBeingResized
                                              ? _buildResizePlaceholder(
                                                  item: item,
                                                  borderRadius: highlightRadius,
                                                )
                                              : DashboardItemRenderer(
                                                  item: item,
                                                  enableInteraction:
                                                      !_isEditMode,
                                                  onItemChanged: !_isEditMode
                                                      ? _updateItemFromRenderer
                                                      : null,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isEditMode && isLocked)
                                    Positioned(
                                      right: -5,
                                      top: -5,
                                      child: _LockedWidgetBadge(
                                        compact: width < 54 || height < 54,
                                        themePreset: _themePreset,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isEditMode
                              ? () {
                                  setState(() {
                                    if (_isMultiSelectMode) {
                                      _toggleItemSelection(item.id);
                                    } else {
                                      _setSingleSelection(item.id);
                                    }
                                  });
                                }
                              : null,
                          onLongPressStart: _isEditMode && !isLocked
                              ? (details) {
                                  _startMove(item, details.globalPosition);
                                }
                              : null,
                          onLongPressMoveUpdate: _isEditMode && !isLocked
                              ? (details) => _updateMove(
                                  item: item,
                                  globalPosition: details.globalPosition,
                                  columns: columns,
                                  stepX: stepX,
                                  stepY: stepY,
                                )
                              : null,
                          onLongPressEnd: _isEditMode && !isLocked
                              ? (_) => _finishGesture()
                              : null,
                          onLongPressCancel: _isEditMode && !isLocked
                              ? _finishGesture
                              : null,
                          child: AnimatedScale(
                            duration: positionAnimationDuration,
                            curve: positionAnimationCurve,
                            scale: isBeingResized ? 1.0 : dragScale,
                            child: AnimatedContainer(
                              duration: isBeingResized
                                  ? Duration.zero
                                  : const Duration(milliseconds: 140),
                              curve: isBeingResized
                                  ? Curves.linear
                                  : Curves.easeOut,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  highlightRadius,
                                ),
                                border: null,
                                boxShadow: showSelectionChrome
                                    ? (usesSliderShellHighlight ||
                                              item.type ==
                                                  DashboardItemType.button)
                                          ? null
                                          : (dragGlowShadows.isEmpty
                                                ? null
                                                : dragGlowShadows)
                                    : null,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: AnimatedOpacity(
                                        duration: isBeingResized
                                            ? Duration.zero
                                            : const Duration(milliseconds: 120),
                                        opacity: isBeingResized
                                            ? 1
                                            : isBeingDragged
                                            ? 0.92
                                            : 1,
                                        child: RepaintBoundary(
                                          child: isBeingResized
                                              ? _buildResizePlaceholder(
                                                  item: item,
                                                  borderRadius: highlightRadius,
                                                )
                                              : DashboardItemRenderer(
                                                  item: item,
                                                  enableInteraction:
                                                      !_isEditMode,
                                                  onItemChanged: !_isEditMode
                                                      ? _updateItemFromRenderer
                                                      : null,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isEditMode && isLocked)
                                    Positioned(
                                      right: -5,
                                      top: -5,
                                      child: _LockedWidgetBadge(
                                        compact: width < 54 || height < 54,
                                        themePreset: _themePreset,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
                if (usesCompactSliderHitbox)
                  Positioned(
                    left: selectionHorizontalInset,
                    top: selectionTopInset,
                    width: selectionWidth,
                    height: selectionHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isEditMode
                          ? () {
                              setState(() {
                                if (_isMultiSelectMode) {
                                  _toggleItemSelection(item.id);
                                } else {
                                  _setSingleSelection(item.id);
                                }
                              });
                            }
                          : null,
                      onLongPressStart: _isEditMode && !isLocked
                          ? (details) {
                              _startMove(item, details.globalPosition);
                            }
                          : null,
                      onLongPressMoveUpdate: _isEditMode && !isLocked
                          ? (details) => _updateMove(
                              item: item,
                              globalPosition: details.globalPosition,
                              columns: columns,
                              stepX: stepX,
                              stepY: stepY,
                            )
                          : null,
                      onLongPressEnd: _isEditMode && !isLocked
                          ? (_) => _finishGesture()
                          : null,
                      onLongPressCancel: _isEditMode && !isLocked
                          ? _finishGesture
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          if (showSelectionChrome)
            Positioned(
              left: selectionLeft,
              top: selectionTop,
              width: selectionWidth,
              height: selectionHeight,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(highlightRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        outlineStartColor.withValues(
                          alpha: isBeingDragged ? 0.14 : 0.08,
                        ),
                        outlineEndColor.withValues(
                          alpha: isBeingDragged ? 0.08 : 0.03,
                        ),
                      ],
                    ),
                    border: Border.all(
                      color: outlineColor.withValues(
                        alpha: isBeingDragged ? 0.86 : 0.58,
                      ),
                      width: isBeingDragged ? 1.8 : 1.25,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: isBeingDragged ? 0.14 : 0.08,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, -1),
                      ),
                      BoxShadow(
                        color: haloColor.withValues(
                          alpha: isBeingDragged ? 0.14 : 0.07,
                        ),
                        blurRadius: isBeingDragged ? 18 : 12,
                        spreadRadius: isBeingDragged ? 0.8 : 0.2,
                      ),
                      BoxShadow(
                        color: ambientColor.withValues(
                          alpha: isBeingDragged ? 0.12 : 0.05,
                        ),
                        blurRadius: isBeingDragged ? 24 : 16,
                        spreadRadius: isBeingDragged ? 0.6 : 0.12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showTopHandle)
            Positioned(
              left: selectionCenterX - (handleExtent / 2),
              top: selectionTop - handleInset,
              width: handleExtent,
              height: handleExtent,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.top,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
          if (showTopLeftHandle)
            Positioned(
              left: selectionLeft - handleInset,
              top: selectionTop - handleInset,
              width: handleExtent,
              height: handleExtent,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.topLeft,
                showIndicator: false,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
          if (showRightHandle)
            Positioned(
              left: selectionLeft + selectionWidth - handleInset,
              top: selectionCenterY - (handleExtent / 2),
              width: handleExtent,
              height: handleExtent,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.right,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
          if (showTopRightHandle)
            Positioned(
              left: selectionLeft + selectionWidth - handleInset,
              top: selectionTop - handleInset,
              width: handleExtent,
              height: handleExtent,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.topRight,
                showIndicator: false,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
          if (showBottomHandle)
            Positioned(
              left: selectionCenterX - (handleExtent / 2),
              width: handleExtent,
              height: handleExtent,
              top: selectionTop + selectionHeight - handleInset,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.bottom,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
          if (showBottomRightHandle)
            Positioned(
              left: selectionLeft + selectionWidth - handleInset,
              top: selectionTop + selectionHeight - handleInset,
              width: handleExtent,
              height: handleExtent,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.bottomRight,
                showIndicator: false,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
          if (showLeftHandle)
            Positioned(
              left: selectionLeft - handleInset,
              top: selectionCenterY - (handleExtent / 2),
              width: handleExtent,
              height: handleExtent,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.left,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
          if (showBottomLeftHandle)
            Positioned(
              left: selectionLeft - handleInset,
              top: selectionTop + selectionHeight - handleInset,
              width: handleExtent,
              height: handleExtent,
              child: _ResizeHandle(
                item: item,
                color: outlineColor,
                position: DashboardBuilderResizeHandlePosition.bottomLeft,
                showIndicator: false,
                onStartResize: (item, globalPosition, handle) =>
                    _startResize(item, globalPosition, handle: handle),
                onUpdateResize: (globalPosition) => _updateResize(
                  item: item,
                  globalPosition: globalPosition,
                  columns: columns,
                  stepX: stepX,
                  stepY: stepY,
                ),
                onFinishResize: _finishGesture,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewOverlay({
    required DashboardItem activeItem,
    required GridRect rect,
    required double cellWidth,
    required double rowHeight,
    required double stepX,
    required double stepY,
  }) {
    const itemVisualInset = 2.0;
    var left = rect.x * stepX;
    var top = rect.y * stepY;
    var width = (rect.w * cellWidth) + ((rect.w - 1) * _gridGap);
    var height = (rect.h * rowHeight) + ((rect.h - 1) * _gridGap);
    if (activeItem.type == DashboardItemType.slider) {
      final contentWidth = math.max(0.0, width - (itemVisualInset * 2));
      final contentHeight = math.max(0.0, height - (itemVisualInset * 2));
      final sliderLayout = buildSliderShellLayout(
        width: contentWidth,
        height: contentHeight,
        desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
        shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
      );
      final selectionHorizontalInset = itemVisualInset;
      final selectionTopInset = itemVisualInset + sliderLayout.shellTopInset;
      final selectionBottomInset =
          itemVisualInset + sliderLayout.shellBottomInset;
      left += selectionHorizontalInset;
      top += selectionTopInset;
      width -= selectionHorizontalInset * 2;
      height -= selectionTopInset + selectionBottomInset;
    }
    final color = _previewInvalid
        ? const Color(0xFFD16A6A)
        : const Color(0xFF67BF91);
    final previewStartColor = _previewInvalid
        ? const Color(0xFFF5BCB7)
        : const Color(0xFFBFE8CF);
    final previewEndColor = _previewInvalid
        ? const Color(0xFFE78982)
        : const Color(0xFF73C89A);
    final glowColor = _previewInvalid
        ? const Color(0xFFF3B6B6)
        : const Color(0xFFC8F0D6);
    final previewRadius = activeItem.type == DashboardItemType.slider
        ? math.max(0.0, (height / 2) - 2.0)
        : 24.0;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(previewRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                previewStartColor.withValues(
                  alpha: _previewInvalid ? 0.18 : 0.10,
                ),
                previewEndColor.withValues(
                  alpha: _previewInvalid ? 0.10 : 0.04,
                ),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: _previewInvalid ? 0.82 : 0.62),
              width: _previewInvalid ? 1.45 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(
                  alpha: _previewInvalid ? 0.10 : 0.08,
                ),
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
              BoxShadow(
                color: glowColor.withValues(
                  alpha: _previewInvalid ? 0.13 : 0.08,
                ),
                blurRadius: 16,
                spreadRadius: 0.35,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResizePlaceholder({
    required DashboardItem item,
    required double borderRadius,
  }) {
    final title = item.title.trim().isEmpty ? 'Widget' : item.title.trim();
    final accent = (item.titleColor ?? DashboardRuntimeTheme.buttonEndColor)
        .withValues(alpha: 0.72);
    final shapeRadius = BorderRadius.circular(borderRadius);

    if (item.type == DashboardItemType.button) {
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.94),
          border: Border.all(color: accent.withValues(alpha: 0.58), width: 1.2),
        ),
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
        ),
      );
    }

    if (item.type == DashboardItemType.slider) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final layout = buildSliderShellLayout(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
            shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
          );
          final titleTop = math.max(0.0, layout.titleTop);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: layout.shellTopInset,
                bottom: layout.shellBottomInset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: shapeRadius,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.42),
                      width: 1.1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: titleTop,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    final hasEnoughHeightForTitle = item.rect.h >= 3;
    final indicatorHeight = item.type == DashboardItemType.toggle ? 18.0 : 10.0;
    final canShowBottomIndicator = item.rect.h >= 2;
    final placeholderBar = Container(
      height: indicatorHeight,
      width: item.type == DashboardItemType.slider
          ? double.infinity
          : item.type == DashboardItemType.gauge
          ? 42
          : double.infinity,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: shapeRadius,
        border: Border.all(color: accent.withValues(alpha: 0.42), width: 1.1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showTitle =
                hasEnoughHeightForTitle && constraints.maxHeight >= 34;
            final showBottomIndicator =
                canShowBottomIndicator &&
                constraints.maxHeight >= indicatorHeight + 4;

            if (!showTitle) {
              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: item.type == DashboardItemType.gauge ? null : 1,
                  child: item.type == DashboardItemType.gauge
                      ? SizedBox(width: 42, child: placeholderBar)
                      : placeholderBar,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent.withValues(alpha: 0.84),
                    letterSpacing: 0.3,
                  ),
                ),
                if (showBottomIndicator) ...[const Spacer(), placeholderBar],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.item,
    required this.color,
    required this.position,
    this.showIndicator = true,
    required this.onStartResize,
    required this.onUpdateResize,
    required this.onFinishResize,
  });

  final DashboardItem item;
  final Color color;
  final DashboardBuilderResizeHandlePosition position;
  final bool showIndicator;
  final void Function(
    DashboardItem item,
    Offset globalPosition,
    DashboardBuilderResizeHandlePosition handle,
  )
  onStartResize;
  final void Function(Offset globalPosition) onUpdateResize;
  final VoidCallback onFinishResize;

  @override
  Widget build(BuildContext context) {
    const hitSize = 64.0;
    final isCorner =
        position == DashboardBuilderResizeHandlePosition.topLeft ||
        position == DashboardBuilderResizeHandlePosition.topRight ||
        position == DashboardBuilderResizeHandlePosition.bottomRight ||
        position == DashboardBuilderResizeHandlePosition.bottomLeft;
    final isVertical =
        position == DashboardBuilderResizeHandlePosition.left ||
        position == DashboardBuilderResizeHandlePosition.right;
    final indicatorWidth = isCorner ? 20.0 : (isVertical ? 12.0 : 24.0);
    final indicatorHeight = isCorner ? 20.0 : (isVertical ? 24.0 : 12.0);
    final accentWidth = isCorner ? 9.0 : (isVertical ? 2.4 : 10.0);
    final accentHeight = isCorner ? 9.0 : (isVertical ? 10.0 : 2.4);
    final indicatorRadius = isCorner
        ? 999.0
        : math.max(indicatorWidth, indicatorHeight);
    final indicatorGradient = <Color>[
      const Color(0xFFFFFFFF).withValues(alpha: 0.96),
      color.withValues(alpha: isCorner ? 0.26 : 0.20),
    ];
    final accentGradient = <Color>[
      color.withValues(alpha: 0.96),
      color.withValues(alpha: 0.70),
    ];

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => onStartResize(item, event.position, position),
      onPointerMove: (event) => onUpdateResize(event.position),
      onPointerUp: (_) => onFinishResize(),
      onPointerCancel: (_) => onFinishResize(),
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: showIndicator
            ? Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: indicatorWidth,
                  height: indicatorHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: indicatorGradient,
                    ),
                    borderRadius: BorderRadius.circular(indicatorRadius),
                    border: Border.all(
                      color: color.withValues(alpha: 0.40),
                      width: 1,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, -1),
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.10),
                        blurRadius: 12,
                        spreadRadius: 0.2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: accentGradient,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: SizedBox(
                        width: accentWidth,
                        height: accentHeight,
                        child: isCorner
                            ? Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SizedBox(
                                    width: 3.6,
                                    height: 3.6,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

class _LockedWidgetBadge extends StatelessWidget {
  const _LockedWidgetBadge({required this.compact, required this.themePreset});

  final bool compact;
  final DashboardThemePreset themePreset;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 13.0 : 16.0;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: themePreset.cardColor.withValues(alpha: 0.88),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.82),
            width: 1,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: DashboardRuntimeTheme.shadowDarkColor,
              blurRadius: 5,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.lock_rounded,
            size: compact ? 7.5 : 9,
            color: DashboardRuntimeTheme.labelTextColor,
          ),
        ),
      ),
    );
  }
}

class _InspectorPill extends StatelessWidget {
  const _InspectorPill({
    required this.label,
    required this.themePreset,
    this.muted = false,
  });

  final String label;
  final DashboardThemePreset themePreset;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? themePreset.mutedTextColor : themePreset.bodyColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: muted ? 0.34 : 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFD7E1E8).withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuilderActionButton extends StatelessWidget {
  const _BuilderActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    this.size = 44,
    this.iconSize = 22,
    this.glowColor,
    this.glowScale = 1,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double iconSize;
  final Color? glowColor;
  final double glowScale;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 14,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
              width: 1,
            ),
            boxShadow: [
              const BoxShadow(
                color: DashboardRuntimeTheme.shadowLightColor,
                blurRadius: 6,
              ),
              BoxShadow(
                color: (glowColor ?? foregroundColor).withValues(
                  alpha: (0.12 * glowScale).clamp(0.0, 0.22).toDouble(),
                ),
                blurRadius: 10 * glowScale,
                spreadRadius: glowScale < 1.2 ? 0.2 : 0.5,
              ),
              const BoxShadow(
                color: DashboardRuntimeTheme.shadowDarkColor,
                blurRadius: 10,
                offset: Offset(4, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: foregroundColor, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuilderInfoRow extends StatelessWidget {
  const _BuilderInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: AppGlassTheme.surfaceDecoration(
              radius: 20,
              borderAlpha: 0.34,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.58),
                const Color(0xFFF4F9FF).withValues(alpha: 0.26),
              ],
              shadows: const <BoxShadow>[],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: 14,
                    borderAlpha: 0.24,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.42),
                      const Color(0xFFEAF3FF).withValues(alpha: 0.16),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: DashboardRuntimeTheme.labelTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: DashboardRuntimeTheme.fieldTextColor,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
