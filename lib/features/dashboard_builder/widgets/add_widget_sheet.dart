import 'package:flutter/material.dart';

import '../models/dashboard_item.dart';
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
      spacing: 10,
      runSpacing: 12,
      childAspectRatio: 0.9,
    );
  }
}

class AddWidgetSheet extends StatelessWidget {
  const AddWidgetSheet({super.key, required this.scrollController});

  final ScrollController? scrollController;

  static const List<DashboardItemType> _orderedTypes = [
    DashboardItemType.button,
    DashboardItemType.toggle,
    DashboardItemType.slider,
    DashboardItemType.gauge,
    DashboardItemType.valueLabel,
  ];

  String _label(DashboardItemType type) {
    switch (type) {
      case DashboardItemType.button:
        return 'Button';
      case DashboardItemType.slider:
        return 'Slider';
      case DashboardItemType.gauge:
        return 'Gauge';
      case DashboardItemType.toggle:
        return 'Toggle';
      case DashboardItemType.valueLabel:
        return 'Value Label';
    }
  }

  IconData _icon(DashboardItemType type) {
    switch (type) {
      case DashboardItemType.button:
        return Icons.power_settings_new_rounded;
      case DashboardItemType.slider:
        return Icons.tune_rounded;
      case DashboardItemType.gauge:
        return Icons.speed_rounded;
      case DashboardItemType.toggle:
        return Icons.toggle_on_rounded;
      case DashboardItemType.valueLabel:
        return Icons.pin_outlined;
    }
  }

  Color _glowColor(DashboardItemType type) {
    switch (type) {
      case DashboardItemType.button:
        return const Color(0xFF9BC8A7);
      case DashboardItemType.slider:
        return const Color(0xFFA8D6C4);
      case DashboardItemType.gauge:
        return const Color(0xFFFFC19A);
      case DashboardItemType.toggle:
        return const Color(0xFF99D1AF);
      case DashboardItemType.valueLabel:
        return const Color(0xFFAEC7E6);
    }
  }

  Widget _buildMascotGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.86),
          width: 1,
        ),
        boxShadow: const [
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
            width: 78,
            height: 78,
            child: Image.asset(
              'assets/icons/mascot/mascot_add_widget.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เลือกตัวช่วยให้เหมาะกับงาน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DashboardRuntimeTheme.headlineColor,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Button ใช้สั่งงานอุปกรณ์\nToggle ใช้เปิดหรือปิดสถานะ\nSlider ใช้ปรับค่าที่ต้องการ\nGauge ใช้ดูค่าจากเซนเซอร์\nValue Label ใช้แสดงค่าตัวเลขหรือข้อความ',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: DashboardRuntimeTheme.mutedTextColor,
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

    return Material(
          color: DashboardRuntimeTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF9FBFE), DashboardRuntimeTheme.backgroundColor],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.84),
                width: 1.1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: DashboardRuntimeTheme.shadowLightColor,
                  blurRadius: 14,
                  offset: Offset(-8, -8),
                ),
                BoxShadow(
                  color: DashboardRuntimeTheme.shadowDarkColor,
                  blurRadius: 22,
                  offset: Offset(0, -8),
                ),
                BoxShadow(
                  color: Color(0x14677E92),
                  blurRadius: 28,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: DashboardRuntimeTheme.surfaceBorderColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Add Widget',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: DashboardRuntimeTheme.headlineColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMascotGuideCard(),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gridMetrics = _AddWidgetGridMetrics.resolve(
                          constraints.maxWidth,
                          shortestSide,
                        );
                        final totalSpacing =
                            gridMetrics.spacing * (gridMetrics.crossAxisCount - 1);
                        final optionWidth =
                            ((constraints.maxWidth - totalSpacing) /
                                    gridMetrics.crossAxisCount)
                                .clamp(80.0, 112.0)
                                .toDouble();
                        final iconBoxSize = (optionWidth * 0.5)
                            .clamp(42.0, 54.0)
                            .toDouble();
                        final optionHeight =
                            (optionWidth / gridMetrics.childAspectRatio)
                                .clamp(92.0, 116.0)
                                .toDouble();

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _orderedTypes.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridMetrics.crossAxisCount,
                            crossAxisSpacing: gridMetrics.spacing,
                            mainAxisSpacing: gridMetrics.runSpacing,
                            childAspectRatio: gridMetrics.childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            final type = _orderedTypes[index];
                            return _AddWidgetOption(
                              label: _label(type),
                              icon: _icon(type),
                              glowColor: _glowColor(type),
                              width: optionWidth,
                              height: optionHeight,
                              iconBoxSize: iconBoxSize,
                              onPressed: () => Navigator.of(context).pop(type),
                            );
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
    required this.label,
    required this.icon,
    required this.glowColor,
    required this.width,
    required this.height,
    required this.iconBoxSize,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color glowColor;
  final double width;
  final double height;
  final double iconBoxSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
            (height * 0.09).clamp(8.0, 10.0).toDouble(),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7FAFE), DashboardRuntimeTheme.cardColor],
            ),
            border: Border.all(
              color: DashboardRuntimeTheme.surfaceBorderColor.withValues(alpha: 0.85),
              width: 1,
            ),
            boxShadow: [
              const BoxShadow(
                color: DashboardRuntimeTheme.shadowLightColor,
                blurRadius: 10,
                offset: Offset(-5, -5),
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: 0.16),
                blurRadius: 18,
                spreadRadius: 0.4,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: DashboardRuntimeTheme.shadowDarkColor,
                blurRadius: 16,
                offset: Offset(6, 8),
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
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DashboardRuntimeTheme.surfaceColor,
                          DashboardRuntimeTheme.cardColor,
                        ],
                      ),
                      border: Border.all(
                        color: DashboardRuntimeTheme.surfaceBorderColor.withValues(
                          alpha: 0.72,
                        ),
                        width: 0.9,
                      ),
                      boxShadow: [
                        const BoxShadow(
                          color: DashboardRuntimeTheme.shadowLightColor,
                          blurRadius: 8,
                          offset: Offset(-3, -3),
                        ),
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.16),
                          blurRadius: 14,
                          spreadRadius: 0.2,
                        ),
                        const BoxShadow(
                          color: DashboardRuntimeTheme.shadowDarkColor,
                          blurRadius: 10,
                          offset: Offset(4, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Color.lerp(
                        glowColor,
                        DashboardRuntimeTheme.fieldTextColor,
                        0.38,
                      ),
                      size: (iconBoxSize * 0.52).clamp(22.0, 28.0).toDouble(),
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
                    color: DashboardRuntimeTheme.headlineColor,
                    letterSpacing: -0.1,
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
