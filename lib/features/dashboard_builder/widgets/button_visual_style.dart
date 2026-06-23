import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../models/dashboard_theme_preset.dart';
import 'widget_shell_layout.dart';

const Color _standardOffAccent = Color(0xFFD94B4B);

Color _resolvedOffAccent(Color? color) {
  if (color == null || color.toARGB32() == const Color(0xFF64748B).toARGB32()) {
    return _standardOffAccent;
  }
  return color;
}

bool _usesDarkTheme(DashboardThemePreset? themePreset) {
  return themePreset?.isDark == true;
}

bool _isRuntimeDefaultSurfaceColor(Color color) {
  return color.toARGB32() == DashboardRuntimeTheme.cardColor.toARGB32() ||
      color.toARGB32() == DashboardRuntimeTheme.cardHighlightColor.toARGB32() ||
      color.toARGB32() == DashboardRuntimeTheme.surfaceColor.toARGB32();
}

Color _themedDefaultBorderColor({
  required Color accentColor,
  required DashboardThemePreset? themePreset,
}) {
  if (_usesDarkTheme(themePreset)) {
    return themePreset!.borderColor;
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

class ButtonVisualStyle {
  const ButtonVisualStyle({
    required this.activeColor,
    required this.inactiveColor,
    required this.currentAccent,
    required this.surfaceColor,
    required this.controlSurfaceColor,
    required this.shellGradientEnd,
    required this.controlGradientEnd,
    required this.highlightShadowColor,
    required this.controlHighlightShadowColor,
    required this.ambientShadowColor,
    required this.resolvedGlowColor,
    required this.resolvedShellBorderColor,
    required this.resolvedShellBorderWidth,
    required this.hasGlow,
    required this.shellGlowAlpha,
    required this.innerGlowAlpha,
    required this.resolvedGlowBlur,
  });

  final Color activeColor;
  final Color inactiveColor;
  final Color currentAccent;
  final Color surfaceColor;
  final Color controlSurfaceColor;
  final Color shellGradientEnd;
  final Color controlGradientEnd;
  final Color highlightShadowColor;
  final Color controlHighlightShadowColor;
  final Color ambientShadowColor;
  final Color resolvedGlowColor;
  final Color resolvedShellBorderColor;
  final double resolvedShellBorderWidth;
  final bool hasGlow;
  final double shellGlowAlpha;
  final double innerGlowAlpha;
  final double resolvedGlowBlur;
}

double resolveItemGlowStrength({
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

double resolveItemGlowBlur({
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

ButtonVisualStyle resolveButtonVisualStyle({
  required DashboardItem item,
  required DashboardThemePreset? themePreset,
  required bool isActive,
  required double shellBorderWidthFallback,
  required ButtonSizeClass sizeClass,
  Color? glowColor,
  double? glowStrength,
  double? glowBlur,
}) {
  final activeColor = item.accentColor;
  final inactiveColor = _resolvedOffAccent(item.secondaryAccentColor);
  final inactiveVisualColor =
      Color.lerp(inactiveColor, const Color(0xFFD94B4B), 0.42) ?? inactiveColor;
  final currentAccent = isActive ? activeColor : inactiveVisualColor;
  final surfaceColor =
      _themedButtonShellColor(item: item, themePreset: themePreset) ??
      (isActive
          ? DashboardRuntimeTheme.cardColor
          : DashboardRuntimeTheme.surfaceColor);
  final controlSurfaceColor =
      _themedButtonInnerColor(item: item, themePreset: themePreset) ??
      DashboardRuntimeTheme.cardHighlightColor;
  final usesDarkSurface =
      ThemeData.estimateBrightnessForColor(surfaceColor) == Brightness.dark;
  final usesDarkControlSurface =
      ThemeData.estimateBrightnessForColor(controlSurfaceColor) ==
      Brightness.dark;
  final shellGradientEnd = usesDarkSurface
      ? (Color.lerp(surfaceColor, Colors.white, 0.08) ?? surfaceColor)
      : (Color.lerp(
              surfaceColor,
              DashboardRuntimeTheme.cardHighlightColor,
              0.35,
            ) ??
            surfaceColor);
  final controlGradientEnd = usesDarkControlSurface
      ? (Color.lerp(controlSurfaceColor, Colors.white, 0.10) ??
            controlSurfaceColor)
      : (Color.lerp(
              controlSurfaceColor,
              DashboardRuntimeTheme.cardColor,
              0.8,
            ) ??
            controlSurfaceColor);
  final highlightShadowColor = usesDarkSurface
      ? Colors.white.withValues(alpha: 0.045)
      : DashboardRuntimeTheme.shadowLightColor;
  final controlHighlightShadowColor = usesDarkControlSurface
      ? Colors.white.withValues(alpha: 0.055)
      : DashboardRuntimeTheme.shadowLightColor;
  final ambientShadowColor = usesDarkSurface
      ? Colors.black.withValues(alpha: 0.24)
      : DashboardRuntimeTheme.shadowDarkColor;
  final resolvedGlowColor = isActive
      ? (glowColor ?? activeColor)
      : inactiveVisualColor;
  final rawGlowStrength = (glowStrength ?? 0.12).clamp(0.0, 0.35).toDouble();
  final resolvedGlowStrength = isActive
      ? rawGlowStrength
      : math.min(rawGlowStrength * 0.24, 0.035);
  final resolvedGlowBlur = (glowBlur ?? 18.0).clamp(0.0, 40.0).toDouble();
  final hasGlow = resolvedGlowStrength > 0 && resolvedGlowBlur > 0;
  final compactGlowBoost = sizeClass == ButtonSizeClass.compact ? 1.2 : 1.0;
  final shellGlowAlpha = (resolvedGlowStrength * compactGlowBoost)
      .clamp(0.0, 0.42)
      .toDouble();
  final innerGlowAlpha = (resolvedGlowStrength * 0.72 * compactGlowBoost)
      .clamp(0.0, 0.30)
      .toDouble();
  final borderColor = isActive
      ? activeColor.withValues(alpha: 0.26)
      : inactiveVisualColor.withValues(alpha: 0.18);
  final resolvedShellBorderColor =
      item.buttonBorderColor ??
      (_usesDarkTheme(themePreset)
          ? _themedDefaultBorderColor(
              accentColor: activeColor,
              themePreset: themePreset,
            ).withValues(alpha: 0.72)
          : borderColor);

  return ButtonVisualStyle(
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    currentAccent: currentAccent,
    surfaceColor: surfaceColor,
    controlSurfaceColor: controlSurfaceColor,
    shellGradientEnd: shellGradientEnd,
    controlGradientEnd: controlGradientEnd,
    highlightShadowColor: highlightShadowColor,
    controlHighlightShadowColor: controlHighlightShadowColor,
    ambientShadowColor: ambientShadowColor,
    resolvedGlowColor: resolvedGlowColor,
    resolvedShellBorderColor: resolvedShellBorderColor,
    resolvedShellBorderWidth:
        item.buttonBorderWidth ?? shellBorderWidthFallback,
    hasGlow: hasGlow,
    shellGlowAlpha: shellGlowAlpha,
    innerGlowAlpha: innerGlowAlpha,
    resolvedGlowBlur: resolvedGlowBlur,
  );
}
