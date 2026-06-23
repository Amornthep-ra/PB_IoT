part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderSelectedInspector on _DashboardBuilderScreenState {
  Widget _buildSelectedWidgetInspector(DashboardItem item) {
    final pin = item.dataKey?.trim();
    final title = _selectedWidgetInspectorTitle(item);

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: _themedSurfaceDecoration(
                    radius: 22,
                    borderAlpha: 0.54,
                    shadows: AppGlassTheme.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _InspectorPill(
                              label: title,
                              themePreset: _themePreset,
                            ),
                            _InspectorPill(
                              label: pin == null || pin.isEmpty
                                  ? 'V Pin: ไม่มี'
                                  : 'V Pin: $pin',
                              muted: pin == null || pin.isEmpty,
                              themePreset: _themePreset,
                            ),
                            _InspectorPill(
                              label: 'ขนาด: ${item.rect.w}x${item.rect.h}',
                              themePreset: _themePreset,
                            ),
                            _InspectorPill(
                              label: 'x:${item.rect.x} y:${item.rect.y}',
                              themePreset: _themePreset,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _selectedWidgetInspectorTitle(DashboardItem item) {
    final title = item.title.trim();
    if (title.isNotEmpty) {
      return title;
    }

    return _fallbackWidgetTypeLabel(item.type);
  }

  bool _isFactoryDefaultInspectorTitle(DashboardItem item, String title) {
    return dashboardIsDefaultTitleForType(item.type, title);
  }

  String _fallbackWidgetTypeLabel(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.button => 'ปุ่ม',
      DashboardItemType.slider => 'สไลด์',
      DashboardItemType.stepH => 'ปรับค่า H',
      DashboardItemType.stepV => 'ปรับค่า V',
      DashboardItemType.gauge => 'เกจ',
      DashboardItemType.toggle => 'สวิตช์',
      DashboardItemType.valueLabel => 'แสดงค่า',
      DashboardItemType.trend => 'กราฟแนวโน้ม',
      DashboardItemType.led => 'ไฟสถานะ',
    };
  }

  Widget _buildSelectedWidgetInspectorSlot(DashboardItem? item) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 210),
      reverseDuration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ClipRect(
          child: SizeTransition(
            sizeFactor: curvedAnimation,
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            ),
          ),
        );
      },
      child: item == null
          ? const SizedBox.shrink(key: ValueKey('empty-inspector'))
          : KeyedSubtree(
              key: const ValueKey('visible-inspector'),
              child: _buildSelectedWidgetInspector(item),
            ),
    );
  }
}
