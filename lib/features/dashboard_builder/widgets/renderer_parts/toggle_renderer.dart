part of '../dashboard_item_renderer.dart';

class _ToggleVisualSpec {
  const _ToggleVisualSpec._();

  static const double shellTrackGap = 10.0;
}

class _ToggleTileShell extends StatelessWidget {
  const _ToggleTileShell({
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

class _ToggleContent extends StatelessWidget {
  const _ToggleContent({
    required this.item,
    required this.metrics,
    required this.themePreset,
    required this.enableInteraction,
    this.onChanged,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final DashboardThemePreset? themePreset;
  final bool enableInteraction;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final offColor = _resolvedOffAccent(item.secondaryAccentColor);
    final onColor = item.accentColor;
    final glowColor = item.enabled ? (item.glowColor ?? onColor) : offColor;
    final glowStrength = _resolvedGlowStrength(
      item: item,
      themePreset: themePreset,
      defaultStrength: 0.12,
    );
    final glowBlur = _resolvedGlowBlur(item: item, themePreset: themePreset);
    final effectiveGlowStrength = item.enabled
        ? glowStrength
        : math.min(glowStrength * 0.18, 0.025);
    final hasGlow = effectiveGlowStrength > 0 && glowBlur > 0;
    final trackGlowAlpha = (effectiveGlowStrength * 0.78)
        .clamp(0.0, 0.30)
        .toDouble();
    final knobGlowAlpha = (effectiveGlowStrength * 0.92)
        .clamp(0.0, 0.34)
        .toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellGap = _ToggleVisualSpec.shellTrackGap;
        final trackWidth = math.max(0.0, constraints.maxWidth - (shellGap * 2));
        final trackHeight = math.max(
          0.0,
          constraints.maxHeight - (shellGap * 2),
        );
        final knobSize = math.min(
          math.max(0.0, trackHeight - 6),
          math.max(0.0, trackWidth * 0.42),
        );
        final knobStartColor = item.enabled
            ? Color.lerp(onColor, Colors.white, 0.25)!
            : Color.lerp(offColor, Colors.white, 0.84)!;
        final knobEndColor = item.enabled
            ? Color.lerp(onColor, Colors.black, 0.08)!
            : Color.lerp(offColor, Colors.white, 0.56)!;
        return Center(
          child: GestureDetector(
            onTap: enableInteraction && onChanged != null
                ? () => onChanged!(!item.enabled)
                : null,
            child: SizedBox(
              width: trackWidth,
              height: trackHeight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.enabled
                        ? [
                            Color.lerp(onColor, Colors.white, 0.60)!,
                            onColor.withValues(alpha: 0.72),
                          ]
                        : [
                            Color.lerp(offColor, Colors.white, 0.90)!,
                            Color.lerp(offColor, Colors.white, 0.74)!,
                          ],
                  ),
                  border: Border.all(
                    color: item.enabled
                        ? onColor.withValues(alpha: 0.62)
                        : offColor.withValues(alpha: 0.44),
                  ),
                  boxShadow: [
                    if (hasGlow)
                      BoxShadow(
                        color: glowColor.withValues(alpha: trackGlowAlpha),
                        blurRadius: math.max(12.0, glowBlur * 0.70),
                        spreadRadius: 0.2,
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        alignment: item.enabled
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: knobSize,
                          height: knobSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [knobStartColor, knobEndColor],
                            ),
                            boxShadow: [
                              if (hasGlow)
                                BoxShadow(
                                  color: glowColor.withValues(
                                    alpha: knobGlowAlpha,
                                  ),
                                  blurRadius: math.max(6.0, glowBlur * 0.34),
                                  spreadRadius: 0.1,
                                ),
                              const BoxShadow(
                                color: DashboardRuntimeTheme.shadowLightColor,
                                blurRadius: 4,
                                offset: Offset(-1, -1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                        ),
                      ),
                    ],
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
