part of '../dashboard_item_renderer.dart';

class _ButtonTileShell extends StatelessWidget {
  const _ButtonTileShell({
    required this.item,
    required this.metrics,
    required this.enableInteraction,
    required this.activeColor,
    required this.inactiveColor,
    required this.onItemChanged,
    required this.themePreset,
    required this.showTitle,
    required this.paintTitle,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final bool enableInteraction;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<DashboardItem>? onItemChanged;
  final DashboardThemePreset? themePreset;
  final bool showTitle;
  final bool paintTitle;

  bool get _isMomentaryButton {
    final normalized = item.sendBehavior.trim().toLowerCase();
    return normalized == 'push';
  }

  @override
  Widget build(BuildContext context) {
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );
    final shellBaseColor = _themedButtonShellColor(
      item: item,
      themePreset: themePreset,
    );
    final innerBaseColor = _themedButtonInnerColor(
      item: item,
      themePreset: themePreset,
    );
    final shellBorderColor =
        item.buttonBorderColor ??
        (_usesDarkTheme(themePreset)
            ? _themedDefaultBorderColor(
                accentColor: activeColor,
                themePreset: themePreset,
              ).withValues(alpha: 0.72)
            : null);

    final titleStyle = TextStyle(
      fontSize: titleFontSize,
      fontWeight: _resolvedTitleFontWeight(item),
      letterSpacing: _resolvedTitleLetterSpacing(item),
      color: _resolvedTitleTextColor(item: item, themePreset: themePreset),
      shadows: _resolvedTitleShadows(item: item, themePreset: themePreset),
    );
    final button = SmartActionButton(
      isActive: item.enabled,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      shellBaseColor: shellBaseColor,
      innerBaseColor: innerBaseColor,
      shellBorderColor: shellBorderColor,
      shellBorderWidth: item.buttonBorderWidth,
      glowColor: item.glowColor,
      glowStrength: _resolvedGlowStrength(
        item: item,
        themePreset: themePreset,
        defaultStrength: 0.12,
      ),
      glowBlur: _resolvedGlowBlur(item: item, themePreset: themePreset),
      isMomentary: _isMomentaryButton,
      onTap: onItemChanged == null
          ? () {}
          : () => onItemChanged!(
              item.copyWith(
                enabled: !item.enabled,
                value: item.enabled ? 0.0 : 1.0,
              ),
            ),
      onPressStart: onItemChanged == null
          ? null
          : () => onItemChanged!(item.copyWith(enabled: true, value: 1.0)),
      onPressEnd: onItemChanged == null
          ? null
          : () => onItemChanged!(item.copyWith(enabled: false, value: 0.0)),
      enableInteraction: enableInteraction,
    );

    return _WidgetTitleFrame(
      item: item,
      style: titleStyle,
      showTitle: showTitle,
      paintTitle: paintTitle,
      child: button,
    );
  }
}
