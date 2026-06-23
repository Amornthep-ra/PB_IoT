part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderAppBar on _DashboardBuilderScreenState {
  Widget _buildSaveAction() {
    final canSave = !_isLayoutLoading && !_isLayoutSaving && _hasUnsavedChanges;
    return Tooltip(
      message: canSave ? 'บันทึกเลย์เอาต์' : 'ไม่มีการเปลี่ยนแปลงให้บันทึก',
      child: DecoratedBox(
        decoration: canSave
            ? AppGlassTheme.accentDecoration(
                radius: 999,
                borderColor: DashboardRuntimeTheme.surfaceBorderFocusColor,
                colors: const <Color>[
                  DashboardRuntimeTheme.buttonStartColor,
                  DashboardRuntimeTheme.buttonEndColor,
                ],
                glowColor: DashboardRuntimeTheme.buttonGlowColor,
              )
            : AppGlassTheme.surfaceDecoration(
                radius: 999,
                borderAlpha: 0.60,
                colors: <Color>[
                  _themePreset.surfaceColor.withValues(alpha: 0.56),
                  _themePreset.cardColor.withValues(alpha: 0.32),
                ],
                shadows: const <BoxShadow>[],
              ),
        child: TextButton.icon(
          onPressed: canSave ? () => _saveLayout() : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            foregroundColor: canSave
                ? Colors.white
                : _appBarMutedForegroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            backgroundColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: _isLayoutSaving
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save_rounded, size: 13),
          label: const Text(
            'บันทึก',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoAction() {
    final canOpenInfo = _isEditMode;
    return DecoratedBox(
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 999,
        borderAlpha: canOpenInfo ? 0.66 : 0.56,
        colors: <Color>[
          _themePreset.surfaceColor.withValues(
            alpha: canOpenInfo ? 0.76 : 0.50,
          ),
          _themePreset.cardColor.withValues(alpha: canOpenInfo ? 0.48 : 0.28),
        ],
        shadows: const <BoxShadow>[],
      ),
      child: Semantics(
        button: true,
        enabled: canOpenInfo,
        label: 'วิธีใช้งาน',
        child: IconButton(
          onPressed: canOpenInfo ? _openEditModeInfoSheet : null,
          icon: Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: canOpenInfo
                ? _appBarActionForegroundColor
                : _appBarMutedForegroundColor,
          ),
          padding: const EdgeInsets.all(7),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          splashRadius: 18,
          tooltip: 'วิธีใช้งาน',
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildBuilderAppBar(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = AppResponsiveLayout.isTabletWidth(mediaQuery.size.width);
    final dashboardShellWidth = AppResponsiveLayout.dashboardShellWidth(
      mediaQuery.size.width,
    );
    if (!isTablet) {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: _appBarForegroundColor,
        toolbarHeight: 54,
        titleSpacing: 20,
        title: Text(
          'โหมดแก้ไข',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _appBarForegroundColor,
          ),
        ),
        flexibleSpace: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: _BuilderAppBarGlass(
              decoration: _themedSurfaceDecoration(
                radius: 22,
                borderAlpha: 0.60,
                shadows: AppGlassTheme.shadowMd,
              ),
            ),
          ),
        ),
        actions: [
          _buildSaveAction(),
          const SizedBox(width: 5),
          _buildInfoAction(),
          const SizedBox(width: 8),
        ],
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      foregroundColor: _appBarForegroundColor,
      toolbarHeight: 54,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dashboardShellWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'โหมดแก้ไข',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _appBarForegroundColor,
                    ),
                  ),
                ),
                _buildSaveAction(),
                const SizedBox(width: 5),
                _buildInfoAction(),
              ],
            ),
          ),
        ),
      ),
      flexibleSpace: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dashboardShellWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: _BuilderAppBarGlass(
                decoration: _themedSurfaceDecoration(
                  radius: 22,
                  borderAlpha: 0.60,
                  shadows: AppGlassTheme.shadowMd,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
