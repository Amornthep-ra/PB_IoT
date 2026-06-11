import 'package:flutter/material.dart';

/// Utility functions for choosing readable text/icon colors
/// on dashboard widget backgrounds.
///
/// Use this when accent colors may be too light or too close
/// to the card/background color.
class DashboardTextContrast {
  const DashboardTextContrast._();

  /// WCAG contrast ratio between two colors.
  ///
  /// Returns values from 1.0 to 21.0.
  /// Higher means better contrast.
  static double contrastRatio(Color foreground, Color background) {
    final foregroundLum = foreground.computeLuminance();
    final backgroundLum = background.computeLuminance();

    final lighter = foregroundLum > backgroundLum
        ? foregroundLum
        : backgroundLum;
    final darker = foregroundLum > backgroundLum
        ? backgroundLum
        : foregroundLum;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns true if [foreground] is readable on [background].
  ///
  /// Default ratio 4.5 follows the common WCAG target for normal text.
  static bool isReadableOn(
    Color foreground,
    Color background, {
    double minRatio = 4.5,
  }) {
    return contrastRatio(foreground, background) >= minRatio;
  }

  /// Pick a readable color from preferred -> fallback -> black/white.
  ///
  /// Example:
  /// ```dart
  /// final color = DashboardTextContrast.readableTextColor(
  ///   preferred: accentColor,
  ///   background: cardColor,
  ///   fallback: headlineColor,
  /// );
  /// ```
  static Color readableTextColor({
    required Color preferred,
    required Color background,
    Color fallback = const Color(0xFF1F2937),
    double minRatio = 4.5,
  }) {
    if (isReadableOn(preferred, background, minRatio: minRatio)) {
      return preferred;
    }

    if (isReadableOn(fallback, background, minRatio: minRatio)) {
      return fallback;
    }

    final blackRatio = contrastRatio(Colors.black, background);
    final whiteRatio = contrastRatio(Colors.white, background);

    return blackRatio >= whiteRatio ? Colors.black : Colors.white;
  }

  /// Pick a readable color for small labels, icons, or knob text.
  ///
  /// Small UI elements need stronger contrast than large display text.
  static Color readableControlColor({
    required Color preferred,
    required Color background,
    Color fallback = const Color(0xFF111827),
  }) {
    return readableTextColor(
      preferred: preferred,
      background: background,
      fallback: fallback,
      minRatio: 4.5,
    );
  }

  /// Pick a readable color for large display values.
  ///
  /// Large text can accept slightly lower contrast, but 4.5 is still safer
  /// for dashboard values because users need to read them quickly.
  static Color readableValueColor({
    required Color preferred,
    required Color background,
    Color fallback = const Color(0xFF1F2937),
  }) {
    return readableTextColor(
      preferred: preferred,
      background: background,
      fallback: fallback,
      minRatio: 4.5,
    );
  }

  /// Returns black or white depending on which has better contrast.
  ///
  /// Useful when text is placed directly on a dynamic accent color.
  static Color blackOrWhiteOn(Color background) {
    final blackRatio = contrastRatio(Colors.black, background);
    final whiteRatio = contrastRatio(Colors.white, background);

    return blackRatio >= whiteRatio ? Colors.black : Colors.white;
  }
}