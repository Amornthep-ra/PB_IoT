part of '../notifications_screen.dart';

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    super.key,
    required this.child,
    this.borderAlpha = 0.5,
    this.colors,
  });

  final Widget child;
  final double borderAlpha;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: borderAlpha,
            colors:
                colors ??
                <Color>[
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 999,
            borderAlpha: 0.18,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.30),
              color.withValues(alpha: 0.06),
            ],
            shadows: const <BoxShadow>[],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventSeverityChip extends StatelessWidget {
  const _EventSeverityChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppGlassTheme.accentDecoration(
        radius: 999,
        colors: <Color>[
          color.withValues(alpha: 0.82),
          color.withValues(alpha: 0.62),
        ],
        borderColor: color.withValues(alpha: 0.72),
        glowColor: color,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CompactInfoChip extends StatelessWidget {
  const _CompactInfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 999,
            borderAlpha: 0.18,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.30),
              color.withValues(alpha: 0.06),
            ],
            shadows: const <BoxShadow>[],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 999,
            borderAlpha: 0.20,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.34),
              color.withValues(alpha: 0.08),
            ],
            shadows: const <BoxShadow>[],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityPalette {
  const _SeverityPalette({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

_SeverityPalette _severityPalette(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return const _SeverityPalette(
        icon: Icons.info_outline_rounded,
        color: Color(0xFF4C8BC8),
      );
    case AlertRuleSeverity.warning:
      return const _SeverityPalette(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFE28A3B),
      );
    case AlertRuleSeverity.critical:
      return const _SeverityPalette(
        icon: Icons.error_outline_rounded,
        color: Color(0xFFCC5A4E),
      );
  }
}

String _severityLabel(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return 'Info';
    case AlertRuleSeverity.warning:
      return 'Warning';
    case AlertRuleSeverity.critical:
      return 'Critical';
  }
}

String _conditionLabel(AlertRuleCondition condition) {
  switch (condition) {
    case AlertRuleCondition.lessThan:
      return 'less than';
    case AlertRuleCondition.lessThanOrEqual:
      return 'less than or equal to';
    case AlertRuleCondition.greaterThan:
      return 'greater than';
    case AlertRuleCondition.greaterThanOrEqual:
      return 'greater than or equal to';
    case AlertRuleCondition.equalTo:
      return 'equal to';
    case AlertRuleCondition.notEqualTo:
      return 'not equal to';
    case AlertRuleCondition.isOn:
      return 'is ON';
    case AlertRuleCondition.isOff:
      return 'is OFF';
    case AlertRuleCondition.becameOn:
      return 'changes to ON';
    case AlertRuleCondition.becameOff:
      return 'changes to OFF';
  }
}

String _alertTitleWithDataKey({
  required String title,
  required String? dataKey,
}) {
  final normalizedTitle = title.trim();
  final normalizedDataKey = dataKey?.trim() ?? '';
  if (normalizedDataKey.isEmpty) {
    return normalizedTitle;
  }
  if (normalizedTitle.toLowerCase().contains(
    '(${normalizedDataKey.toLowerCase()})',
  )) {
    return normalizedTitle;
  }
  return '$normalizedTitle ($normalizedDataKey)';
}

String _ruleSummary(AlertRuleModel rule) {
  final buffer = StringBuffer(rule.widgetTitle);
  buffer.write(' ');
  buffer.write(_conditionLabel(rule.condition));
  if (rule.thresholdValue != null) {
    final threshold = rule.thresholdValue!;
    buffer.write(' ');
    buffer.write(
      threshold.truncateToDouble() == threshold
          ? threshold.toInt().toString()
          : threshold.toString(),
    );
  }
  return buffer.toString();
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(local.year, local.month, local.day);
  final difference = today.difference(eventDay).inDays;

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  if (difference <= 0) {
    return 'Today $hour:$minute';
  }
  if (difference == 1) {
    return 'Yesterday $hour:$minute';
  }

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/$hour:$minute';
}
