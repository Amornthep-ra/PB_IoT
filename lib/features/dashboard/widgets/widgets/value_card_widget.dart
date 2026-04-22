import 'package:flutter/material.dart';

import '../../models/dashboard_widget_model.dart';
import '../../models/device_snapshot_model.dart';
import '../../services/widget_binding_resolver.dart';
import '../dashboard_card.dart';
import '../dashboard_runtime_theme.dart';

class ValueCardWidget extends StatelessWidget {
  const ValueCardWidget({
    super.key,
    required this.widget,
    required this.snapshot,
  });

  final DashboardWidgetModel widget;
  final DeviceSnapshotModel snapshot;

  @override
  Widget build(BuildContext context) {
    final value = WidgetBindingResolver.resolveReadValue(
      snapshot: snapshot,
      binding: widget.binding,
    );
    final configuredSuffix = widget.options['suffix']?.toString() ?? '';
    final suffix = configuredSuffix.isNotEmpty
        ? configuredSuffix
        : WidgetBindingResolver.resolveUnit(
            snapshot: snapshot,
            binding: widget.binding,
          );
    final fallbackText = widget.options['fallbackText']?.toString() ?? '--';
    final subtitle = widget.options['subtitle']?.toString();

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? 'Value',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DashboardRuntimeTheme.labelTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value == null ? fallbackText : '$value$suffix',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: DashboardRuntimeTheme.headlineColor,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: DashboardRuntimeTheme.mutedTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
