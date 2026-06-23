part of '../widget_settings_sheet.dart';

extension _WidgetSettingsBindingPickerSection on _WidgetSettingsSheetState {
  String? _catalogUsageNote(_BindingCatalogEntry entry) {
    if (_isRecommendedCatalogEntry(entry)) {
      return null;
    }
    return 'ไม่ค่อยเหมาะกับ${_widgetTypeLabel(widget.item.type)}';
  }

  IconData _catalogIcon(_BindingCatalogEntry entry) {
    return switch (entry.group) {
      _BindingSourceGroup.virtualPin => Icons.memory_rounded,
      _BindingSourceGroup.deviceStatus => Icons.insights_outlined,
      _BindingSourceGroup.deviceState => Icons.router_outlined,
      _BindingSourceGroup.control => Icons.tune_rounded,
    };
  }

  Widget _buildBindingField() {
    final hasValidationError =
        _showBindingValidationError && !_hasSelectedBinding;

    return KeyedSubtree(
      key: _bindingFieldKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldShell(
            focused: hasValidationError,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _openBindingPicker,
              key: const ValueKey('widget_settings_binding_field'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 15,
                      color: hasValidationError
                          ? const Color(0xFFCC5A4E)
                          : DashboardRuntimeTheme.labelTextColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _bindingLabelFor(_selectedBindingKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DashboardRuntimeTheme.fieldTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bindingSubtitleFor(_selectedBindingKey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DashboardRuntimeTheme.labelTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: DashboardRuntimeTheme.mutedTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_bindingAssistiveMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _bindingAssistiveMessage!,
              style: TextStyle(
                color: _bindingAssistiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<String?> _openBindingSourcePicker({
    required BuildContext context,
    required String currentBindingKey,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scale = _pickerScale(context);
        final selected = _canonicalBindingKey(currentBindingKey) ?? '';
        final catalogEntries = _sortedBindingCatalog();
        final customEntries = _sortedCustomBindingCatalog();
        final visibleCatalogEntries = catalogEntries.where((entry) {
          if (entry.group == _BindingSourceGroup.control) {
            return _isWritableWidget;
          }
          return true;
        }).toList();
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                0,
                18 * scale,
                14 * scale,
              ),
              child: _buildGlassSheetShell(
                radius: 22 * scale,
                blur: 18,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8 * scale),
                      Container(
                        width: 38 * scale,
                        height: 3 * scale,
                        decoration: BoxDecoration(
                          color: DashboardRuntimeTheme.surfaceBorderColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        'เลือกแหล่งข้อมูล',
                        style: TextStyle(
                          color: DashboardRuntimeTheme.headlineColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15 * scale,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Flexible(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            14 * scale,
                            4 * scale,
                            14 * scale,
                            14 * scale,
                          ),
                          shrinkWrap: true,
                          children: [
                            _buildPickerSectionLabel(
                              label: 'Advanced',
                              scale: scale,
                            ),
                            _buildBindingPickerActionCard(
                              scale: scale,
                              icon: Icons.add_link_rounded,
                              accentColor: DashboardRuntimeTheme.buttonEndColor,
                              title: 'Custom Virtual Pin',
                              subtitle:
                                  'สร้างหรือแก้ไข V Pin เพิ่มเติม เช่น V4, V5',
                              onTap: () =>
                                  Navigator.of(context).pop('__custom_vpin__'),
                            ),
                            SizedBox(height: 10 * scale),
                            _buildBindingPickerActionCard(
                              scale: scale,
                              icon: Icons.route_rounded,
                              accentColor: const Color(0xFF8B7FF3),
                              title: 'Advanced Path Binding',
                              subtitle:
                                  'ใช้ runtime path เช่น status.temperature หรือ control.soilThreshold',
                              onTap: () =>
                                  Navigator.of(context).pop('__advanced__'),
                            ),
                            SizedBox(height: 14 * scale),
                            if (customEntries.isNotEmpty) ...[
                              _buildPickerSectionLabel(
                                label: 'รายการกำหนดเอง',
                                scale: scale,
                              ),
                              for (final entry in customEntries) ...[
                                _buildBindingPickerOptionCard(
                                  scale: scale,
                                  icon: Icons.bookmark_outline_rounded,
                                  iconColor: DashboardRuntimeTheme
                                      .surfaceBorderFocusColor,
                                  title: entry.name,
                                  details: <String>[
                                    _bindingSourceLabelForKey(entry.key),
                                    _bindingMetaLine(
                                      dataType: entry.dataType,
                                      rangeLabel: _customBindingRangeLabel(
                                        entry,
                                      ),
                                      unit: entry.unit,
                                    ),
                                    _customBindingUsageLabel(entry.key),
                                  ],
                                  isSelected: entry.key == selected,
                                  onTap: () =>
                                      Navigator.of(context).pop(entry.key),
                                  trailing:
                                      ((_customBindingUsageCountMap()[entry
                                                  .key] ??
                                              0) ==
                                          0)
                                      ? IconButton(
                                          tooltip: 'ลบคีย์ข้อมูลที่กำหนดเอง',
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop('__delete__:${entry.key}'),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18 * scale,
                                            color: const Color(0xFFD95C54),
                                          ),
                                        )
                                      : (entry.key == selected
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: const Color(0xFF2E6F57),
                                                size: 20 * scale,
                                              )
                                            : Icon(
                                                Icons.lock_outline_rounded,
                                                size: 16 * scale,
                                                color: DashboardRuntimeTheme
                                                    .surfaceBorderColor,
                                              )),
                                ),
                                SizedBox(height: 10 * scale),
                              ],
                            ],
                            for (final group in _BindingSourceGroup.values) ...[
                              if (visibleCatalogEntries.any(
                                (entry) => entry.group == group,
                              )) ...[
                                _buildPickerSectionLabel(
                                  label: _bindingSourceGroupLabel(group),
                                  scale: scale,
                                ),
                                for (final entry in visibleCatalogEntries.where(
                                  (candidate) => candidate.group == group,
                                )) ...[
                                  _buildBindingPickerOptionCard(
                                    scale: scale,
                                    icon: _catalogIcon(entry),
                                    iconColor: _isRecommendedCatalogEntry(entry)
                                        ? DashboardRuntimeTheme
                                              .surfaceBorderFocusColor
                                        : DashboardRuntimeTheme.labelTextColor,
                                    title: _bindingSourceLabelForKey(entry.key),
                                    details: <String>[
                                      _bindingMetaLine(
                                        dataType: entry.dataType,
                                        rangeLabel: entry.rangeLabel,
                                        unit: entry.unit,
                                      ),
                                      if (entry.description.trim().isNotEmpty)
                                        entry.description.trim(),
                                      if (_catalogUsageNote(entry) != null)
                                        _catalogUsageNote(entry)!,
                                    ],
                                    isSelected: entry.key == selected,
                                    onTap: () =>
                                        Navigator.of(context).pop(entry.key),
                                  ),
                                  SizedBox(height: 10 * scale),
                                ],
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _pickerScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 390).clamp(0.86, 1.08);
  }

  Widget _buildPickerSectionLabel({
    required String label,
    required double scale,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        6 * scale,
        16 * scale,
        8 * scale,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: DashboardRuntimeTheme.labelTextColor,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBindingPickerActionCard({
    required double scale,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      decoration: AppGlassTheme.accentDecoration(
        radius: 18 * scale,
        colors: <Color>[
          Color.lerp(accentColor, Colors.white, 0.35) ?? accentColor,
          Color.lerp(accentColor, Colors.black, 0.10) ?? accentColor,
        ],
        borderColor: Colors.white.withValues(alpha: 0.65),
        glowColor: accentColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18 * scale),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 13 * scale,
            ),
            child: Row(
              children: [
                Container(
                  width: 36 * scale,
                  height: 36 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14 * scale),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13 * scale,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w500,
                          fontSize: 11 * scale,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 22 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBindingPickerOptionCard({
    required double scale,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> details,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final decoration = isSelected
        ? AppGlassTheme.accentDecoration(
            radius: 18 * scale,
            colors: const <Color>[Color(0xFFBFE4D4), Color(0xFF9FD1BB)],
            borderColor: const Color(0xFF85B89F),
            glowColor: const Color(0xFFA9D3C7),
          )
        : _glassInsetDecoration(radius: 18 * scale);

    final titleColor = isSelected
        ? const Color(0xFF123329)
        : DashboardRuntimeTheme.fieldTextColor;
    final detailColor = isSelected
        ? const Color(0xFF325246)
        : DashboardRuntimeTheme.labelTextColor;

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18 * scale),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34 * scale,
                  height: 34 * scale,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.48)
                        : Colors.white.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(14 * scale),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.55)
                          : DashboardRuntimeTheme.surfaceBorderColor.withValues(
                              alpha: 0.45,
                            ),
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 18 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w700,
                          fontSize: 13 * scale,
                        ),
                      ),
                      for (final detail in details.where(
                        (text) => text.trim().isNotEmpty,
                      )) ...[
                        SizedBox(height: 2 * scale),
                        Text(
                          detail,
                          style: TextStyle(
                            color: detailColor,
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8 * scale),
                trailing ??
                    (isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: const Color(0xFF2E6F57),
                            size: 20 * scale,
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: DashboardRuntimeTheme.mutedTextColor,
                            size: 20 * scale,
                          )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
