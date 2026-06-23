import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../models/dashboard_theme_preset.dart';
import 'dashboard_text_contrast.dart';
import 'dashboard_value_formatter.dart';

class SmartSliderVisualSpec {
  const SmartSliderVisualSpec._();

  static const double compactValueFontSize = 14.0;
  static const double valueFontSize = 16.0;
  static const double roomyValueFontSize = 17.0;
  static const double unboundValueFontBoost = 0.5;

  static const double compactTrackHeight = 6.0;
  static const double trackHeight = 9.0;
  static const double roomyTrackHeight = 10.0;

  static const double thumbSize = 22.0;

  static const double estimatedValueHeight = 18.0;
  static const double labelTrackGap = 2.0;
  static const double compactLabelTrackGap = 1.0;
  static const double trackTouchHeight = 28.0;
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

  double _resolvedValueFontSize(BoxConstraints constraints) {
    if (constraints.maxHeight < 52 || constraints.maxWidth < 120) {
      return SmartSliderVisualSpec.compactValueFontSize;
    }

    if (constraints.maxHeight >= 84 && constraints.maxWidth >= 180) {
      return SmartSliderVisualSpec.roomyValueFontSize;
    }

    return SmartSliderVisualSpec.valueFontSize;
  }

  double _resolvedTrackHeight(BoxConstraints constraints) {
    if (constraints.maxHeight < 52 || constraints.maxWidth < 120) {
      return SmartSliderVisualSpec.compactTrackHeight;
    }

    if (constraints.maxHeight >= 84 && constraints.maxWidth >= 180) {
      return SmartSliderVisualSpec.roomyTrackHeight;
    }

    return SmartSliderVisualSpec.trackHeight;
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _transientValue ?? widget.item.value;
    final hasBoundDataKey = _hasBoundDataKey(widget.item);
    final isMutedState = !hasBoundDataKey || !widget.enableInteraction;
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
        final horizontalInset = constraints.maxWidth < 180 ? 6.0 : 8.0;
        final valueFontSize = _resolvedValueFontSize(constraints);
        final trackHeight = _resolvedTrackHeight(constraints);
        final estimatedValueWidth = displayText.length * valueFontSize * 0.72;
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
            trackHeight: trackHeight,
            thumbSize: SmartSliderVisualSpec.thumbSize,
            trackGradientColors: widget.trackGradientColors,
            trackBorderColor: widget.trackBorderColor,
            trackShadowColor: widget.trackShadowColor,
            touchHeight: resolvedTrackTouchHeight,
            enableInteraction: widget.enableInteraction,
            muted: isMutedState,
            onChanged: _handleValueChanged,
            onChangeEnd: _handleValueCommit,
          ),
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canShowValue)
              Transform.translate(
                offset: const Offset(0, 1),
                child: SizedBox(
                  height: SmartSliderVisualSpec.estimatedValueHeight,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: hasBoundDataKey
                              ? valueFontSize
                              : valueFontSize +
                                    SmartSliderVisualSpec.unboundValueFontBoost,
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
    required this.muted,
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
  final bool muted;
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
          final trackBaseColors = widget.muted
              ? const [Color(0xFFEAF0F6), Color(0xFFD2DDE8)]
              : widget.trackGradientColors ??
                    const [Color(0xFFF3F8FD), Color(0xFFC7D4E2)];
          final trackBorderColor = widget.muted
              ? const Color(0xFFC9D3DF)
              : widget.trackBorderColor ?? const Color(0xFFB8C7D6);
          final trackShadowColor = widget.muted
              ? const Color(0x14000000)
              : widget.trackShadowColor ?? const Color(0x18000000);
          final fillStart = widget.muted
              ? const Color(0xFFBFD8E8)
              : Color.lerp(widget.accentColor, Colors.white, 0.03)!;
          final fillEnd = widget.muted
              ? const Color(0xFFAFC6D8)
              : Color.lerp(widget.accentColor, Colors.black, 0.20)!;
          final thumbStart = widget.muted
              ? const Color(0xFFE2E8EF)
              : Color.lerp(widget.accentColor, Colors.white, 0.14)!;
          final thumbEnd = widget.muted
              ? const Color(0xFFCAD4DF)
              : Color.lerp(widget.accentColor, Colors.black, 0.08)!;
          final thumbBorderColor = widget.muted
              ? const Color(0xCCF4F7FA)
              : const Color(0xE8FFFFFF);
          final thumbGlowColor = widget.muted
              ? const Color(0x14000000)
              : widget.accentColor.withValues(alpha: 0.26);
          final fillGlowColor = widget.muted
              ? const Color(0x0A000000)
              : widget.accentColor.withValues(alpha: 0.24);

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
                        colors: trackBaseColors,
                      ),
                      border: Border.all(color: trackBorderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: trackShadowColor,
                          blurRadius: widget.muted ? 3 : 5,
                          offset: const Offset(0, 1),
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
                        colors: [fillStart, fillEnd],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: fillGlowColor,
                          blurRadius: widget.muted ? 4 : 7,
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
                        colors: [thumbStart, thumbEnd],
                      ),
                      border: Border.all(color: thumbBorderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: thumbGlowColor,
                          blurRadius: widget.muted ? 4 : 8,
                          spreadRadius: widget.muted ? 0 : 0.1,
                        ),
                        BoxShadow(
                          color: widget.muted
                              ? const Color(0x0D000000)
                              : const Color(0x29000000),
                          blurRadius: widget.muted ? 3 : 5,
                          offset: const Offset(0, 2),
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
