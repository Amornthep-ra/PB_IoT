import 'dart:math' as math;

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
