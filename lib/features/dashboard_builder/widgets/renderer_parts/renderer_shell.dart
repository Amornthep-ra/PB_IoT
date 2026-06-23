part of '../dashboard_item_renderer.dart';

class _DashboardTileShell extends StatelessWidget {
  const _DashboardTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.themePreset,
    this.showTitleInside = true,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final DashboardThemePreset? themePreset;
  final bool showTitleInside;
  final Widget child;

  static const double _defaultValueLabelBorderWidth = 1.2;
  static const double _defaultGaugeBorderWidth = 1.0;
  static const double _defaultSliderBorderWidth = 1.0;
  static const double _defaultToggleBorderWidth = 1.0;

  double get _padding {
    if (item.type == DashboardItemType.gauge) {
      return 0;
    }

    if (item.type == DashboardItemType.toggle) {
      return 0;
    }

    if (item.type == DashboardItemType.led) {
      return metrics.isTiny ? 5 : 8;
    }

    if (item.type == DashboardItemType.slider) {
      if (metrics.isTiny) {
        return 3;
      }
      if (metrics.isVeryShort || metrics.isVeryNarrow) {
        return 4;
      }
      switch (metrics.sizeClass) {
        case _TileSizeClass.tiny:
          return 3;
        case _TileSizeClass.compact:
          return 4;
        case _TileSizeClass.medium:
          return 5;
        case _TileSizeClass.large:
          return 6;
      }
    }

    if (item.type == DashboardItemType.stepH ||
        item.type == DashboardItemType.stepV) {
      if (metrics.isTiny) {
        return 3;
      }
      if (metrics.isVeryShort || metrics.isVeryNarrow) {
        return 4;
      }
      return metrics.sizeClass == _TileSizeClass.large ? 7 : 5;
    }

    if (metrics.isTiny) {
      return 5;
    }
    if (metrics.isVeryShort || metrics.isVeryNarrow) {
      return 6;
    }
    switch (metrics.sizeClass) {
      case _TileSizeClass.tiny:
        return 5;
      case _TileSizeClass.compact:
        return 8;
      case _TileSizeClass.medium:
        return 10;
      case _TileSizeClass.large:
        return 14;
    }
  }

  double get _titleFontSize {
    return 10;
  }

  double get _titleSpacing {
    if (item.type == DashboardItemType.slider) {
      if (metrics.isVeryShort) {
        return 1;
      }
      if (metrics.isShort) {
        return 2;
      }
    }

    if (item.type == DashboardItemType.stepH ||
        item.type == DashboardItemType.stepV) {
      return metrics.isShort ? 2 : 4;
    }

    if (metrics.isTiny) {
      return 2;
    }
    if (metrics.isVeryShort) {
      return 2;
    }
    if (metrics.isShort) {
      return 4;
    }
    switch (metrics.sizeClass) {
      case _TileSizeClass.tiny:
        return 2;
      case _TileSizeClass.compact:
        return 4;
      case _TileSizeClass.medium:
        return 5;
      case _TileSizeClass.large:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTitleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: _titleFontSize,
      minSize: 8,
      maxSize: 18,
    );
    final isStepper =
        item.type == DashboardItemType.stepH ||
        item.type == DashboardItemType.stepV;
    final customSurfaceColor = item.type == DashboardItemType.valueLabel
        ? _themedDefaultSurfaceColor(item: item, themePreset: themePreset)
        : item.type == DashboardItemType.gauge
        ? _themedDefaultSurfaceColor(item: item, themePreset: themePreset)
        : item.type == DashboardItemType.slider
        ? _themedDefaultSurfaceColor(item: item, themePreset: themePreset)
        : isStepper
        ? _themedDefaultSurfaceColor(item: item, themePreset: themePreset)
        : item.type == DashboardItemType.toggle
        ? _themedDefaultSurfaceColor(item: item, themePreset: themePreset)
        : item.type == DashboardItemType.trend
        ? _themedDefaultSurfaceColor(item: item, themePreset: themePreset)
        : item.type == DashboardItemType.led
        ? _themedDefaultSurfaceColor(item: item, themePreset: themePreset)
        : null;
    final defaultBorderColor = _themedDefaultBorderColor(
      accentColor: accentColor,
      themePreset: themePreset,
    );
    final valueLabelBorderBaseColor =
        item.buttonShellColor ?? defaultBorderColor;
    final gaugeBorderBaseColor =
        item.buttonShellColor ?? _shellBorderColor(defaultBorderColor);
    final toggleBorderBaseColor =
        item.buttonShellColor ?? _shellBorderColor(defaultBorderColor);
    final valueLabelBorderWidth =
        (item.valueLabelBorderWidth ?? _defaultValueLabelBorderWidth).clamp(
          0.0,
          4.0,
        );
    final gaugeBorderWidth = (item.gaugeBorderWidth ?? _defaultGaugeBorderWidth)
        .clamp(0.0, 4.0);
    final sliderBorderWidth =
        (item.sliderBorderWidth ?? _defaultSliderBorderWidth).clamp(0.0, 4.0);
    final toggleBorderWidth =
        (item.toggleBorderWidth ?? _defaultToggleBorderWidth).clamp(0.0, 4.0);
    final borderColor = item.type == DashboardItemType.slider || isStepper
        ? (item.buttonShellColor ?? defaultBorderColor.withValues(alpha: 0.34))
        : item.type == DashboardItemType.valueLabel
        ? valueLabelBorderBaseColor.withValues(alpha: 0.42)
        : item.type == DashboardItemType.gauge
        ? gaugeBorderBaseColor
        : item.type == DashboardItemType.toggle
        ? toggleBorderBaseColor
        : item.type == DashboardItemType.trend
        ? (item.buttonShellColor ?? defaultBorderColor.withValues(alpha: 0.34))
        : item.type == DashboardItemType.led
        ? toggleBorderBaseColor.withValues(alpha: item.enabled ? 0.58 : 0.32)
        : customSurfaceColor != null
        ? _shellBorderColor(
            Color.lerp(customSurfaceColor, defaultBorderColor, 0.35) ??
                defaultBorderColor,
          )
        : _shellBorderColor(defaultBorderColor);
    final defaultGlowStrength = item.type == DashboardItemType.valueLabel
        ? 0.0
        : item.type == DashboardItemType.trend
        ? 0.08
        : item.type == DashboardItemType.led && !item.enabled
        ? 0.04
        : item.type == DashboardItemType.slider || isStepper
        ? 0.08
        : item.type == DashboardItemType.toggle && !item.enabled
        ? 0.03
        : 0.12;
    final glowColor = item.glowColor ?? accentColor;
    final glowStrength = _resolvedGlowStrength(
      item: item,
      themePreset: themePreset,
      defaultStrength: defaultGlowStrength,
    );
    final glowBlur = _resolvedGlowBlur(item: item, themePreset: themePreset);
    final baseShadows = _defaultTileShadows(
      type: item.type,
      themePreset: themePreset,
    );
    final shellRadius = item.type == DashboardItemType.toggle ? 999.0 : 24.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            item.type == DashboardItemType.valueLabel ||
                item.type == DashboardItemType.toggle ||
                item.type == DashboardItemType.led
            ? customSurfaceColor
            : null,
        gradient:
            item.type == DashboardItemType.valueLabel ||
                item.type == DashboardItemType.toggle ||
                item.type == DashboardItemType.led
            ? null
            : (item.type == DashboardItemType.slider || isStepper) &&
                  customSurfaceColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _surfaceGradientColors(customSurfaceColor, themePreset),
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _surfaceGradientColors(customSurfaceColor, themePreset),
              ),
        borderRadius: BorderRadius.circular(shellRadius),
        border: Border.all(
          color: borderColor,
          width: item.type == DashboardItemType.valueLabel
              ? valueLabelBorderWidth
              : item.type == DashboardItemType.gauge
              ? gaugeBorderWidth
              : item.type == DashboardItemType.slider
              ? sliderBorderWidth
              : isStepper
              ? sliderBorderWidth
              : item.type == DashboardItemType.toggle
              ? toggleBorderWidth
              : item.type == DashboardItemType.trend
              ? sliderBorderWidth
              : item.type == DashboardItemType.led
              ? toggleBorderWidth
              : 1.0,
        ),
        boxShadow: [
          ...baseShadows,
          if (glowStrength > 0 && glowBlur > 0)
            BoxShadow(
              color: glowColor.withValues(alpha: glowStrength),
              blurRadius: glowBlur,
              spreadRadius: -2,
            ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitleInside &&
                metrics.showTitle &&
                _shouldRenderVisibleTitle(item)) ...[
              SizedBox(
                width: double.infinity,
                child: Text(
                  item.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: resolvedTitleFontSize,
                    fontWeight: _resolvedTitleFontWeight(item),
                    color: _resolvedTitleTextColor(
                      item: item,
                      themePreset: themePreset,
                    ),
                    shadows: _resolvedTitleShadows(
                      item: item,
                      themePreset: themePreset,
                    ),
                  ),
                ),
              ),
              SizedBox(height: _titleSpacing),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

enum _ResolvedTitlePosition { topOutside, bottomOutside, hidden }

class _WidgetTitleFrame extends StatelessWidget {
  const _WidgetTitleFrame({
    required this.item,
    required this.style,
    required this.showTitle,
    required this.paintTitle,
    required this.child,
  });

  final DashboardItem item;
  final TextStyle style;
  final bool showTitle;
  final bool paintTitle;
  final Widget child;

  _ResolvedTitlePosition _resolvePosition(String raw) {
    final normalized = raw.trim().toLowerCase();

    if (normalized == DashboardItemTitlePosition.hidden) {
      return _ResolvedTitlePosition.hidden;
    }

    if (normalized == DashboardItemTitlePosition.bottomOutside) {
      return _ResolvedTitlePosition.bottomOutside;
    }

    return _ResolvedTitlePosition.topOutside;
  }

  @override
  Widget build(BuildContext context) {
    final position = _resolvePosition(item.titlePosition);
    if (!showTitle ||
        !_shouldRenderVisibleTitle(item) ||
        position == _ResolvedTitlePosition.hidden) {
      return child;
    }

    final titleHeight = _FloatingWidgetTitle.heightFor(style);
    final title = IgnorePointer(
      child: SizedBox(
        height: titleHeight,
        child: paintTitle
            ? _FloatingWidgetTitle(text: item.title.toUpperCase(), style: style)
            : null,
      ),
    );

    switch (position) {
      case _ResolvedTitlePosition.topOutside:
        return Column(
          children: [
            title,
            Expanded(child: child),
          ],
        );
      case _ResolvedTitlePosition.bottomOutside:
        return Column(
          children: [
            Expanded(child: child),
            title,
          ],
        );
      case _ResolvedTitlePosition.hidden:
        return child;
    }
  }
}

class _FloatingWidgetTitle extends StatelessWidget {
  const _FloatingWidgetTitle({required this.text, required this.style});

  final String text;
  final TextStyle style;

  static double heightFor(TextStyle style) {
    return ((style.fontSize ?? 10.0) * 1.4).clamp(12.0, 24.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 200.0;
        return Center(
          child: SizedBox(
            width: width,
            height: heightFor(style),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }
}
