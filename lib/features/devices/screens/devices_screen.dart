import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../dashboard/models/device_snapshot_model.dart';
import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../../dashboard_builder/models/dashboard_item.dart';
import '../../../theme/app_theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, required this.runtimeController});

  final DashboardRuntimeController runtimeController;

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
                  'Devices',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: DashboardRuntimeTheme.fieldTextColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ติดตามสถานะเชื่อมต่อและตรวจสอบข้อมูลอุปกรณ์แบบ Real-time จากจุดเดียว',
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
    final showLegacyHeader = DateTime.now().millisecondsSinceEpoch < 0;

    return SafeArea(
      child: RefreshIndicator(
        color: DashboardRuntimeTheme.buttonEndColor,
        onRefresh: _runtimeController.refreshSnapshotFromServer,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _buildHeader(isLoading: isLoading),
            const SizedBox(height: 18),
            if (showLegacyHeader) ...[
              const SizedBox.shrink(),
              const Text(
                'Devices',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: DashboardRuntimeTheme.fieldTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ตรวจสอบสถานะการเชื่อมต่อและวิเคราะห์ปัญหาอุปกรณ์ได้ครบในจุดเดียว',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: DashboardRuntimeTheme.mutedTextColor,
                ),
              ),
              const SizedBox(height: 18),
            ],
            _buildStatusCard(snapshot),
            const SizedBox(height: 18),
            if (isLoading && snapshot == null)
              const _LoadingCard()
            else ...[
              _buildVirtualPinSection(snapshot),
            ],
          ],
        ),
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
                label: 'Status',
                value: title,
                background: pillColor,
                foreground: accentColor,
              ),
              _StatusPill(
                label: 'Updated',
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

  Widget _buildVirtualPinSection(DeviceSnapshotModel? snapshot) {
    final pinWidgetIndex = _buildPinWidgetIndex(_runtimeController.items);
    final snapshotPins = snapshot?.virtualPins ?? const <String, dynamic>{};

    // Only show pins that are actually bound to a widget. With V0-V255 possible
    // pins on the device, showing unused ones would clutter the screen.
    final allPins = pinWidgetIndex.keys.toList()..sort(_comparePinNames);

    final liveCount = allPins
        .where((pin) => snapshotPins.containsKey(pin))
        .length;
    final waitingCount = allPins.length - liveCount;
    final normalizedSearch = _pinSearchQuery.trim().toLowerCase();
    final filteredPins = allPins.where((pin) {
      final boundItems = pinWidgetIndex[pin] ?? const <DashboardItem>[];
      final value = snapshotPins.containsKey(pin)
          ? _formatPinValue(snapshotPins[pin])
          : null;
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
                      'ค่าพินแบบ Real-time พร้อมดูว่าแต่ละพินถูกใช้โดย widget ใดบน dashboard',
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
                  label: 'กำลังใช้งาน',
                  value: '$liveCount',
                  background: const Color(0xFFE5F4EB),
                  foreground: const Color(0xFF4E9070),
                ),
                if (waitingCount > 0)
                  _StatusPill(
                    label: 'รอการใช้งาน',
                    value: '$waitingCount',
                    background: const Color(0xFFFFF1DC),
                    foreground: const Color(0xFFBF8741),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPinSearchAndFilters(),
          ],
          const SizedBox(height: 14),
          if (allPins.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: AppGlassTheme.surfaceDecoration(
                radius: 16,
                borderAlpha: 0.38,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.58),
                  const Color(0xFFF7FBFF).withValues(alpha: 0.32),
                ],
                shadows: AppGlassTheme.shadowSm,
              ),
              child: const Text(
                'ยังไม่มี widget ใดผูกกับ virtual pin — สร้าง widget จากหน้า Dashboard แล้ว bind pin เพื่อเริ่มติดตามค่า',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: DashboardRuntimeTheme.mutedTextColor,
                ),
              ),
            )
          else if (filteredPins.isEmpty)
            _buildNoPinMatchesState()
          else
            Column(
              children: [
                for (var i = 0; i < filteredPins.length; i++) ...[
                  _PinRow(
                    pin: filteredPins[i],
                    value: snapshotPins.containsKey(filteredPins[i])
                        ? _formatPinValue(snapshotPins[filteredPins[i]])
                        : null,
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

  Widget _buildPinSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _pinSearchController,
          onChanged: (value) => setState(() => _pinSearchQuery = value),
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontSize: 13,
            color: DashboardRuntimeTheme.fieldTextColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search pin, widget, or type',
            hintStyle: const TextStyle(
              color: DashboardRuntimeTheme.mutedTextColor,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: DashboardRuntimeTheme.mutedTextColor,
            ),
            suffixIcon: _pinSearchQuery.trim().isEmpty
                ? null
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: DashboardRuntimeTheme.mutedTextColor,
                    ),
                    onPressed: () {
                      _pinSearchController.clear();
                      setState(() => _pinSearchQuery = '');
                    },
                  ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.56),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFD7E1E8).withValues(alpha: 0.7),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFD7E1E8).withValues(alpha: 0.7),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF82AEE8)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PinFilterChip(
              label: 'All',
              selected: _pinListFilter == _PinListFilter.all,
              onTap: () => _setPinFilter(_PinListFilter.all),
            ),
            _PinFilterChip(
              label: 'Live',
              selected: _pinListFilter == _PinListFilter.live,
              onTap: () => _setPinFilter(_PinListFilter.live),
            ),
            _PinFilterChip(
              label: 'Waiting',
              selected: _pinListFilter == _PinListFilter.waiting,
              onTap: () => _setPinFilter(_PinListFilter.waiting),
            ),
            _PinFilterChip(
              label: 'Multiple widgets',
              selected: _pinListFilter == _PinListFilter.multiple,
              onTap: () => _setPinFilter(_PinListFilter.multiple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoPinMatchesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 16,
        borderAlpha: 0.38,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.58),
          const Color(0xFFF7FBFF).withValues(alpha: 0.32),
        ],
        shadows: AppGlassTheme.shadowSm,
      ),
      child: const Text(
        'No pins match the current search or filter.',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: DashboardRuntimeTheme.mutedTextColor,
        ),
      ),
    );
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
      _PinListFilter.live => snapshotPins.containsKey(pin),
      _PinListFilter.waiting => !snapshotPins.containsKey(pin),
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
    final match = RegExp(r'V\d+', caseSensitive: false).firstMatch(value);
    return match?.group(0)?.toUpperCase();
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
    return '$hour:$minute:$second';
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isRefreshing, required this.onPressed});

  final bool isRefreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isRefreshing ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: AppGlassTheme.accentDecoration(
            radius: 18,
            colors: const <Color>[Color(0xFFB6D2F5), Color(0xFF82AEE8)],
            borderColor: const Color(0xFF9EC3F0),
            glowColor: const Color(0xFF82AEE8),
          ),
          child: isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 16,
        borderAlpha: 0.36,
        colors: <Color>[
          Color.alphaBlend(Colors.white.withValues(alpha: 0.18), background),
          Color.alphaBlend(Colors.white.withValues(alpha: 0.05), background),
        ],
        shadows: AppGlassTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinFilterChip extends StatelessWidget {
  const _PinFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? const Color(0xFF4E9070)
        : DashboardRuntimeTheme.mutedTextColor;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? const Color(0xFFE5F4EB)
                : Colors.white.withValues(alpha: 0.46),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB7DCC8)
                  : const Color(0xFFD7E1E8).withValues(alpha: 0.72),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinWidgetPickerSheet extends StatelessWidget {
  const _PinWidgetPickerSheet({required this.pin, required this.items});

  final String pin;
  final List<DashboardItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset > 0 ? 8 : 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 520),
              decoration: AppGlassTheme.surfaceDecoration(
                radius: 26,
                borderAlpha: 0.58,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.86),
                  const Color(0xFFF5FBFF).withValues(alpha: 0.56),
                ],
                shadows: AppGlassTheme.shadowLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8C4D0).withValues(alpha: 0.64),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F4EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pin,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4E9070),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select widget',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: DashboardRuntimeTheme.fieldTextColor,
                                ),
                              ),
                              Text(
                                '${items.length} widgets use this pin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: DashboardRuntimeTheme.mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _PinWidgetPickerTile(
                          item: item,
                          index: index,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinWidgetPickerTile extends StatelessWidget {
  const _PinWidgetPickerTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final DashboardItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = _widgetLabel(item);
    final subtitle = _widgetSubtitle(item);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 18,
            borderAlpha: 0.36,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.62),
              const Color(0xFFF7FBFF).withValues(alpha: 0.34),
            ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _widgetIcon(item.type),
                  size: 19,
                  color: item.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DashboardRuntimeTheme.fieldTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DashboardRuntimeTheme.mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DashboardRuntimeTheme.mutedTextColor,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: DashboardRuntimeTheme.mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiWidgetBadge extends StatelessWidget {
  const _MultiWidgetBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC9DBF7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.dashboard_customize_rounded,
            size: 13,
            color: Color(0xFF5B7FB6),
          ),
          const SizedBox(width: 4),
          Text(
            '$count widgets',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5B7FB6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinRow extends StatelessWidget {
  const _PinRow({
    required this.pin,
    required this.value,
    required this.boundItems,
    required this.onTap,
  });

  final String pin;
  final String? value;
  final List<DashboardItem> boundItems;
  final VoidCallback onTap;

  bool get _isBound => boundItems.isNotEmpty;
  bool get _hasValue => value != null;
  bool get _hasMultipleWidgets => boundItems.length > 1;

  @override
  Widget build(BuildContext context) {
    final accentColor = _isBound
        ? const Color(0xFF4E9070)
        : const Color(0xFFBF8741);
    final pinBadgeBackground = _isBound
        ? const Color(0xFFE5F4EB)
        : const Color(0xFFFFF1DC);

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 14,
        borderAlpha: 0.32,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.64),
          const Color(0xFFF7FBFF).withValues(alpha: 0.3),
        ],
        shadows: AppGlassTheme.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pinBadgeBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              pin,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBindingLabel(),
                const SizedBox(height: 2),
                _buildBindingSubtitle(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _hasValue ? value! : '—',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _hasValue
                  ? DashboardRuntimeTheme.fieldTextColor
                  : const Color(0xFFB7C0C8),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (_isBound) ...[
            const SizedBox(width: 8),
            if (_hasMultipleWidgets)
              _MultiWidgetBadge(count: boundItems.length)
            else
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: accentColor.withValues(alpha: 0.78),
              ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTap: _isBound ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }

  Widget _buildBindingLabel() {
    if (!_isBound) {
      return const Text(
        'Unused pin',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9B7637),
        ),
      );
    }
    final primary = boundItems.first;
    final label = _widgetLabel(primary);
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: DashboardRuntimeTheme.fieldTextColor,
      ),
    );
  }

  Widget _buildBindingSubtitle() {
    if (!_isBound) {
      return Text(
        _hasValue
            ? 'ค่าส่งจากอุปกรณ์แต่ยังไม่ถูกใช้โดย widget'
            : 'ยังไม่มีค่าและไม่ได้ผูกกับ widget',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11.5,
          color: DashboardRuntimeTheme.mutedTextColor,
        ),
      );
    }

    final primary = boundItems.first;
    final typeLabel = _widgetTypeLabel(primary.type);
    final unit = primary.unit?.trim();
    final extra = boundItems.length > 1 ? ' • +${boundItems.length - 1}' : '';
    final unitText = unit != null && unit.isNotEmpty ? ' · $unit' : '';
    return Text(
      '$typeLabel$unitText$extra',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11.5,
        color: DashboardRuntimeTheme.mutedTextColor,
      ),
    );
  }
}

String _widgetLabel(DashboardItem item) {
  if (item.title.trim().isNotEmpty) {
    return item.title.trim();
  }
  if (item.dataKeyLabel?.trim().isNotEmpty == true) {
    return item.dataKeyLabel!.trim();
  }
  return _widgetTypeLabel(item.type);
}

String _widgetSubtitle(DashboardItem item) {
  final typeLabel = _widgetTypeLabel(item.type);
  final dataKeyLabel = item.dataKeyLabel?.trim();
  final unit = item.unit?.trim();
  final mode = item.bindingMode.trim().isNotEmpty
      ? item.bindingMode.trim()
      : '';
  final parts = <String>[
    typeLabel,
    if (dataKeyLabel != null && dataKeyLabel.isNotEmpty) dataKeyLabel,
    if (unit != null && unit.isNotEmpty) unit,
    if (mode.isNotEmpty) mode,
    'x:${item.rect.x}, y:${item.rect.y}',
  ];
  return parts.join(' · ');
}

String _widgetTypeLabel(DashboardItemType type) {
  switch (type) {
    case DashboardItemType.button:
      return 'Button';
    case DashboardItemType.slider:
      return 'Slider';
    case DashboardItemType.gauge:
      return 'Gauge';
    case DashboardItemType.toggle:
      return 'Toggle';
    case DashboardItemType.valueLabel:
      return 'Value';
  }
}

IconData _widgetIcon(DashboardItemType type) {
  switch (type) {
    case DashboardItemType.button:
      return Icons.power_settings_new_rounded;
    case DashboardItemType.slider:
      return Icons.tune_rounded;
    case DashboardItemType.gauge:
      return Icons.speed_rounded;
    case DashboardItemType.toggle:
      return Icons.toggle_on_rounded;
    case DashboardItemType.valueLabel:
      return Icons.text_fields_rounded;
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: 0.5,
            colors: <Color>[
              Color(0xFFFFFFFF).withValues(alpha: 0.76),
              Color(0xFFF5FBFF).withValues(alpha: 0.38),
            ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: const Center(
            child: Column(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                SizedBox(height: 14),
                Text(
                  'Loading device status...',
                  style: TextStyle(
                    fontSize: 14,
                    color: DashboardRuntimeTheme.mutedTextColor,
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
