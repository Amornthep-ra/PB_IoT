import 'dart:math' as math;

import 'package:flutter/material.dart';

class WidgetShellLayoutSpec {
  const WidgetShellLayoutSpec({
    required this.shellTopInset,
    required this.shellBottomInset,
    required this.titleLift,
  });

  final double shellTopInset;
  final double shellBottomInset;
  final double titleLift;

  double get titleTop => shellTopInset - titleLift;
}

class SliderVisualGeometry {
  const SliderVisualGeometry({
    required this.bodyRect,
    required this.cornerRadius,
    required this.valueRect,
    required this.trackRect,
  });

  final Rect bodyRect;
  final double cornerRadius;
  final Rect valueRect;
  final Rect trackRect;
}

enum ButtonSizeClass { compact, medium, large }

class ButtonLayoutMetrics {
  const ButtonLayoutMetrics({
    required this.sizeClass,
    required this.shellRadius,
    required this.shellPadding,
    required this.innerInset,
    required this.borderWidth,
    required this.baseShadowBlur,
    required this.iconBaseSize,
    required this.iconMinSize,
    required this.iconMaxSize,
    required this.statusBaseFontSize,
    required this.statusMinFontSize,
    required this.statusMaxFontSize,
    required this.statusLetterSpacing,
    required this.controlBorderWidth,
    required this.controlGapFactor,
  });

  final ButtonSizeClass sizeClass;
  final double shellRadius;
  final double shellPadding;
  final double innerInset;
  final double borderWidth;
  final double baseShadowBlur;
  final double iconBaseSize;
  final double iconMinSize;
  final double iconMaxSize;
  final double statusBaseFontSize;
  final double statusMinFontSize;
  final double statusMaxFontSize;
  final double statusLetterSpacing;
  final double controlBorderWidth;
  final double controlGapFactor;

  factory ButtonLayoutMetrics.resolve(double width, double height) {
    final shortestSide = width < height ? width : height;
    final area = width * height;

    if (shortestSide >= 156 || area >= 36000) {
      return ButtonLayoutMetrics(
        sizeClass: ButtonSizeClass.large,
        shellRadius: width * 0.12,
        shellPadding: 7,
        innerInset: 4,
        borderWidth: (width * 0.0045).clamp(1.1, 1.7).toDouble(),
        baseShadowBlur: width * 0.1,
        iconBaseSize: 24,
        iconMinSize: 20,
        iconMaxSize: 96,
        statusBaseFontSize: 14,
        statusMinFontSize: 11,
        statusMaxFontSize: 15,
        statusLetterSpacing: 0.55,
        controlBorderWidth: 2.4,
        controlGapFactor: 0.05,
      );
    }

    if (shortestSide >= 108 || area >= 18000) {
      return ButtonLayoutMetrics(
        sizeClass: ButtonSizeClass.medium,
        shellRadius: width * 0.12,
        shellPadding: 6.5,
        innerInset: 4,
        borderWidth: (width * 0.0045).clamp(1.0, 1.6).toDouble(),
        baseShadowBlur: width * 0.08,
        iconBaseSize: 22,
        iconMinSize: 18,
        iconMaxSize: 24,
        statusBaseFontSize: 13,
        statusMinFontSize: 10,
        statusMaxFontSize: 14,
        statusLetterSpacing: 0.4,
        controlBorderWidth: 2.0,
        controlGapFactor: 0.045,
      );
    }

    return ButtonLayoutMetrics(
      sizeClass: ButtonSizeClass.compact,
      shellRadius: width * 0.12,
      shellPadding: 6,
      innerInset: 4,
      borderWidth: (width * 0.0042).clamp(1.0, 1.4).toDouble(),
      baseShadowBlur: width * 0.07,
      iconBaseSize: 20,
      iconMinSize: 14,
      iconMaxSize: 22,
      statusBaseFontSize: 12,
      statusMinFontSize: 9,
      statusMaxFontSize: 12,
      statusLetterSpacing: 0.2,
      controlBorderWidth: 1.8,
      controlGapFactor: 0.04,
    );
  }
}

class ButtonShellGeometry {
  const ButtonShellGeometry({
    required this.metrics,
    required this.shellRect,
    required this.controlRect,
    required this.shellCornerRadius,
    required this.controlCornerRadius,
    required this.iconSize,
  });

  final ButtonLayoutMetrics metrics;
  final Rect shellRect;
  final Rect controlRect;
  final double shellCornerRadius;
  final double controlCornerRadius;
  final double iconSize;
}

ButtonShellGeometry resolveButtonShellGeometry({
  required double width,
  required double height,
}) {
  final metrics = ButtonLayoutMetrics.resolve(width, height);
  final availableHeight = (height - (metrics.shellPadding * 2))
      .clamp(0.0, double.infinity)
      .toDouble();
  final availableWidth = (width - (metrics.shellPadding * 2))
      .clamp(0.0, double.infinity)
      .toDouble();
  final controlWidth = (availableWidth - (metrics.innerInset * 2))
      .clamp(0.0, availableWidth)
      .toDouble();
  final controlHeight = (availableHeight - (metrics.innerInset * 2))
      .clamp(0.0, availableHeight)
      .toDouble();
  final controlShortSide = math.min(controlWidth, controlHeight);
  final controlCornerRadius = controlShortSide / 2;
  final shellCornerRadius =
      controlCornerRadius + metrics.innerInset + metrics.shellPadding;
  final safeContentHeight = math.max(0.0, controlHeight - 1.0);
  final maxIconWidth = controlWidth - 16;
  final maxIconHeight = safeContentHeight - 12;
  final baseIconSize = metrics.sizeClass == ButtonSizeClass.large
      ? math
            .max(metrics.iconBaseSize, math.min(controlShortSide * 0.34, 96.0))
            .clamp(metrics.iconMinSize, metrics.iconMaxSize)
            .toDouble()
      : metrics.iconBaseSize
            .clamp(metrics.iconMinSize, metrics.iconMaxSize)
            .toDouble();
  final iconSize = math
      .max(0.0, math.min(baseIconSize, math.min(maxIconWidth, maxIconHeight)))
      .toDouble();

  return ButtonShellGeometry(
    metrics: metrics,
    shellRect: Rect.fromLTWH(0, 0, width, height),
    controlRect: Rect.fromLTWH(
      metrics.shellPadding + metrics.innerInset,
      metrics.shellPadding + metrics.innerInset,
      controlWidth,
      controlHeight,
    ),
    shellCornerRadius: shellCornerRadius,
    controlCornerRadius: controlCornerRadius,
    iconSize: iconSize,
  );
}

WidgetShellLayoutSpec buildButtonShellLayout({
  required double width,
  required double height,
}) {
  final shortestSide = math.min(width, height);
  final area = width * height;
  final titleLift = shortestSide >= 156 || area >= 36000
      ? 18.0
      : shortestSide >= 108 || area >= 18000
      ? 16.0
      : 14.0;

  return WidgetShellLayoutSpec(
    shellTopInset: 0,
    shellBottomInset: 0,
    titleLift: titleLift,
  );
}

WidgetShellLayoutSpec buildSliderShellLayout({
  required double width,
  required double height,
  required double desiredShellHeight,
  required double Function(double height) shellBottomInsetFor,
}) {
  final titleLift = height >= 156
      ? 18.0
      : height >= 108
      ? 16.0
      : 14.0;
  final shellBottomInset = shellBottomInsetFor(height);

  return WidgetShellLayoutSpec(
    shellTopInset: 0,
    shellBottomInset: shellBottomInset,
    titleLift: titleLift,
  );
}

SliderVisualGeometry resolveSliderVisualGeometry({
  required double width,
  required double height,
  required double estimatedValueHeight,
  required double labelTrackGap,
  required double compactLabelTrackGap,
  required double trackTouchHeight,
  required double compactTrackTouchHeight,
}) {
  final shellPadding = width < 120 || height < 52
      ? 4.0
      : width >= 180 && height >= 84
      ? 6.0
      : 5.0;
  final availableWidth = math.max(0.0, width);
  final availableHeight = math.max(0.0, height);
  final canUseRegularValueLayout =
      availableHeight >=
      estimatedValueHeight + labelTrackGap + trackTouchHeight;
  final canUseCompactValueLayout =
      availableHeight >=
      estimatedValueHeight + compactLabelTrackGap + compactTrackTouchHeight;
  final canShowValue =
      availableWidth >= 72.0 &&
      (canUseRegularValueLayout || canUseCompactValueLayout);
  final resolvedLabelTrackGap = canUseRegularValueLayout
      ? labelTrackGap
      : compactLabelTrackGap;
  final resolvedTrackTouchHeight = canShowValue
      ? math.max(
          compactTrackTouchHeight,
          math.min(
            trackTouchHeight,
            availableHeight - estimatedValueHeight - resolvedLabelTrackGap,
          ),
        )
      : math.min(trackTouchHeight, availableHeight);
  final contentHeight = canShowValue
      ? estimatedValueHeight + resolvedLabelTrackGap + resolvedTrackTouchHeight
      : resolvedTrackTouchHeight;
  final bodyHeight = math
      .min(availableHeight, contentHeight + (shellPadding * 2))
      .clamp(0.0, availableHeight)
      .toDouble();
  final bodyTop = (availableHeight - bodyHeight) / 2;
  final bodyRect = Rect.fromLTWH(0, bodyTop, availableWidth, bodyHeight);
  final contentTop = bodyTop + math.max(0.0, (bodyHeight - contentHeight) / 2);
  final horizontalInset = availableWidth < 180 ? 6.0 : 8.0;
  final valueRect = canShowValue
      ? Rect.fromLTWH(
          horizontalInset,
          contentTop,
          math.max(0.0, availableWidth - (horizontalInset * 2)),
          estimatedValueHeight,
        )
      : Rect.zero;
  final trackTop = canShowValue
      ? contentTop + estimatedValueHeight + resolvedLabelTrackGap
      : contentTop;
  final trackRect = Rect.fromLTWH(
    horizontalInset,
    trackTop,
    math.max(0.0, availableWidth - (horizontalInset * 2)),
    resolvedTrackTouchHeight,
  );

  return SliderVisualGeometry(
    bodyRect: bodyRect,
    cornerRadius: math.max(0.0, (bodyHeight / 2) - 2.0),
    valueRect: valueRect,
    trackRect: trackRect,
  );
}
