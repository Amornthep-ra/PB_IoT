part of '../notifications_screen.dart';

class _AlertsPageSwitcher extends StatelessWidget {
  const _AlertsPageSwitcher({
    super.key,
    required this.selectedPage,
    required this.onChanged,
    this.compact = false,
  });

  final _AlertsPage selectedPage;
  final ValueChanged<_AlertsPage> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: Container(
        padding: EdgeInsets.all(compact ? 2.5 : 3),
        decoration: AppGlassTheme.surfaceDecoration(
          radius: compact ? 14 : 16,
          borderAlpha: compact ? 0.28 : 0.40,
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: compact ? 0.54 : 0.64),
            const Color(0xFFF4F8FF).withValues(alpha: compact ? 0.22 : 0.30),
          ],
          shadows: const <BoxShadow>[],
        ),
        child: Row(
          children: [
            _SwitcherButton(
              label: 'เหตุการณ์ล่าสุด',
              isSelected: selectedPage == _AlertsPage.currentEvents,
              onTap: () => onChanged(_AlertsPage.currentEvents),
              selectedColors: const <Color>[
                Color(0xFFB6D2F5),
                Color(0xFF82AEE8),
              ],
              selectedBorderColor: const Color(0xFF9EC3F0),
              selectedGlowColor: const Color(0xFF82AEE8),
              idleTintColor: const Color(0xFFEEF6FF),
              compact: compact,
            ),
            SizedBox(width: compact ? 3 : 4),
            _SwitcherButton(
              label: 'ประวัติทั้งหมด',
              isSelected: selectedPage == _AlertsPage.allHistory,
              onTap: () => onChanged(_AlertsPage.allHistory),
              selectedColors: const <Color>[
                Color(0xFFC7B9F4),
                Color(0xFF9B7EE6),
              ],
              selectedBorderColor: const Color(0xFFB8A6EE),
              selectedGlowColor: const Color(0xFF9B7EE6),
              idleTintColor: const Color(0xFFF6F1FF),
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitcherButton extends StatelessWidget {
  const _SwitcherButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColors,
    required this.selectedBorderColor,
    required this.selectedGlowColor,
    required this.idleTintColor,
    this.compact = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> selectedColors;
  final Color selectedBorderColor;
  final Color selectedGlowColor;
  final Color idleTintColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 7 : 8,
          ),
          decoration: isSelected
              ? AppGlassTheme.accentDecoration(
                  radius: compact ? 10 : 12,
                  colors: selectedColors,
                  borderColor: selectedBorderColor,
                  glowColor: selectedGlowColor,
                )
              : AppGlassTheme.surfaceDecoration(
                  radius: compact ? 10 : 12,
                  borderAlpha: 0.18,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.18),
                    idleTintColor.withValues(alpha: 0.18),
                  ],
                  shadows: const <BoxShadow>[],
                ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 9.5 : 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF53616D),
            ),
          ),
        ),
      ),
    );
  }
}
