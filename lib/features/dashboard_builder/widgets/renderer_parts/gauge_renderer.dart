part of '../dashboard_item_renderer.dart';

class _GaugeTileShell extends StatelessWidget {
  const _GaugeTileShell({
    required this.item,
    required this.metrics,
    required this.accentColor,
    required this.themePreset,
    required this.showTitle,
    required this.paintTitle,
    required this.child,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final Color accentColor;
  final DashboardThemePreset? themePreset;
  final bool showTitle;
  final bool paintTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleFontSize = _resolvedTitleFontSize(
      item: item,
      fallbackSize: 10,
      minSize: 7,
      maxSize: 12,
    );

    return _WidgetTitleFrame(
      item: item,
      showTitle: showTitle,
      paintTitle: paintTitle,
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: _resolvedTitleFontWeight(item),
        letterSpacing: _resolvedTitleLetterSpacing(item),
        color: _resolvedTitleTextColor(item: item, themePreset: themePreset),
        shadows: _resolvedTitleShadows(item: item, themePreset: themePreset),
      ),
      child: _DashboardTileShell(
        item: item,
        metrics: metrics,
        accentColor: accentColor,
        themePreset: themePreset,
        showTitleInside: false,
        child: child,
      ),
    );
  }
}

class _GaugeContent extends StatelessWidget {
  const _GaugeContent({
    required this.item,
    required this.metrics,
    required this.themePreset,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final DashboardThemePreset? themePreset;

  @override
  Widget build(BuildContext context) {
    final isUnbound = _isUnboundValueItem(item);
    final useTinyGaugeFallback =
        metrics.isTiny && (metrics.w <= 6 || metrics.h <= 4);
    if (useTinyGaugeFallback) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: item.value, end: item.value),
        duration: _valueAnimationDuration,
        curve: _valueAnimationCurve,
        builder: (context, animatedValue, child) {
          final animatedItem = item.copyWith(value: animatedValue);
          return Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isUnbound
                        ? _neutralInactiveAccent
                        : item.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    metrics.formatPrimaryValue(animatedItem),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isUnbound ? FontWeight.w800 : FontWeight.w700,
                      color: _resolvedValueTextColor(
                        item: item,
                        themePreset: themePreset,
                        isUnbound: isUnbound,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final baseValueFont = metrics.isShort
        ? 11.0
        : switch (metrics.sizeClass) {
            _TileSizeClass.tiny => 11.0,
            _TileSizeClass.compact => 11.0,
            _TileSizeClass.medium => 15.0,
            _TileSizeClass.large => 20.0,
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final controlInset = shortestSide >= 56
            ? 11.0
            : (shortestSide * 0.18).clamp(4.0, 11.0).toDouble();
        final usableWidth = math.max(
          0.0,
          constraints.maxWidth - (controlInset * 2),
        );
        final usableHeight = math.max(
          0.0,
          constraints.maxHeight - (controlInset * 2),
        );
        // Keep gauge perfectly circular regardless of tile aspect ratio.
        final gaugeSize = math.min(usableWidth, usableHeight);
        final strokeWidth = (gaugeSize * 0.12).clamp(6.0, 11.0).toDouble();
        final valueFont = (gaugeSize * 0.21)
            .clamp(
              isUnbound ? baseValueFont + 2.0 : baseValueFont,
              baseValueFont + 7.0,
            )
            .toDouble();
        final opticalOffsetY =
            (gaugeSize * 0.035).clamp(1.5, 4.0).toDouble() +
            (gaugeSize < 92 ? 1.0 : 0.0);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: item.value, end: item.value),
          duration: _valueAnimationDuration,
          curve: _valueAnimationCurve,
          builder: (context, animatedValue, child) {
            final animatedItem = item.copyWith(value: animatedValue);
            return Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.all(controlInset),
                child: Transform.translate(
                  offset: Offset(0, opticalOffsetY),
                  child: SizedBox.square(
                    dimension: gaugeSize,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        value: animatedValue,
                        minValue: item.minValue,
                        maxValue: item.maxValue,
                        color: isUnbound
                            ? _neutralInactiveAccent
                            : item.accentColor,
                        strokeWidth: strokeWidth,
                        isEmpty: isUnbound,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            metrics.formatPrimaryValue(animatedItem),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: valueFont,
                              fontWeight: isUnbound
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: _resolvedValueTextColor(
                                item: item,
                                themePreset: themePreset,
                                isUnbound: isUnbound,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.strokeWidth,
    this.isEmpty = false,
  });

  final double value;
  final double minValue;
  final double maxValue;
  final Color color;
  final double strokeWidth;
  final bool isEmpty;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.45;
    final brightColor = Color.lerp(color, Colors.white, 0.28) ?? color;
    final deepColor = Color.lerp(color, Colors.black, 0.18) ?? color;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = DashboardRuntimeTheme.surfaceBorderColor.withValues(
        alpha: isEmpty ? 0.95 : 0.82,
      );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final normalized =
        ((value - minValue) /
                (maxValue - minValue == 0 ? 1 : maxValue - minValue))
            .clamp(0.0, 1.0);

    canvas.drawArc(arcRect, start, sweep, false, background);
    if (normalized > 0) {
      final activeSweep = sweep * normalized;
      canvas.drawArc(arcRect, start, activeSweep, false, glow);

      const segmentCount = 72;
      final paintedSegments = math.max(1, (segmentCount * normalized).ceil());
      final segmentSweep = activeSweep / paintedSegments;
      final segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      for (var i = 0; i < paintedSegments; i += 1) {
        final t = paintedSegments == 1 ? 1.0 : i / (paintedSegments - 1);
        segmentPaint.color =
            Color.lerp(brightColor, deepColor, t.clamp(0.0, 1.0)) ?? color;
        canvas.drawArc(
          arcRect,
          start + (segmentSweep * i),
          segmentSweep + 0.002,
          false,
          segmentPaint,
        );
      }

      final startOffset = Offset(
        center.dx + (radius * math.cos(start)),
        center.dy + (radius * math.sin(start)),
      );
      final endAngle = start + activeSweep;
      final endOffset = Offset(
        center.dx + (radius * math.cos(endAngle)),
        center.dy + (radius * math.sin(endAngle)),
      );
      final startCapPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = brightColor;
      final endCapPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = deepColor;
      canvas.drawCircle(startOffset, strokeWidth / 2, startCapPaint);
      canvas.drawCircle(endOffset, strokeWidth / 2, endCapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color ||
        oldDelegate.isEmpty != isEmpty;
  }
}
