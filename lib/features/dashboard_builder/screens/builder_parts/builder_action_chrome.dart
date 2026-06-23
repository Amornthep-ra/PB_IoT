part of '../dashboard_builder_screen.dart';

class _BuilderActionTone {
  const _BuilderActionTone({
    required this.background,
    required this.foreground,
    required this.glow,
  });

  final Color background;
  final Color foreground;
  final Color glow;
}

const _BuilderActionTone _undoActionTone = _BuilderActionTone(
  background: Color(0xFFF0ECFB),
  foreground: Color(0xFF7A64BE),
  glow: Color(0xFFC3B2EE),
);

const _BuilderActionTone _redoActionTone = _BuilderActionTone(
  background: Color(0xFFE7F4FF),
  foreground: Color(0xFF5A8EC7),
  glow: Color(0xFFAFD0F0),
);

const _BuilderActionTone _duplicateActionTone = _BuilderActionTone(
  background: Color(0xFFEAF7E3),
  foreground: Color(0xFF67984F),
  glow: Color(0xFFB8D89E),
);

const _BuilderActionTone _selectionActionTone = _BuilderActionTone(
  background: Color(0xFFE4F6F7),
  foreground: Color(0xFF4399A0),
  glow: Color(0xFFA6DDE0),
);

const _BuilderActionTone _settingsActionTone = _BuilderActionTone(
  background: Color(0xFFFFF1DC),
  foreground: Color(0xFFBF8741),
  glow: Color(0xFFF0CA8D),
);

const _BuilderActionTone _deleteActionTone = _BuilderActionTone(
  background: Color(0xFFFFE9EC),
  foreground: Color(0xFFD46B7B),
  glow: Color(0xFFF0B1BC),
);

class _BuilderActionButton extends StatelessWidget {
  const _BuilderActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    this.size = 44,
    this.iconSize = 22,
    this.glowColor,
    this.glowScale = 1,
    this.isDarkTheme = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double iconSize;
  final Color? glowColor;
  final double glowScale;
  final bool isDarkTheme;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final effectiveGlow = glowColor ?? foregroundColor;
    final borderAlpha = isEnabled ? 0.78 : 0.66;
    final iconAlpha = isEnabled ? 1.0 : 0.62;
    final surfaceStart = isDarkTheme
        ? Color.lerp(backgroundColor, Colors.white, isEnabled ? 0.06 : 0.02)!
        : Color.lerp(backgroundColor, Colors.white, isEnabled ? 0.18 : 0.28)!;
    final surfaceEnd = isDarkTheme
        ? Color.lerp(backgroundColor, Colors.black, isEnabled ? 0.10 : 0.18)!
        : Color.lerp(backgroundColor, effectiveGlow, isEnabled ? 0.18 : 0.04)!;
    final innerSurface = isDarkTheme
        ? Color.lerp(backgroundColor, effectiveGlow, isEnabled ? 0.16 : 0.04)!
        : Color.lerp(Colors.white, effectiveGlow, isEnabled ? 0.18 : 0.06)!;

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 14,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isDarkTheme
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isEnabled ? 0.28 : 0.18,
                      ),
                      blurRadius: isEnabled ? 10 : 7,
                      offset: const Offset(0, 5),
                    ),
                    if (isEnabled && glowScale >= 1.0)
                      BoxShadow(
                        color: effectiveGlow.withValues(alpha: 0.09),
                        blurRadius: 10,
                        spreadRadius: 0.1,
                      ),
                  ]
                : <BoxShadow>[
                    const BoxShadow(
                      color: DashboardRuntimeTheme.shadowLightColor,
                      blurRadius: 7,
                      offset: Offset(-3, -3),
                    ),
                    BoxShadow(
                      color: effectiveGlow.withValues(
                        alpha: isEnabled
                            ? (0.075 * glowScale).clamp(0.0, 0.14).toDouble()
                            : 0.03,
                      ),
                      blurRadius: isEnabled ? 8.5 * glowScale : 6,
                      spreadRadius: isEnabled ? 0.08 : 0,
                    ),
                    const BoxShadow(
                      color: DashboardRuntimeTheme.shadowDarkColor,
                      blurRadius: 9,
                      offset: Offset(3, 5),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [surfaceStart, surfaceEnd],
                        ),
                        border: Border.all(
                          color: isEnabled
                              ? effectiveGlow.withValues(alpha: 0.22)
                              : Colors.white.withValues(alpha: borderAlpha),
                          width: 1.05,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: size * 0.68,
                    height: size * 0.68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(innerSurface, Colors.white, 0.22)!,
                          innerSurface,
                        ],
                      ),
                      border: Border.all(
                        color: effectiveGlow.withValues(
                          alpha: isEnabled ? 0.24 : 0.10,
                        ),
                        width: 0.8,
                      ),
                    ),
                  ),
                  Positioned(
                    top: size * 0.18,
                    left: size * 0.24,
                    child: Container(
                      width: size * 0.24,
                      height: size * 0.07,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: isEnabled
                              ? (isDarkTheme ? 0.12 : 0.66)
                              : (isDarkTheme ? 0.06 : 0.30),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    color: foregroundColor.withValues(alpha: iconAlpha),
                    size: iconSize,
                  ),
                  Positioned(
                    bottom: size * 0.15,
                    child: Container(
                      width: size * 0.18,
                      height: 2.4,
                      decoration: BoxDecoration(
                        color: effectiveGlow.withValues(
                          alpha: isEnabled ? 0.34 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
