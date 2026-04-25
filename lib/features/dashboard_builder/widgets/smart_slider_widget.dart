import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';

class SmartSliderVisualSpec {
  const SmartSliderVisualSpec._();

  static const double valueFontSize = 12.0;
  static const double trackHeight = 8.0;
  static const double thumbSize = 16.0;
  static const double trackBottomInset = 11.0;
  static const double estimatedValueHeight = 12.0;
  static const double valueOpticalLift = 8.0;
  static const double desiredShellHeight =
      estimatedValueHeight +
      estimatedValueHeight +
      thumbSize +
      trackBottomInset;
  static const double selectionVisualHeight = desiredShellHeight;

  static double shellBottomInsetFor(double height) {
    if (height >= 156) {
      return 4.0;
    }
    if (height >= 108) {
      return 3.0;
    }
    return 2.0;
  }
}

class SmartSliderControl extends StatefulWidget {
  const SmartSliderControl({
    super.key,
    required this.item,
    required this.showValue,
    required this.enableInteraction,
    this.emitOnDrag = true,
    this.onValueChanged,
  });

  final DashboardItem item;
  final bool showValue;
  final bool enableInteraction;
  final bool emitOnDrag;
  final ValueChanged<double>? onValueChanged;

  @override
  State<SmartSliderControl> createState() => _SmartSliderControlState();
}

class _SmartSliderControlState extends State<SmartSliderControl> {
  double? _transientValue;

  double _snapToStep(double value) {
    final min = widget.item.minValue;
    final max = widget.item.maxValue;
    final step = widget.item.stepValue;
    if (step <= 0 || max <= min) {
      return value.clamp(min, max);
    }
    final clamped = value.clamp(min, max);
    final units = ((clamped - min) / step).round();
    return (min + (units * step)).clamp(min, max);
  }

  void _handleValueChanged(double value) {
    final snappedValue = _snapToStep(value);
    setState(() {
      _transientValue = snappedValue;
    });

    if (widget.emitOnDrag) {
      widget.onValueChanged?.call(snappedValue);
    }
  }

  void _handleValueCommit(double value) {
    final committedValue = _transientValue ?? _snapToStep(value);
    if (!widget.emitOnDrag) {
      widget.onValueChanged?.call(committedValue);
    }
    if (_transientValue != null) {
      setState(() {
        _transientValue = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _transientValue ?? widget.item.value;
    final normalized =
        ((displayValue - widget.item.minValue) /
                (widget.item.maxValue - widget.item.minValue == 0
                    ? 1
                    : widget.item.maxValue - widget.item.minValue))
            .clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = constraints.maxWidth < 180 ? 4.0 : 6.0;
        final trackSlotHeight = math.max(
          SmartSliderVisualSpec.trackHeight,
          SmartSliderVisualSpec.thumbSize,
        );
        final trackTop =
            constraints.maxHeight -
            SmartSliderVisualSpec.trackBottomInset -
            trackSlotHeight;
        final valueTop = math.max(
          0.0,
          ((trackTop - SmartSliderVisualSpec.estimatedValueHeight) / 2) -
              SmartSliderVisualSpec.valueOpticalLift,
        );

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: SmartSliderVisualSpec.trackBottomInset,
              child: _SliderTrack(
                value: displayValue,
                minValue: widget.item.minValue,
                maxValue: widget.item.maxValue,
                normalized: normalized,
                accentColor: widget.item.accentColor,
                horizontalInset: horizontalInset,
                trackHeight: SmartSliderVisualSpec.trackHeight,
                thumbSize: SmartSliderVisualSpec.thumbSize,
                enableInteraction: widget.enableInteraction,
                onChanged: _handleValueChanged,
                onChangeEnd: _handleValueCommit,
              ),
            ),
            if (widget.showValue)
              Positioned(
                left: 0,
                right: 0,
                top: valueTop,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      _formatValueText(
                        widget.item.copyWith(value: displayValue),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: SmartSliderVisualSpec.valueFontSize,
                        fontWeight: FontWeight.w700,
                        color: _emphasizedTextColor(widget.item.accentColor),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatValueText(DashboardItem item) {
    final key = item.dataKey?.trim();
    if (key == null || key.isEmpty) {
      return '0';
    }

    final hasWholeNumberValue = item.value % 1 == 0;
    final valueText = hasWholeNumberValue
        ? item.value.toStringAsFixed(0)
        : item.value.toStringAsFixed(1);

    return '$valueText${item.unit ?? ''}';
  }

  Color _emphasizedTextColor(Color baseColor) {
    return Color.lerp(baseColor, DashboardRuntimeTheme.headlineColor, 0.22) ??
        baseColor;
  }
}

class _SliderTrack extends StatefulWidget {
  const _SliderTrack({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.normalized,
    required this.accentColor,
    required this.horizontalInset,
    required this.trackHeight,
    required this.thumbSize,
    required this.enableInteraction,
    this.onChanged,
    this.onChangeEnd,
  });

  final double value;
  final double minValue;
  final double maxValue;
  final double normalized;
  final Color accentColor;
  final double horizontalInset;
  final double trackHeight;
  final double thumbSize;
  final bool enableInteraction;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<_SliderTrack> createState() => _SliderTrackState();
}

class _SliderTrackState extends State<_SliderTrack> {
  double? _lastInteractionValue;

  double _resolveValue({
    required double localDx,
    required double horizontalInset,
    required double usableWidth,
  }) {
    final span = widget.maxValue - widget.minValue;
    if (span == 0) {
      return widget.minValue;
    }

    final clampedX = (localDx - horizontalInset).clamp(0.0, usableWidth);
    final nextNormalized = usableWidth <= 0 ? 0.0 : (clampedX / usableWidth);
    return widget.minValue + (span * nextNormalized);
  }

  void _emitInteractionValue(double value) {
    _lastInteractionValue = value;
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: math.max(widget.trackHeight, widget.thumbSize),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolvedInset = widget.horizontalInset
              .clamp(1.0, math.max(1.0, constraints.maxWidth * 0.2))
              .toDouble();
          final usableWidth = math
              .max(0.0, constraints.maxWidth - (resolvedInset * 2))
              .toDouble();
          final clampedValue = widget.normalized.clamp(0.0, 1.0).toDouble();
          final maxThumbTravel = math
              .max(0.0, usableWidth - widget.thumbSize)
              .toDouble();
          final thumbLeft = maxThumbTravel * clampedValue;
          final fillWidth = math
              .max(widget.trackHeight, thumbLeft + (widget.thumbSize * 0.5))
              .toDouble();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.enableInteraction
                ? (details) {
                    final value = _resolveValue(
                      localDx: details.localPosition.dx,
                      horizontalInset: resolvedInset,
                      usableWidth: usableWidth,
                    );
                    _emitInteractionValue(value);
                    widget.onChangeEnd?.call(value);
                    _lastInteractionValue = null;
                  }
                : null,
            onHorizontalDragUpdate: widget.enableInteraction
                ? (details) {
                    final value = _resolveValue(
                      localDx: details.localPosition.dx,
                      horizontalInset: resolvedInset,
                      usableWidth: usableWidth,
                    );
                    _emitInteractionValue(value);
                  }
                : null,
            onHorizontalDragEnd: widget.enableInteraction
                ? (_) {
                    final value = _lastInteractionValue ?? widget.value;
                    _lastInteractionValue = null;
                    if (widget.onChangeEnd == null) {
                      return;
                    }
                    widget.onChangeEnd!(value);
                  }
                : null,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: resolvedInset,
                  right: resolvedInset,
                  child: Container(
                    height: widget.trackHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DashboardRuntimeTheme.surfaceColor,
                          Color(0xFFE7EDF4),
                        ],
                      ),
                      border: Border.all(
                        color: DashboardRuntimeTheme.surfaceBorderColor,
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: DashboardRuntimeTheme.shadowLightColor,
                          blurRadius: 6,
                          offset: Offset(-2, -2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: resolvedInset,
                  child: Container(
                    width: fillWidth,
                    height: widget.trackHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.lerp(widget.accentColor, Colors.white, 0.18)!,
                          Color.lerp(widget.accentColor, Colors.black, 0.05)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.26),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: resolvedInset + thumbLeft,
                  child: Container(
                    width: widget.thumbSize,
                    height: widget.thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(widget.accentColor, Colors.white, 0.28)!,
                          widget.accentColor,
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xBFF7FBF7),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.24),
                          blurRadius: 10,
                          spreadRadius: 0.2,
                        ),
                        const BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
