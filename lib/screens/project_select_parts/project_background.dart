part of '../project_select_screen.dart';

class _ProjectBackground extends StatelessWidget {
  const _ProjectBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF2F5FA),
            Color(0xFFEAF7F1),
            Color(0xFFF7FBFF),
          ],
        ),
      ),
      child: CustomPaint(painter: _ProjectBackgroundPainter()),
    );
  }
}

class _ProjectBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.34)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
