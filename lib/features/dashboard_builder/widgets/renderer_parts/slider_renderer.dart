part of '../dashboard_item_renderer.dart';

class _SliderTileShell extends StatelessWidget {
  const _SliderTileShell({
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
