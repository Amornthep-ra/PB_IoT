part of '../dashboard_builder_screen.dart';

class _BuilderAppBarGlass extends StatelessWidget {
  const _BuilderAppBarGlass({required this.decoration});

  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          key: const ValueKey<String>('dashboard_builder_app_bar_surface'),
          decoration: decoration,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
