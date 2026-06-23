part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderEmptyState on _DashboardBuilderScreenState {
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final titleFontSize = maxWidth < 360 ? 18.0 : 22.0;
        final bodyFontSize = maxWidth < 360 ? 13.0 : 14.0;
        final topBottomPadding = maxHeight < 560 ? 20.0 : 30.0;

        return Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              30,
              topBottomPadding,
              30,
              topBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เพิ่มวิดเจ็ตเพื่อเริ่มใช้งาน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                    color: _sheetHeadlineColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'แตะปุ่ม + หรือลากและวางวิดเจ็ต\nเพื่อสร้างแดชบอร์ดของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    height: 1.3,
                    color: _themePreset.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassEmptyState() {
    assert(() {
      _buildEmptyState;
      return true;
    }());
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final titleFontSize = maxWidth < 360 ? 18.0 : 22.0;
        final bodyFontSize = maxWidth < 360 ? 13.0 : 14.0;
        final topBottomPadding = maxHeight < 560 ? 20.0 : 30.0;
        final isTablet = AppResponsiveLayout.isTabletWidth(
          MediaQuery.sizeOf(context).width,
        );
        final emptyStateAlignment = isTablet
            ? const Alignment(0, 0.28)
            : const Alignment(0, 0.78);

        return Align(
          alignment: emptyStateAlignment,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              30,
              topBottomPadding,
              30,
              topBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      key: const ValueKey<String>(
                        'dashboard_builder_empty_state_card',
                      ),
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                      decoration: _themedAppBarDecoration(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'เริ่มจัดวางวิดเจ็ตในโหมดแก้ไข',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                              color: _sheetHeadlineColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'แตะปุ่ม + เพื่อเพิ่มวิดเจ็ต แล้วลากจัดวางบนพื้นที่นี้',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: bodyFontSize,
                              height: 1.35,
                              color: _themePreset.mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 116,
                  child: Stack(
                    children: [
                      Align(
                        alignment: const Alignment(-0.58, 0),
                        child: SizedBox(
                          width: 116,
                          height: 116,
                          child: Opacity(
                            opacity: _themePreset.isDark ? 0.88 : 1.0,
                            child: Image.asset(
                              'assets/icons/mascot/mascot_editMode.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(0.58, 0),
                        child: SizedBox(
                          width: 116,
                          height: 116,
                          child: Opacity(
                            opacity: _themePreset.isDark ? 0.88 : 1.0,
                            child: Image.asset(
                              'assets/icons/mascot/mascot_editMode2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
