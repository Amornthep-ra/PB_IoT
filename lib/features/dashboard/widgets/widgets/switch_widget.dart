import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
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
    final stateLabel = currentValue ? onLabel : offLabel;
    final stateColors = currentValue
        ? <Color>[
            DashboardRuntimeTheme.buttonStartColor.withValues(alpha: 0.96),
            DashboardRuntimeTheme.buttonEndColor.withValues(alpha: 0.96),
          ]
        : <Color>[
            const Color(0xFFE5EBF2),
            const Color(0xFFCAD5E2),
          ];

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
                  stateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: currentValue
                        ? DashboardRuntimeTheme.buttonEndColor
                        : DashboardRuntimeTheme.mutedTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: currentValue
                      ? AppGlassTheme.accentDecoration(
                          radius: 999,
                          borderColor: Colors.transparent,
                          colors: stateColors,
                          glowColor: DashboardRuntimeTheme.buttonGlowColor,
                        )
                      : AppGlassTheme.surfaceDecoration(
                          radius: 999,
                          borderAlpha: 0.62,
                          colors: <Color>[
                            const Color(0xFFFFFFFF).withValues(alpha: 0.50),
                            const Color(0xFFF0F4F8).withValues(alpha: 0.28),
                          ],
                          shadows: const <BoxShadow>[],
                        ),
                  child: Text(
                    canWrite ? 'Tap switch to update' : 'Read only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: currentValue
                          ? Colors.white
                          : DashboardRuntimeTheme.labelTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: AppGlassTheme.surfaceDecoration(
              radius: 999,
              borderAlpha: canWrite ? 0.68 : 0.58,
              colors: <Color>[
                const Color(0xFFFFFFFF).withValues(alpha: 0.54),
                const Color(0xFFEAF2F8).withValues(alpha: 0.30),
              ],
              shadows: const <BoxShadow>[],
            ),
            child: SwitchTheme(
              data: SwitchThemeData(
                trackColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return DashboardRuntimeTheme.buttonStartColor
                        .withValues(alpha: 0.90);
                  }
                  return const Color(0xFFD6DEE7);
                }),
                thumbColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return DashboardRuntimeTheme.cardHighlightColor;
                  }
                  return const Color(0xFFF8FBFD);
                }),
                overlayColor: MaterialStateProperty.all(
                  DashboardRuntimeTheme.buttonGlowColor.withValues(alpha: 0.14),
                ),
                trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Switch(
                value: currentValue,
                onChanged: canWrite ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
