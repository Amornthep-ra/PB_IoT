part of '../alert_rule_editor_screen.dart';

String _previewTriggerText({
  required String widgetName,
  required AlertRuleCondition? condition,
  required String thresholdText,
}) {
  if (condition == null) {
    return widgetName;
  }

  switch (condition) {
    case AlertRuleCondition.lessThan:
      return thresholdText.isEmpty
          ? '$widgetName ต่ำกว่าค่าที่กำหนด'
          : '$widgetName ต่ำกว่า $thresholdText';
    case AlertRuleCondition.lessThanOrEqual:
      return thresholdText.isEmpty
          ? '$widgetName ไม่เกินค่าที่กำหนด'
          : '$widgetName ไม่เกิน $thresholdText';
    case AlertRuleCondition.greaterThan:
      return thresholdText.isEmpty
          ? '$widgetName สูงกว่าค่าที่กำหนด'
          : '$widgetName สูงกว่า $thresholdText';
    case AlertRuleCondition.greaterThanOrEqual:
      return thresholdText.isEmpty
          ? '$widgetName อย่างน้อยค่าที่กำหนด'
          : '$widgetName อย่างน้อย $thresholdText';
    case AlertRuleCondition.equalTo:
      return thresholdText.isEmpty
          ? '$widgetName เท่ากับค่าที่กำหนด'
          : '$widgetName เท่ากับ $thresholdText';
    case AlertRuleCondition.notEqualTo:
      return thresholdText.isEmpty
          ? '$widgetName ไม่เท่ากับค่าที่กำหนด'
          : '$widgetName ไม่เท่ากับ $thresholdText';
    case AlertRuleCondition.isOn:
      return '$widgetName เปิดอยู่';
    case AlertRuleCondition.isOff:
      return '$widgetName ปิดอยู่';
    case AlertRuleCondition.becameOn:
      return '$widgetName เปลี่ยนเป็นเปิด';
    case AlertRuleCondition.becameOff:
      return '$widgetName เปลี่ยนเป็นปิด';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: 0.5,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.76),
              const Color(0xFFF5FBFF).withValues(alpha: 0.38),
            ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF20303A),
      ),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({required this.value, required this.onChanged});

  final AlertRuleSeverity value;
  final ValueChanged<AlertRuleSeverity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AlertRuleSeverity.values.map((severity) {
        final selected = severity == value;
        final color = _severityColor(severity);
        final icon = _severityIcon(severity);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(severity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: selected
                ? AppGlassTheme.accentDecoration(
                    radius: 16,
                    colors: <Color>[
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.72),
                    ],
                    borderColor: color.withValues(alpha: 0.78),
                    glowColor: color,
                  )
                : AppGlassTheme.surfaceDecoration(
                    radius: 16,
                    borderAlpha: 0.36,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.5),
                      color.withValues(alpha: 0.08),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : color),
                const SizedBox(width: 8),
                Text(
                  _severityLabel(severity),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF20303A),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WidgetBindingChips extends StatelessWidget {
  const _WidgetBindingChips({required this.item});

  final DashboardItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final part in _widgetBindingParts(item))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: AppGlassTheme.surfaceDecoration(
              radius: 999,
              borderAlpha: 0.28,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.46),
                const Color(0xFFEEF6FF).withValues(alpha: 0.34),
              ],
              shadows: const <BoxShadow>[],
            ),
            child: Text(
              part,
              style: const TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Color(0xFF667587),
              ),
            ),
          ),
      ],
    );
  }
}

InputDecoration _inputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.52),
    hintStyle: const TextStyle(
      color: Color(0xFF8A97A5),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.68)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.68)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF8CB7E6), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCC5A4E), width: 1.1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCC5A4E), width: 1.5),
    ),
    errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );
}

String _conditionLabel(AlertRuleCondition condition) {
  switch (condition) {
    case AlertRuleCondition.lessThan:
      return '<';
    case AlertRuleCondition.lessThanOrEqual:
      return '<=';
    case AlertRuleCondition.greaterThan:
      return '>';
    case AlertRuleCondition.greaterThanOrEqual:
      return '>=';
    case AlertRuleCondition.equalTo:
      return '==';
    case AlertRuleCondition.notEqualTo:
      return '!=';
    case AlertRuleCondition.isOn:
      return 'เปิดอยู่';
    case AlertRuleCondition.isOff:
      return 'ปิดอยู่';
    case AlertRuleCondition.becameOn:
      return 'เปลี่ยนเป็นเปิด';
    case AlertRuleCondition.becameOff:
      return 'เปลี่ยนเป็นปิด';
  }
}

IconData _severityIcon(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return Icons.info_outline_rounded;
    case AlertRuleSeverity.warning:
      return Icons.warning_amber_rounded;
    case AlertRuleSeverity.critical:
      return Icons.error_outline_rounded;
  }
}

Color _severityColor(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return const Color(0xFF4C8BC8);
    case AlertRuleSeverity.warning:
      return const Color(0xFFE28A3B);
    case AlertRuleSeverity.critical:
      return const Color(0xFFCC5A4E);
  }
}

String _severityLabel(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return 'ข้อมูล';
    case AlertRuleSeverity.warning:
      return 'เตือน';
    case AlertRuleSeverity.critical:
      return 'วิกฤต';
  }
}

String _thresholdHintForItem(DashboardItem? item) {
  if (item == null) {
    return 'ใส่ค่าตัวเลข';
  }
  final unit = (item.unit ?? '').trim();
  if (unit.isEmpty) {
    return 'ใส่ค่าตัวเลข';
  }
  return 'ใส่ค่าเป็น $unit';
}

String _widgetDisplayName(DashboardItem item) {
  final title = item.title.trim();
  final typeLabel = _widgetTypeLabel(item.type);
  if (title.isEmpty) {
    return typeLabel;
  }
  return '$title ($typeLabel)';
}

String _widgetTypeLabel(DashboardItemType type) {
  return switch (type) {
    DashboardItemType.button => 'ปุ่ม',
    DashboardItemType.toggle => 'สวิตช์',
    DashboardItemType.slider => 'สไลเดอร์',
    DashboardItemType.stepH => 'ปรับค่า H',
    DashboardItemType.stepV => 'ปรับค่า V',
    DashboardItemType.gauge => 'เกจ',
    DashboardItemType.valueLabel => 'แสดงค่า',
    DashboardItemType.trend => 'กราฟแนวโน้ม',
    DashboardItemType.led => 'ไฟสถานะ',
  };
}

String _widgetBindingSummary(DashboardItem item) {
  return _widgetBindingParts(item).join('  •  ');
}

List<String> _widgetBindingParts(DashboardItem item) {
  final dataKeyLabel = (item.dataKeyLabel ?? '').trim();
  final dataKey = (item.dataKey ?? '').trim();
  final normalizedType = item.dataType.trim().toLowerCase();
  final typeLabel = switch (normalizedType) {
    'bool' || 'boolean' => 'บูลีน',
    'enum' || 'enumeration' => 'enum',
    'string' => 'ข้อความ',
    'integer' || 'int' => 'จำนวนเต็ม',
    _ => 'ตัวเลข',
  };
  final unit = (item.unit ?? '').trim();
  final bindingMode = item.bindingMode.trim().toLowerCase();
  final modeLabel = bindingMode == 'write'
      ? 'เขียนค่า'
      : bindingMode == 'read_write'
      ? 'อ่าน/เขียน'
      : 'อ่านค่า';

  return <String>[
    if (dataKeyLabel.isNotEmpty) dataKeyLabel,
    if (dataKey.isNotEmpty &&
        dataKey.toLowerCase() != dataKeyLabel.toLowerCase())
      dataKey,
    typeLabel,
    if (unit.isNotEmpty) unit,
    modeLabel,
  ];
}

class _SourceMissingBanner extends StatelessWidget {
  const _SourceMissingBanner({required this.widgetTitle});

  final String widgetTitle;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFCC5A4E);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'วิดเจ็ตต้นทางถูกลบแล้ว',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20303A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'กฎนี้เคยผูกกับ "$widgetTitle" '
                  'กรุณาเลือกวิดเจ็ตใหม่เพื่อบันทึก',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF667587),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetOptionTile extends StatelessWidget {
  const _WidgetOptionTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF20303A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7B8895),
          ),
        ),
      ],
    );
  }
}
