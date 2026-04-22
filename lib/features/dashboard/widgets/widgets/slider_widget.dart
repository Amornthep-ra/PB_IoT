import 'package:flutter/material.dart';

import '../../models/dashboard_widget_model.dart';
import '../../models/device_snapshot_model.dart';
import '../../services/widget_binding_resolver.dart';
import '../dashboard_card.dart';
import '../dashboard_runtime_theme.dart';

class SliderWidget extends StatefulWidget {
  const SliderWidget({
    super.key,
    required this.widget,
    required this.snapshot,
    this.onChanged,
  });

  final DashboardWidgetModel widget;
  final DeviceSnapshotModel snapshot;
  final ValueChanged<double>? onChanged;

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final currentValue = WidgetBindingResolver.resolveNumber(
      snapshot: widget.snapshot,
      binding: widget.widget.binding,
    );
    final min = (widget.widget.options['min'] as num?)?.toDouble() ?? 0.0;
    final max = (widget.widget.options['max'] as num?)?.toDouble() ?? 100.0;
    final displayValue = (_dragValue ?? currentValue).clamp(min, max).toDouble();
    final canWrite = widget.widget.binding?.pin?.trim().isNotEmpty == true ||
        widget.widget.binding?.writeKey?.trim().isNotEmpty == true;
    final sendBehavior =
        widget.widget.options['sendBehavior']?.toString().trim().toLowerCase() ??
            'on_release';
    final emitOnDrag = sendBehavior == 'on_drag';

    return DashboardCard(
      emphasize: canWrite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.widget.title ?? 'Slider',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardRuntimeTheme.headlineColor,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DashboardRuntimeTheme.buttonEndColor,
              inactiveTrackColor: DashboardRuntimeTheme.surfaceBorderColor,
              thumbColor: DashboardRuntimeTheme.cardHighlightColor,
              overlayColor: DashboardRuntimeTheme.buttonGlowColor.withValues(
                alpha: 0.16,
              ),
              trackHeight: 7,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: displayValue,
              onChanged: canWrite
                  ? (value) {
                      if (emitOnDrag) {
                        widget.onChanged?.call(value);
                        return;
                      }
                      setState(() {
                        _dragValue = value;
                      });
                    }
                  : null,
              onChangeEnd: canWrite
                  ? (value) {
                      if (emitOnDrag) {
                        return;
                      }
                      widget.onChanged?.call(value);
                      if (_dragValue != null) {
                        setState(() {
                          _dragValue = null;
                        });
                      }
                    }
                  : null,
              min: min,
              max: max,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              displayValue.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DashboardRuntimeTheme.labelTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
