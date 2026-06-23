part of '../dashboard_item_renderer.dart';

const Color _stepperIncreaseColor = Color(0xFF22C55E);
const Color _stepperDecreaseColor = Color(0xFFEF4444);

class _StepperContent extends StatelessWidget {
  const _StepperContent({
    required this.item,
    required this.metrics,
    required this.themePreset,
    required this.isVertical,
    required this.enableInteraction,
    this.onChanged,
  });

  final DashboardItem item;
  final _TileMetrics metrics;
  final DashboardThemePreset? themePreset;
  final bool isVertical;
  final bool enableInteraction;
  final ValueChanged<double>? onChanged;

  void _emitStep(double direction) {
    final step = item.stepValue <= 0 ? 1.0 : item.stepValue;
    final next = _snapToStep(
      value: item.value + (step * direction),
      min: item.minValue,
      max: item.maxValue,
      step: step,
    );
    if (next == item.value) {
      return;
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = metrics.formatPrimaryValue(item);
    final isUnbound = _isUnboundValueItem(item);
    final active = enableInteraction && onChanged != null;
    final valueColor = _resolvedValueTextColor(
      item: item,
      themePreset: themePreset,
      isUnbound: isUnbound,
    );
    final plusButtonColor = active
        ? _stepperIncreaseColor
        : _neutralInactiveAccent;
    final minusButtonColor = active
        ? _stepperDecreaseColor
        : _neutralInactiveAccent;
    final valueFont = metrics.isTiny
        ? 14.0
        : metrics.isVeryNarrow || metrics.isVeryShort
        ? 15.0
        : switch (metrics.sizeClass) {
            _TileSizeClass.tiny => 14.0,
            _TileSizeClass.compact => 17.0,
            _TileSizeClass.medium => 20.0,
            _TileSizeClass.large => 24.0,
          };
    final compactVertical =
        isVertical &&
        (metrics.isTiny || metrics.sizeClass == _TileSizeClass.compact);
    final buttonSize = compactVertical
        ? 26.0
        : metrics.isTiny || metrics.sizeClass == _TileSizeClass.compact
        ? 28.0
        : metrics.sizeClass == _TileSizeClass.large
        ? 34.0
        : 30.0;
    final iconSize = compactVertical
        ? 16.0
        : metrics.isTiny || metrics.sizeClass == _TileSizeClass.compact
        ? 17.0
        : metrics.sizeClass == _TileSizeClass.large
        ? 20.0
        : 18.0;
    final value = Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            displayValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: valueFont,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ),
    );
    final minusButton = _StepperIconButton(
      icon: Icons.remove_rounded,
      tooltip: 'ลดค่า',
      color: minusButtonColor,
      enabled: active,
      size: buttonSize,
      iconSize: iconSize,
      onTap: () => _emitStep(-1),
    );
    final plusButton = _StepperIconButton(
      icon: Icons.add_rounded,
      tooltip: 'เพิ่มค่า',
      color: plusButtonColor,
      enabled: active,
      size: buttonSize,
      iconSize: iconSize,
      onTap: () => _emitStep(1),
    );

    if (isVertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [plusButton, value, minusButton],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [minusButton, value, plusButton],
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.enabled,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool enabled;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, enabled ? 0.18 : 0.42)!,
                  color.withValues(alpha: enabled ? 0.92 : 0.36),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: enabled
                  ? Colors.white
                  : DashboardRuntimeTheme.mutedTextColor.withValues(
                      alpha: 0.72,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
