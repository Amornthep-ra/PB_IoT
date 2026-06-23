import 'package:flutter/material.dart';

import '../models/dashboard_item.dart';
import '../models/dashboard_theme_preset.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';

enum _AddWidgetSheetSizeClass { compact, regular, expanded }

class _AddWidgetGridMetrics {
  const _AddWidgetGridMetrics({
    required this.sizeClass,
    required this.crossAxisCount,
    required this.spacing,
    required this.runSpacing,
    required this.childAspectRatio,
  });

  final _AddWidgetSheetSizeClass sizeClass;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  factory _AddWidgetGridMetrics.resolve(double width, double shortestSide) {
    if (shortestSide >= 720 || width >= 760) {
      return const _AddWidgetGridMetrics(
        sizeClass: _AddWidgetSheetSizeClass.expanded,
        crossAxisCount: 5,
        spacing: 14,
        runSpacing: 16,
        childAspectRatio: 0.96,
      );
    }

    if (shortestSide >= 600 || width >= 560) {
      return const _AddWidgetGridMetrics(
        sizeClass: _AddWidgetSheetSizeClass.regular,
        crossAxisCount: 4,
        spacing: 12,
        runSpacing: 14,
        childAspectRatio: 0.94,
      );
    }

    return const _AddWidgetGridMetrics(
      sizeClass: _AddWidgetSheetSizeClass.compact,
      crossAxisCount: 3,
      spacing: 9,
      runSpacing: 10,
      childAspectRatio: 0.98,
    );
  }
}

class AddWidgetSheet extends StatelessWidget {
  const AddWidgetSheet({
    super.key,
    required this.scrollController,
    required this.themePreset,
  });

  final ScrollController? scrollController;
  final DashboardThemePreset themePreset;

  static const List<DashboardItemType> _orderedTypes = [
    DashboardItemType.button,
    DashboardItemType.toggle,
    DashboardItemType.slider,
    DashboardItemType.stepH,
    DashboardItemType.stepV,
    DashboardItemType.gauge,
    DashboardItemType.valueLabel,
    DashboardItemType.trend,
    DashboardItemType.led,
  ];

  String _label(DashboardItemType type) {
    switch (type) {
      case DashboardItemType.button:
        return 'ปุ่ม';
      case DashboardItemType.slider:
        return 'สไลด์';
      case DashboardItemType.stepH:
        return 'ปรับค่า H';
      case DashboardItemType.stepV:
        return 'ปรับค่า V';
      case DashboardItemType.gauge:
        return 'เกจ';
      case DashboardItemType.toggle:
        return 'สวิตช์';
      case DashboardItemType.valueLabel:
        return 'แสดงค่า';
      case DashboardItemType.trend:
        return 'กราฟ';
      case DashboardItemType.led:
        return 'ไฟสถานะ';
    }
  }

  IconData _icon(DashboardItemType type) {
    switch (type) {
      case DashboardItemType.button:
        return Icons.power_settings_new_rounded;
      case DashboardItemType.slider:
        return Icons.tune_rounded;
      case DashboardItemType.stepH:
        return Icons.swap_horiz_rounded;
      case DashboardItemType.stepV:
        return Icons.swap_vert_rounded;
      case DashboardItemType.gauge:
        return Icons.speed_rounded;
      case DashboardItemType.toggle:
        return Icons.toggle_on_rounded;
      case DashboardItemType.valueLabel:
        return Icons.pin_outlined;
      case DashboardItemType.trend:
        return Icons.show_chart_rounded;
      case DashboardItemType.led:
        return Icons.lightbulb_outline_rounded;
    }
  }

  Color _glowColor(DashboardItemType type) {
    switch (type) {
      case DashboardItemType.button:
        return const Color(0xFF9BC8A7);
      case DashboardItemType.slider:
        return const Color(0xFFA8D6C4);
      case DashboardItemType.stepH:
      case DashboardItemType.stepV:
        return const Color(0xFFA8D3F5);
      case DashboardItemType.gauge:
        return const Color(0xFFFFC19A);
      case DashboardItemType.toggle:
        return const Color(0xFF99D1AF);
      case DashboardItemType.valueLabel:
        return const Color(0xFFAEC7E6);
      case DashboardItemType.trend:
        return const Color(0xFFA9D4F8);
      case DashboardItemType.led:
        return const Color(0xFFA7DDB8);
    }
  }

  Color _sheetBackgroundStart() {
    return themePreset.isDark
        ? themePreset.surfaceColor
        : const Color(0xFFF9FBFE);
  }

  Color _sheetBackgroundEnd() {
    return themePreset.isDark
        ? themePreset.cardColor
        : DashboardRuntimeTheme.backgroundColor;
  }

  Color _sheetBorderColor([double alpha = 1]) {
    return themePreset.isDark
        ? themePreset.borderColor.withValues(alpha: alpha)
        : Colors.white.withValues(alpha: alpha);
  }

  Color _cardBackgroundColor([double alpha = 1]) {
    return themePreset.isDark
        ? themePreset.surfaceColor.withValues(alpha: alpha)
        : Colors.white.withValues(alpha: alpha);
  }

  Widget _buildMascotGuideCard() {
    return Container(
      key: const ValueKey<String>('add_widget_guide_card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _cardBackgroundColor(themePreset.isDark ? 0.86 : 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _sheetBorderColor(themePreset.isDark ? 0.68 : 0.86),
          width: 1,
        ),
        boxShadow: themePreset.isDark
            ? const <BoxShadow>[]
            : const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Image.asset(
              'assets/icons/mascot/mascot_add_widget.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เลือกตัวช่วยให้เหมาะกับงาน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: themePreset.headlineColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ปุ่ม ใช้สั่งงานอุปกรณ์\nสวิตช์ ใช้เปิดหรือปิดสถานะ\nสไลด์ ใช้ปรับค่าที่ต้องการ\nเกจ / แสดงค่า ใช้ดูข้อมูล',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.18,
                    color: themePreset.mutedTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    final isTablet = shortestSide >= 600;
    final gridMetrics = _AddWidgetGridMetrics.resolve(
      mediaQuery.size.width,
      shortestSide,
    );
    final isCompactPhone =
        gridMetrics.sizeClass == _AddWidgetSheetSizeClass.compact;
    final handleTitleGap = isCompactPhone ? 12.0 : (isTablet ? 14.0 : 16.0);
    final titleGuideGap = isCompactPhone ? 10.0 : (isTablet ? 12.0 : 14.0);
    final guideGridGap = isCompactPhone ? 12.0 : (isTablet ? 14.0 : 16.0);
    final sheetPadding = EdgeInsets.fromLTRB(
      16,
      isCompactPhone ? 10 : 14,
      16,
      isCompactPhone ? 18 : 22,
    );
    final titleFontSize = isCompactPhone ? 21.0 : 22.0;

    return Material(
      key: const ValueKey<String>('add_widget_sheet_surface'),
      color: themePreset.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_sheetBackgroundStart(), _sheetBackgroundEnd()],
          ),
          border: Border.all(
            color: _sheetBorderColor(themePreset.isDark ? 0.72 : 0.84),
            width: 1.1,
          ),
          boxShadow: themePreset.isDark
              ? const [
                  BoxShadow(
                    color: Color(0x40111827),
                    blurRadius: 26,
                    offset: Offset(0, -10),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: DashboardRuntimeTheme.shadowLightColor,
                    blurRadius: 9,
                    offset: Offset(-5, -5),
                  ),
                  BoxShadow(
                    color: DashboardRuntimeTheme.shadowDarkColor,
                    blurRadius: 14,
                    offset: Offset(0, -5),
                  ),
                  BoxShadow(
                    color: Color(0x0F677E92),
                    blurRadius: 18,
                    offset: Offset(0, -6),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: sheetPadding,
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: themePreset.borderColor.withValues(
                      alpha: themePreset.isDark ? 0.72 : 0.46,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: handleTitleGap),
                Text(
                  'เพิ่มวิดเจ็ต',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: themePreset.headlineColor,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: titleGuideGap),
                _buildMascotGuideCard(),
                SizedBox(height: guideGridGap),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final effectiveGridMetrics = _AddWidgetGridMetrics.resolve(
                      constraints.maxWidth,
                      shortestSide,
                    );
                    final totalSpacing =
                        effectiveGridMetrics.spacing *
                        (effectiveGridMetrics.crossAxisCount - 1);
                    final optionWidth =
                        ((constraints.maxWidth - totalSpacing) /
                                effectiveGridMetrics.crossAxisCount)
                            .clamp(80.0, 112.0)
                            .toDouble();
                    final iconBoxSize = (optionWidth * 0.5)
                        .clamp(40.0, 52.0)
                        .toDouble();
                    final optionHeight =
                        (optionWidth / effectiveGridMetrics.childAspectRatio)
                            .clamp(88.0, 112.0)
                            .toDouble();
                    final optionCards = [
                      for (final type in _orderedTypes)
                        _AddWidgetOption(
                          key: ValueKey<String>(
                            'add_widget_option_${type.name}',
                          ),
                          themePreset: themePreset,
                          label: _label(type),
                          icon: _icon(type),
                          glowColor: _glowColor(type),
                          width: optionWidth,
                          height: optionHeight,
                          iconBoxSize: iconBoxSize,
                          onPressed: () => Navigator.of(context).pop(type),
                        ),
                    ];

                    if (effectiveGridMetrics.sizeClass !=
                        _AddWidgetSheetSizeClass.compact) {
                      final gridWidth =
                          (optionWidth * effectiveGridMetrics.crossAxisCount) +
                          (effectiveGridMetrics.spacing *
                              (effectiveGridMetrics.crossAxisCount - 1));
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          key: const ValueKey<String>('add_widget_option_grid'),
                          width: gridWidth,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: effectiveGridMetrics.spacing,
                            runSpacing: effectiveGridMetrics.runSpacing,
                            children: [
                              for (final option in optionCards)
                                SizedBox(
                                  width: optionWidth,
                                  height: optionHeight,
                                  child: option,
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      key: const ValueKey<String>('add_widget_option_grid'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orderedTypes.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: effectiveGridMetrics.crossAxisCount,
                        crossAxisSpacing: effectiveGridMetrics.spacing,
                        mainAxisSpacing: effectiveGridMetrics.runSpacing,
                        childAspectRatio: effectiveGridMetrics.childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        return optionCards[index];
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddWidgetOption extends StatelessWidget {
  const _AddWidgetOption({
    super.key,
    required this.themePreset,
    required this.label,
    required this.icon,
    required this.glowColor,
    required this.width,
    required this.height,
    required this.iconBoxSize,
    required this.onPressed,
  });

  final DashboardThemePreset themePreset;
  final String label;
  final IconData icon;
  final Color glowColor;
  final double width;
  final double height;
  final double iconBoxSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accentColor = Color.lerp(glowColor, themePreset.bodyColor, 0.28)!;
    final iconTileStart = themePreset.isDark
        ? themePreset.surfaceColor.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.94);
    final iconTileEnd = themePreset.isDark
        ? themePreset.cardColor.withValues(alpha: 0.92)
        : glowColor.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.fromLTRB(
            10,
            10,
            10,
            (height * 0.075).clamp(6.0, 8.0).toDouble(),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themePreset.isDark
                    ? themePreset.surfaceColor
                    : Colors.white.withValues(alpha: 0.92),
                themePreset.isDark
                    ? themePreset.cardColor
                    : glowColor.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: themePreset.borderColor.withValues(
                alpha: themePreset.isDark ? 0.78 : 0.70,
              ),
              width: 1,
            ),
            boxShadow: [
              if (!themePreset.isDark)
                const BoxShadow(
                  color: DashboardRuntimeTheme.shadowLightColor,
                  blurRadius: 8,
                  offset: Offset(-4, -4),
                ),
              BoxShadow(
                color: glowColor.withValues(alpha: 0.13),
                blurRadius: 16,
                spreadRadius: 0.2,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: themePreset.isDark
                    ? const Color(0x40111827)
                    : DashboardRuntimeTheme.shadowDarkColor,
                blurRadius: 13,
                offset: const Offset(5, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [iconTileStart, iconTileEnd],
                      ),
                      border: Border.all(
                        color: glowColor.withValues(
                          alpha: themePreset.isDark ? 0.38 : 0.20,
                        ),
                        width: 1,
                      ),
                      boxShadow: [
                        if (!themePreset.isDark)
                          const BoxShadow(
                            color: DashboardRuntimeTheme.shadowLightColor,
                            blurRadius: 7,
                            offset: Offset(-3, -3),
                          ),
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.20),
                          blurRadius: 14,
                          spreadRadius: 0.4,
                        ),
                        BoxShadow(
                          color: themePreset.isDark
                              ? const Color(0x33111827)
                              : DashboardRuntimeTheme.shadowDarkColor,
                          blurRadius: 9,
                          offset: const Offset(4, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: iconBoxSize * 0.16,
                          left: iconBoxSize * 0.18,
                          child: Container(
                            width: iconBoxSize * 0.22,
                            height: iconBoxSize * 0.08,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: themePreset.isDark ? 0.10 : 0.70,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Icon(
                          icon,
                          color: accentColor,
                          size: (iconBoxSize * 0.52)
                              .clamp(22.0, 28.0)
                              .toDouble(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: (height * 0.055).clamp(4.0, 6.0).toDouble()),
              Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (width * 0.145).clamp(12.5, 15.0).toDouble(),
                    fontWeight: FontWeight.w700,
                    color: themePreset.headlineColor,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  width: (width * 0.18).clamp(18.0, 28.0).toDouble(),
                  height: 3,
                  decoration: BoxDecoration(
                    color: glowColor.withValues(
                      alpha: themePreset.isDark ? 0.34 : 0.22,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
