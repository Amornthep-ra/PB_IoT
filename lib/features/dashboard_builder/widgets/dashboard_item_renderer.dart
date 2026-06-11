import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../models/dashboard_theme_preset.dart';
import 'dashboard_text_contrast.dart';
import 'dashboard_value_formatter.dart';
import 'smart_action_button.dart';
import 'smart_slider_widget.dart';

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
          item.type == DashboardItemType.valueLabel);
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

class _GaugeTileShell extends StatelessWidget {
  const _GaugeTileShell({
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
    final valueLabelBackgroundColor = _themedDefaultSurfaceColor(
      item: item,
      themePreset: themePreset,
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: valueLabelBackgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        ),
      ),
    );
  }
}

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
        return 4;
      }
      if (metrics.isVeryShort || metrics.isVeryNarrow) {
        return 5;
      }
      return metrics.sizeClass == _TileSizeClass.large ? 10 : 7;
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
        : customSurfaceColor != null
        ? _shellBorderColor(
            Color.lerp(customSurfaceColor, defaultBorderColor, 0.35) ??
                defaultBorderColor,
          )
        : _shellBorderColor(defaultBorderColor);
    final defaultGlowStrength = item.type == DashboardItemType.valueLabel
        ? 0.0
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
                item.type == DashboardItemType.toggle
            ? customSurfaceColor
            : null,
        gradient:
            item.type == DashboardItemType.valueLabel ||
                item.type == DashboardItemType.toggle
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

class _GaugeContent extends StatelessWidget {
  const _GaugeContent({
    required this.item,
    required this.metrics,
    required this.themePreset,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final DashboardThemePreset? themePreset;

  @override
  Widget build(BuildContext context) {
    final isUnbound = _isUnboundValueItem(item);
    final useTinyGaugeFallback =
        metrics.isTiny && (metrics.w <= 6 || metrics.h <= 4);
    if (useTinyGaugeFallback) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: item.value, end: item.value),
        duration: _valueAnimationDuration,
        curve: _valueAnimationCurve,
        builder: (context, animatedValue, child) {
          final animatedItem = item.copyWith(value: animatedValue);
          return Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isUnbound
                        ? _neutralInactiveAccent
                        : item.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    metrics.formatPrimaryValue(animatedItem),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isUnbound ? FontWeight.w800 : FontWeight.w700,
                      color: _resolvedValueTextColor(
                        item: item,
                        themePreset: themePreset,
                        isUnbound: isUnbound,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
        final shortestSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
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
            .clamp(
              isUnbound ? baseValueFont + 2.0 : baseValueFont,
              baseValueFont + 7.0,
            )
            .toDouble();
        final opticalOffsetY =
            (gaugeSize * 0.035).clamp(1.5, 4.0).toDouble() +
            (gaugeSize < 92 ? 1.0 : 0.0);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: item.value, end: item.value),
          duration: _valueAnimationDuration,
          curve: _valueAnimationCurve,
          builder: (context, animatedValue, child) {
            final animatedItem = item.copyWith(value: animatedValue);
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
                        value: animatedValue,
                        minValue: item.minValue,
                        maxValue: item.maxValue,
                        color: isUnbound
                            ? _neutralInactiveAccent
                            : item.accentColor,
                        strokeWidth: strokeWidth,
                        isEmpty: isUnbound,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            metrics.formatPrimaryValue(animatedItem),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: valueFont,
                              fontWeight: isUnbound
                                  ? FontWeight.w800
                                  : FontWeight.w700,
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
                  ),
                ),
              ),
            );
          },
        );
      },
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
    final labelFontSize = metrics.isTiny ? 11.0 : 12.0;
    final showKnobLabel =
        !metrics.isTiny && !metrics.isVeryShort && !metrics.isVeryNarrow;
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
        final knobReferenceColor = item.enabled ? onColor : knobEndColor;
        final resolvedLabelColor = item.enabled
            ? DashboardRuntimeTheme.headlineColor
            : offColor;
        final knobContentColor = _readableTextColor(
          preferred: resolvedLabelColor,
          background: knobReferenceColor,
          fallback: item.enabled
              ? Colors.white
              : DashboardRuntimeTheme.headlineColor,
        );
        final fallbackIconSize = (knobSize * 0.58).clamp(12.0, 18.0).toDouble();

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
                          child: showKnobLabel
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.enabled ? 'ON' : 'OFF',
                                    style: TextStyle(
                                      color: knobContentColor,
                                      fontSize: labelFontSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                )
                              : Icon(
                                  item.enabled
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  size: fallbackIconSize,
                                  color: knobContentColor,
                                ),
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

class _StepperContent extends StatelessWidget {
  const _StepperContent({
    required this.item,
    required this.metrics,
    required this.themePreset,
    required this.isVertical,
    required this.enableInteraction,
    this.onChanged,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final DashboardThemePreset? themePreset;
  final bool isVertical;
  final bool enableInteraction;
  final ValueChanged<double>? onChanged;

  void _emitStep(double direction) {
    final step = item.stepValue <= 0 ? 1.0 : item.stepValue;
    final next = _snapToStep(
      value: item.value + (step * direction),
      min: item.minValue,
      max: item.maxValue,
      step: step,
    );
    if (next == item.value) {
      return;
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = metrics.formatPrimaryValue(item);
    final isUnbound = _isUnboundValueItem(item);
    final active = enableInteraction && onChanged != null;
    final valueColor = _resolvedValueTextColor(
      item: item,
      themePreset: themePreset,
      isUnbound: isUnbound,
    );
    final buttonColor = active ? item.accentColor : _neutralInactiveAccent;
    final valueFont = metrics.isTiny
        ? 14.0
        : metrics.isVeryNarrow || metrics.isVeryShort
        ? 15.0
        : switch (metrics.sizeClass) {
            _TileSizeClass.tiny => 14.0,
            _TileSizeClass.compact => 17.0,
            _TileSizeClass.medium => 20.0,
            _TileSizeClass.large => 24.0,
          };
    final value = Expanded(
      child: Center(
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
              color: valueColor,
            ),
          ),
        ),
      ),
    );
    final minusButton = _StepperIconButton(
      icon: Icons.remove_rounded,
      tooltip: 'ลดค่า',
      color: buttonColor,
      enabled: active,
      onTap: () => _emitStep(-1),
    );
    final plusButton = _StepperIconButton(
      icon: Icons.add_rounded,
      tooltip: 'เพิ่มค่า',
      color: buttonColor,
      enabled: active,
      onTap: () => _emitStep(1),
    );

    if (isVertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [plusButton, value, minusButton],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [minusButton, value, plusButton],
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, enabled ? 0.18 : 0.42)!,
                  color.withValues(alpha: enabled ? 0.92 : 0.36),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? Colors.white
                  : DashboardRuntimeTheme.mutedTextColor.withValues(
                      alpha: 0.72,
                    ),
            ),
          ),
        ),
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
        final shortestSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
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
        final valueFont = (shortestSide * 0.22)
            .clamp(
              isUnbound ? baseValueFont : baseValueFont - lengthPenalty,
              baseValueFont + (isUnbound ? 4.0 : 3.0),
            )
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

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.strokeWidth,
    this.isEmpty = false,
  });

  final double value;
  final double minValue;
  final double maxValue;
  final Color color;
  final double strokeWidth;
  final bool isEmpty;

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
      ..color = DashboardRuntimeTheme.surfaceBorderColor.withValues(
        alpha: isEmpty ? 0.95 : 0.82,
      );
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
        oldDelegate.color != color ||
        oldDelegate.isEmpty != isEmpty;
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
