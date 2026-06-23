part of '../dashboard_item_renderer.dart';

class _ValueLabelTileShell extends StatelessWidget {
  const _ValueLabelTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.themePreset,
    required this.showTitle,
    required this.paintTitle,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final DashboardThemePreset? themePreset;
  final bool showTitle;
  final bool paintTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );

    return _WidgetTitleFrame(
      item: item,
      showTitle: showTitle,
      paintTitle: paintTitle,
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: _resolvedTitleFontWeight(item),
        letterSpacing: _resolvedTitleLetterSpacing(item),
        color: _resolvedTitleTextColor(item: item, themePreset: themePreset),
        shadows: _resolvedTitleShadows(item: item, themePreset: themePreset),
      ),
      child: _DashboardTileShell(
        item: item,
        metrics: metrics,
        accentColor: accentColor,
        themePreset: themePreset,
        showTitleInside: false,
        child: child,
      ),
    );
  }
}

class _ValueLabelContent extends StatelessWidget {
  const _ValueLabelContent({
    required this.item,
    required this.metrics,
    required this.themePreset,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final DashboardThemePreset? themePreset;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final displayValue = metrics.formatPrimaryValue(item);
        final isUnbound = _isUnboundValueItem(item);
        final displayLength = displayValue.length;
        final baseValueFont = metrics.isTiny
            ? 12.0
            : metrics.isVeryShort || metrics.isVeryNarrow
            ? 14.0
            : switch (metrics.sizeClass) {
                _TileSizeClass.tiny => 12.0,
                _TileSizeClass.compact => 15.0,
                _TileSizeClass.medium => 18.0,
                _TileSizeClass.large => 22.0,
              };
        final lengthPenalty = displayLength >= 6
            ? 2.5
            : displayLength == 5
            ? 1.5
            : 0.0;
        final heightDriven = constraints.maxHeight * 0.58;
        final widthDriven = constraints.maxWidth * 0.24;
        final targetFont = math.min(heightDriven, widthDriven);
        final adjustedTargetFont = isUnbound
            ? targetFont
            : targetFont - lengthPenalty;
        final minValueFont = math.max(
          14.0,
          isUnbound ? baseValueFont : baseValueFont - lengthPenalty,
        );
        final maxValueFont = isUnbound ? 32.0 : 112.0;
        final valueFont = adjustedTargetFont
            .clamp(minValueFont, maxValueFont)
            .toDouble();

        return SizedBox.expand(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayValue,
                  key: const ValueKey<String>('value_label_display_text'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: valueFont,
                    fontWeight: FontWeight.w800,
                    color: _resolvedValueTextColor(
                      item: item,
                      themePreset: themePreset,
                      isUnbound: isUnbound,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
