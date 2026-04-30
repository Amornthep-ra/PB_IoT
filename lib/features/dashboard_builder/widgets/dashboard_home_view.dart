import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../dashboard/models/widget_binding_model.dart';
import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import 'dashboard_item_renderer.dart';

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
  const DashboardHomeView({super.key, required this.runtimeController});

  final DashboardRuntimeController runtimeController;

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  static const double _gridGap = 0;
  static const double _canvasHorizontalPadding = 0;
  static const double _canvasTopPadding = 0;
  static const double _canvasBottomScrollPadding = 24;
  static const double _targetCellSize = 14;
  static const int _minColumns = 18;
  static const int _maxColumns = 26;
  static const Duration _controlTapCooldown = Duration(milliseconds: 1500);

  final DashboardService _dashboardService = DashboardService();
  final Map<String, Timer> _controlWriteDebounceTimers = <String, Timer>{};
  final Set<String> _controlWriteInFlight = <String>{};
  final Map<String, _QueuedControlWrite> _controlWriteInFlightPayloads =
      <String, _QueuedControlWrite>{};
  final Map<String, _QueuedControlWrite> _queuedControlWrites =
      <String, _QueuedControlWrite>{};
  final Map<String, DateTime> _recentControlInteractions = <String, DateTime>{};
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
    _runtimeController.addListener(_handleRuntimeChanged);
    unawaited(_runtimeController.initialize());
  }

  @override
  void dispose() {
    _runtimeController.removeListener(_handleRuntimeChanged);
    for (final timer in _controlWriteDebounceTimers.values) {
      timer.cancel();
    }
    _controlWriteDebounceTimers.clear();
    _controlWriteInFlightPayloads.clear();
    _queuedControlWrites.clear();
    super.dispose();
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
        type == DashboardItemType.slider;
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

    if (next.type == DashboardItemType.slider) {
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

    if (item.type == DashboardItemType.slider) {
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 156,
                height: 156,
                child: Image.asset(
                  'assets/icons/mascot/mascot_default.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 24,
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
                      'ยินดีต้อนรับสู่แดชบอร์ดของคุณ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DashboardRuntimeTheme.headlineColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เริ่มจาก Edit Mode แล้วเพิ่มวิดเจ็ตตัวแรกของคุณได้เลย',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: DashboardRuntimeTheme.mutedTextColor,
                      ),
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
                        _canvasBottomScrollPadding)
                    .clamp(0.0, double.infinity);
            final minVisibleRows =
                ((viewportCanvasHeight + _gridGap) / (rowHeight + _gridGap))
                    .ceil();
            final rows = math.max(minVisibleRows, maxBottom).clamp(6, 72);
            final contentHeight = (rows * rowHeight) + ((rows - 1) * _gridGap);
            final canvasHeight = contentHeight < viewportCanvasHeight
                ? viewportCanvasHeight
                : contentHeight;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                _canvasHorizontalPadding,
                _canvasTopPadding + 8,
                _canvasHorizontalPadding,
                _canvasBottomScrollPadding,
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
                                      color:
                                          DashboardRuntimeTheme.fieldTextColor,
                                    ),
                                  ),
                                ),
                              );
                              final builderButton = DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF9EC3F0),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFFB6D2F5),
                                      const Color(0xFF82AEE8),
                                    ],
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        '/dashboard-builder',
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      await _reloadDashboardDataAfterBuilder();
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 7,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Edit Mode',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                            child: _items.isEmpty
                                ? _buildEmptyState()
                                : Stack(
                                    children: [
                                      for (final item in _items)
                                        Positioned(
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
                                                          enableInteraction:
                                                              !_isItemInteractionLocked(
                                                                item,
                                                              ),
                                                          onItemChanged:
                                                              _updateItemFromRenderer,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                if (_isItemInteractionLocked(
                                                  item,
                                                ))
                                                  Positioned.fill(
                                                    child: AbsorbPointer(
                                                      child:
                                                          SizedBox.expand(),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
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
            );
          },
        ),
      ),
    );
  }
}
