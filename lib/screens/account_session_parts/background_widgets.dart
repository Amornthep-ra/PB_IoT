part of '../account_session_screen.dart';

class _AccountBackground extends StatelessWidget {
  const _AccountBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF7FBFF),
            Color(0xFFF1F5FA),
            Color(0xFFEEF3F8),
          ],
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
            left: -68,
            top: 88,
            child: _GlowOrb(
              size: 228,
              color: const Color(0xFFBCD7C7).withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            right: -78,
            top: 26,
            child: _GlowOrb(
              size: 236,
              color: const Color(0xFFD7E5EF).withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            right: -46,
            bottom: 104,
            child: _GlowOrb(
              size: 184,
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

class _HeroProfileCard extends StatelessWidget {
  const _HeroProfileCard({
    required this.metrics,
    required this.profileAvatarId,
    required this.isUpdating,
    required this.onEditTap,
  });

  final AppResponsiveMetrics metrics;
  final String? profileAvatarId;
  final bool isUpdating;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final avatarInset = metrics.isCompactHeight ? 8.0 : 14.0;
    final avatarSize = (metrics.heroAvatarSize - avatarInset).clamp(
      112.0,
      metrics.heroAvatarSize,
    );
    final iconSize = (metrics.heroAvatarIconSize - 10).clamp(
      56.0,
      metrics.heroAvatarIconSize,
    );
    const badgeSize = 34.0;

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: avatarSize / 2,
                  borderAlpha: 0.54,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.76),
                    const Color(0xFFE8F5FF).withValues(alpha: 0.28),
                  ],
                  shadows: AppGlassTheme.shadowMd,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (profileAvatarId != null)
                      _ProfileAvatarPresetImage(avatarId: profileAvatarId!)
                    else
                      _ProfileAvatarFallback(iconSize: iconSize),
                    if (isUpdating)
                      Container(
                        color: Colors.black.withValues(alpha: 0.20),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditTap,
                    borderRadius: BorderRadius.circular(badgeSize / 2),
                    child: Ink(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: AppGlassTheme.accentDecoration(
                        radius: badgeSize / 2,
                        colors: const <Color>[
                          Color(0xFF6BB38A),
                          Color(0xFF4E8D6B),
                        ],
                        borderColor: Colors.white.withValues(alpha: 0.92),
                        glowColor: const Color(0xFF6BB38A),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
