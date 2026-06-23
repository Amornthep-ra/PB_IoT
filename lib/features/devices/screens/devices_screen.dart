import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../dashboard/models/device_snapshot_model.dart';
import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../../dashboard_builder/models/dashboard_item.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_responsive.dart';

part 'devices_parts/device_chrome_widgets.dart';
part 'devices_parts/pin_filter_widgets.dart';
part 'devices_parts/pin_display_widgets.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
    required this.runtimeController,
    this.bottomContentPadding = 0,
  });

  final DashboardRuntimeController runtimeController;
  final double bottomContentPadding;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

enum _PinListFilter { all, live, waiting, multiple }

class _DevicesScreenState extends State<DevicesScreen> {
  final TextEditingController _pinSearchController = TextEditingController();
  _PinListFilter _pinListFilter = _PinListFilter.all;
  String _pinSearchQuery = '';

  DashboardRuntimeController get _runtimeController => widget.runtimeController;

  BoxDecoration _glassSurface({double radius = 24, bool emphasized = false}) {
    return AppGlassTheme.surfaceDecoration(
      radius: radius,
      borderAlpha: emphasized ? 0.62 : 0.5,
      colors: <Color>[
        const Color(0xFFFFFFFF).withValues(alpha: emphasized ? 0.82 : 0.74),
        const Color(0xFFF5FBFF).withValues(alpha: emphasized ? 0.54 : 0.42),
      ],
      shadows: emphasized ? AppGlassTheme.shadowMd : AppGlassTheme.shadowSm,
    );
  }

  Widget _buildGlassSection({
    required Widget child,
    double radius = 24,
    bool emphasized = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: _glassSurface(radius: radius, emphasized: emphasized),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isLoading}) {
    return _buildGlassSection(
      radius: 28,
      emphasized: true,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'อุปกรณ์',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: DashboardRuntimeTheme.fieldTextColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ดูสุขภาพอุปกรณ์ ข้อมูลล่าสุด และ Virtual Pins สำหรับตรวจสอบจากจุดเดียว',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: DashboardRuntimeTheme.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RefreshButton(
            isRefreshing: isLoading,
            onPressed: () =>
                unawaited(_runtimeController.refreshSnapshotFromServer()),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _runtimeController.addListener(_handleRuntimeChanged);
    unawaited(_runtimeController.initialize());
  }

  @override
  void dispose() {
    _runtimeController.removeListener(_handleRuntimeChanged);
    _pinSearchController.dispose();
    super.dispose();
  }

  void _handleRuntimeChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _runtimeController.snapshot;
    final isLoading = _runtimeController.isLoading;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = AppResponsiveLayout.isTabletWidth(
            constraints.maxWidth,
          );
          final shellWidth = isTablet
              ? AppResponsiveLayout.dashboardShellWidth(constraints.maxWidth)
              : double.infinity;
          final content = SizedBox(
            key: const ValueKey<String>('devices_content_shell'),
            width: shellWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isLoading: isLoading),
                const SizedBox(height: 18),
                _buildOverviewCard(snapshot),
                const SizedBox(height: 18),
                if (isLoading && snapshot == null)
                  const _LoadingCard()
                else
                  _buildVirtualPinSection(snapshot),
              ],
            ),
          );

          return RefreshIndicator(
            color: DashboardRuntimeTheme.buttonEndColor,
            onRefresh: _runtimeController.refreshSnapshotFromServer,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isTablet ? 0 : 20,
                isTablet ? 36 : 18,
                isTablet ? 0 : 20,
                widget.bottomContentPadding,
              ),
              children: [
                if (isTablet)
                  Align(alignment: Alignment.topCenter, child: content)
                else
                  content,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(DeviceSnapshotModel? snapshot) {
    final isOnline = snapshot?.online == true;
    final updatedLabel = _formatUpdatedAt(snapshot?.updatedAt);
    final errorMessage = _runtimeController.errorText;
    final hasError = errorMessage != null && errorMessage.trim().isNotEmpty;
    final accentColor = hasError
        ? DashboardRuntimeTheme.errorTextColor
        : isOnline
        ? DashboardRuntimeTheme.buttonEndColor
        : const Color(0xFFC95E68);
    final pillColor = hasError
        ? DashboardRuntimeTheme.errorBackgroundColor
        : isOnline
        ? const Color(0xFFE5F4EB)
        : const Color(0xFFFFECEF);
    final title = hasError
        ? 'การเชื่อมต่อขัดข้อง'
        : isOnline
        ? 'ออนไลน์'
        : 'ออฟไลน์';
    final subtitle = hasError
        ? errorMessage
        : isOnline
        ? 'อุปกรณ์กำลังรายงานสถานะอย่างปกติ'
        : 'อุปกรณ์ไม่ได้รายงานสถานะในขณะนี้';

    return _buildGlassSection(
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isOnline
                            ? Icons.router_rounded
                            : Icons.portable_wifi_off_rounded,
                        color: accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: DashboardRuntimeTheme.headlineColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: DashboardRuntimeTheme.mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill(
                label: 'สถานะ',
                value: title,
                background: pillColor,
                foreground: accentColor,
              ),
              _StatusPill(
                label: 'อัปเดต',
                value: updatedLabel,
                background: DashboardRuntimeTheme.surfaceColor,
                foreground: DashboardRuntimeTheme.labelTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(DeviceSnapshotModel? snapshot) {
    final statusCard = _buildStatusCard(snapshot);
    final freshness = _resolveFreshnessSummary(snapshot);
    final pinSummary = _buildPinSummary(snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        statusCard,
        const SizedBox(height: 14),
        _buildGlassSection(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ภาพรวมอุปกรณ์',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DashboardRuntimeTheme.fieldTextColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'สรุปความสดใหม่ของข้อมูลและภาพรวม Virtual Pins ที่ใช้บน Dashboard',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: DashboardRuntimeTheme.mutedTextColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusPill(
                    label: 'ความสดใหม่',
                    value: freshness.label,
                    background: freshness.background,
                    foreground: freshness.foreground,
                  ),
                  _StatusPill(
                    label: 'พินมีค่า',
                    value: '${pinSummary.livePins}',
                    background: const Color(0xFFE5F4EB),
                    foreground: const Color(0xFF4E9070),
                  ),
                  _StatusPill(
                    label: 'รอข้อมูล',
                    value: '${pinSummary.waitingPins}',
                    background: const Color(0xFFFFF1DC),
                    foreground: const Color(0xFFBF8741),
                  ),
                  _StatusPill(
                    label: 'ผูกกับ Widget',
                    value: '${pinSummary.boundWidgets}',
                    background: const Color(0xFFEAF2FF),
                    foreground: const Color(0xFF5B7FB6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualPinSection(DeviceSnapshotModel? snapshot) {
    final pinWidgetIndex = _buildPinWidgetIndex(_runtimeController.items);
    final rawSnapshotPins = snapshot?.virtualPins ?? const <String, dynamic>{};
    final snapshotPins = <String, dynamic>{
      for (final entry in rawSnapshotPins.entries)
        if (entry.key.trim().isNotEmpty)
          entry.key.trim().toUpperCase(): entry.value,
    };

    final allPins = pinWidgetIndex.keys.toList()..sort(_comparePinNames);

    final liveCount = allPins.where((pin) => snapshotPins[pin] != null).length;
    final waitingCount = allPins
        .where(
          (pin) =>
              (pinWidgetIndex[pin]?.isNotEmpty ?? false) &&
              snapshotPins[pin] == null,
        )
        .length;
    final normalizedSearch = _pinSearchQuery.trim().toLowerCase();
    final filteredPins = allPins.where((pin) {
      final boundItems = pinWidgetIndex[pin] ?? const <DashboardItem>[];
      final value = snapshotPins[pin] == null
          ? null
          : _formatPinValue(snapshotPins[pin]);
      return _matchesPinFilter(
            pin: pin,
            snapshotPins: snapshotPins,
            boundItems: boundItems,
          ) &&
          _matchesPinSearch(
            pin: pin,
            value: value,
            boundItems: boundItems,
            query: normalizedSearch,
          );
    }).toList();

    return _buildGlassSection(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Virtual Pins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DashboardRuntimeTheme.fieldTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ค่าพินแบบ Real-time พร้อมดูว่าแต่ละพินถูกใช้โดย Widget ใดบน Dashboard',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: DashboardRuntimeTheme.mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (allPins.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  label: 'Live',
                  value: '$liveCount',
                  background: const Color(0xFFE5F4EB),
                  foreground: const Color(0xFF4E9070),
                ),
                if (waitingCount > 0)
                  _StatusPill(
                    label: 'รอข้อมูล',
                    value: '$waitingCount',
                    background: const Color(0xFFFFF1DC),
                    foreground: const Color(0xFFBF8741),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _PinSearchAndFilters(
              controller: _pinSearchController,
              query: _pinSearchQuery,
              selectedFilter: _pinListFilter,
              onSearchChanged: (value) =>
                  setState(() => _pinSearchQuery = value),
              onClearSearch: () {
                _pinSearchController.clear();
                setState(() => _pinSearchQuery = '');
              },
              onFilterChanged: _setPinFilter,
            ),
          ],
          const SizedBox(height: 14),
          if (allPins.isEmpty)
            const _NoVirtualPinsState()
          else if (filteredPins.isEmpty)
            const _NoPinMatchesState()
          else
            Column(
              children: [
                for (var i = 0; i < filteredPins.length; i++) ...[
                  _PinRow(
                    pin: filteredPins[i],
                    value: snapshotPins[filteredPins[i]] == null
                        ? null
                        : _formatPinValue(snapshotPins[filteredPins[i]]),
                    boundItems:
                        pinWidgetIndex[filteredPins[i]] ??
                        const <DashboardItem>[],
                    onTap: () => _handlePinRowTap(
                      pin: filteredPins[i],
                      boundItems:
                          pinWidgetIndex[filteredPins[i]] ??
                          const <DashboardItem>[],
                    ),
                  ),
                  if (i != filteredPins.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Map<String, List<DashboardItem>> _buildPinWidgetIndex(
    List<DashboardItem> items,
  ) {
    final index = <String, List<DashboardItem>>{};
    for (final item in items) {
      final pin = _extractVirtualPin(item.dataKey);
      if (pin == null) {
        continue;
      }
      index.putIfAbsent(pin, () => <DashboardItem>[]).add(item);
    }
    return index;
  }

  void _setPinFilter(_PinListFilter filter) {
    if (_pinListFilter == filter) {
      return;
    }
    setState(() => _pinListFilter = filter);
  }

  bool _matchesPinFilter({
    required String pin,
    required Map<String, dynamic> snapshotPins,
    required List<DashboardItem> boundItems,
  }) {
    return switch (_pinListFilter) {
      _PinListFilter.all => true,
      _PinListFilter.live => snapshotPins[pin] != null,
      _PinListFilter.waiting => snapshotPins[pin] == null,
      _PinListFilter.multiple => boundItems.length > 1,
    };
  }

  bool _matchesPinSearch({
    required String pin,
    required String? value,
    required List<DashboardItem> boundItems,
    required String query,
  }) {
    if (query.isEmpty) {
      return true;
    }

    final searchableParts = <String>[
      pin,
      ?value,
      for (final item in boundItems) ...[
        _widgetLabel(item),
        _widgetSubtitle(item),
        item.dataKey ?? '',
        item.dataKeyLabel ?? '',
        item.bindingMode,
        _widgetTypeLabel(item.type),
      ],
    ];

    return searchableParts.any((part) => part.toLowerCase().contains(query));
  }

  String? _extractVirtualPin(String? rawKey) {
    final value = rawKey?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final directMatch = RegExp(
      r'^V\d+$',
      caseSensitive: false,
    ).firstMatch(value);
    if (directMatch != null) {
      return value.toUpperCase();
    }
    final pathMatch = RegExp(
      r'^virtualPins\.(V\d+)$',
      caseSensitive: false,
    ).firstMatch(value);
    return pathMatch?.group(1)?.toUpperCase();
  }

  int _comparePinNames(String a, String b) {
    final numA = int.tryParse(a.replaceAll(RegExp(r'\D'), ''));
    final numB = int.tryParse(b.replaceAll(RegExp(r'\D'), ''));
    if (numA != null && numB != null) {
      return numA.compareTo(numB);
    }
    return a.compareTo(b);
  }

  String _formatPinValue(Object? value) {
    if (value == null) {
      return '--';
    }
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  _DeviceFreshnessSummary _resolveFreshnessSummary(
    DeviceSnapshotModel? snapshot,
  ) {
    final updatedAt = snapshot?.updatedAt;
    if (updatedAt == null) {
      return const _DeviceFreshnessSummary(
        label: 'ไม่ทราบ',
        foreground: Color(0xFF97A3AF),
        background: Color(0xFFF0F3F7),
      );
    }

    final age = DateTime.now().difference(updatedAt.toLocal());
    if (age <= const Duration(seconds: 15)) {
      return const _DeviceFreshnessSummary(
        label: 'สดใหม่',
        foreground: Color(0xFF4E9070),
        background: Color(0xFFE5F4EB),
      );
    }
    if (age <= const Duration(minutes: 2)) {
      return const _DeviceFreshnessSummary(
        label: 'ช้ากว่าปกติ',
        foreground: Color(0xFFBF8741),
        background: Color(0xFFFFF1DC),
      );
    }
    return const _DeviceFreshnessSummary(
      label: 'ข้อมูลค้าง',
      foreground: Color(0xFFC95E68),
      background: Color(0xFFFFECEF),
    );
  }

  _PinSummary _buildPinSummary(DeviceSnapshotModel? snapshot) {
    final pinWidgetIndex = _buildPinWidgetIndex(_runtimeController.items);
    final boundPins = pinWidgetIndex.keys.toList();
    final snapshotPins = <String, dynamic>{
      for (final entry
          in (snapshot?.virtualPins ?? const <String, dynamic>{}).entries)
        if (entry.key.trim().isNotEmpty)
          entry.key.trim().toUpperCase(): entry.value,
    };
    final livePins = boundPins.where((pin) => snapshotPins[pin] != null).length;
    final waitingPins = boundPins
        .where((pin) => snapshotPins[pin] == null)
        .length;
    final boundWidgets = pinWidgetIndex.values.fold<int>(
      0,
      (count, items) => count + items.length,
    );
    return _PinSummary(
      livePins: livePins,
      waitingPins: waitingPins,
      boundWidgets: boundWidgets,
    );
  }

  Future<void> _handlePinRowTap({
    required String pin,
    required List<DashboardItem> boundItems,
  }) async {
    if (boundItems.isEmpty) {
      return;
    }

    if (boundItems.length == 1) {
      _runtimeController.requestHighlightItem(boundItems.first.id);
      return;
    }

    final selectedItem = await showModalBottomSheet<DashboardItem>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      isScrollControlled: true,
      builder: (context) {
        return _PinWidgetPickerSheet(pin: pin, items: boundItems);
      },
    );

    if (!mounted || selectedItem == null) {
      return;
    }
    _runtimeController.requestHighlightItem(selectedItem.id);
  }

  String _formatUpdatedAt(DateTime? value) {
    if (value == null) {
      return '--';
    }
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final time = '$hour:$minute:$second';
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return time;
    }
    return '${local.day} ${_thaiShortMonth(local.month)} ${local.year} $time';
  }

  String _thaiShortMonth(int month) {
    const months = <String>[
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    if (month < 1 || month > months.length) {
      return '';
    }
    return months[month - 1];
  }
}

class _DeviceFreshnessSummary {
  const _DeviceFreshnessSummary({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

class _PinSummary {
  const _PinSummary({
    required this.livePins,
    required this.waitingPins,
    required this.boundWidgets,
  });

  final int livePins;
  final int waitingPins;
  final int boundWidgets;
}
