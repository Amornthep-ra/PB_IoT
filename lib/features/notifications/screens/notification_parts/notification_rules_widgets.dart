part of '../notifications_screen.dart';

enum _RulesOverflowAction { delete }

class _RulesSection extends StatelessWidget {
  const _RulesSection({
    required this.rules,
    required this.availableWidgetIds,
    required this.onCreateRule,
    required this.onEditRule,
    required this.onDeleteRule,
    required this.onDeleteRules,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final List<AlertRuleModel> rules;
  final Set<String> availableWidgetIds;
  final VoidCallback onCreateRule;
  final ValueChanged<AlertRuleModel> onEditRule;
  final ValueChanged<AlertRuleModel> onDeleteRule;
  final ValueChanged<List<AlertRuleModel>> onDeleteRules;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final hasRules = rules.isNotEmpty;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = AppResponsiveLayout.isTabletWidth(screenWidth);
    final disabledActionDecoration = AppGlassTheme.surfaceDecoration(
      radius: 14,
      borderAlpha: 0.22,
      colors: <Color>[
        Colors.white.withValues(alpha: 0.2),
        const Color(0xFFE4EAF1).withValues(alpha: 0.2),
      ],
      shadows: const <BoxShadow>[],
    );
    return _GlassCard(
      key: const ValueKey<String>('notification_rules_section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final useStackedHeader = constraints.maxWidth < 520;
              final titleRow = Row(
                children: [
                  const Flexible(
                    child: Text(
                      'กฎแจ้งเตือน',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20303A),
                      ),
                    ),
                  ),
                  if (rules.isNotEmpty && isTablet) ...[
                    const SizedBox(width: 8),
                    _CompactInfoChip(
                      label: '${rules.length} กฎ',
                      color: const Color(0xFF4C8BC8),
                    ),
                  ],
                ],
              );

              Widget buildCompactActionSurface({
                Key? key,
                required bool enabled,
                required double borderAlpha,
                required List<Color> colors,
                required Widget child,
              }) {
                return Container(
                  key: key,
                  width: 44,
                  height: 44,
                  decoration: enabled
                      ? AppGlassTheme.surfaceDecoration(
                          radius: 14,
                          borderAlpha: borderAlpha,
                          colors: colors,
                          shadows: const <BoxShadow>[],
                        )
                      : disabledActionDecoration,
                  alignment: Alignment.center,
                  child: child,
                );
              }

              final actions = Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  Container(
                    key: const ValueKey<String>(
                      'notification_rules_primary_create_action',
                    ),
                    decoration: AppGlassTheme.accentDecoration(
                      radius: 14,
                      colors: const <Color>[
                        Color(0xFFB6D2F5),
                        Color(0xFF82AEE8),
                      ],
                      borderColor: const Color(0xFF9EC3F0),
                      glowColor: const Color(0xFF82AEE8),
                    ),
                    child: TextButton.icon(
                      onPressed: onCreateRule,
                      icon: const Icon(Icons.add_alert_rounded, size: 16),
                      label: const Text(
                        'สร้างกฎ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  buildCompactActionSurface(
                    enabled: hasRules,
                    borderAlpha: 0.28,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.26),
                      const Color(0xFF4C8BC8).withValues(alpha: 0.08),
                    ],
                    child: IconButton(
                      onPressed: hasRules ? onToggleExpanded : null,
                      tooltip: isExpanded
                          ? 'ย่อกฎแจ้งเตือน'
                          : 'แสดงกฎแจ้งเตือน',
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 22,
                      ),
                      color: const Color(0xFF4C8BC8),
                      disabledColor: const Color(0xFFC8D0D8),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 19,
                    ),
                  ),
                  buildCompactActionSurface(
                    key: const ValueKey<String>(
                      'notification_rules_overflow_action',
                    ),
                    enabled: hasRules,
                    borderAlpha: 0.24,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.24),
                      const Color(0xFFF7FAFF).withValues(alpha: 0.14),
                    ],
                    child: PopupMenuButton<_RulesOverflowAction>(
                      enabled: hasRules,
                      tooltip: 'ตัวเลือกเพิ่มเติม',
                      onSelected: (action) {
                        switch (action) {
                          case _RulesOverflowAction.delete:
                            _openDeleteRulePicker(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<_RulesOverflowAction>(
                          value: _RulesOverflowAction.delete,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFCC5A4E),
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'ลบกฎแจ้งเตือน',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      padding: EdgeInsets.zero,
                      menuPadding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 168,
                        maxWidth: 220,
                      ),
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: Color(0xFF607180),
                      ),
                      splashRadius: 19,
                    ),
                  ),
                ],
              );

              if (useStackedHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Flexible(child: actions)],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 10),
                  actions,
                ],
              );
            },
          ),
          if (rules.isEmpty) ...[
            const SizedBox(height: 12),
            _EmptyRulesCard(onCreateRule: onCreateRule),
          ] else if (isExpanded) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                for (var index = 0; index < rules.length; index++) ...[
                  _AlertRuleCard(
                    rule: rules[index],
                    sourceMissing: !availableWidgetIds.contains(
                      rules[index].widgetId,
                    ),
                    onTap: () => onEditRule(rules[index]),
                  ),
                  if (index != rules.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDeleteRulePicker(BuildContext context) async {
    if (rules.length == 1) {
      onDeleteRule(rules.single);
      return;
    }

    final selectedRules = await showModalBottomSheet<List<AlertRuleModel>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 26,
                  borderAlpha: 0.58,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.86),
                    const Color(0xFFF5FBFF).withValues(alpha: 0.56),
                  ],
                  shadows: AppGlassTheme.shadowMd,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: AppGlassTheme.surfaceDecoration(
                            radius: 12,
                            borderAlpha: 0.32,
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.34),
                              const Color(0xFFCC5A4E).withValues(alpha: 0.12),
                            ],
                            shadows: const <BoxShadow>[],
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFCC5A4E),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'ลบกฎแจ้งเตือน',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF20303A),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(
                            sheetContext,
                          ).pop(List<AlertRuleModel>.of(rules)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFCC5A4E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'เลือกทั้งหมด',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final rule = rules[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(
                              sheetContext,
                            ).pop(<AlertRuleModel>[rule]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: AppGlassTheme.surfaceDecoration(
                                radius: 16,
                                borderAlpha: 0.3,
                                colors: <Color>[
                                  Colors.white.withValues(alpha: 0.44),
                                  const Color(
                                    0xFFF7FAFF,
                                  ).withValues(alpha: 0.2),
                                ],
                                shadows: const <BoxShadow>[],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _alertTitleWithDataKey(
                                            title: rule.title,
                                            dataKey: rule.dataKey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF20303A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          rule.widgetTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF667587),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFCC5A4E),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

    if (selectedRules != null && selectedRules.isNotEmpty) {
      onDeleteRules(selectedRules);
    }
  }
}
