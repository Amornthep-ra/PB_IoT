part of '../notifications_screen.dart';

class _AlertRuleCard extends StatelessWidget {
  const _AlertRuleCard({
    required this.rule,
    required this.sourceMissing,
    required this.onTap,
  });

  final AlertRuleModel rule;
  final bool sourceMissing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _severityPalette(rule.severity);
    final summary = _ruleSummary(rule);
    final alertMessage = rule.message.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: AppGlassTheme.surfaceDecoration(
                        radius: 16,
                        borderAlpha: 0.44,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.62),
                          palette.color.withValues(alpha: 0.14),
                        ],
                        shadows: AppGlassTheme.shadowSm,
                      ),
                      alignment: Alignment.center,
                      child: Icon(palette.icon, color: palette.color, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _alertTitleWithDataKey(
                          title: rule.title,
                          dataKey: rule.dataKey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20303A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (alertMessage.isNotEmpty) ...[
                        Text(
                          alertMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4E9070),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.45,
                          color: Color(0xFF667587),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: AppGlassTheme.accentDecoration(
                    radius: 999,
                    colors: <Color>[
                      palette.color.withValues(alpha: 0.82),
                      palette.color.withValues(alpha: 0.62),
                    ],
                    borderColor: palette.color.withValues(alpha: 0.72),
                    glowColor: palette.color,
                  ),
                  child: Text(
                    _severityLabel(rule.severity),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                _InfoChip(
                  label: rule.widgetTitle,
                  color: const Color(0xFF4E9070),
                ),
                _InfoChip(
                  label: rule.enabled ? 'Enabled' : 'Disabled',
                  color: rule.enabled
                      ? const Color(0xFF4E9070)
                      : const Color(0xFF97A3AF),
                ),
                if (sourceMissing)
                  const _InfoChip(
                    label: 'Source missing',
                    color: Color(0xFFCC5A4E),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
