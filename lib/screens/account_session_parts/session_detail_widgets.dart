part of '../account_session_screen.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.metrics,
    required this.title,
    required this.children,
  });

  final AppResponsiveMetrics metrics;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(metrics.sectionCardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: metrics.sectionCardPadding,
          decoration: AppGlassTheme.surfaceDecoration(
            radius: metrics.sectionCardRadius,
            borderAlpha: 0.5,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.76),
              const Color(0xFFF5FBFF).withValues(alpha: 0.38),
            ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 999,
                  borderAlpha: 0.3,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.46),
                    const Color(0xFFEAF3FF).withValues(alpha: 0.2),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _AccountSessionScreenState._labelTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF6B7280),
    this.valueMonospace = false,
    this.trailing,
  });

  final AppResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool valueMonospace;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: metrics.infoRowVerticalPadding + 2,
      ),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 18,
        borderAlpha: 0.28,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.42),
          const Color(0xFFF3F9FF).withValues(alpha: 0.22),
        ],
        shadows: const <BoxShadow>[],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(metrics.iconTileRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: metrics.iconTileSize,
                height: metrics.iconTileSize,
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: metrics.iconTileRadius,
                  borderAlpha: 0.32,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.54),
                    const Color(0xFFEAF3FF).withValues(alpha: 0.18),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AccountSessionScreenState._mutedTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: valueColor,
                    fontFeatures: valueMonospace
                        ? const <FontFeature>[FontFeature.tabularFigures()]
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _TokenActions extends StatelessWidget {
  const _TokenActions({
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onCopy,
  });

  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TokenIconButton(
          icon: isVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          tooltip: isVisible ? 'ซ่อนโทเค็น' : 'แสดงโทเค็น',
          onPressed: onToggleVisibility,
        ),
        const SizedBox(width: 2),
        _TokenIconButton(
          icon: Icons.copy_rounded,
          tooltip: 'คัดลอกโทเค็น',
          onPressed: onCopy,
        ),
      ],
    );
  }
}

class _TokenIconButton extends StatelessWidget {
  const _TokenIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      icon: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AppResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: metrics.menuRowVerticalPadding + 2,
        ),
        decoration: AppGlassTheme.surfaceDecoration(
          radius: 18,
          borderAlpha: 0.28,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.42),
            const Color(0xFFF3F9FF).withValues(alpha: 0.22),
          ],
          shadows: const <BoxShadow>[],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(metrics.iconTileRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: metrics.iconTileSize,
                  height: metrics.iconTileSize,
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: metrics.iconTileRadius,
                    borderAlpha: 0.32,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.54),
                      const Color(0xFFEAF3FF).withValues(alpha: 0.18),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AccountSessionScreenState._labelTextColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF718093),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.42),
      ),
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({
    required this.height,
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final double height;
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: AppGlassTheme.accentDecoration(
            radius: 16,
            colors: <Color>[
              _AccountSessionScreenState._dangerStartColor.withValues(
                alpha: disabled ? 0.76 : 0.96,
              ),
              _AccountSessionScreenState._dangerEndColor.withValues(
                alpha: disabled ? 0.76 : 0.92,
              ),
            ],
            borderColor: Colors.white.withValues(alpha: 0.34),
            glowColor: _AccountSessionScreenState._dangerGlowColor.withValues(
              alpha: disabled ? 0.08 : 0.2,
            ),
          ),
          child: SizedBox(
            height: height,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          label,
                          key: const ValueKey('label'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
