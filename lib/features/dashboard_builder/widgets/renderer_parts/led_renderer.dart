part of '../dashboard_item_renderer.dart';

class _LedTileShell extends StatelessWidget {
  const _LedTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.inactiveColor,
    required this.themePreset,
    required this.showTitle,
    required this.paintTitle,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final Color inactiveColor;
  final DashboardThemePreset? themePreset;
  final bool showTitle;
  final bool paintTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final displayColor = _hasBoundDataKey(item)
        ? (item.enabled ? accentColor : inactiveColor)
        : _neutralInactiveAccent;
    return _WidgetTitleFrame(
      item: item,
      showTitle: showTitle,
      paintTitle: paintTitle,
      style: TextStyle(
        fontSize: _resolvedTitleFontSize(
          item: item,
          fallbackSize: 10,
          minSize: 7,
          maxSize: 12,
        ),
        fontWeight: _resolvedTitleFontWeight(item),
        letterSpacing: _resolvedTitleLetterSpacing(item),
        color: _resolvedTitleTextColor(item: item, themePreset: themePreset),
        shadows: _resolvedTitleShadows(item: item, themePreset: themePreset),
      ),
      child: _LedStatusShell(
        item: item,
        metrics: metrics,
        accentColor: displayColor,
        themePreset: themePreset,
        child: child,
      ),
    );
  }
}

class _LedStatusShell extends StatelessWidget {
  const _LedStatusShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.themePreset,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final DashboardThemePreset? themePreset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        _themedDefaultSurfaceColor(item: item, themePreset: themePreset) ??
        DashboardRuntimeTheme.cardColor;
    final borderColor = accentColor.withValues(
      alpha: _hasBoundDataKey(item) ? (item.enabled ? 0.14 : 0.07) : 0.08,
    );
    final shadowColor = accentColor.withValues(
      alpha: _hasBoundDataKey(item) && item.enabled ? 0.05 : 0.015,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: item.enabled ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(metrics.isTiny ? 5 : 7),
        child: child,
      ),
    );
  }
}

class _LedContent extends StatelessWidget {
  const _LedContent({
    required this.item,
    required this.metrics,
    required this.activeColor,
    required this.inactiveColor,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final hasBinding = _hasBoundDataKey(item);
    final stateColor = hasBinding
        ? (item.enabled ? activeColor : inactiveColor)
        : _neutralInactiveAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final compact = constraints.maxHeight < 70 || metrics.isTiny;
        final ledSize = (shortest * (compact ? 0.70 : 0.76))
            .clamp(30.0, 64.0)
            .toDouble();

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const ValueKey<String>('led_indicator_light'),
                width: ledSize,
                height: ledSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stateColor,
                  boxShadow: [
                    BoxShadow(
                      color: stateColor.withValues(
                        alpha: hasBinding && item.enabled ? 0.16 : 0.035,
                      ),
                      blurRadius: hasBinding && item.enabled ? 11 : 4,
                      spreadRadius: hasBinding && item.enabled ? 0.5 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: ledSize * 0.66,
                    height: ledSize * 0.66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: hasBinding && item.enabled ? 0.48 : 0.26,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
            ],
          ),
        );
      },
    );
  }
}
