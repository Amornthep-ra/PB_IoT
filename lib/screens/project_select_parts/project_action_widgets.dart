part of '../project_select_screen.dart';

class _ProjectHeaderCreateButton extends StatelessWidget {
  const _ProjectHeaderCreateButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: AppGlassTheme.accentDecoration(
          radius: 15,
          colors: const <Color>[_buttonStartColor, _buttonEndColor],
          borderColor: Colors.white,
          glowColor: _buttonGlowColor,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white.withValues(
                      alpha: onPressed == null ? 0.54 : 1,
                    ),
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'สร้างโปรเจกต์',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(
                        alpha: onPressed == null ? 0.54 : 1,
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

class _ProjectTileMenu extends StatelessWidget {
  const _ProjectTileMenu({
    required this.isEnabled,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isEnabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: PopupMenuButton<_ProjectTileAction>(
        tooltip: 'ตัวเลือกโปรเจกต์',
        enabled: isEnabled,
        icon: const Icon(Icons.more_horiz_rounded),
        color: const Color(0xFFF8FAFD),
        surfaceTintColor: Colors.transparent,
        iconColor: _mutedTextColor,
        iconSize: 24,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (action) {
          switch (action) {
            case _ProjectTileAction.edit:
              onEdit();
            case _ProjectTileAction.delete:
              onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem<_ProjectTileAction>(
            value: _ProjectTileAction.edit,
            child: _ProjectMenuItem(
              icon: Icons.edit_outlined,
              label: 'แก้ไข',
              color: _mutedTextColor,
            ),
          ),
          PopupMenuItem<_ProjectTileAction>(
            value: _ProjectTileAction.delete,
            child: _ProjectMenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'ลบ',
              color: _dangerColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProjectTileAction { edit, delete }

class _ProjectMenuItem extends StatelessWidget {
  const _ProjectMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProjectActionButton extends StatelessWidget {
  const _ProjectActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final foreground = isSecondary ? _labelTextColor : Colors.white;
    final accentColors = isDanger
        ? const <Color>[Color(0xFFE9828C), _dangerColor]
        : const <Color>[_buttonStartColor, _buttonEndColor];
    final glowColor = isDanger ? const Color(0xFFECA1A8) : _buttonGlowColor;

    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: isSecondary
            ? AppGlassTheme.surfaceDecoration(
                radius: 16,
                borderAlpha: 0.76,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.64),
                  const Color(0xFFF6FBFF).withValues(alpha: 0.42),
                ],
                shadows: const <BoxShadow>[],
              )
            : AppGlassTheme.accentDecoration(
                radius: 16,
                colors: accentColors,
                borderColor: Colors.white,
                glowColor: glowColor,
              ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: onPressed == null
                      ? foreground.withValues(alpha: 0.54)
                      : foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectErrorBanner extends StatelessWidget {
  const _ProjectErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5B7BE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _dangerColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9E3F48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
