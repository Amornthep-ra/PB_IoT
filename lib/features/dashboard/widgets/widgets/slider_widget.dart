import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
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
    final progress = max <= min
        ? 0.0
        : ((displayValue - min) / (max - min)).clamp(0.0, 1.0).toDouble();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 999,
                  borderAlpha: 0.62,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.52),
                    const Color(0xFFEAF2F8).withValues(alpha: 0.30),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: Text(
                  emitOnDrag ? 'Live update' : 'Release to send',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: canWrite
                        ? DashboardRuntimeTheme.labelTextColor
                        : DashboardRuntimeTheme.mutedTextColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: AppGlassTheme.accentDecoration(
                  radius: 999,
                  borderColor: Colors.transparent,
                  colors: <Color>[
                    DashboardRuntimeTheme.buttonStartColor.withValues(alpha: 0.96),
                    DashboardRuntimeTheme.buttonEndColor.withValues(alpha: 0.96),
                  ],
                  glowColor: DashboardRuntimeTheme.buttonGlowColor,
                ),
                child: Text(
                  displayValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: AppGlassTheme.surfaceDecoration(
              radius: 20,
              borderAlpha: 0.60,
              colors: <Color>[
                const Color(0xFFFFFFFF).withValues(alpha: 0.48),
                const Color(0xFFEAF2F8).withValues(alpha: 0.28),
              ],
              shadows: const <BoxShadow>[],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 10,
                          decoration: AppGlassTheme.surfaceDecoration(
                            radius: 999,
                            borderAlpha: 0.50,
                            colors: <Color>[
                              const Color(0xFFFFFFFF).withValues(alpha: 0.38),
                              const Color(0xFFDCE6F0).withValues(alpha: 0.22),
                            ],
                            shadows: const <BoxShadow>[],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 10,
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
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        disabledActiveTrackColor: Colors.transparent,
                        disabledInactiveTrackColor: Colors.transparent,
                        thumbColor: DashboardRuntimeTheme.cardHighlightColor,
                        disabledThumbColor: const Color(0xFFF8FBFD),
                        overlayColor: DashboardRuntimeTheme.buttonGlowColor
                            .withValues(alpha: 0.16),
                        trackHeight: 18,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                          disabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 18,
                        ),
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
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      Text(
                        min.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DashboardRuntimeTheme.mutedTextColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        max.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DashboardRuntimeTheme.mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!canWrite) ...[
            const SizedBox(height: 8),
            Text(
              'Read only',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: DashboardRuntimeTheme.mutedTextColor.withValues(
                  alpha: 0.86,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
