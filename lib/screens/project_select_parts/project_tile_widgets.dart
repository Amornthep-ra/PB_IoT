part of '../project_select_screen.dart';

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectModel project;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isBusy ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: AppGlassTheme.surfaceDecoration(
                radius: 20,
                borderAlpha: isSelected ? 0.92 : 0.58,
                colors: isSelected
                    ? <Color>[
                        const Color(0xFFEAF7F1).withValues(alpha: 0.84),
                        const Color(0xFFFFFFFF).withValues(alpha: 0.68),
                      ]
                    : <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.70),
                        const Color(0xFFF6FBFF).withValues(alpha: 0.42),
                      ],
                shadows: AppGlassTheme.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _projectIconColors(project.iconKey),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _projectIconGlowColor(
                            project.iconKey,
                          ).withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _projectIconData(project.iconKey),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _headlineColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'แก้ไขล่าสุด ${_formatProjectDate(project.updatedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSelected)
                    const _SelectedProjectChip()
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _mutedTextColor,
                      size: 26,
                    ),
                  const SizedBox(width: 2),
                  _ProjectTileMenu(
                    isEnabled: !isBusy,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatProjectDate(DateTime value) {
    final local = value.toLocal();
    const monthLabels = <String>[
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${local.day} ${monthLabels[local.month - 1]} ${local.year}';
  }
}

class _SelectedProjectChip extends StatelessWidget {
  const _SelectedProjectChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F2E9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB8DDC9)),
      ),
      child: const Text(
        'เลือกอยู่',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w800,
          color: _buttonEndColor,
        ),
      ),
    );
  }
}
