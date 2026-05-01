import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';

enum _ButtonSizeClass { compact, medium, large }

class _ButtonLayoutMetrics {
  const _ButtonLayoutMetrics({
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

  final _ButtonSizeClass sizeClass;
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

  factory _ButtonLayoutMetrics.resolve(double width, double height) {
    final shortestSide = width < height ? width : height;
    final area = width * height;

    if (shortestSide >= 156 || area >= 36000) {
      return _ButtonLayoutMetrics(
        sizeClass: _ButtonSizeClass.large,
        shellRadius: width * 0.12,
        shellPadding: 7,
        innerInset: 4,
        borderWidth: (width * 0.0045).clamp(1.1, 1.7).toDouble(),
        baseShadowBlur: width * 0.1,
        iconBaseSize: 24,
        iconMinSize: 20,
        iconMaxSize: 26,
        statusBaseFontSize: 14,
        statusMinFontSize: 11,
        statusMaxFontSize: 15,
        statusLetterSpacing: 0.55,
        controlBorderWidth: 2.4,
        controlGapFactor: 0.05,
      );
    }

    if (shortestSide >= 108 || area >= 18000) {
      return _ButtonLayoutMetrics(
        sizeClass: _ButtonSizeClass.medium,
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

    return _ButtonLayoutMetrics(
      sizeClass: _ButtonSizeClass.compact,
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

class SmartActionButton extends StatefulWidget {
  const SmartActionButton({
    super.key,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.onPressStart,
    this.onPressEnd,
    this.isMomentary = false,
    this.enableInteraction = true,
    this.shellBaseColor,
    this.innerBaseColor,
    this.shellBorderColor,
    this.shellBorderWidth,
    this.glowColor,
    this.glowStrength,
    this.glowBlur,
  });

  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;
  final bool isMomentary;
  final bool enableInteraction;
  final Color? shellBaseColor;
  final Color? innerBaseColor;
  final Color? shellBorderColor;
  final double? shellBorderWidth;
  final Color? glowColor;
  final double? glowStrength;
  final double? glowBlur;

  @override
  State<SmartActionButton> createState() => _SmartActionButtonState();
}

class _SmartActionButtonState extends State<SmartActionButton> {
  late bool _isActive;
  bool _isPressed = false;

  Widget _buildPowerIcon({
    required double size,
    required Color color,
    required List<Shadow> shadows,
    double yOffsetFactor = 0.08,
  }) {
    // The Material icon glyph sits optically low inside its box on some sizes,
    // so nudge it slightly upward to keep it visually centered in the circle.
    return Transform.translate(
      offset: Offset(0, -(size * yOffsetFactor)),
      child: Icon(
        Icons.power_settings_new_rounded,
        size: size,
        color: color,
        shadows: shadows,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isActive = widget.isActive;
  }

  @override
  void didUpdateWidget(covariant SmartActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _isActive = widget.isActive;
    }
  }

  void _handleTap() {
    widget.onTap();
  }

  void _handlePressStart() {
    if (!widget.isMomentary) {
      return;
    }
    widget.onPressStart?.call();
  }

  void _handlePressEnd() {
    if (!widget.isMomentary) {
      return;
    }
    widget.onPressEnd?.call();
  }

  void _setPressed(bool value) {
    if (!mounted || _isPressed == value) {
      return;
    }

    void applyPressedState() {
      if (!mounted || _isPressed == value) {
        return;
      }
      setState(() {
        _isPressed = value;
      });
    }

    try {
      applyPressedState();
    } on FlutterError {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        applyPressedState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final layout = _ButtonLayoutMetrics.resolve(width, height);
        final availableHeight = (height - (layout.shellPadding * 2))
            .clamp(0.0, double.infinity)
            .toDouble();
        final availableWidth = (width - (layout.shellPadding * 2))
            .clamp(0.0, double.infinity)
            .toDouble();
        final controlAreaHeight = availableHeight;
        final controlWidth = (availableWidth - (layout.innerInset * 2))
            .clamp(0.0, availableWidth)
            .toDouble();
        final controlHeight = (controlAreaHeight - (layout.innerInset * 2))
            .clamp(0.0, controlAreaHeight)
            .toDouble();
        final controlShortSide = controlWidth < controlHeight
            ? controlWidth
            : controlHeight;
        final controlCornerRadius = controlShortSide / 2;
        final shellCornerRadius =
            controlCornerRadius + layout.innerInset + layout.shellPadding;
        final canRenderControl = controlWidth >= 12 && controlHeight >= 12;
        final onColor = widget.activeColor;
        final offColor = widget.inactiveColor;
        final currentAccent = _isActive ? onColor : offColor;
        final surfaceColor =
            widget.shellBaseColor ??
            (_isActive
                ? DashboardRuntimeTheme.cardColor
                : DashboardRuntimeTheme.surfaceColor);
        final controlSurfaceColor =
            widget.innerBaseColor ?? DashboardRuntimeTheme.cardHighlightColor;
        final resolvedGlowColor = widget.glowColor ?? currentAccent;
        final resolvedGlowStrength = (widget.glowStrength ?? 0.12)
            .clamp(0.0, 0.35)
            .toDouble();
        final resolvedGlowBlur = (widget.glowBlur ?? 18.0)
            .clamp(0.0, 40.0)
            .toDouble();
        final hasGlow = resolvedGlowStrength > 0 && resolvedGlowBlur > 0;
        final compactGlowBoost = layout.sizeClass == _ButtonSizeClass.compact
            ? 1.2
            : 1.0;
        final shellGlowAlpha = (resolvedGlowStrength * compactGlowBoost)
            .clamp(0.0, 0.42)
            .toDouble();
        final innerGlowAlpha = (resolvedGlowStrength * 0.72 * compactGlowBoost)
            .clamp(0.0, 0.30)
            .toDouble();
        final borderColor = _isActive
            ? onColor.withValues(alpha: 0.26)
            : offColor.withValues(alpha: 0.22);
        final resolvedShellBorderColor = widget.shellBorderColor ?? borderColor;
        final resolvedShellBorderWidth =
            widget.shellBorderWidth ?? layout.borderWidth;
        final statusText = _isActive ? 'ON' : 'OFF';

        final controlWidget = canRenderControl
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: controlWidth,
                height: controlHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(controlCornerRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      controlSurfaceColor,
                      Color.lerp(
                            controlSurfaceColor,
                            DashboardRuntimeTheme.cardColor,
                            0.8,
                          ) ??
                          controlSurfaceColor,
                    ],
                  ),
                  border: Border.all(
                    color: (_isActive ? onColor : offColor).withValues(
                      alpha: 0.88,
                    ),
                    width: layout.controlBorderWidth,
                  ),
                  boxShadow: [
                    if (hasGlow)
                      BoxShadow(
                        color: resolvedGlowColor.withValues(
                          alpha: innerGlowAlpha,
                        ),
                        blurRadius: math.max(16.0, resolvedGlowBlur * 0.62),
                        spreadRadius: 1,
                      ),
                    const BoxShadow(
                      color: DashboardRuntimeTheme.shadowLightColor,
                      blurRadius: 5,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, controlConstraints) {
                    final rawLabelMaxWidth = controlConstraints.maxWidth - 20;
                    final labelMaxWidth = rawLabelMaxWidth > 12
                        ? rawLabelMaxWidth
                        : controlConstraints.maxWidth;
                    final currentWidth = controlConstraints.maxWidth;
                    final currentHeight = controlConstraints.maxHeight;
                    final safeContentHeight = math.max(
                      0.0,
                      currentHeight - 1.0,
                    );
                    final baseStatusFontSize = layout.statusBaseFontSize
                        .clamp(
                          layout.statusMinFontSize,
                          layout.statusMaxFontSize,
                        )
                        .toDouble();
                    final maxStatusFontFromWidth = currentWidth <= 20
                        ? 0.0
                        : ((currentWidth - 20) / 3.0)
                              .clamp(
                                layout.statusMinFontSize,
                                layout.statusMaxFontSize,
                              )
                              .toDouble();
                    final statusFontSize = maxStatusFontFromWidth <= 0
                        ? 0.0
                        : math
                              .min(baseStatusFontSize, maxStatusFontFromWidth)
                              .toDouble();
                    final provisionalStatusGap =
                        (safeContentHeight * layout.controlGapFactor)
                            .clamp(3.0, 10.0)
                            .toDouble();
                    final baseIconSize = layout.iconBaseSize
                        .clamp(layout.iconMinSize, layout.iconMaxSize)
                        .toDouble();
                    final maxIconWidth = currentWidth - 16;
                    final maxIconHeightWithoutStatus = safeContentHeight - 12;
                    final iconSizeWithoutStatus = math
                        .max(
                          0.0,
                          math.min(
                            baseIconSize,
                            math.min(maxIconWidth, maxIconHeightWithoutStatus),
                          ),
                        )
                        .toDouble();
                    final maxIconHeightWithStatus =
                        safeContentHeight -
                        statusFontSize -
                        provisionalStatusGap -
                        12;
                    final iconSizeWithStatus = math
                        .max(
                          0.0,
                          math.min(
                            baseIconSize,
                            math.min(maxIconWidth, maxIconHeightWithStatus),
                          ),
                        )
                        .toDouble();
                    final pillHorizontalPadding = (currentWidth * 0.08)
                        .clamp(10.0, 18.0)
                        .toDouble();
                    final pillVerticalPadding = (safeContentHeight * 0.06)
                        .clamp(4.0, 7.0)
                        .toDouble();
                    final estimatedPillHeight =
                        statusFontSize + (pillVerticalPadding * 2) + 2;
                    final maxBadgeHeightWithStatus = math.max(
                      0.0,
                      safeContentHeight -
                          provisionalStatusGap -
                          estimatedPillHeight,
                    );
                    final minWidthForStatus =
                        layout.sizeClass == _ButtonSizeClass.compact
                        ? 86.0
                        : 74.0;
                    final minHeightForStatus =
                        layout.sizeClass == _ButtonSizeClass.compact
                        ? 68.0
                        : 52.0;
                    final canFitStatusText =
                        currentWidth >= minWidthForStatus &&
                        currentHeight >= minHeightForStatus &&
                        statusFontSize > 0 &&
                        iconSizeWithStatus >= layout.iconMinSize * 0.8 &&
                        maxBadgeHeightWithStatus >= 24;
                    final showStatusText = canFitStatusText;
                    final statusGap = showStatusText
                        ? (provisionalStatusGap * 0.08)
                              .clamp(0.0, 1.0)
                              .toDouble()
                        : 0.0;
                    final iconSize = showStatusText
                        ? iconSizeWithStatus
                        : iconSizeWithoutStatus;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(controlCornerRadius),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    currentAccent.withValues(
                                      alpha: _isActive ? 0.1 : 0.05,
                                    ),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.72],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: labelMaxWidth,
                                maxHeight: safeContentHeight,
                              ),
                              child: iconSize > 0
                                  ? Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        _buildPowerIcon(
                                          size: iconSize,
                                          color: currentAccent,
                                          shadows: [
                                            BoxShadow(
                                              color: currentAccent.withValues(
                                                alpha: _isActive ? 0.18 : 0.08,
                                              ),
                                              blurRadius: 10,
                                            ),
                                          ],
                                          yOffsetFactor: 0.08,
                                        ),
                                        if (showStatusText)
                                          Transform.translate(
                                            offset: Offset(
                                              0,
                                              (iconSize * 0.62) + statusGap,
                                            ),
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                -pillVerticalPadding * 0.08,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      pillHorizontalPadding *
                                                      0.25,
                                                  vertical:
                                                      pillVerticalPadding *
                                                      0.02,
                                                ),
                                                child: Text(
                                                  statusText,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.fade,
                                                  softWrap: false,
                                                  style: TextStyle(
                                                    fontSize: statusFontSize,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: layout
                                                        .statusLetterSpacing,
                                                    color: currentAccent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : const SizedBox.shrink();

        final buttonCore = AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surfaceColor,
                Color.lerp(
                      surfaceColor,
                      DashboardRuntimeTheme.cardHighlightColor,
                      0.35,
                    ) ??
                    surfaceColor,
              ],
            ),
            borderRadius: BorderRadius.circular(shellCornerRadius),
            border: Border.all(
              color: resolvedShellBorderColor,
              width: resolvedShellBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardRuntimeTheme.shadowLightColor,
                blurRadius: layout.baseShadowBlur * 0.45,
                offset: Offset.zero,
              ),
              BoxShadow(
                color: DashboardRuntimeTheme.shadowDarkColor,
                blurRadius: layout.baseShadowBlur * 0.8,
                offset: Offset(0, width * 0.03),
              ),
              if (_isActive)
                BoxShadow(
                  color: onColor.withValues(alpha: 0.10),
                  blurRadius: width * 0.12,
                  spreadRadius: width * 0.01,
                ),
              if (hasGlow) ...[
                BoxShadow(
                  color: resolvedGlowColor.withValues(alpha: shellGlowAlpha),
                  blurRadius: resolvedGlowBlur,
                  spreadRadius: math.max(0.0, width * 0.015),
                ),
                BoxShadow(
                  color: resolvedGlowColor.withValues(
                    alpha: (shellGlowAlpha * 0.42).clamp(0.0, 0.22).toDouble(),
                  ),
                  blurRadius: resolvedGlowBlur * 1.35,
                  spreadRadius: -1,
                ),
              ],
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(shellCornerRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                          currentAccent.withValues(
                            alpha: _isActive ? 0.04 : 0.02,
                          ),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(layout.shellPadding),
                child: Align(alignment: Alignment.center, child: controlWidget),
              ),
            ],
          ),
        );

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 140),
          tween: Tween<double>(end: _isPressed ? 0.96 : 1),
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: widget.enableInteraction
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    _setPressed(true);
                    _handlePressStart();
                  },
                  onTapUp: (_) {
                    _setPressed(false);
                    _handlePressEnd();
                  },
                  onTapCancel: () {
                    _setPressed(false);
                    _handlePressEnd();
                  },
                  onTap: widget.isMomentary ? null : _handleTap,
                  child: buttonCore,
                )
              : buttonCore,
        );
      },
    );
  }
}
