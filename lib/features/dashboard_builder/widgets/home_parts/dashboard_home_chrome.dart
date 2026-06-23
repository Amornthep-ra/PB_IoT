part of '../dashboard_home_view.dart';

extension _DashboardHomeChrome on _DashboardHomeViewState {
  Widget _buildErrorBanner(String message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 14,
            borderAlpha: 0.62,
            colors: <Color>[
              const Color(0xFFFFF7F7).withValues(alpha: 0.84),
              const Color(0xFFFFE7E6).withValues(alpha: 0.54),
            ],
            shadows: const <BoxShadow>[
              BoxShadow(
                color: Color(0x12A33A3A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF6B3AE).withValues(alpha: 0.32),
                  border: Border.all(
                    color: const Color(0xFFFFE4E1).withValues(alpha: 0.88),
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: DashboardRuntimeTheme.errorTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: DashboardRuntimeTheme.errorTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Image.asset(
                  'assets/icons/mascot/mascot_default.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: AppGlassTheme.surfaceDecoration(
                      radius: 22,
                      borderAlpha: 0.60,
                      colors: <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                        const Color(0xFFF4FBF7).withValues(alpha: 0.44),
                      ],
                      shadows: AppGlassTheme.shadowMd,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'เริ่มสร้างแดชบอร์ดของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: DashboardRuntimeTheme.headlineColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'เพิ่มวิดเจ็ตตัวแรกเพื่อเริ่มติดตามอุปกรณ์',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: DashboardRuntimeTheme.mutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DashboardBuilderButton(
                          label: 'เพิ่มวิดเจ็ต',
                          icon: Icons.add_rounded,
                          onTap: _openDashboardBuilder,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBuilderButton extends StatelessWidget {
  const _DashboardBuilderButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isCompact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 15 : 16),
        border: Border.all(color: const Color(0xFF9EC3F0)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB6D2F5), Color(0xFF82AEE8)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isCompact ? 15 : 16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 16,
              vertical: isCompact ? 7 : 11,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: isCompact ? 14 : 18, color: Colors.white),
                SizedBox(width: isCompact ? 6 : 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

class _DashboardWidgetTitleOverlay extends StatelessWidget {
  const _DashboardWidgetTitleOverlay({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 200.0;
        return Center(
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardItemHighlightOverlay extends StatelessWidget {
  const _DashboardItemHighlightOverlay({
    required this.item,
    required this.alpha,
  });

  final DashboardItem item;
  final double alpha;

  static const Color _borderColor = Color(0xFFFFC857);
  static const Color _glowColor = Color(0xFFFFD166);

  @override
  Widget build(BuildContext context) {
    if (alpha <= 0) {
      return const SizedBox.expand();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final shape = _shapeFor(item.type, width, height);
        final highlight = DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: shape,
            shadows: [
              BoxShadow(
                color: _glowColor.withValues(alpha: alpha * 0.46),
                blurRadius: 26,
                spreadRadius: 4,
              ),
            ],
          ),
        );

        if (item.type == DashboardItemType.slider) {
          final layout = buildSliderShellLayout(
            width: width,
            height: height,
            desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
            shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
          );
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: layout.shellTopInset,
                bottom: layout.shellBottomInset,
                child: highlight,
              ),
            ],
          );
        }

        return highlight;
      },
    );
  }

  ShapeBorder _shapeFor(DashboardItemType type, double width, double height) {
    final side = BorderSide(
      color: _borderColor.withValues(alpha: alpha),
      width: 3,
    );

    return switch (type) {
      DashboardItemType.button => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(math.min(width, height) / 2),
        side: side,
      ),
      DashboardItemType.toggle => StadiumBorder(side: side),
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.gauge ||
      DashboardItemType.valueLabel ||
      DashboardItemType.trend ||
      DashboardItemType.led => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: side,
      ),
    };
  }
}
