part of '../devices_screen.dart';

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
                                '${items.length} Widget ใช้ Pin นี้',
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
            '$count Widget',
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

  bool get _hasValue => value != null;
  bool get _hasMultipleWidgets => boundItems.length > 1;

  @override
  Widget build(BuildContext context) {
    assert(boundItems.isNotEmpty);
    const accentColor = Color(0xFF4E9070);
    const pinBadgeBackground = Color(0xFFE5F4EB);

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
            _hasValue ? value! : '--',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _hasValue
                  ? DashboardRuntimeTheme.fieldTextColor
                  : const Color(0xFFB7C0C8),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
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
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }

  Widget _buildBindingLabel() {
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
      return 'ปุ่ม';
    case DashboardItemType.slider:
      return 'สไลด์';
    case DashboardItemType.stepH:
      return 'ปรับค่า H';
    case DashboardItemType.stepV:
      return 'ปรับค่า V';
    case DashboardItemType.gauge:
      return 'เกจ';
    case DashboardItemType.toggle:
      return 'สวิตช์';
    case DashboardItemType.valueLabel:
      return 'แสดงค่า';
    case DashboardItemType.trend:
      return 'กราฟแนวโน้ม';
    case DashboardItemType.led:
      return 'ไฟสถานะ';
  }
}

IconData _widgetIcon(DashboardItemType type) {
  switch (type) {
    case DashboardItemType.button:
      return Icons.power_settings_new_rounded;
    case DashboardItemType.slider:
      return Icons.tune_rounded;
    case DashboardItemType.stepH:
      return Icons.swap_horiz_rounded;
    case DashboardItemType.stepV:
      return Icons.swap_vert_rounded;
    case DashboardItemType.gauge:
      return Icons.speed_rounded;
    case DashboardItemType.toggle:
      return Icons.toggle_on_rounded;
    case DashboardItemType.valueLabel:
      return Icons.text_fields_rounded;
    case DashboardItemType.trend:
      return Icons.show_chart_rounded;
    case DashboardItemType.led:
      return Icons.lightbulb_outline_rounded;
  }
}
