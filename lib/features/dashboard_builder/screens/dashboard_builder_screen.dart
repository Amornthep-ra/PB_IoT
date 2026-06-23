import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_responsive.dart';
import '../../dashboard/models/widget_binding_model.dart';
import '../../dashboard/models/device_snapshot_model.dart';
import '../../dashboard/services/dashboard_item_runtime_binding.dart';
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
import '../services/dashboard_grid_metrics.dart';
import '../services/dashboard_layout_engine.dart';
import '../services/dashboard_settings_service.dart';
import '../widgets/add_widget_sheet.dart';
import '../widgets/button_visual_style.dart';
import '../widgets/dashboard_grid_painter.dart';
import '../widgets/dashboard_item_renderer.dart';
import '../widgets/smart_slider_widget.dart';
import '../widgets/widget_shell_layout.dart';
import '../widgets/widget_settings_sheet.dart';
import '../widgets/dashboard_text_contrast.dart';

part 'builder_parts/builder_app_bar_glass.dart';
part 'builder_parts/delete_with_alerts_action_button.dart';
part 'builder_parts/builder_action_chrome.dart';
part 'builder_parts/canvas_overlays.dart';
part 'builder_parts/builder_info_row.dart';
part 'builder_parts/builder_history.dart';
part 'builder_parts/builder_gestures.dart';
part 'builder_parts/builder_item_actions.dart';
part 'builder_parts/builder_runtime_writes.dart';
part 'builder_parts/builder_layout_persistence.dart';
part 'builder_parts/builder_runtime_snapshot.dart';
part 'builder_parts/builder_geometry_helpers.dart';
part 'builder_parts/builder_info_sheet.dart';
part 'builder_parts/builder_selected_inspector.dart';
part 'builder_parts/builder_floating_controls.dart';
part 'builder_parts/builder_app_bar.dart';
part 'builder_parts/builder_empty_state.dart';
part 'builder_parts/builder_canvas_overlay_helpers.dart';

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

enum _LeaveAction { cancel, discard, save }

class DashboardBuilderScreen extends StatefulWidget {
  const DashboardBuilderScreen({super.key});

  @override
  State<DashboardBuilderScreen> createState() => _DashboardBuilderScreenState();
}

class _DashboardBuilderScreenState extends State<DashboardBuilderScreen> {
  static const double _gridGap = DashboardGridMetrics.gridGap;
  static const int _maxRows = 72;
  static const double _canvasHorizontalPadding = 0;
  static const double _canvasTopPadding = 0;
  static const double _canvasBottomScrollPadding = 32;
  static const double _editModeViewportInset = 0;
  static const double _resizeHandleMinVerticalSelectionHeight = 52;
  static const double _compactResizeHandleMinVerticalSelectionHeight = 36;
  static const double _compactResizeHandleRowHeightThreshold = 18;
  static const int _editModeExtraCanvasRows = 10;
  static const double _dragAutoScrollEdgeThreshold = 112;
  static const double _dragAutoScrollMaxStep = 18;
  static const double _sliderCompactCollisionCellThreshold = 22;
  static const int _maxHistoryEntries = 60;
  static const int _buttonMinW = 4;
  static const int _buttonMaxW = 32;
  static const int _buttonMinH = 4;
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
  List<DashboardItem>? _pendingDraftItems;
  DashboardBuilderHistoryState? _pendingDraftHistory;
  double _gestureStartScrollOffset = 0;
  Offset? _lastGestureGlobalPosition;
  int _latestCanvasColumns = DashboardGridMetrics.minColumns;
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

  List<DashboardItem> _buildInitialItems() {
    return const <DashboardItem>[];
  }

  void _setHistoryState(VoidCallback fn) {
    setState(fn);
  }

  void _setGestureState(VoidCallback fn) {
    setState(fn);
  }

  void _setItemActionState(VoidCallback fn) {
    setState(fn);
  }

  void _setRuntimeWriteState(VoidCallback fn) {
    setState(fn);
  }

  void _setRuntimeSnapshotState(VoidCallback fn) {
    setState(fn);
  }

  void _setLayoutPersistenceState(VoidCallback fn) {
    setState(fn);
  }

  BoxDecoration get _pageDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[DashboardRuntimeTheme.backgroundColor, Color(0xFFF8FBF8)],
    ),
  );

  BoxDecoration get _canvasDecoration => AppGlassTheme.surfaceDecoration(
    radius: 34,
    borderAlpha: 0.62,
    colors: _themePreset.canvasColors,
    shadows: AppGlassTheme.shadowLg,
  );

  BoxDecoration _themedSurfaceDecoration({
    double radius = 22,
    double borderAlpha = 0.54,
    List<BoxShadow> shadows = AppGlassTheme.shadowSm,
  }) {
    final surface = _themePreset.surfaceColor;
    final card = _themePreset.cardColor;

    return AppGlassTheme.surfaceDecoration(
      radius: radius,
      borderAlpha: borderAlpha,
      colors: <Color>[
        surface.withValues(alpha: _themePreset.isDark ? 0.86 : 0.74),
        card.withValues(alpha: _themePreset.isDark ? 0.72 : 0.42),
      ],
      shadows: _themePreset.isDark ? const <BoxShadow>[] : shadows,
    );
  }

  BoxDecoration _themedModalSurfaceDecoration({
    double radius = 22,
    double borderAlpha = 0.54,
    List<BoxShadow> shadows = AppGlassTheme.shadowSm,
  }) {
    final surface = _themePreset.surfaceColor;
    final card = _themePreset.cardColor;

    return AppGlassTheme.surfaceDecoration(
      radius: radius,
      borderAlpha: borderAlpha,
      colors: <Color>[
        surface.withValues(alpha: _themePreset.isDark ? 0.86 : 0.92),
        card.withValues(alpha: _themePreset.isDark ? 0.72 : 0.88),
      ],
      shadows: _themePreset.isDark ? const <BoxShadow>[] : shadows,
    );
  }

  Color _themedBorderColor([double alpha = 0.62]) {
    return _themePreset.isDark
        ? _themePreset.borderColor.withValues(alpha: alpha)
        : Colors.white.withValues(alpha: alpha);
  }

  Color get _appBarForegroundColor {
    return _themePreset.isDark
        ? const Color(0xFF15212B)
        : _themePreset.headlineColor;
  }

  Color get _appBarActionForegroundColor => _themePreset.headlineColor;

  Color get _appBarMutedForegroundColor => _themePreset.mutedTextColor;

  Color get _sheetHeadlineColor => _themePreset.headlineColor;

  BoxDecoration _themedAppBarDecoration() {
    return AppGlassTheme.surfaceDecoration(
      radius: 22,
      borderAlpha: _themePreset.isDark ? 0.28 : 0.60,
      colors: <Color>[
        _themePreset.surfaceColor.withValues(
          alpha: _themePreset.isDark ? 0.24 : 0.74,
        ),
        _themePreset.cardColor.withValues(
          alpha: _themePreset.isDark ? 0.16 : 0.42,
        ),
      ],
      shadows: _themePreset.isDark
          ? const <BoxShadow>[]
          : AppGlassTheme.shadowMd,
    );
  }

  _BuilderActionTone _resolveActionTone(_BuilderActionTone lightTone) {
    if (!_themePreset.isDark) {
      return lightTone;
    }

    return _BuilderActionTone(
      background: _themePreset.surfaceColor,
      foreground: lightTone.foreground,
      glow: _themePreset.borderColor,
    );
  }

  void _resetInteractionState() {
    _interactionState.reset();
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
        appBar: _buildBuilderAppBar(context),
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
                    final availableCanvasWidth =
                        constraints.maxWidth -
                        (_canvasHorizontalPadding * 2) -
                        (viewportInset * 2);
                    final canvasWidth =
                        AppResponsiveLayout.dashboardCanvasWidth(
                          availableCanvasWidth,
                        );
                    final columns = _columnsForWidth(canvasWidth);
                    final cellWidth = DashboardGridMetrics.cellWidthFor(
                      width: canvasWidth,
                      columns: columns,
                    );
                    final rowHeight = DashboardGridMetrics.rowHeightFor(
                      cellWidth,
                    );
                    final stepX = DashboardGridMetrics.stepFor(cellWidth);
                    final stepY = DashboardGridMetrics.stepFor(rowHeight);
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
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: canvasWidth,
                                child: DecoratedBox(
                                  decoration: _canvasDecoration,
                                  child: SizedBox(
                                    height: canvasHeight,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: _isEditMode
                                          ? _clearSelection
                                          : null,
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
                                                  opacity: _themePreset.isDark
                                                      ? 0.56
                                                      : 0.86,
                                                  child: CustomPaint(
                                                    painter:
                                                        DashboardGridPainter(
                                                          columns: columns,
                                                          rows: rows,
                                                          gap: _gridGap,
                                                          lineColor:
                                                              _themePreset
                                                                  .gridColor,
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
                                              canvasWidth: canvasWidth,
                                              canvasHeight: canvasHeight,
                                              cellWidth: cellWidth,
                                              rowHeight: rowHeight,
                                              stepX: stepX,
                                              stepY: stepY,
                                              isSelected: _selectedIds.contains(
                                                item.id,
                                              ),
                                            ),
                                          if (!_isEditMode)
                                            for (final item in activeItems)
                                              _buildPositionedItemTitleOverlay(
                                                item: item,
                                                cellWidth: cellWidth,
                                                rowHeight: rowHeight,
                                                stepX: stepX,
                                                stepY: stepY,
                                              ),
                                        ],
                                      ),
                                    ),
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
    required double canvasWidth,
    required double canvasHeight,
    required double cellWidth,
    required double rowHeight,
    required double stepX,
    required double stepY,
    required bool isSelected,
  }) {
    const handleExtent = 44.0;
    const handleInset = handleExtent / 2;
    const itemVisualInset = 2.0;
    final left = item.rect.x * stepX;
    final top = item.rect.y * stepY;
    final width = DashboardGridMetrics.itemWidthFor(
      rect: item.rect,
      cellWidth: cellWidth,
    );
    final height = DashboardGridMetrics.itemHeightFor(
      rect: item.rect,
      rowHeight: rowHeight,
    );
    final chromeWidth = math.min(canvasWidth, width + handleExtent);
    final chromeHeight = math.min(canvasHeight, height + handleExtent);
    final maxChromeLeft = math.max(0.0, canvasWidth - chromeWidth);
    final maxChromeTop = math.max(0.0, canvasHeight - chromeHeight);
    final chromeLeft = (left - handleInset).clamp(0.0, maxChromeLeft);
    final chromeTop = (top - handleInset).clamp(0.0, maxChromeTop);
    final contentLeft = left - chromeLeft;
    final contentTop = top - chromeTop;
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
    final showRightHandle = showHandles && canResizeHorizontally;
    final showLeftHandle = showHandles && canResizeHorizontally;
    final canDirectMove =
        _isEditMode &&
        isSelected &&
        _hasSingleSelection &&
        !_isMultiSelectMode &&
        !isLocked;
    final outlineColor = _dashboardEditorChromePalette.selectionBorder;
    final usesSliderShellHighlight = item.type == DashboardItemType.slider;
    final usesCompactSliderHitbox =
        usesSliderShellHighlight &&
        rowHeight >= _sliderCompactCollisionCellThreshold;
    final editorGeometry = _resolveEditorGeometry(
      item: item,
      width: width,
      height: height,
    );
    final selectionRect = editorGeometry.selectionRect;
    final sliderLayout = usesSliderShellHighlight
        ? buildSliderShellLayout(
            width: contentWidth,
            height: contentHeight,
            desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
            shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
          )
        : null;
    final selectionLeft = contentLeft + selectionRect.left;
    final selectionTop = contentTop + selectionRect.top;
    final selectionWidth = selectionRect.width;
    final selectionHeight = selectionRect.height;
    final selectionCenterX = selectionLeft + (selectionWidth / 2);
    final selectionCenterY = selectionTop + (selectionHeight / 2);
    final minVerticalHandleSelectionHeight =
        rowHeight < _compactResizeHandleRowHeightThreshold
        ? _compactResizeHandleMinVerticalSelectionHeight
        : _resizeHandleMinVerticalSelectionHeight;
    final showVerticalResizeHandles =
        selectionHeight >= minVerticalHandleSelectionHeight;
    final showTopHandle =
        showHandles && canResizeVertically && showVerticalResizeHandles;
    final showBottomHandle =
        showHandles && canResizeVertically && showVerticalResizeHandles;
    final highlightRadius = editorGeometry.selectionCornerRadius;
    final placeholderRadius = editorGeometry.placeholderCornerRadius;
    final positionAnimationCurve = isBeingResized || isBeingDragged
        ? Curves.linear
        : Curves.easeOutBack;
    final positionAnimationDuration = isBeingResized || isBeingDragged
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final liftAnimationDuration = isBeingResized
        ? Duration.zero
        : const Duration(milliseconds: 140);
    final liftAnimationCurve = isBeingResized ? Curves.linear : Curves.easeOut;
    final isActivelyManipulating = isBeingDragged || isBeingResized;
    final showStaticSelectionChrome =
        showSelectionChrome && !isActivelyManipulating;
    final dragScale = isBeingDragged
        ? item.type == DashboardItemType.button
              ? 1.0
              : 1.04
        : 1.0;
    final dragGlowShadows = isBeingResized
        ? <BoxShadow>[]
        : _themePreset.isDark
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isBeingDragged ? 0.22 : 0.10,
              ),
              blurRadius: isBeingDragged ? 14 : 6,
              offset: Offset(0, isBeingDragged ? 8 : 2),
            ),
            BoxShadow(
              color: outlineColor.withValues(
                alpha: isBeingDragged ? 0.14 : 0.04,
              ),
              blurRadius: isBeingDragged ? 14 : 6,
              spreadRadius: isBeingDragged ? 0.2 : 0,
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: const Color(
                0xFF08110C,
              ).withValues(alpha: isBeingDragged ? 0.18 : 0.06),
              blurRadius: isBeingDragged ? 18 : 8,
              offset: Offset(0, isBeingDragged ? 12 : 3),
            ),
            BoxShadow(
              color: _dashboardEditorChromePalette.ambient.withValues(
                alpha: isBeingDragged ? 0.06 : 0.010,
              ),
              blurRadius: isBeingDragged ? 12 : 5,
              spreadRadius: isBeingDragged ? 0.2 : 0,
            ),
            BoxShadow(
              color: _dashboardEditorChromePalette.halo.withValues(
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
      left: chromeLeft,
      top: chromeTop,
      width: chromeWidth,
      height: chromeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: contentLeft,
            top: contentTop,
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
                      onPanStart: canDirectMove
                          ? (details) =>
                                _startDirectMove(item, details.globalPosition)
                          : null,
                      onPanUpdate: canDirectMove
                          ? (details) => _updateMove(
                              item: item,
                              globalPosition: details.globalPosition,
                              columns: columns,
                              stepX: stepX,
                              stepY: stepY,
                            )
                          : null,
                      onPanEnd: canDirectMove ? (_) => _finishGesture() : null,
                      onPanCancel: canDirectMove ? _finishGesture : null,
                    ),
                  ),
                Positioned.fill(
                  child: usesCompactSliderHitbox
                      ? IgnorePointer(
                          child: AnimatedScale(
                            duration: liftAnimationDuration,
                            curve: liftAnimationCurve,
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
                                                  borderRadius:
                                                      placeholderRadius,
                                                )
                                              : DashboardItemRenderer(
                                                  item: item,
                                                  enableInteraction:
                                                      !_isEditMode,
                                                  isEditMode: _isEditMode,
                                                  onItemChanged: !_isEditMode
                                                      ? _updateItemFromRenderer
                                                      : null,
                                                  themePreset: _themePreset,
                                                  showTitle: !_isEditMode,
                                                  paintTitle: _isEditMode,
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
                          onPanStart: canDirectMove
                              ? (details) => _startDirectMove(
                                  item,
                                  details.globalPosition,
                                )
                              : null,
                          onPanUpdate: canDirectMove
                              ? (details) => _updateMove(
                                  item: item,
                                  globalPosition: details.globalPosition,
                                  columns: columns,
                                  stepX: stepX,
                                  stepY: stepY,
                                )
                              : null,
                          onPanEnd: canDirectMove
                              ? (_) => _finishGesture()
                              : null,
                          onPanCancel: canDirectMove ? _finishGesture : null,
                          child: AnimatedScale(
                            duration: liftAnimationDuration,
                            curve: liftAnimationCurve,
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
                                                  borderRadius:
                                                      placeholderRadius,
                                                )
                                              : DashboardItemRenderer(
                                                  item: item,
                                                  enableInteraction:
                                                      !_isEditMode,
                                                  isEditMode: _isEditMode,
                                                  onItemChanged: !_isEditMode
                                                      ? _updateItemFromRenderer
                                                      : null,
                                                  themePreset: _themePreset,
                                                  showTitle: !_isEditMode,
                                                  paintTitle: _isEditMode,
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
                    left: selectionRect.left,
                    top: selectionRect.top,
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
                      onPanStart: canDirectMove
                          ? (details) =>
                                _startDirectMove(item, details.globalPosition)
                          : null,
                      onPanUpdate: canDirectMove
                          ? (details) => _updateMove(
                              item: item,
                              globalPosition: details.globalPosition,
                              columns: columns,
                              stepX: stepX,
                              stepY: stepY,
                            )
                          : null,
                      onPanEnd: canDirectMove ? (_) => _finishGesture() : null,
                      onPanCancel: canDirectMove ? _finishGesture : null,
                    ),
                  ),
              ],
            ),
          ),
          if (showStaticSelectionChrome)
            Positioned(
              left: selectionLeft,
              top: selectionTop,
              width: selectionWidth,
              height: selectionHeight,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: ValueKey<String>(
                    'dashboard_builder_selection_chrome_${item.id}',
                  ),
                  decoration: _dashboardSelectionChromeDecoration(
                    isActivelyManipulating: isActivelyManipulating,
                    radius: highlightRadius,
                  ),
                ),
              ),
            ),
          if (showTopHandle)
            Positioned(
              left: (selectionCenterX - (handleExtent / 2)).clamp(
                0.0,
                math.max(0.0, chromeWidth - handleExtent),
              ),
              top: (selectionTop - handleInset).clamp(
                0.0,
                math.max(0.0, chromeHeight - handleExtent),
              ),
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
          if (showRightHandle)
            Positioned(
              left: (selectionLeft + selectionWidth - handleInset).clamp(
                0.0,
                math.max(0.0, chromeWidth - handleExtent),
              ),
              top: (selectionCenterY - (handleExtent / 2)).clamp(
                0.0,
                math.max(0.0, chromeHeight - handleExtent),
              ),
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
          if (showBottomHandle)
            Positioned(
              left: (selectionCenterX - (handleExtent / 2)).clamp(
                0.0,
                math.max(0.0, chromeWidth - handleExtent),
              ),
              width: handleExtent,
              height: handleExtent,
              top: (selectionTop + selectionHeight - handleInset).clamp(
                0.0,
                math.max(0.0, chromeHeight - handleExtent),
              ),
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
          if (showLeftHandle)
            Positioned(
              left: (selectionLeft - handleInset).clamp(
                0.0,
                math.max(0.0, chromeWidth - handleExtent),
              ),
              top: (selectionCenterY - (handleExtent / 2)).clamp(
                0.0,
                math.max(0.0, chromeHeight - handleExtent),
              ),
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
        ],
      ),
    );
  }
}
