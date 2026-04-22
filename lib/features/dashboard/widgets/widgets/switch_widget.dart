import 'package:flutter/material.dart';

import '../../models/dashboard_widget_model.dart';
import '../../models/device_snapshot_model.dart';
import '../../services/widget_binding_resolver.dart';
import '../dashboard_card.dart';
import '../dashboard_runtime_theme.dart';

class SwitchWidget extends StatelessWidget {
  const SwitchWidget({
    super.key,
    required this.widget,
    required this.snapshot,
    this.onChanged,
  });

  final DashboardWidgetModel widget;
  final DeviceSnapshotModel snapshot;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = WidgetBindingResolver.resolveBool(
      snapshot: snapshot,
      binding: widget.binding,
    );
    final onLabel = widget.options['onLabel']?.toString() ?? 'ON';
    final offLabel = widget.options['offLabel']?.toString() ?? 'OFF';
    final canWrite = widget.binding?.pin?.trim().isNotEmpty == true ||
        widget.binding?.writeKey?.trim().isNotEmpty == true;

    return DashboardCard(
      emphasize: currentValue,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? 'Switch',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DashboardRuntimeTheme.headlineColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentValue ? onLabel : offLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: currentValue
                        ? DashboardRuntimeTheme.buttonEndColor
                        : DashboardRuntimeTheme.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          SwitchTheme(
            data: SwitchThemeData(
              trackColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return DashboardRuntimeTheme.buttonStartColor;
                }
                return DashboardRuntimeTheme.surfaceBorderColor;
              }),
              thumbColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return DashboardRuntimeTheme.cardHighlightColor;
                }
                return DashboardRuntimeTheme.surfaceColor;
              }),
              trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: Switch(
              value: currentValue,
              onChanged: canWrite ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
