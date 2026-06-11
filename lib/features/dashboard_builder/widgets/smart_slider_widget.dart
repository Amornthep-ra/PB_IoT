import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../models/dashboard_theme_preset.dart';
import 'dashboard_text_contrast.dart';
import 'dashboard_value_formatter.dart';

class SmartSliderVisualSpec {
  const SmartSliderVisualSpec._();

  static const double valueFontSize = 16.0;
  static const double trackHeight = 10.0;
  static const double thumbSize = 24.0;
  static const double estimatedValueHeight = 18.0;
  static const double labelTrackGap = 8.0;
  static const double compactLabelTrackGap = 4.0;
  static const double trackTouchHeight = 40.0;
  static const double compactTrackTouchHeight = thumbSize;
  static const double desiredShellHeight =
      estimatedValueHeight + labelTrackGap + trackTouchHeight;
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
    this.themePreset,
    this.emitOnDrag = true,
    this.trackGradientColors,
    this.trackBorderColor,
    this.trackShadowColor,
    this.onValueChanged,
  });

  final DashboardItem item;
  final bool showValue;
  final bool enableInteraction;
  final DashboardThemePreset? themePreset;
  final bool emitOnDrag;
  final List<Color>? trackGradientColors;
  final Color? trackBorderColor;
  final Color? trackShadowColor;
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

  Color _resolvedValueTextColor({required bool hasBoundDataKey}) {
    final fallback =
        widget.themePreset?.headlineColor ??
        DashboardRuntimeTheme.headlineColor;

    if (!hasBoundDataKey) {
      return fallback.withValues(alpha: 0.86);
    }

    final background =
        widget.themePreset?.surfaceColor ?? DashboardRuntimeTheme.cardColor;

    return DashboardTextContrast.readableTextColor(
      preferred: _emphasizedTextColor(widget.item.accentColor),
      background: background,
      fallback: fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _transientValue ?? widget.item.value;
    final hasBoundDataKey = _hasBoundDataKey(widget.item);
    final displayText = formatDashboardDisplayValue(
      widget.item.copyWith(value: displayValue),
    );
    final normalized =
        ((displayValue - widget.item.minValue) /
                (widget.item.maxValue - widget.item.minValue == 0
                    ? 1
                    : widget.item.maxValue - widget.item.minValue))
            .clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = constraints.maxWidth < 180 ? 4.0 : 6.0;
        final estimatedValueWidth =
            displayText.length * SmartSliderVisualSpec.valueFontSize * 0.72;
        final regularHeightForValue =
            SmartSliderVisualSpec.estimatedValueHeight +
            SmartSliderVisualSpec.labelTrackGap +
            SmartSliderVisualSpec.trackTouchHeight;
        final compactHeightForValue =
            SmartSliderVisualSpec.estimatedValueHeight +
            SmartSliderVisualSpec.compactLabelTrackGap +
            SmartSliderVisualSpec.compactTrackTouchHeight;
        final canUseRegularValueLayout =
            constraints.maxHeight >= regularHeightForValue;
        final canUseCompactValueLayout =
            constraints.maxHeight >= compactHeightForValue;
        final canShowValue =
            widget.showValue &&
            (canUseRegularValueLayout || canUseCompactValueLayout) &&
            constraints.maxWidth >= math.max(72.0, estimatedValueWidth + 18.0);
        final resolvedLabelTrackGap = canUseRegularValueLayout
            ? SmartSliderVisualSpec.labelTrackGap
            : SmartSliderVisualSpec.compactLabelTrackGap;
        final resolvedTrackTouchHeight = canShowValue
            ? math.max(
                SmartSliderVisualSpec.compactTrackTouchHeight,
                math.min(
                  SmartSliderVisualSpec.trackTouchHeight,
                  constraints.maxHeight -
                      SmartSliderVisualSpec.estimatedValueHeight -
                      resolvedLabelTrackGap,
                ),
              )
            : math.min(
                SmartSliderVisualSpec.trackTouchHeight,
                constraints.maxHeight,
              );

        final track = SizedBox(
          height: resolvedTrackTouchHeight,
          child: _SliderTrack(
            value: displayValue,
            minValue: widget.item.minValue,
            maxValue: widget.item.maxValue,
            normalized: normalized,
            accentColor: widget.item.accentColor,
            horizontalInset: horizontalInset,
            trackHeight: SmartSliderVisualSpec.trackHeight,
            thumbSize: SmartSliderVisualSpec.thumbSize,
            trackGradientColors: widget.trackGradientColors,
            trackBorderColor: widget.trackBorderColor,
            trackShadowColor: widget.trackShadowColor,
            touchHeight: resolvedTrackTouchHeight,
            enableInteraction: widget.enableInteraction,
            onChanged: _handleValueChanged,
            onChangeEnd: _handleValueCommit,
          ),
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canShowValue)
              SizedBox(
                height: SmartSliderVisualSpec.estimatedValueHeight,
                child: Align(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: hasBoundDataKey
                            ? SmartSliderVisualSpec.valueFontSize
                            : SmartSliderVisualSpec.valueFontSize + 1,
                        fontWeight: hasBoundDataKey
                            ? FontWeight.w700
                            : FontWeight.w800,
                        color: _resolvedValueTextColor(
                          hasBoundDataKey: hasBoundDataKey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (canShowValue) SizedBox(height: resolvedLabelTrackGap),
            track,
          ],
        );
      },
    );
  }

  bool _hasBoundDataKey(DashboardItem item) {
    final key = item.dataKey?.trim();
    return key != null && key.isNotEmpty;
  }

  Color _emphasizedTextColor(Color baseColor) {
    final headlineColor =
        widget.themePreset?.headlineColor ??
        DashboardRuntimeTheme.headlineColor;

    return Color.lerp(baseColor, headlineColor, 0.22) ?? baseColor;
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
    this.trackGradientColors,
    this.trackBorderColor,
    this.trackShadowColor,
    required this.touchHeight,
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
  final List<Color>? trackGradientColors;
  final Color? trackBorderColor;
  final Color? trackShadowColor;
  final double touchHeight;
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
      height: math.max(
        widget.touchHeight,
        math.max(widget.trackHeight, widget.thumbSize),
      ),
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
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            widget.trackGradientColors ??
                            const [
                              DashboardRuntimeTheme.surfaceColor,
                              Color(0xFFE7EDF4),
                            ],
                      ),
                      border: Border.all(
                        color:
                            widget.trackBorderColor ??
                            DashboardRuntimeTheme.surfaceBorderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              widget.trackShadowColor ??
                              DashboardRuntimeTheme.shadowLightColor,
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
