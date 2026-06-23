import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../models/dashboard_theme_preset.dart';
import 'dashboard_text_contrast.dart';
import 'dashboard_value_formatter.dart';
import 'smart_action_button.dart';
import 'smart_slider_widget.dart';

part 'renderer_parts/button_renderer.dart';
part 'renderer_parts/slider_renderer.dart';
part 'renderer_parts/gauge_renderer.dart';
part 'renderer_parts/toggle_renderer.dart';
part 'renderer_parts/stepper_renderer.dart';
part 'renderer_parts/value_label_renderer.dart';
part 'renderer_parts/trend_renderer.dart';
part 'renderer_parts/led_renderer.dart';
part 'renderer_parts/renderer_shell.dart';

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

  String formatPrimaryValue(DashboardItem item) {
    final valueText = formatDashboardDisplayValue(item);
    if (valueText == '--') {
      return valueText;
    }

    final combinedLength = valueText.length;
    final shouldHideUnit =
        (isTiny && isVeryNarrow && combinedLength >= 4) ||
        (isTiny && valueText.length >= 4) ||
        (isNarrow && valueText.length >= 5);

    return shouldHideUnit ? valueText.split(' ').first : valueText;
  }
}

Color _emphasizedTextColor(Color baseColor) {
  return Color.lerp(baseColor, DashboardRuntimeTheme.headlineColor, 0.22) ??
      baseColor;
}

Color _readableTextColor({
  required Color preferred,
  required Color background,
  Color fallback = DashboardRuntimeTheme.headlineColor,
  double minRatio = 4.5,
}) {
  return DashboardTextContrast.readableTextColor(
    preferred: preferred,
    background: background,
    fallback: fallback,
    minRatio: minRatio,
  );
}

Color _canvasReferenceColor(DashboardThemePreset themePreset) {
  return themePreset.canvasColors.isEmpty
      ? themePreset.pageEnd
      : themePreset.canvasColors.first;
}

List<Shadow> _lightTitleShadows() {
  return [Shadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 8)];
}

List<Shadow> _darkTitleShadows(Color textColor) {
  final textIsLight =
      ThemeData.estimateBrightnessForColor(textColor) == Brightness.light;
  return [
    Shadow(
      color: Colors.black.withValues(alpha: textIsLight ? 0.42 : 0.28),
      blurRadius: textIsLight ? 5 : 3,
      offset: const Offset(0, 1),
    ),
  ];
}

Color _shellBorderColor(Color baseColor) {
  return baseColor.withValues(alpha: 0.58);
}

List<Color> _surfaceGradientColors(
  Color? customSurfaceColor,
  DashboardThemePreset? themePreset,
) {
  if (customSurfaceColor == null && themePreset?.isDark == true) {
    return <Color>[
      Color.lerp(themePreset!.surfaceColor, Colors.white, 0.04) ??
          themePreset.surfaceColor,
      Color.lerp(themePreset.cardColor, Colors.black, 0.08) ??
          themePreset.cardColor,
    ];
  }

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

const Duration _valueAnimationDuration = Duration(milliseconds: 450);
const Curve _valueAnimationCurve = Curves.easeOutCubic;
const Color _factoryDefaultWidgetTitleColor = Color(0xFF15212B);
const Color _neutralInactiveAccent = Color(0xFF94A3B8);
const Color _standardOffAccent = Color(0xFFD94B4B);

bool _isFactoryDefaultTitleColor(Color? color) {
  return color == null ||
      color.toARGB32() == _factoryDefaultWidgetTitleColor.toARGB32();
}

bool _isFactoryDefaultTitle(DashboardItem item) {
  return dashboardIsDefaultTitleForType(item.type, item.title);
}

bool _isTitleHidden(DashboardItem item) {
  return item.titlePosition.trim().toLowerCase() ==
      DashboardItemTitlePosition.hidden;
}

bool _shouldRenderVisibleTitle(DashboardItem item) {
  return !_isFactoryDefaultTitle(item) &&
      !_isTitleHidden(item) &&
      item.title.trim().isNotEmpty;
}

bool _hasBoundDataKey(DashboardItem item) {
  final key = item.dataKey?.trim();
  return key != null && key.isNotEmpty;
}

bool _isUnboundValueItem(DashboardItem item) {
  return !_hasBoundDataKey(item) &&
      (item.type == DashboardItemType.slider ||
          item.type == DashboardItemType.stepH ||
          item.type == DashboardItemType.stepV ||
          item.type == DashboardItemType.gauge ||
          item.type == DashboardItemType.valueLabel ||
          item.type == DashboardItemType.trend ||
          item.type == DashboardItemType.led);
}

Color _resolvedOffAccent(Color? color) {
  if (color == null || color.toARGB32() == const Color(0xFF64748B).toARGB32()) {
    return _standardOffAccent;
  }
  return color;
}

bool _isRuntimeDefaultSurfaceColor(Color color) {
  return color.toARGB32() == DashboardRuntimeTheme.cardColor.toARGB32() ||
      color.toARGB32() == DashboardRuntimeTheme.cardHighlightColor.toARGB32() ||
      color.toARGB32() == DashboardRuntimeTheme.surfaceColor.toARGB32();
}

bool _usesDarkTheme(DashboardThemePreset? themePreset) {
  return themePreset?.isDark == true;
}

Color _resolvedTitleTextColor({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
}) {
  final canvasColor = themePreset == null
      ? DashboardRuntimeTheme.cardColor
      : _canvasReferenceColor(themePreset);

  final isCanvasDark =
      ThemeData.estimateBrightnessForColor(canvasColor) == Brightness.dark;

  final fallback = isCanvasDark
      ? Colors.white
      : (themePreset?.headlineColor ?? DashboardRuntimeTheme.headlineColor);

  final rawTitleColor = item.titleColor ?? fallback;

  final preferredColor = _isFactoryDefaultTitleColor(item.titleColor)
      ? fallback
      : rawTitleColor;

  final resolvedColor = DashboardTextContrast.readableTextColor(
    preferred: preferredColor,
    background: canvasColor,
    fallback: fallback,
    minRatio: 4.5,
  );

  return _isFactoryDefaultTitle(item)
      ? resolvedColor.withValues(alpha: isCanvasDark ? 0.94 : 0.72)
      : resolvedColor.withValues(alpha: isCanvasDark ? 0.96 : 1.0);
}

List<Shadow> _resolvedTitleShadows({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
}) {
  if (_isFactoryDefaultTitle(item)) {
    return const <Shadow>[];
  }

  if (_usesDarkTheme(themePreset)) {
    return _darkTitleShadows(
      _resolvedTitleTextColor(item: item, themePreset: themePreset),
    );
  }

  return _lightTitleShadows();
}

Color? _themedDefaultSurfaceColor({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
}) {
  if (item.buttonInnerColor != null &&
      !(_usesDarkTheme(themePreset) &&
          _isRuntimeDefaultSurfaceColor(item.buttonInnerColor!))) {
    return item.buttonInnerColor;
  }

  if (_usesDarkTheme(themePreset)) {
    return themePreset!.surfaceColor;
  }

  return DashboardRuntimeTheme.cardColor;
}

Color _resolvedValueBackgroundColor({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
}) {
  if (_usesDarkTheme(themePreset)) {
    return _themedDefaultSurfaceColor(item: item, themePreset: themePreset) ??
        themePreset!.surfaceColor;
  }

  return _themedDefaultSurfaceColor(item: item, themePreset: themePreset) ??
      DashboardRuntimeTheme.cardColor;
}

Color _resolvedValueTextColor({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
  required bool isUnbound,
}) {
  final background = _resolvedValueBackgroundColor(
    item: item,
    themePreset: themePreset,
  );

  final fallback =
      themePreset?.headlineColor ?? DashboardRuntimeTheme.headlineColor;

  if (isUnbound) {
    return fallback.withValues(alpha: 0.88);
  }

  return _readableTextColor(
    preferred: _emphasizedTextColor(item.accentColor),
    background: background,
    fallback: fallback,
  );
}

Color _themedDefaultBorderColor({
  required Color accentColor,
  required DashboardThemePreset? themePreset,
}) {
  if (_usesDarkTheme(themePreset)) {
    return Color.lerp(themePreset!.borderColor, accentColor, 0.24) ??
        themePreset.borderColor;
  }

  return accentColor;
}

Color _darkButtonShellColor(DashboardThemePreset themePreset) {
  return Color.lerp(themePreset.cardColor, Colors.white, 0.10) ??
      themePreset.cardColor;
}

Color _darkButtonInnerColor(DashboardThemePreset themePreset) {
  return Color.lerp(themePreset.cardColor, Colors.white, 0.14) ??
      themePreset.cardColor;
}

Color? _themedButtonShellColor({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
}) {
  if (!_usesDarkTheme(themePreset)) {
    return item.buttonShellColor;
  }

  if (item.buttonShellColor == null ||
      _isRuntimeDefaultSurfaceColor(item.buttonShellColor!)) {
    return _darkButtonShellColor(themePreset!);
  }

  return item.buttonShellColor;
}

Color? _themedButtonInnerColor({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
}) {
  if (!_usesDarkTheme(themePreset)) {
    return item.buttonInnerColor;
  }

  if (item.buttonInnerColor == null ||
      _isRuntimeDefaultSurfaceColor(item.buttonInnerColor!)) {
    return _darkButtonInnerColor(themePreset!);
  }

  return item.buttonInnerColor;
}

double _resolvedGlowStrength({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
  required double defaultStrength,
}) {
  final rawStrength = item.glowStrength ?? defaultStrength;
  if (!_usesDarkTheme(themePreset)) {
    return rawStrength.clamp(0.0, 0.35).toDouble();
  }

  final glowColor = item.glowColor ?? item.accentColor;
  final isBrightGlow =
      ThemeData.estimateBrightnessForColor(glowColor) == Brightness.light;
  final darkStrength = item.glowStrength == null
      ? rawStrength * (isBrightGlow ? 0.42 : 0.55)
      : math.min(rawStrength, isBrightGlow ? 0.12 : 0.16);
  return darkStrength.clamp(0.0, 0.20).toDouble();
}

double _resolvedGlowBlur({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
}) {
  final rawBlur = item.glowBlur ?? 18.0;
  if (!_usesDarkTheme(themePreset)) {
    return rawBlur.clamp(0.0, 40.0).toDouble();
  }

  final darkBlur = item.glowBlur == null ? math.min(rawBlur, 14.0) : rawBlur;
  return darkBlur.clamp(0.0, 28.0).toDouble();
}

List<BoxShadow> _defaultTileShadows({
  required DashboardItemType type,
  required DashboardThemePreset? themePreset,
}) {
  if (type == DashboardItemType.valueLabel) {
    return const <BoxShadow>[];
  }

  if (_usesDarkTheme(themePreset)) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ];
  }

  return const <BoxShadow>[
    BoxShadow(
      color: DashboardRuntimeTheme.shadowLightColor,
      blurRadius: 12,
      offset: Offset(-6, -6),
    ),
    BoxShadow(
      color: DashboardRuntimeTheme.shadowDarkColor,
      blurRadius: 18,
      offset: Offset(8, 10),
    ),
  ];
}

double _resolvedTitleFontSize({
  required DashboardItem item,
  required double fallbackSize,
  required double minSize,
  required double maxSize,
}) {
  final defaultTitleAdjustment =
      item.titleFontSize == null && _isFactoryDefaultTitle(item) ? -1.0 : 0.0;
  return ((item.titleFontSize ?? fallbackSize) + defaultTitleAdjustment).clamp(
    minSize,
    maxSize,
  );
}

FontWeight _resolvedTitleFontWeight(DashboardItem item) {
  return _isFactoryDefaultTitle(item) ? FontWeight.w600 : FontWeight.w700;
}

double _resolvedTitleLetterSpacing(DashboardItem item) {
  return _isFactoryDefaultTitle(item) ? 0.3 : 0.4;
}

class DashboardItemRenderer extends StatelessWidget {
  const DashboardItemRenderer({
    super.key,
    required this.item,
    this.enableInteraction = true,
    this.isEditMode = false,
    this.showTitle = true,
    this.paintTitle = true,
    this.onItemChanged,
    this.themePreset,
  });

  final DashboardItem item;
  final bool enableInteraction;
  final bool isEditMode;
  final bool showTitle;
  final bool paintTitle;
  final ValueChanged<DashboardItem>? onItemChanged;
  final DashboardThemePreset? themePreset;

  @override
  Widget build(BuildContext context) {
    final activeColor = item.accentColor;
    final inactiveColor = _resolvedOffAccent(item.secondaryAccentColor);
    final currentColor =
        (item.type == DashboardItemType.button ||
                item.type == DashboardItemType.toggle) &&
            !item.enabled
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
          themePreset: themePreset,
          showTitle: showTitle,
          paintTitle: paintTitle,
        );
      case DashboardItemType.slider:
        final darkThemePreset = _usesDarkTheme(themePreset)
            ? themePreset!
            : null;
        final darkTrackGradientColors = darkThemePreset != null
            ? <Color>[
                Color.lerp(
                      darkThemePreset.surfaceColor,
                      darkThemePreset.cardColor,
                      0.60,
                    ) ??
                    darkThemePreset.surfaceColor,
                Color.lerp(darkThemePreset.cardColor, Colors.black, 0.12) ??
                    darkThemePreset.cardColor,
              ]
            : null;
        final darkTrackBorderColor = darkThemePreset?.borderColor.withValues(
          alpha: 0.48,
        );
        final darkTrackShadowColor = darkThemePreset?.isDark == true
            ? Colors.black.withValues(alpha: 0.20)
            : null;
        return _SliderTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          themePreset: themePreset,
          showTitle: showTitle,
          paintTitle: paintTitle,
          child: SmartSliderControl(
            item: item,
            showValue: !metrics.isVeryNarrow,
            enableInteraction: enableInteraction && canWrite,
            themePreset: themePreset,
            emitOnDrag: item.sendBehavior == 'on_drag',
            trackGradientColors: darkTrackGradientColors,
            trackBorderColor: darkTrackBorderColor,
            trackShadowColor: darkTrackShadowColor,
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
      case DashboardItemType.stepH:
      case DashboardItemType.stepV:
        return _DashboardTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          themePreset: themePreset,
          showTitleInside: showTitle,
          child: _StepperContent(
            item: item,
            metrics: metrics,
            themePreset: themePreset,
            isVertical: item.type == DashboardItemType.stepV,
            enableInteraction:
                enableInteraction && canWrite && _hasBoundDataKey(item),
            onChanged: onItemChanged == null
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
          themePreset: themePreset,
          showTitle: showTitle,
          paintTitle: paintTitle,
          child: _GaugeContent(
            item: item,
            metrics: metrics,
            themePreset: themePreset,
          ),
        );
      case DashboardItemType.toggle:
        return _ToggleTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          themePreset: themePreset,
          showTitle: showTitle,
          paintTitle: paintTitle,
          child: _ToggleContent(
            item: item,
            metrics: metrics,
            themePreset: themePreset,
            enableInteraction: enableInteraction && canWrite,
            onChanged: onItemChanged == null
                ? null
                : (enabled) => onItemChanged!(
                    item.copyWith(enabled: enabled, value: enabled ? 1.0 : 0.0),
                  ),
          ),
        );
      case DashboardItemType.valueLabel:
        return _ValueLabelTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          themePreset: themePreset,
          showTitle: showTitle,
          paintTitle: paintTitle,
          child: _ValueLabelContent(
            item: item,
            metrics: metrics,
            themePreset: themePreset,
          ),
        );
      case DashboardItemType.trend:
        return _TrendTileShell(
          item: item,
          metrics: metrics,
          accentColor: currentColor,
          themePreset: themePreset,
          showTitle: showTitle,
          paintTitle: paintTitle,
          child: _TrendContent(
            item: item,
            metrics: metrics,
            themePreset: themePreset,
          ),
        );
      case DashboardItemType.led:
        return _LedTileShell(
          item: item,
          metrics: metrics,
          accentColor: activeColor,
          inactiveColor: inactiveColor,
          themePreset: themePreset,
          showTitle: showTitle,
          paintTitle: paintTitle,
          child: _LedContent(
            item: item,
            metrics: metrics,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        );
    }
  }
}
