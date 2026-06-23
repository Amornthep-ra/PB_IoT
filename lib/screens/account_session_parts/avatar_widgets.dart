part of '../account_session_screen.dart';

enum _ProfileAvatarAction { avatar, remove }

const List<_ProfileAvatarPreset> _profileAvatarPresets = <_ProfileAvatarPreset>[
  _ProfileAvatarPreset(
    id: 'avatar1',
    assetPath: 'assets/icons/profile/avatar1.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar2',
    assetPath: 'assets/icons/profile/avatar2.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar3',
    assetPath: 'assets/icons/profile/avatar3.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar4',
    assetPath: 'assets/icons/profile/avatar4.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar5',
    assetPath: 'assets/icons/profile/avatar5.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar6',
    assetPath: 'assets/icons/profile/avatar6.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar7',
    assetPath: 'assets/icons/profile/avatar7.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar8',
    assetPath: 'assets/icons/profile/avatar8.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar9',
    assetPath: 'assets/icons/profile/avatar9.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar10',
    assetPath: 'assets/icons/profile/avatar10.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar11',
    assetPath: 'assets/icons/profile/avatar11.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar12',
    assetPath: 'assets/icons/profile/avatar12.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar13',
    assetPath: 'assets/icons/profile/avatar13.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar14',
    assetPath: 'assets/icons/profile/avatar14.png',
  ),
];

_ProfileAvatarPreset _profileAvatarPresetById(String avatarId) {
  return _profileAvatarPresets.firstWhere(
    (preset) => preset.id == avatarId,
    orElse: () => _profileAvatarPresets.first,
  );
}

class _ProfileAvatarPreset {
  const _ProfileAvatarPreset({required this.id, required this.assetPath});

  final String id;
  final String assetPath;
}

class _ProfileAvatarPresetImage extends StatelessWidget {
  const _ProfileAvatarPresetImage({required this.avatarId});

  final String avatarId;

  @override
  Widget build(BuildContext context) {
    final preset = _profileAvatarPresetById(avatarId);

    return Image.asset(
      preset.assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.person_outline_rounded,
          color: Color(0xFF5A9676),
        );
      },
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_outline_rounded,
      size: iconSize,
      color: const Color(0xFF5A9676),
    );
  }
}

class _ProfileAvatarSourceSheet extends StatelessWidget {
  const _ProfileAvatarSourceSheet({
    required this.hasProfileAvatar,
    required this.onActionSelected,
  });

  final bool hasProfileAvatar;
  final ValueChanged<_ProfileAvatarAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight =
        (mediaQuery.size.height - mediaQuery.padding.vertical - 24)
            .clamp(0.0, double.infinity)
            .toDouble();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 24,
                  borderAlpha: 0.5,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                    const Color(0xFFF5FBFF).withValues(alpha: 0.38),
                  ],
                  shadows: AppGlassTheme.shadowMd,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รูปโปรไฟล์',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _AccountSessionScreenState._headlineColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'เลือกรูปโปรไฟล์สำเร็จรูปสำหรับบัญชีนี้',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _AccountSessionScreenState._mutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SourceActionTile(
                          icon: Icons.grid_view_rounded,
                          label: 'เลือกรูปโปรไฟล์',
                          onTap: () =>
                              onActionSelected(_ProfileAvatarAction.avatar),
                        ),
                        if (hasProfileAvatar) ...[
                          const SizedBox(height: 8),
                          _SourceActionTile(
                            icon: Icons.delete_outline_rounded,
                            label: 'ลบรูปโปรไฟล์',
                            iconColor: const Color(0xFFB24A46),
                            onTap: () =>
                                onActionSelected(_ProfileAvatarAction.remove),
                          ),
                        ],
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceActionTile extends StatelessWidget {
  const _SourceActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = const Color(0xFF557B67),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: AppGlassTheme.surfaceDecoration(
          radius: 18,
          borderAlpha: 0.34,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.46),
            iconColor.withValues(alpha: 0.08),
          ],
          shadows: const <BoxShadow>[],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: 14,
                    borderAlpha: 0.32,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.56),
                      iconColor.withValues(alpha: 0.1),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
                  child: Icon(icon, color: iconColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AccountSessionScreenState._labelTextColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF718093),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarPickerSheet extends StatelessWidget {
  const _ProfileAvatarPickerSheet({required this.currentAvatarId});

  final String? currentAvatarId;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final sheetMaxWidth = isTablet ? 640.0 : double.infinity;
    final maxSheetHeight =
        (mediaQuery.size.height - mediaQuery.padding.vertical - 24)
            .clamp(0.0, double.infinity)
            .toDouble();
    final maxTileExtent = isTablet ? 104.0 : 82.0;
    final avatarSize = isTablet ? 58.0 : 44.0;
    final gridSpacing = isTablet ? 12.0 : 8.0;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: sheetMaxWidth,
              maxHeight: maxSheetHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: 24,
                    borderAlpha: 0.5,
                    colors: <Color>[
                      const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                      const Color(0xFFF5FBFF).withValues(alpha: 0.42),
                    ],
                    shadows: AppGlassTheme.shadowMd,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        18,
                        18,
                        isTablet ? 22 : 18,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เลือกรูปโปรไฟล์',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _AccountSessionScreenState._headlineColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'เลือกรูปโปรไฟล์สำเร็จรูปสำหรับบัญชีนี้',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _AccountSessionScreenState._mutedTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final crossAxisCount =
                                  (availableWidth / maxTileExtent).ceil().clamp(
                                    3,
                                    _profileAvatarPresets.length,
                                  );
                              final tileWidth =
                                  (availableWidth -
                                      (gridSpacing * (crossAxisCount - 1))) /
                                  crossAxisCount;
                              final rowCount =
                                  (_profileAvatarPresets.length /
                                          crossAxisCount)
                                      .ceil();
                              final gridBottomPadding = isTablet ? 10.0 : 6.0;
                              final gridHeight =
                                  (rowCount * tileWidth) +
                                  ((rowCount - 1) * gridSpacing) +
                                  gridBottomPadding;

                              return SizedBox(
                                height: gridHeight,
                                child: GridView.builder(
                                  padding: EdgeInsets.only(
                                    bottom: gridBottomPadding,
                                  ),
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _profileAvatarPresets.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: gridSpacing,
                                        crossAxisSpacing: gridSpacing,
                                        childAspectRatio: 1,
                                      ),
                                  itemBuilder: (context, index) {
                                    final preset = _profileAvatarPresets[index];
                                    final isSelected =
                                        preset.id == currentAvatarId;
                                    return _ProfileAvatarChoice(
                                      preset: preset,
                                      isSelected: isSelected,
                                      avatarSize: avatarSize,
                                      onTap: () =>
                                          Navigator.of(context).pop(preset.id),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarChoice extends StatelessWidget {
  const _ProfileAvatarChoice({
    required this.preset,
    required this.isSelected,
    required this.avatarSize,
    required this.onTap,
  });

  final _ProfileAvatarPreset preset;
  final bool isSelected;
  final double avatarSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('profile_avatar_choice_${preset.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(6),
        decoration: AppGlassTheme.surfaceDecoration(
          radius: 14,
          borderAlpha: isSelected ? 0.86 : 0.34,
          colors: <Color>[
            Colors.white.withValues(alpha: isSelected ? 0.72 : 0.48),
            const Color(0xFF6BB38A).withValues(alpha: isSelected ? 0.14 : 0.06),
          ],
          shadows: const <BoxShadow>[],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: ClipOval(
                child: _ProfileAvatarPresetImage(avatarId: preset.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
