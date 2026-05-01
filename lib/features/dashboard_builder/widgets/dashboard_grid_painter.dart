import 'package:flutter/material.dart';

class DashboardGridPainter extends CustomPainter {
  const DashboardGridPainter({
    required this.columns,
    required this.rows,
    required this.gap,
    required this.lineColor,
  });

  final int columns;
  final int rows;
  final double gap;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.68;

    final cellWidth = (size.width - (gap * (columns - 1))) / columns;
    final cellHeight = (size.height - (gap * (rows - 1))) / rows;
    final stepX = cellWidth + gap;
    final stepY = cellHeight + gap;

    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), linePaint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      linePaint,
    );

    for (var row = 1; row < rows; row++) {
      final y = (row * stepY) - (gap / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    canvas.drawLine(Offset(0, 0), Offset(0, size.height), linePaint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      linePaint,
    );

    for (var column = 1; column < columns; column++) {
      final x = (column * stepX) - (gap / 2);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DashboardGridPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.gap != gap ||
        oldDelegate.lineColor != lineColor;
  }
}
