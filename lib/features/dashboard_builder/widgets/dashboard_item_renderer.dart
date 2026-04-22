import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import 'smart_action_button.dart';
import 'smart_slider_widget.dart';
import 'widget_shell_layout.dart';

enum _TileSizeClass { tiny, compact, medium, large }

class _TileMetrics {
  const _TileMetrics(this.item);

  final DashboardItem item;

  int get w => item.rect.w;
  int get h => item.rect.h;
  int get area => w * h;

  _TileSizeClass get sizeClass {
    if (area <= 40 || h <= 4 || w <= 8) {
      return _TileSizeClass.tiny;
    }
    if (area >= 150 || h >= 10 || w >= 20) {
      return _TileSizeClass.large;
    }
    if (area >= 72 || h >= 7 || w >= 14) {
      return _TileSizeClass.medium;
    }
    return _TileSizeClass.compact;
  }

  bool get isShort => h <= 5;
  bool get isVeryShort => h <= 4;
  bool get isNarrow => w <= 10;
  bool get isVeryNarrow => w <= 7;
  bool get isWide => w >= 18;
  bool get isTiny => sizeClass == _TileSizeClass.tiny;
  bool get showTitle => !isTiny;

  bool _hasBoundDataKey(DashboardItem item) {
    final key = item.dataKey?.trim();
    return key != null && key.isNotEmpty;
  }

  String formatPrimaryValue(DashboardItem item) {
    if (!_hasBoundDataKey(item) &&
        (item.type == DashboardItemType.slider ||
            item.type == DashboardItemType.gauge ||
            item.type == DashboardItemType.valueLabel)) {
      return '0';
    }

    final hasWholeNumberValue = item.value % 1 == 0;
    final valueText = hasWholeNumberValue
        ? item.value.toStringAsFixed(0)
        : item.value.toStringAsFixed(1);
    final unitText = item.unit?.trim() ?? '';

    if (unitText.isEmpty) {
      return valueText;
    }

    final combinedLength = valueText.length + unitText.length;
    final shouldHideUnit =
        (isTiny && isVeryNarrow && combinedLength >= 4) ||
        (isTiny && valueText.length >= 4) ||
        (isNarrow && valueText.length >= 5);

    if (shouldHideUnit) {
      return valueText;
    }

    return '$valueText$unitText';
  }
}

Color _emphasizedTextColor(Color baseColor) {
  return Color.lerp(baseColor, DashboardRuntimeTheme.headlineColor, 0.22) ??
      baseColor;
}

Color _titleTextColor(Color baseColor) {
  return Color.lerp(baseColor, DashboardRuntimeTheme.labelTextColor, 0.30) ??
      baseColor;
}

List<Shadow> _titleShadows(Color baseColor) {
  return [
    Shadow(
      color: Colors.white.withValues(alpha: 0.7),
      blurRadius: 8,
    ),
  ];
}

Color _shellBorderColor(Color baseColor) {
  return baseColor.withValues(alpha: 0.58);
}

List<Color> _surfaceGradientColors(Color? customSurfaceColor) {
  if (customSurfaceColor == null) {
    return const <Color>[
      DashboardRuntimeTheme.cardHighlightColor,
      DashboardRuntimeTheme.cardColor,
    ];
  }

  return <Color>[
    Color.lerp(customSurfaceColor, Colors.white, 0.18) ?? customSurfaceColor,
    Color.lerp(customSurfaceColor, Colors.black, 0.08) ?? customSurfaceColor,
  ];
}

double _snapToStep({
  required double value,
  required double min,
  required double max,
  required double step,
}) {
  if (step <= 0 || max <= min) {
    return value.clamp(min, max);
  }
  final clamped = value.clamp(min, max);
  final units = ((clamped - min) / step).round();
  final snapped = min + (units * step);
  return snapped.clamp(min, max);
}

bool _canWriteBinding(DashboardItem item) {
  return item.bindingMode == 'write' || item.bindingMode == 'read_write';
}

const Color _defaultWidgetTitleColor = DashboardRuntimeTheme.headlineColor;

class _ToggleVisualSpec {
  const _ToggleVisualSpec._();

  static const double shellTrackGap = 10.0;
}

double _resolvedTitleFontSize({
  required DashboardItem item,
  required double fallbackSize,
  required double minSize,
  required double maxSize,
}) {
  return (item.titleFontSize ?? fallbackSize).clamp(minSize, maxSize);
}

class DashboardItemRenderer extends StatelessWidget {
  const DashboardItemRenderer({
    super.key,
    required this.item,
    this.enableInteraction = true,
    this.onItemChanged,
  });

  final DashboardItem item;
  final bool enableInteraction;
  final ValueChanged<DashboardItem>? onItemChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = item.accentColor;
    final inactiveColor = item.secondaryAccentColor ?? const Color(0xFFCDBD9A);
    final currentColor = item.type == DashboardItemType.button && !item.enabled
        ? inactiveColor
        : activeColor;
    final canWrite = _canWriteBinding(item);
    final metrics = _TileMetrics(item);

    switch (item.type) {
      case DashboardItemType.button:
        return _ButtonTileShell(
          item: item,
          metrics: metrics,
          enableInteraction: enableInteraction && canWrite,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onItemChanged: onItemChanged,
        );
      case DashboardItemType.slider:
        return _SliderTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          child: SmartSliderControl(
            item: item,
            showValue: !metrics.isVeryNarrow,
            enableInteraction: enableInteraction && canWrite,
            emitOnDrag: item.sendBehavior == 'on_drag',
            onValueChanged: onItemChanged == null
                ? null
                : (value) => onItemChanged!(
                      item.copyWith(
                        value: _snapToStep(
                          value: value,
                          min: item.minValue,
                          max: item.maxValue,
                          step: item.stepValue,
                        ),
                      ),
                    ),
          ),
        );
      case DashboardItemType.gauge:
        return _GaugeTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          child: _GaugeContent(item: item, metrics: metrics),
        );
      case DashboardItemType.toggle:
        return _ToggleTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          child: _ToggleContent(
            item: item,
            metrics: metrics,
            enableInteraction: enableInteraction && canWrite,
            onChanged: onItemChanged == null
                ? null
                : (enabled) => onItemChanged!(
                      item.copyWith(
                        enabled: enabled,
                        value: enabled ? 1.0 : 0.0,
                      ),
                    ),
          ),
        );
      case DashboardItemType.valueLabel:
        return _ValueLabelTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          child: _ValueLabelContent(item: item, metrics: metrics),
        );
    }
  }
}

class _ButtonTileShell extends StatelessWidget {
  const _ButtonTileShell({
    required this.item,
    required this.metrics,
    required this.enableInteraction,
    required this.activeColor,
    required this.inactiveColor,
    required this.onItemChanged,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final bool enableInteraction;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<DashboardItem>? onItemChanged;

  bool get _isMomentaryButton {
    final normalized = item.sendBehavior.trim().toLowerCase();
    return normalized == 'push';
  }

  @override
  Widget build(BuildContext context) {
    final titleColor =
        item.titleColor ?? _defaultWidgetTitleColor;
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final layout = buildButtonShellLayout(width: width, height: height);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: SmartActionButton(
                isActive: item.enabled,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                shellBaseColor: item.buttonShellColor,
                innerBaseColor: item.buttonInnerColor,
                shellBorderColor: item.buttonBorderColor,
                shellBorderWidth: item.buttonBorderWidth,
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
                    : () => onItemChanged!(
                          item.copyWith(
                            enabled: true,
                            value: 1.0,
                          ),
                        ),
                onPressEnd: onItemChanged == null
                    ? null
                    : () => onItemChanged!(
                          item.copyWith(
                            enabled: false,
                            value: 0.0,
                          ),
                        ),
                enableInteraction: enableInteraction,
              ),
            ),
            _WidgetTitleOverlay(
              item: item,
              layout: layout,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _titleTextColor(titleColor),
                shadows: _titleShadows(titleColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SliderTileShell extends StatelessWidget {
  const _SliderTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.titleColor ?? _defaultWidgetTitleColor;
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = buildSliderShellLayout(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
          shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: layout.shellTopInset,
              bottom: layout.shellBottomInset,
              child: _DashboardTileShell(
                item: item,
                metrics: metrics,
                accentColor: accentColor,
                showTitleInside: false,
                child: child,
              ),
            ),
            _WidgetTitleOverlay(
              item: item,
              layout: layout,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _titleTextColor(titleColor),
                shadows: _titleShadows(titleColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugeTileShell extends StatelessWidget {
  const _GaugeTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.titleColor ?? _defaultWidgetTitleColor;
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = buildButtonShellLayout(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _DashboardTileShell(
                item: item,
                metrics: metrics,
                accentColor: accentColor,
                showTitleInside: false,
                child: child,
              ),
            ),
            _WidgetTitleOverlay(
              item: item,
              layout: layout,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _titleTextColor(titleColor),
                shadows: _titleShadows(titleColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ToggleTileShell extends StatelessWidget {
  const _ToggleTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.titleColor ?? _defaultWidgetTitleColor;
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = buildButtonShellLayout(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _DashboardTileShell(
                item: item,
                metrics: metrics,
                accentColor: accentColor,
                showTitleInside: false,
                child: child,
              ),
            ),
            _WidgetTitleOverlay(
              item: item,
              layout: layout,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _titleTextColor(titleColor),
                shadows: _titleShadows(titleColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ValueLabelTileShell extends StatelessWidget {
  const _ValueLabelTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.titleColor ?? _defaultWidgetTitleColor;
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );
    final valueLabelBackgroundColor =
        item.buttonInnerColor ?? DashboardRuntimeTheme.cardColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = buildButtonShellLayout(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _DashboardTileShell(
                item: item,
                metrics: metrics,
                accentColor: accentColor,
                showTitleInside: false,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: valueLabelBackgroundColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: child,
                ),
              ),
            ),
            _WidgetTitleOverlay(
              item: item,
              layout: layout,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _titleTextColor(titleColor),
                shadows: _titleShadows(titleColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardTileShell extends StatelessWidget {
  const _DashboardTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    this.showTitleInside = true,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
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
    final customSurfaceColor = item.type == DashboardItemType.valueLabel
        ? (item.buttonInnerColor ?? DashboardRuntimeTheme.cardColor)
        : item.type == DashboardItemType.gauge
        ? (item.buttonInnerColor ?? DashboardRuntimeTheme.cardColor)
        : item.type == DashboardItemType.slider
        ? (item.buttonInnerColor ?? DashboardRuntimeTheme.cardColor)
        : item.type == DashboardItemType.toggle
        ? (item.buttonInnerColor ?? DashboardRuntimeTheme.cardColor)
        : null;
    final valueLabelBorderBaseColor =
        item.buttonShellColor ?? accentColor;
    final gaugeBorderBaseColor =
        item.buttonShellColor ?? _shellBorderColor(accentColor);
    final toggleBorderBaseColor =
        item.buttonShellColor ?? _shellBorderColor(accentColor);
    final valueLabelBorderWidth =
        (item.valueLabelBorderWidth ?? _defaultValueLabelBorderWidth)
            .clamp(0.0, 4.0);
    final gaugeBorderWidth = (item.gaugeBorderWidth ?? _defaultGaugeBorderWidth)
        .clamp(0.0, 4.0);
    final sliderBorderWidth =
        (item.sliderBorderWidth ?? _defaultSliderBorderWidth).clamp(0.0, 4.0);
    final toggleBorderWidth =
        (item.toggleBorderWidth ?? _defaultToggleBorderWidth).clamp(0.0, 4.0);
    final borderColor = item.type == DashboardItemType.slider
        ? (item.buttonShellColor ?? accentColor.withValues(alpha: 0.34))
        : item.type == DashboardItemType.valueLabel
        ? valueLabelBorderBaseColor.withValues(alpha: 0.42)
        : item.type == DashboardItemType.gauge
        ? gaugeBorderBaseColor
        : item.type == DashboardItemType.toggle
        ? toggleBorderBaseColor
        : customSurfaceColor != null
        ? _shellBorderColor(
            Color.lerp(customSurfaceColor, accentColor, 0.35) ?? accentColor,
          )
        : _shellBorderColor(accentColor);
    final accentShadowAlpha = item.type == DashboardItemType.slider ? 0.08 : 0.12;
    final shellRadius = item.type == DashboardItemType.toggle ? 999.0 : 24.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.type == DashboardItemType.valueLabel || item.type == DashboardItemType.toggle
            ? customSurfaceColor
            : null,
        gradient: item.type == DashboardItemType.valueLabel || item.type == DashboardItemType.toggle
            ? null
            : item.type == DashboardItemType.slider && customSurfaceColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _surfaceGradientColors(customSurfaceColor),
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _surfaceGradientColors(customSurfaceColor),
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
              : item.type == DashboardItemType.toggle
              ? toggleBorderWidth
              : 1.0,
        ),
        boxShadow: item.type == DashboardItemType.valueLabel
            ? const []
            : [
                BoxShadow(
                  color: DashboardRuntimeTheme.shadowLightColor,
                  blurRadius: 12,
                  offset: const Offset(-6, -6),
                ),
                BoxShadow(
                  color: DashboardRuntimeTheme.shadowDarkColor,
                  blurRadius: 18,
                  offset: const Offset(8, 10),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: accentShadowAlpha),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitleInside && metrics.showTitle) ...[
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: resolvedTitleFontSize,
                  fontWeight: FontWeight.w700,
                  color: _titleTextColor(
                    item.titleColor ?? _defaultWidgetTitleColor,
                  ),
                  shadows: _titleShadows(
                    item.titleColor ?? _defaultWidgetTitleColor,
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

class _GaugeContent extends StatelessWidget {
  const _GaugeContent({required this.item, required this.metrics});

  final DashboardItem item;
  final _TileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final useTinyGaugeFallback = metrics.isTiny && (metrics.w <= 6 || metrics.h <= 4);
    if (useTinyGaugeFallback) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                metrics.formatPrimaryValue(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _emphasizedTextColor(item.accentColor),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final baseValueFont = metrics.isShort
        ? 11.0
        : switch (metrics.sizeClass) {
            _TileSizeClass.tiny => 11.0,
            _TileSizeClass.compact => 11.0,
            _TileSizeClass.medium => 15.0,
            _TileSizeClass.large => 20.0,
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = math.min(constraints.maxWidth, constraints.maxHeight);
        final controlInset = shortestSide >= 56
            ? 11.0
            : (shortestSide * 0.18).clamp(4.0, 11.0).toDouble();
        final usableWidth = math.max(
          0.0,
          constraints.maxWidth - (controlInset * 2),
        );
        final usableHeight = math.max(
          0.0,
          constraints.maxHeight - (controlInset * 2),
        );
        // Keep gauge perfectly circular regardless of tile aspect ratio.
        final gaugeSize = math.min(usableWidth, usableHeight);
        final strokeWidth = (gaugeSize * 0.12).clamp(6.0, 11.0).toDouble();
        final valueFont = (gaugeSize * 0.21)
            .clamp(baseValueFont, baseValueFont + 6.0)
            .toDouble();
        final opticalOffsetY =
            (gaugeSize * 0.035).clamp(1.5, 4.0).toDouble() +
            (gaugeSize < 92 ? 1.0 : 0.0);

        return Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(controlInset),
            child: Transform.translate(
              offset: Offset(0, opticalOffsetY),
              child: SizedBox.square(
                dimension: gaugeSize,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: item.value,
                    minValue: item.minValue,
                    maxValue: item.maxValue,
                    color: item.accentColor,
                    strokeWidth: strokeWidth,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        metrics.formatPrimaryValue(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: valueFont,
                          fontWeight: FontWeight.w700,
                          color: _emphasizedTextColor(item.accentColor),
                        ),
                      ),
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

class _ToggleContent extends StatelessWidget {
  const _ToggleContent({
    required this.item,
    required this.metrics,
    required this.enableInteraction,
    this.onChanged,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final bool enableInteraction;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final offColor = item.secondaryAccentColor ?? const Color(0xFFD86E6E);
    final onColor = item.accentColor;
    final activeColor = item.enabled ? onColor : offColor;
    final offTextColor = DashboardRuntimeTheme.errorTextColor;
    final labelFontSize = metrics.isTiny ? 11.0 : 12.0;
    final showKnobLabel = !metrics.isTiny && !metrics.isVeryShort && !metrics.isVeryNarrow;

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellGap = _ToggleVisualSpec.shellTrackGap;
        final trackWidth = math.max(0.0, constraints.maxWidth - (shellGap * 2));
        final trackHeight = math.max(0.0, constraints.maxHeight - (shellGap * 2));
        final knobSize = math.min(
          math.max(0.0, trackHeight - 6),
          math.max(0.0, trackWidth * 0.42),
        );
        final resolvedLabelColor = item.enabled
            ? DashboardRuntimeTheme.headlineColor
            : offTextColor;

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
                            Color.lerp(offColor, Colors.white, 0.60)!,
                            offColor.withValues(alpha: 0.72),
                          ],
                  ),
                  border: Border.all(
                    color: item.enabled
                        ? onColor.withValues(alpha: 0.62)
                        : offColor.withValues(alpha: 0.70),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: item.enabled ? 0.20 : 0.16),
                      blurRadius: 12,
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
                              colors: [
                                Color.lerp(activeColor, Colors.white, 0.25)!,
                                Color.lerp(activeColor, Colors.black, 0.08)!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.28),
                                blurRadius: 6,
                              ),
                              const BoxShadow(
                                color: DashboardRuntimeTheme.shadowLightColor,
                                blurRadius: 4,
                                offset: Offset(-1, -1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: showKnobLabel
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.enabled ? 'ON' : 'OFF',
                                    style: TextStyle(
                                      color: resolvedLabelColor,
                                      fontSize: labelFontSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                )
                              : null,
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

class _ValueLabelContent extends StatelessWidget {
  const _ValueLabelContent({required this.item, required this.metrics});

  final DashboardItem item;
  final _TileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final displayValue = metrics.formatPrimaryValue(item);
        final rawValueDigits = item.value % 1 == 0
            ? item.value.toStringAsFixed(0).length
            : item.value.toStringAsFixed(1).length;
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
        final lengthPenalty = rawValueDigits >= 5
            ? 2.5
            : rawValueDigits == 4
            ? 1.5
            : 0.0;
        final valueFont = (shortestSide * 0.22)
            .clamp(baseValueFont - lengthPenalty, baseValueFont + 3.0)
            .toDouble();

        return SizedBox.expand(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: valueFont,
                    fontWeight: FontWeight.w800,
                    color: _emphasizedTextColor(item.accentColor),
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

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.strokeWidth,
  });

  final double value;
  final double minValue;
  final double maxValue;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.45;
    final brightColor = Color.lerp(color, Colors.white, 0.28) ?? color;
    final deepColor = Color.lerp(color, Colors.black, 0.18) ?? color;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = DashboardRuntimeTheme.surfaceBorderColor.withValues(alpha: 0.82);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final normalized =
        ((value - minValue) /
                (maxValue - minValue == 0 ? 1 : maxValue - minValue))
            .clamp(0.0, 1.0);

    canvas.drawArc(arcRect, start, sweep, false, background);
    if (normalized > 0) {
      final activeSweep = sweep * normalized;
      canvas.drawArc(arcRect, start, activeSweep, false, glow);

      const segmentCount = 72;
      final paintedSegments = math.max(1, (segmentCount * normalized).ceil());
      final segmentSweep = activeSweep / paintedSegments;
      final segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      for (var i = 0; i < paintedSegments; i += 1) {
        final t = paintedSegments == 1 ? 1.0 : i / (paintedSegments - 1);
        segmentPaint.color =
            Color.lerp(brightColor, deepColor, t.clamp(0.0, 1.0)) ?? color;
        canvas.drawArc(
          arcRect,
          start + (segmentSweep * i),
          segmentSweep + 0.002,
          false,
          segmentPaint,
        );
      }

      final startOffset = Offset(
        center.dx + (radius * math.cos(start)),
        center.dy + (radius * math.sin(start)),
      );
      final endAngle = start + activeSweep;
      final endOffset = Offset(
        center.dx + (radius * math.cos(endAngle)),
        center.dy + (radius * math.sin(endAngle)),
      );
      final startCapPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = brightColor;
      final endCapPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = deepColor;
      canvas.drawCircle(startOffset, strokeWidth / 2, startCapPaint);
      canvas.drawCircle(endOffset, strokeWidth / 2, endCapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color;
  }
}

enum _ResolvedTitlePosition {
  topOutside,
  bottomOutside,
}

class _WidgetTitleOverlay extends StatelessWidget {
  const _WidgetTitleOverlay({
    required this.item,
    required this.layout,
    required this.style,
  });

  final DashboardItem item;
  final WidgetShellLayoutSpec layout;
  final TextStyle style;

  _ResolvedTitlePosition _resolvePosition(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == DashboardItemTitlePosition.bottomOutside) {
      return _ResolvedTitlePosition.bottomOutside;
    }
    return _ResolvedTitlePosition.topOutside;
  }

  @override
  Widget build(BuildContext context) {
    final position = _resolvePosition(item.titlePosition);
    final title = item.title.toUpperCase();

    switch (position) {
      case _ResolvedTitlePosition.topOutside:
        return Positioned(
          left: 0,
          right: 0,
          top: layout.titleTop,
          child: IgnorePointer(
            child: _FloatingWidgetTitle(text: title, style: style),
          ),
        );
      case _ResolvedTitlePosition.bottomOutside:
        return Positioned(
          left: 0,
          right: 0,
          bottom: -14,
          child: IgnorePointer(
            child: _FloatingWidgetTitle(text: title, style: style),
          ),
        );
    }
  }
}

class _FloatingWidgetTitle extends StatelessWidget {
  const _FloatingWidgetTitle({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 200.0;
        final height = ((style.fontSize ?? 10.0) * 1.4).clamp(12.0, 24.0);
        return Center(
          child: SizedBox(
            width: width,
            height: height,
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
