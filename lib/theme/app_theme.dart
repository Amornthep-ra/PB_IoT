import 'package:flutter/material.dart';

class AppGlassTheme {
  static const List<BoxShadow> shadowSm = <BoxShadow>[
    BoxShadow(
      color: Color(0x100F172A),
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> shadowMd = <BoxShadow>[
    BoxShadow(
      color: Color(0x120F172A),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> shadowLg = <BoxShadow>[
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static LinearGradient surfaceGradient(List<Color> colors) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  static BoxDecoration surfaceDecoration({
    required double radius,
    required List<Color> colors,
    double borderAlpha = 0.58,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFFFFFFFF).withValues(alpha: borderAlpha),
      ),
      gradient: surfaceGradient(colors),
      boxShadow: shadows ?? shadowSm,
    );
  }

  static BoxDecoration accentDecoration({
    required double radius,
    required List<Color> colors,
    required Color borderColor,
    Color? glowColor,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      gradient: surfaceGradient(colors),
      boxShadow: shadows ??
          <BoxShadow>[
            if (glowColor != null)
              BoxShadow(
                color: glowColor.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
    );
  }
}
