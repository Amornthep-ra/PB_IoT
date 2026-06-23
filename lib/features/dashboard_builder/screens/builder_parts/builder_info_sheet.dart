part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderInfoSheet on _DashboardBuilderScreenState {
  Future<void> _openEditModeInfoSheet() async {
    const rows = <MapEntry<String, String>>[
      MapEntry(
        'เพิ่มวิดเจ็ต',
        'แตะปุ่ม + ตรงกลางด้านล่างเพื่อเพิ่ม widget ใหม่ลงบนพื้นที่ว่าง dashboard',
      ),
      MapEntry(
        'เลือกวิดเจ็ต',
        'แตะ widget หนึ่งครั้งเพื่อเลือก และเปิดปุ่ม Settings หรือ Delete',
      ),
      MapEntry('ย้ายวิดเจ็ต', 'กดค้างบน widget แล้วลากไปตำแหน่งใหม่บน grid'),
      MapEntry(
        'ปรับขนาด',
        'เลือก widget แล้วลากจุดจับรอบกรอบเพื่อปรับขนาดความกว้างและความสูง',
      ),
      MapEntry(
        'เลือกหลายวิดเจ็ต',
        'ใช้ปุ่ม Select ด้านล่างเพื่อเข้าโหมดเลือกหลายชิ้น แล้วแตะเลือก widget หลายตัวได้',
      ),
      MapEntry(
        'คัดลอกวิดเจ็ต',
        'เลือก widget แล้วกด Duplicate เพื่อสร้างสำเนาใกล้ตำแหน่งเดิม',
      ),
      MapEntry(
        'ตั้งค่าวิดเจ็ต',
        'กด Settings เพื่อแก้ Data Key, title, style และค่าต่างๆ ของ widget',
      ),
      MapEntry(
        'บันทึกเลย์เอาต์',
        'เมื่อจัดวางเสร็จแล้วกด บันทึก ด้านบนเพื่อบันทึก layout ล่าสุด',
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: DecoratedBox(
              decoration: _themedModalSurfaceDecoration(
                radius: 28,
                borderAlpha: _themePreset.isDark ? 0.38 : 0.64,
                shadows: AppGlassTheme.shadowMd,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: AppGlassTheme.surfaceDecoration(
                                radius: 15,
                                borderAlpha: 0.34,
                                colors: <Color>[
                                  _themePreset.surfaceColor.withValues(
                                    alpha: _themePreset.isDark ? 0.42 : 0.62,
                                  ),
                                  const Color(
                                    0xFFEAF3FF,
                                  ).withValues(alpha: 0.26),
                                ],
                                shadows: const <BoxShadow>[],
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: _themePreset.bodyColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'คู่มือโหมดแก้ไข',
                                style: TextStyle(color: _sheetHeadlineColor),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'วิธีใช้งานหน้าโหมดแก้ไขและการจัดการ widget',
                                style: TextStyle(
                                  color: _themePreset.mutedTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: AppGlassTheme.surfaceDecoration(
                                    radius: 15,
                                    borderAlpha: 0.3,
                                    colors: <Color>[
                                      _themePreset.surfaceColor.withValues(
                                        alpha: _themePreset.isDark
                                            ? 0.36
                                            : 0.54,
                                      ),
                                      const Color(
                                        0xFFF2F6FB,
                                      ).withValues(alpha: 0.2),
                                    ],
                                    shadows: const <BoxShadow>[],
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: _themePreset.mutedTextColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final row in rows)
                              _BuilderInfoRow(
                                label: row.key,
                                value: row.value,
                                themePreset: _themePreset,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
