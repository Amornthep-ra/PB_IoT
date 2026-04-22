import 'package:flutter/material.dart';

class DashboardRuntimeTheme {
  static const Color backgroundColor = Color(0xFFF2F5FA);
  static const Color cardColor = Color(0xFFEFF3F8);
  static const Color cardHighlightColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF8FAFD);
  static const Color surfaceBorderColor = Color(0xFFD7E0EA);
  static const Color surfaceBorderFocusColor = Color(0xFF6EAB90);
  static const Color fieldTextColor = Color(0xFF20303A);
  static const Color mutedTextColor = Color(0xFF667587);
  static const Color labelTextColor = Color(0xFF4B5A69);
  static const Color headlineColor = Color(0xFF15212B);
  static const Color buttonStartColor = Color(0xFF7FC39C);
  static const Color buttonEndColor = Color(0xFF4E9070);
  static const Color buttonGlowColor = Color(0xFF9CCCB0);
  static const Color shadowDarkColor = Color(0x1D9CA9B5);
  static const Color shadowLightColor = Color(0xF9FFFFFF);
  static const Color errorBackgroundColor = Color(0xFFFFF2F2);
  static const Color errorBorderColor = Color(0xFFF2C8C8);
  static const Color errorTextColor = Color(0xFFB24A4A);

  static const double cardRadius = 24;
  static const double fieldRadius = 16;
  static const double buttonRadius = 18;

  static BoxDecoration cardDecoration({
    double radius = cardRadius,
    bool emphasize = false,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      boxShadow: [
        const BoxShadow(
          color: shadowLightColor,
          offset: Offset(-8, -8),
          blurRadius: 16,
        ),
        BoxShadow(
          color: emphasize
              ? buttonGlowColor.withValues(alpha: 0.18)
              : shadowDarkColor,
          offset: const Offset(10, 12),
          blurRadius: emphasize ? 26 : 24,
        ),
        const BoxShadow(
          color: Color(0x14677E92),
          offset: Offset(0, 18),
          blurRadius: 28,
        ),
      ],
    );
  }

  static BoxDecoration insetSurfaceDecoration({
    double radius = fieldRadius,
    bool emphasize = false,
  }) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: emphasize ? surfaceBorderFocusColor : surfaceBorderColor,
        width: emphasize ? 1.4 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: emphasize
              ? buttonGlowColor.withValues(alpha: 0.18)
              : shadowLightColor,
          offset: const Offset(-4, -4),
          blurRadius: emphasize ? 12 : 8,
        ),
        BoxShadow(
          color: emphasize
              ? buttonGlowColor.withValues(alpha: 0.10)
              : shadowDarkColor,
          offset: const Offset(6, 8),
          blurRadius: emphasize ? 18 : 12,
        ),
      ],
    );
  }

  static LinearGradient accentGradient({bool disabled = false}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        buttonStartColor.withValues(alpha: disabled ? 0.76 : 1),
        buttonEndColor.withValues(alpha: disabled ? 0.76 : 1),
      ],
    );
  }
}
