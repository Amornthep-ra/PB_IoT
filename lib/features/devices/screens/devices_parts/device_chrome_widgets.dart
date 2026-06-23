part of '../devices_screen.dart';

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isRefreshing, required this.onPressed});

  final bool isRefreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isRefreshing ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: AppGlassTheme.accentDecoration(
            radius: 18,
            colors: const <Color>[Color(0xFFB6D2F5), Color(0xFF82AEE8)],
            borderColor: const Color(0xFF9EC3F0),
            glowColor: const Color(0xFF82AEE8),
          ),
          child: isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 16,
        borderAlpha: 0.36,
        colors: <Color>[
          Color.alphaBlend(Colors.white.withValues(alpha: 0.18), background),
          Color.alphaBlend(Colors.white.withValues(alpha: 0.05), background),
        ],
        shadows: AppGlassTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: 0.5,
            colors: <Color>[
              Color(0xFFFFFFFF).withValues(alpha: 0.76),
              Color(0xFFF5FBFF).withValues(alpha: 0.38),
            ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: const Center(
            child: Column(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                SizedBox(height: 14),
                Text(
                  'กำลังโหลดสถานะอุปกรณ์...',
                  style: TextStyle(
                    fontSize: 14,
                    color: DashboardRuntimeTheme.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
