import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../../theme/app_theme.dart';
import '../../dashboard/models/widget_binding_model.dart';
import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import 'dashboard_item_renderer.dart';
import 'dashboard_text_contrast.dart';
import 'smart_slider_widget.dart';
import 'widget_shell_layout.dart';

class _QueuedControlWrite {
  const _QueuedControlWrite({
    required this.pin,
    required this.value,
    required this.valueType,
    required this.rollbackItems,
    required this.rollbackRevision,
  });

  final String pin;
  final Object value;
  final WidgetBindingValueType valueType;
  final List<DashboardItem> rollbackItems;
  final int rollbackRevision;

  _QueuedControlWrite copyWith({
    List<DashboardItem>? rollbackItems,
    int? rollbackRevision,
  }) {
    return _QueuedControlWrite(
      pin: pin,
      value: value,
      valueType: valueType,
      rollbackItems: rollbackItems ?? this.rollbackItems,
      rollbackRevision: rollbackRevision ?? this.rollbackRevision,
    );
  }
}

class DashboardHomeView extends StatefulWidget {
  const DashboardHomeView({
    super.key,
    required this.runtimeController,
    this.dashboardService,
    this.bottomContentPadding = 0,
    this.onScrollActivityChanged,
  });

  final DashboardRuntimeController runtimeController;
  final DashboardService? dashboardService;
  final double bottomContentPadding;
  final ValueChanged<bool>? onScrollActivityChanged;

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView>
    with SingleTickerProviderStateMixin {
  static const double _gridGap = 0;
  static const double _canvasHorizontalPadding = 0;
  static const double _canvasTopPadding = 0;
  static const double _canvasBottomScrollPadding = 24;
  static const double _emptyCanvasMinHeight = 420;
  static const double _emptyCanvasMaxHeight = 520;
  static const double _targetCellSize = 14;
  static const int _minColumns = 18;
  static const int _maxColumns = 26;
  static const Duration _controlTapCooldown = Duration(milliseconds: 1500);
  static const Duration _highlightDuration = Duration(milliseconds: 1800);

  late final DashboardService _dashboardService =
      widget.dashboardService ?? DashboardService();
  final Map<String, Timer> _controlWriteDebounceTimers = <String, Timer>{};
  final Set<String> _controlWriteInFlight = <String>{};
  final Map<String, _QueuedControlWrite> _controlWriteInFlightPayloads =
      <String, _QueuedControlWrite>{};
  final Map<String, _QueuedControlWrite> _queuedControlWrites =
      <String, _QueuedControlWrite>{};
  final Map<String, DateTime> _recentControlInteractions = <String, DateTime>{};
  final Map<String, GlobalKey> _itemHighlightKeys = <String, GlobalKey>{};
  late final AnimationController _highlightController;
  late final Animation<double> _highlightAlpha;
  String? _highlightedItemId;
  int _controlWriteRevision = 0;
  bool _runtimeRefreshFrameScheduled = false;

  DashboardRuntimeController get _runtimeController => widget.runtimeController;
  List<DashboardItem> get _items => _runtimeController.items;
  bool get _isLoading => _runtimeController.isLoading;
  String? get _errorText => _runtimeController.errorText;
  String get _dashboardTitle => _runtimeController.dashboardTitle;
  BoxDecoration get _pageDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[DashboardRuntimeTheme.backgroundColor, Color(0xFFF8FBF8)],
    ),
  );
  BoxDecoration get _canvasDecoration => AppGlassTheme.surfaceDecoration(
    radius: 28,
    borderAlpha: 0.58,
    colors: _runtimeController.themePreset.canvasColors,
    shadows: AppGlassTheme.shadowSm,
  );

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: _highlightDuration,
    );
    _highlightAlpha = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_highlightController);
    _runtimeController.addListener(_handleRuntimeChanged);
    _runtimeController.highlightItemIdNotifier.addListener(
      _handleHighlightRequest,
    );
    unawaited(_runtimeController.initialize());

    // If a highlight was requested before this view mounted (e.g. user tapped
    // from the Devices tab while the Dashboard tab was not yet built), react
    // to the pending request once the first layout settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_runtimeController.highlightItemIdNotifier.value != null) {
        _handleHighlightRequest();
      }
    });
  }

  @override
  void dispose() {
    _runtimeController.removeListener(_handleRuntimeChanged);
    _runtimeController.highlightItemIdNotifier.removeListener(
      _handleHighlightRequest,
    );
    _highlightController.dispose();
    for (final timer in _controlWriteDebounceTimers.values) {
      timer.cancel();
    }
    _controlWriteDebounceTimers.clear();
    _controlWriteInFlightPayloads.clear();
    _queuedControlWrites.clear();
    super.dispose();
  }

  void _handleHighlightRequest() {
    final targetId = _runtimeController.highlightItemIdNotifier.value;
    if (targetId == null || !mounted) {
      return;
    }

    // Wait until the target widget has been laid out so that
    // Scrollable.ensureVisible can compute its final offset.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final key = _itemHighlightKeys[targetId];
      final context = key?.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          alignment: 0.35,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
      if (!mounted) {
        return;
      }

      setState(() {
        _highlightedItemId = targetId;
      });
      _highlightController
        ..stop()
        ..reset();
      unawaited(_highlightController.forward());
      Future<void>.delayed(
        _highlightDuration + const Duration(milliseconds: 80),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            _highlightedItemId = null;
          });
        },
      );

      _runtimeController.consumeHighlightRequest();
    });
  }

  void _handleRuntimeChanged() {
    if (!mounted) {
      return;
    }
    _setStateSafely(() {});
  }

  void _setStateSafely(VoidCallback update) {
    if (!mounted) {
      return;
    }

    void applyUpdate() {
      if (!mounted) {
        return;
      }
      setState(update);
    }

    try {
      applyUpdate();
    } on FlutterError {
      if (_runtimeRefreshFrameScheduled) {
        return;
      }
      _runtimeRefreshFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runtimeRefreshFrameScheduled = false;
        applyUpdate();
      });
    }
  }

  Future<void> _reloadDashboardDataAfterBuilder() async {
    await _runtimeController.reloadFromStorageAndSnapshot();
  }

  Future<void> _openDashboardBuilder() async {
    await Navigator.pushNamed(context, '/dashboard-builder');
    if (!mounted) {
      return;
    }
    await _reloadDashboardDataAfterBuilder();
  }

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
      DashboardItemType.button || DashboardItemType.toggle => item.enabled,
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => item.value,
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
      case DashboardItemType.stepH:
      case DashboardItemType.stepV:
      case DashboardItemType.gauge:
      case DashboardItemType.valueLabel:
        final numeric = _coerceDouble(value);
        if (numeric == null) {
          return item;
        }
        final clampedNumeric = numeric
            .clamp(item.minValue, item.maxValue)
            .toDouble();
        return item.copyWith(value: clampedNumeric);
    }
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

  String? _normalizedBindingKey(String? rawKey) {
    final key = rawKey?.trim();
    if (key == null || key.isEmpty) {
      return null;
    }
    return key.toUpperCase();
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
        now.difference(previousAt) < _controlTapCooldown) {
      return false;
    }
    _markControlInteraction(next);
    return true;
  }

  String _interactionKey(DashboardItem item) => '${item.id}:${item.type.name}';

  void _markControlInteraction(DashboardItem item) {
    _recentControlInteractions[_interactionKey(item)] = DateTime.now();
    unawaited(
      Future<void>.delayed(_controlTapCooldown, () {
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

    final pin = _extractVirtualPin(item.dataKey);
    if (pin != null) {
      final writeKey = '${item.id}:$pin';
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
    return DateTime.now().difference(previousAt) < _controlTapCooldown;
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
        return null;
    }
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
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => WidgetBindingValueType.number,
    };
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

  String? _extractVirtualPin(String? rawKey) {
    final value = rawKey?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final match = RegExp(r'V\d+', caseSensitive: false).firstMatch(value);
    return match?.group(0)?.toUpperCase();
  }

  int _columnsForWidth(double width) {
    final rawColumns = ((width + _gridGap) / (_targetCellSize + _gridGap))
        .floor();
    return rawColumns.clamp(_minColumns, _maxColumns);
  }

  Widget _buildErrorBanner(String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 14,
            borderAlpha: 0.62,
            colors: <Color>[
              const Color(0xFFFFF7F7).withValues(alpha: 0.84),
              const Color(0xFFFFE7E6).withValues(alpha: 0.54),
            ],
            shadows: const <BoxShadow>[
              BoxShadow(
                color: Color(0x12A33A3A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF6B3AE).withValues(alpha: 0.32),
                  border: Border.all(
                    color: const Color(0xFFFFE4E1).withValues(alpha: 0.88),
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: DashboardRuntimeTheme.errorTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: DashboardRuntimeTheme.errorTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Image.asset(
                  'assets/icons/mascot/mascot_default.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: AppGlassTheme.surfaceDecoration(
                      radius: 22,
                      borderAlpha: 0.60,
                      colors: <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                        const Color(0xFFF4FBF7).withValues(alpha: 0.44),
                      ],
                      shadows: AppGlassTheme.shadowMd,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'เริ่มสร้างแดชบอร์ดของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: DashboardRuntimeTheme.headlineColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'เพิ่มวิดเจ็ตตัวแรกเพื่อเริ่มติดตามอุปกรณ์',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: DashboardRuntimeTheme.mutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DashboardBuilderButton(
                          label: 'เพิ่มวิดเจ็ต',
                          icon: Icons.add_rounded,
                          onTap: _openDashboardBuilder,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DashboardRuntimeTheme.buttonEndColor,
        ),
      );
    }

    return DecoratedBox(
      decoration: _pageDecoration,
      child: SafeArea(
        bottom: false,
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomScrollPadding =
                _canvasBottomScrollPadding + widget.bottomContentPadding;
            final canvasWidth =
                constraints.maxWidth - (_canvasHorizontalPadding * 2);
            final columns = _columnsForWidth(canvasWidth);
            final cellWidth =
                (canvasWidth - (_gridGap * (columns - 1))) / columns;
            final rowHeight = cellWidth;
            final stepX = cellWidth + _gridGap;
            final stepY = rowHeight + _gridGap;
            final maxBottom = _items.fold<int>(
              0,
              (current, item) =>
                  item.rect.bottom > current ? item.rect.bottom : current,
            );
            final viewportCanvasHeight =
                (constraints.maxHeight -
                        _canvasTopPadding -
                        bottomScrollPadding)
                    .clamp(0.0, double.infinity);
            final isEmptyDashboard = _items.isEmpty;
            final minVisibleRows =
                ((viewportCanvasHeight + _gridGap) / (rowHeight + _gridGap))
                    .ceil();
            final rows = math.max(minVisibleRows, maxBottom).clamp(6, 72);
            final contentHeight = (rows * rowHeight) + ((rows - 1) * _gridGap);
            final emptyCanvasHeight = viewportCanvasHeight.clamp(
              _emptyCanvasMinHeight,
              _emptyCanvasMaxHeight,
            );
            final canvasHeight = isEmptyDashboard
                ? emptyCanvasHeight
                : (contentHeight < viewportCanvasHeight
                      ? viewportCanvasHeight
                      : contentHeight);

            return NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  _canvasHorizontalPadding,
                  _canvasTopPadding + 8,
                  _canvasHorizontalPadding,
                  bottomScrollPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: AppGlassTheme.surfaceDecoration(
                              radius: 22,
                              borderAlpha: 0.60,
                              colors: <Color>[
                                const Color(0xFFFFFFFF).withValues(alpha: 0.66),
                                const Color(0xFFF4FBF7).withValues(alpha: 0.40),
                              ],
                              shadows: AppGlassTheme.shadowMd,
                            ),
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                            child: LayoutBuilder(
                              builder: (context, headerConstraints) {
                                final titleWidget = Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      _dashboardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                        color: DashboardRuntimeTheme
                                            .fieldTextColor,
                                      ),
                                    ),
                                  ),
                                );
                                final builderButton = _DashboardBuilderButton(
                                  label: 'เพิ่มวิดเจ็ต',
                                  icon: Icons.add_rounded,
                                  isCompact: true,
                                  onTap: _openDashboardBuilder,
                                );

                                return Row(
                                  children: [
                                    Expanded(child: titleWidget),
                                    const SizedBox(width: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: builderButton,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_errorText != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _buildErrorBanner(_errorText!),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: _canvasDecoration,
                            child: SizedBox(
                              height: canvasHeight,
                              child: isEmptyDashboard
                                  ? _buildEmptyState()
                                  : Stack(
                                      children: [
                                        for (final item in _items)
                                          Positioned(
                                            key: ValueKey(item.id),
                                            left: item.rect.x * stepX,
                                            top: item.rect.y * stepY,
                                            width:
                                                (item.rect.w * cellWidth) +
                                                ((item.rect.w - 1) * _gridGap),
                                            height:
                                                (item.rect.h * rowHeight) +
                                                ((item.rect.h - 1) * _gridGap),
                                            child: Padding(
                                              padding: const EdgeInsets.all(2),
                                              child: KeyedSubtree(
                                                key: _itemHighlightKeys
                                                    .putIfAbsent(
                                                      item.id,
                                                      () => GlobalKey(),
                                                    ),
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: Opacity(
                                                        opacity:
                                                            _isItemInteractionLocked(
                                                              item,
                                                            )
                                                            ? 0.72
                                                            : 1,
                                                        child: Builder(
                                                          builder: (context) {
                                                            return DashboardItemRenderer(
                                                              item: item,
                                                              themePreset:
                                                                  _runtimeController
                                                                      .themePreset,
                                                              isEditMode: false,
                                                              enableInteraction:
                                                                  !_isItemInteractionLocked(
                                                                    item,
                                                                  ),
                                                              onItemChanged:
                                                                  _updateItemFromRenderer,
                                                              paintTitle: false,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    if (_highlightedItemId ==
                                                        item.id)
                                                      Positioned.fill(
                                                        child: IgnorePointer(
                                                          child: AnimatedBuilder(
                                                            animation:
                                                                _highlightAlpha,
                                                            builder: (context, child) {
                                                              final alpha =
                                                                  _highlightAlpha
                                                                      .value;
                                                              return _DashboardItemHighlightOverlay(
                                                                item: item,
                                                                alpha: alpha,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    if (_isItemInteractionLocked(
                                                      item,
                                                    ))
                                                      const Positioned.fill(
                                                        child: AbsorbPointer(
                                                          child:
                                                              SizedBox.expand(),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        for (final item in _items)
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final callback = widget.onScrollActivityChanged;
    if (callback == null || notification.depth != 0) {
      return false;
    }

    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      callback(false);
    } else if (notification is ScrollStartNotification ||
        notification is UserScrollNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      callback(true);
    } else if (notification is ScrollEndNotification) {
      callback(false);
    }
    return false;
  }

  Widget _buildPositionedItemTitleOverlay({
    required DashboardItem item,
    required double cellWidth,
    required double rowHeight,
    required double stepX,
    required double stepY,
  }) {
    if (!_shouldRenderRuntimeTitle(item)) {
      return const SizedBox.shrink();
    }

    final left = item.rect.x * stepX;
    final top = item.rect.y * stepY;
    final width = (item.rect.w * cellWidth) + ((item.rect.w - 1) * _gridGap);
    final height = (item.rect.h * rowHeight) + ((item.rect.h - 1) * _gridGap);
    final style = _runtimeWidgetTitleStyle(item);
    final titleHeight = _runtimeWidgetTitleHeight(style);
    final isBottomTitle =
        item.titlePosition.trim().toLowerCase() ==
        DashboardItemTitlePosition.bottomOutside;

    return Positioned(
      left: left,
      top: isBottomTitle ? top + height - titleHeight : top,
      width: width,
      height: titleHeight,
      child: IgnorePointer(
        child: _DashboardWidgetTitleOverlay(
          text: item.title.toUpperCase(),
          style: style,
        ),
      ),
    );
  }

  bool _shouldRenderRuntimeTitle(DashboardItem item) {
    final title = item.title.trim();
    return title.isNotEmpty &&
        item.titlePosition.trim().toLowerCase() !=
            DashboardItemTitlePosition.hidden &&
        !_isFactoryDefaultTitle(item);
  }

  bool _isFactoryDefaultTitle(DashboardItem item) {
    return dashboardIsDefaultTitleForType(item.type, item.title);
  }

  TextStyle _runtimeWidgetTitleStyle(DashboardItem item) {
    final themePreset = _runtimeController.themePreset;
    final fontSize = (item.titleFontSize ?? 10.0).clamp(7.0, 12.0);

    final canvasColor = themePreset.canvasColors.isNotEmpty
        ? themePreset.canvasColors.first
        : themePreset.pageEnd;

    final isCanvasDark =
        ThemeData.estimateBrightnessForColor(canvasColor) == Brightness.dark;

    final fallback = isCanvasDark ? Colors.white : themePreset.headlineColor;

    final titleColor = item.titleColor ?? fallback;

    final resolvedTitleColor = DashboardTextContrast.readableTextColor(
      preferred: titleColor,
      background: canvasColor,
      fallback: fallback,
      minRatio: 4.5,
    );

    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: resolvedTitleColor.withValues(alpha: isCanvasDark ? 0.96 : 1.0),
      shadows: isCanvasDark
          ? <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : <Shadow>[
              Shadow(
                color: Colors.white.withValues(alpha: 0.88),
                blurRadius: 5,
              ),
            ],
    );
  }

  double _runtimeWidgetTitleHeight(TextStyle style) {
    return ((style.fontSize ?? 10.0) * 1.4).clamp(12.0, 24.0);
  }
}

class _DashboardBuilderButton extends StatelessWidget {
  const _DashboardBuilderButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isCompact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 15 : 16),
        border: Border.all(color: const Color(0xFF9EC3F0)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB6D2F5), Color(0xFF82AEE8)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isCompact ? 15 : 16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 16,
              vertical: isCompact ? 7 : 11,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: isCompact ? 14 : 18, color: Colors.white),
                SizedBox(width: isCompact ? 6 : 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

class _DashboardWidgetTitleOverlay extends StatelessWidget {
  const _DashboardWidgetTitleOverlay({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 200.0;
        return Center(
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardItemHighlightOverlay extends StatelessWidget {
  const _DashboardItemHighlightOverlay({
    required this.item,
    required this.alpha,
  });

  final DashboardItem item;
  final double alpha;

  static const Color _borderColor = Color(0xFFFFC857);
  static const Color _glowColor = Color(0xFFFFD166);

  @override
  Widget build(BuildContext context) {
    if (alpha <= 0) {
      return const SizedBox.expand();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final shape = _shapeFor(item.type, width, height);
        final highlight = DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: shape,
            shadows: [
              BoxShadow(
                color: _glowColor.withValues(alpha: alpha * 0.46),
                blurRadius: 26,
                spreadRadius: 4,
              ),
            ],
          ),
        );

        if (item.type == DashboardItemType.slider) {
          final layout = buildSliderShellLayout(
            width: width,
            height: height,
            desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
            shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
          );
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: layout.shellTopInset,
                bottom: layout.shellBottomInset,
                child: highlight,
              ),
            ],
          );
        }

        return highlight;
      },
    );
  }

  ShapeBorder _shapeFor(DashboardItemType type, double width, double height) {
    final side = BorderSide(
      color: _borderColor.withValues(alpha: alpha),
      width: 3,
    );

    return switch (type) {
      DashboardItemType.button => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(math.min(width, height) / 2),
        side: side,
      ),
      DashboardItemType.toggle => StadiumBorder(side: side),
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: side,
      ),
    };
  }
}
