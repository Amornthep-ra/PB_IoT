part of '../notifications_screen.dart';

class _AlertEventCard extends StatelessWidget {
  const _AlertEventCard({
    required this.event,
    required this.ruleDataKey,
    required this.onTap,
    this.onDelete,
  });

  final AlertEventModel event;
  final String? ruleDataKey;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = _severityPalette(event.severity);
    final displayTitle = _alertTitleWithDataKey(
      title: event.ruleTitle,
      dataKey: _eventDataKey(event, fallback: ruleDataKey),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _GlassCard(
        borderAlpha: event.isRead ? 0.5 : 0.66,
        colors: event.isRead
            ? null
            : <Color>[
                const Color(0xFFFFF7F5).withValues(alpha: 0.9),
                const Color(0xFFFFDAD4).withValues(alpha: 0.46),
              ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _formatTimestamp(event.createdAt),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A8794),
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: AppGlassTheme.surfaceDecoration(
                          radius: 12,
                          borderAlpha: 0.26,
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.28),
                            const Color(0xFFF7FAFF).withValues(alpha: 0.16),
                          ],
                          shadows: const <BoxShadow>[],
                        ),
                        child: IconButton(
                          onPressed: onDelete,
                          tooltip: 'ลบ',
                          constraints: const BoxConstraints.tightFor(
                            width: 30,
                            height: 30,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          splashRadius: 15,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFCC5A4E),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
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
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: event.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: const Color(0xFF20303A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.35,
                          color: Color(0xFF667587),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _EventSeverityChip(
                  label: _severityLabel(event.severity),
                  color: palette.color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: _CompactInfoChip(
                    label: event.widgetTitle,
                    color: const Color(0xFF4E9070),
                  ),
                ),
                if (!event.isRead) ...[
                  const SizedBox(width: 6),
                  const _CompactInfoChip(
                    label: 'New',
                    color: Color(0xFFE28A3B),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: event.isRead
                        ? AppGlassTheme.surfaceDecoration(
                            radius: 999,
                            borderAlpha: 0.24,
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.3),
                              const Color(0xFFF7FAFF).withValues(alpha: 0.18),
                            ],
                            shadows: const <BoxShadow>[],
                          )
                        : AppGlassTheme.accentDecoration(
                            radius: 999,
                            colors: const <Color>[
                              Color(0xFFE7867A),
                              Color(0xFFCC5A4E),
                            ],
                            borderColor: const Color(0xFFD46C60),
                            glowColor: const Color(0xFFCC5A4E),
                          ),
                    child: Text(
                      event.isRead ? 'อ่านแล้ว' : 'ยังไม่อ่าน',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: event.isRead
                            ? const Color(0xFF5F6E7D)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: AppGlassTheme.surfaceDecoration(
                      radius: 999,
                      borderAlpha: 0.2,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.28),
                        const Color(0xFFF7FAFF).withValues(alpha: 0.12),
                      ],
                      shadows: const <BoxShadow>[],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF7A8794),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
