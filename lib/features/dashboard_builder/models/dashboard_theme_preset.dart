import 'package:flutter/material.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';

const String customDashboardThemeName = 'Custom';

class DashboardThemePreset {
  const DashboardThemePreset({
    required this.name,
    required this.pageStart,
    required this.pageEnd,
    required this.canvasColors,
    required this.gridColor,
    this.headlineColor = const Color(0xFF15212B),
    this.bodyColor = const Color(0xFF344054),
    this.mutedTextColor = const Color(0xFF667085),
    this.surfaceColor = const Color(0xFFF8FAFD),
    this.cardColor = const Color(0xFFEFF3F8),
    this.borderColor = const Color(0xFFE2E8F0),
    this.accentColor = const Color(0xFF16A34A),
    this.dangerColor = const Color(0xFFEF4444),
    this.isDark = false,
  });

  final String name;
  final Color pageStart;
  final Color pageEnd;
  final List<Color> canvasColors;
  final Color gridColor;

  final Color headlineColor;
  final Color bodyColor;
  final Color mutedTextColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;
  final Color dangerColor;

  final bool isDark;
}

DashboardThemePreset dashboardCustomThemePreset({
  required Color canvasColor,
  required Color gridColor,
}) {
  final normalizedCanvasColor = canvasColor.withAlpha(255);

  return DashboardThemePreset(
    name: customDashboardThemeName,
    pageStart: normalizedCanvasColor,
    pageEnd: normalizedCanvasColor,
    canvasColors: <Color>[
      normalizedCanvasColor,
      normalizedCanvasColor.withValues(alpha: 0.96),
      normalizedCanvasColor.withValues(alpha: 0.92),
    ],
    gridColor: gridColor,
  );
}

const List<DashboardThemePreset> dashboardThemePresets =
    <DashboardThemePreset>[
  DashboardThemePreset(
    name: 'Default',
    pageStart: DashboardRuntimeTheme.backgroundColor,
    pageEnd: Color(0xFFF8FBF8),
    canvasColors: <Color>[
      Color(0x8FFFFFFF),
      Color(0x57F2F8FB),
      Color(0x42EAF3F8),
    ],
    gridColor: Color(0x229FB2A6),
  ),
  DashboardThemePreset(
    name: 'Mint',
    pageStart: Color(0xFFEAF7F1),
    pageEnd: Color(0xFFF7FBF6),
    canvasColors: <Color>[
      Color(0x99FFFFFF),
      Color(0x66E2F3EA),
      Color(0x4CD4ECE2),
    ],
    gridColor: Color(0x2A62A884),
  ),
  DashboardThemePreset(
    name: 'Sky',
    pageStart: Color(0xFFEAF3FF),
    pageEnd: Color(0xFFF7FAFF),
    canvasColors: <Color>[
      Color(0x99FFFFFF),
      Color(0x66E4F0FF),
      Color(0x4CD6E7FA),
    ],
    gridColor: Color(0x2A6A9ED1),
  ),
  DashboardThemePreset(
    name: 'Dusk',
    pageStart: Color(0xFFF2EEFA),
    pageEnd: Color(0xFFFAF7FB),
    canvasColors: <Color>[
      Color(0x99FFFFFF),
      Color(0x66ECE6F7),
      Color(0x4CDFD7EF),
    ],
    gridColor: Color(0x2A8B76C9),
  ),
  DashboardThemePreset(
    name: 'Stone',
    pageStart: Color(0xFFECEFF2),
    pageEnd: Color(0xFFF7F8F9),
    canvasColors: <Color>[
      Color(0x99FFFFFF),
      Color(0x66E6EBEF),
      Color(0x4CD9E0E6),
    ],
    gridColor: Color(0x2A7B8C99),
  ),
  DashboardThemePreset(
    name: 'Warm',
    pageStart: Color(0xFFF7F1E8),
    pageEnd: Color(0xFFFBF8F2),
    canvasColors: <Color>[
      Color(0x99FFFFFF),
      Color(0x66F3E8DA),
      Color(0x4CE9D9C7),
    ],
    gridColor: Color(0x2AAE8A5F),
  ),
  DashboardThemePreset(
    name: 'Dark',
    pageStart: Color(0xFF111827),
    pageEnd: Color(0xFF172033),
    canvasColors: <Color>[
      Color(0xF01B2538),
      Color(0xE8202E45),
      Color(0xDD121A2A),
    ],
    gridColor: Color(0xFF334155),
    headlineColor: Color(0xFFF8FAFC),
    bodyColor: Color(0xFFE2E8F0),
    mutedTextColor: Color(0xFF94A3B8),
    surfaceColor: Color(0xFF1E203B),
    cardColor: Color(0xFF111827),
    borderColor: Color(0xFF334155),
    accentColor: Color(0xFF38BDF8),
    isDark: true,
  ),
];

DashboardThemePreset dashboardThemePresetByName(String? name) {
  final normalizedName = name?.trim().toLowerCase();

  if (normalizedName == null || normalizedName.isEmpty) {
    return dashboardThemePresets.first;
  }

  for (final preset in dashboardThemePresets) {
    if (preset.name.toLowerCase() == normalizedName) {
      return preset;
    }
  }

  return dashboardThemePresets.first;
}