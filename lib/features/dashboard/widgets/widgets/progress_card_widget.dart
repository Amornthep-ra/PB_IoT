import 'package:flutter/material.dart';

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
          const Spacer(),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: DashboardRuntimeTheme.surfaceBorderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              DashboardRuntimeTheme.buttonEndColor,
            ),
          ),
        ],
      ),
    );
  }
}
