import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/dashboard_widget_model.dart';
import '../../models/device_snapshot_model.dart';
import '../../services/widget_binding_resolver.dart';
import '../dashboard_card.dart';
import '../dashboard_runtime_theme.dart';

class ProgressCardWidget extends StatelessWidget {
  const ProgressCardWidget({
    super.key,
    required this.widget,
    required this.snapshot,
  });

  final DashboardWidgetModel widget;
  final DeviceSnapshotModel snapshot;

  @override
  Widget build(BuildContext context) {
    final rawValue = WidgetBindingResolver.resolveNumber(
      snapshot: snapshot,
      binding: widget.binding,
    );
    final progress = (rawValue / 100).clamp(0, 1).toDouble();
    final configuredSuffix = widget.options['suffix']?.toString() ?? '';
    final suffix = configuredSuffix.isNotEmpty
        ? configuredSuffix
        : WidgetBindingResolver.resolveUnit(
            snapshot: snapshot,
            binding: widget.binding,
            fallback: '%',
          );
    final clampedPercent = (progress * 100).round();

    return DashboardCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? 'Progress',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DashboardRuntimeTheme.labelTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${rawValue.toStringAsFixed(0)}$suffix',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: DashboardRuntimeTheme.headlineColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: DashboardRuntimeTheme.labelTextColor.withValues(
                    alpha: 0.86,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 999,
                  borderAlpha: 0.66,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.54),
                    const Color(0xFFEAF7F1).withValues(alpha: 0.30),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: Text(
                  '$clampedPercent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: DashboardRuntimeTheme.headlineColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: AppGlassTheme.surfaceDecoration(
                      radius: 999,
                      borderAlpha: 0.52,
                      colors: <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.42),
                        const Color(0xFFE6EEF6).withValues(alpha: 0.26),
                      ],
                      shadows: const <BoxShadow>[],
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: DecoratedBox(
                      decoration: AppGlassTheme.accentDecoration(
                        radius: 999,
                        borderColor: Colors.transparent,
                        colors: <Color>[
                          DashboardRuntimeTheme.buttonStartColor,
                          DashboardRuntimeTheme.buttonEndColor,
                        ],
                        glowColor: DashboardRuntimeTheme.buttonGlowColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
