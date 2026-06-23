part of '../dashboard_item_renderer.dart';

class _TrendTileShell extends StatelessWidget {
  const _TrendTileShell({
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
    return _WidgetTitleFrame(
      item: item,
      showTitle: showTitle,
      paintTitle: paintTitle,
      style: TextStyle(
        fontSize: _resolvedTitleFontSize(
          item: item,
          fallbackSize: 10,
          minSize: 7,
          maxSize: 12,
        ),
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

class _TrendContent extends StatelessWidget {
  const _TrendContent({
    required this.item,
    required this.metrics,
    required this.themePreset,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final DashboardThemePreset? themePreset;

  @override
  Widget build(BuildContext context) {
    final hasBinding = _hasBoundDataKey(item);
    final series = item.series;
    final hasHistory = hasBinding && series.length >= 2;
    final valueText = hasBinding ? metrics.formatPrimaryValue(item) : '--';
    final labelColor = _resolvedValueTextColor(
      item: item,
      themePreset: themePreset,
      isUnbound: !hasBinding,
    );
    final mutedColor =
        themePreset?.mutedTextColor ?? DashboardRuntimeTheme.mutedTextColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 76 || metrics.isTiny;
        final valueFont = compact ? 15.0 : 18.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(10, compact ? 8 : 10, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueFont,
                        fontWeight: FontWeight.w800,
                        color: labelColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.show_chart_rounded,
                    size: compact ? 14 : 16,
                    color: hasBinding
                        ? item.accentColor.withValues(alpha: 0.78)
                        : mutedColor.withValues(alpha: 0.62),
                  ),
                ],
              ),
              SizedBox(height: compact ? 4 : 7),
              Expanded(
                child: CustomPaint(
                  key: const ValueKey<String>('trend_chart_painter'),
                  painter: _TrendLinePainter(
                    values: hasHistory ? series : const <double>[],
                    color: item.accentColor,
                    mutedColor: mutedColor,
                    isDark: _usesDarkTheme(themePreset),
                  ),
                  child: SizedBox.expand(
                    key: ValueKey<String>(
                      hasHistory
                          ? 'trend_chart_history_surface'
                          : 'trend_chart_empty_surface',
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
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.values,
    required this.color,
    required this.mutedColor,
    required this.isDark,
  });

  final List<double> values;
  final Color color;
  final Color mutedColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    if (values.length < 2) {
      final emptyPaint = Paint()
        ..color = mutedColor.withValues(alpha: isDark ? 0.08 : 0.06)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = mutedColor.withValues(alpha: isDark ? 0.18 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final rect = RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, emptyPaint);
      canvas.drawRRect(rect, borderPaint);
      return;
    }

    final gridPaint = Paint()
      ..color = mutedColor.withValues(alpha: isDark ? 0.10 : 0.07)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i += 1) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    var minValue = values.first;
    var maxValue = values.first;
    for (final value in values) {
      minValue = math.min(minValue, value);
      maxValue = math.max(maxValue, value);
    }
    final span = math.max(0.0001, maxValue - minValue);
    final stepX = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i += 1) {
      final normalized = (values[i] - minValue) / span;
      final point = Offset(i * stepX, size.height - (normalized * size.height));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: isDark ? 0.30 : 0.24),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: isDark ? 0.96 : 0.94)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.isDark != isDark;
  }
}
