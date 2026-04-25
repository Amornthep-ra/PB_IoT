import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'dashboard_runtime_theme.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.emphasize = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = emphasize
        ? <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.74),
            const Color(0xFFEAF7F1).withValues(alpha: 0.44),
          ]
        : <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.68),
            const Color(0xFFF4F8FC).withValues(alpha: 0.40),
          ];

    final shadows = emphasize
        ? <BoxShadow>[
            BoxShadow(
              color: DashboardRuntimeTheme.buttonGlowColor.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            const BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ]
        : AppGlassTheme.shadowMd;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 22,
            borderAlpha: emphasize ? 0.70 : 0.60,
            colors: colors,
            shadows: shadows,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
