part of '../token_login_screen.dart';

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFD), Color(0xFFE8EEF5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFFFF).withValues(alpha: 0.54),
                    Colors.transparent,
                    const Color(0xFFDCE7F0).withValues(alpha: 0.18),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            top: 110,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFFBCD7C7).withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            right: -70,
            top: 20,
            child: _GlowOrb(
              size: 230,
              color: const Color(0xFFD7E5EF).withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            right: -48,
            bottom: 90,
            child: _GlowOrb(
              size: 180,
              color: const Color(0xFFB8DCC3).withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
