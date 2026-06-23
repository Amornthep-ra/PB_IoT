part of '../dashboard_builder_screen.dart';

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.item,
    required this.color,
    required this.position,
    required this.onStartResize,
    required this.onUpdateResize,
    required this.onFinishResize,
  });

  final DashboardItem item;
  final Color color;
  final DashboardBuilderResizeHandlePosition position;
  final void Function(
    DashboardItem item,
    Offset globalPosition,
    DashboardBuilderResizeHandlePosition handle,
  )
  onStartResize;
  final void Function(Offset globalPosition) onUpdateResize;
  final VoidCallback onFinishResize;

  @override
  Widget build(BuildContext context) {
    const hitSize = 44.0;
    final isVertical =
        position == DashboardBuilderResizeHandlePosition.left ||
        position == DashboardBuilderResizeHandlePosition.right;
    final indicatorWidth = isVertical ? 11.0 : 24.0;
    final indicatorHeight = isVertical ? 24.0 : 11.0;
    final accentWidth = isVertical ? 2.2 : 10.0;
    final accentHeight = isVertical ? 10.0 : 2.2;
    final indicatorRadius = math.max(indicatorWidth, indicatorHeight);
    final indicatorGradient = <Color>[
      const Color(0xFFFFFFFF).withValues(alpha: 0.92),
      color.withValues(alpha: 0.18),
    ];
    final accentGradient = <Color>[
      color.withValues(alpha: 0.78),
      color.withValues(alpha: 0.56),
    ];

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => onStartResize(item, event.position, position),
      onPointerMove: (event) => onUpdateResize(event.position),
      onPointerUp: (_) => onFinishResize(),
      onPointerCancel: (_) => onFinishResize(),
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: indicatorWidth,
            height: indicatorHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: indicatorGradient,
              ),
              borderRadius: BorderRadius.circular(indicatorRadius),
              border: Border.all(
                color: color.withValues(alpha: 0.26),
                width: 1,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
                BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 9),
              ],
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: accentGradient,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: SizedBox(width: accentWidth, height: accentHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedWidgetBadge extends StatelessWidget {
  const _LockedWidgetBadge({required this.compact, required this.themePreset});

  final bool compact;
  final DashboardThemePreset themePreset;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 13.0 : 16.0;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: themePreset.cardColor.withValues(alpha: 0.88),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.82),
            width: 1,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: DashboardRuntimeTheme.shadowDarkColor,
              blurRadius: 5,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.lock_rounded,
            size: compact ? 7.5 : 9,
            color: themePreset.bodyColor,
          ),
        ),
      ),
    );
  }
}

class _InspectorPill extends StatelessWidget {
  const _InspectorPill({
    required this.label,
    required this.themePreset,
    this.muted = false,
  });

  final String label;
  final DashboardThemePreset themePreset;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? themePreset.mutedTextColor : themePreset.bodyColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: muted ? 0.34 : 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFD7E1E8).withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasWidgetTitleOverlay extends StatelessWidget {
  const _CanvasWidgetTitleOverlay({required this.text, required this.style});

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
