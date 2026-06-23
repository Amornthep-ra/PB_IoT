import 'package:flutter/material.dart';

import '../../../models/dashboard_item.dart';
import '../../../../dashboard/widgets/dashboard_runtime_theme.dart';

enum WidgetSettingsBorderWidthField {
  none,
  button,
  valueLabel,
  gauge,
  slider,
  toggle,
}

enum WidgetSettingsBorderColorField { none, buttonBorderColor, shellColor }

class WidgetSettingsCapabilities {
  const WidgetSettingsCapabilities({
    required this.primaryLabel,
    required this.primaryPickerTitle,
    this.showPrimaryColor = true,
    this.showSecondaryColor = false,
    this.secondaryPickerTitle = 'สีรอง/ปิด',
    this.backgroundPickerTitle = 'สีพื้นหลัง',
    this.borderColorField = WidgetSettingsBorderColorField.shellColor,
    this.borderPickerTitle = 'สีขอบ',
    this.borderWidthField = WidgetSettingsBorderWidthField.none,
    this.showGlow = true,
  });

  factory WidgetSettingsCapabilities.forType(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.button => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีหลักของปุ่ม',
        showSecondaryColor: true,
        secondaryPickerTitle: 'สีรอง/ปิดของปุ่ม',
        backgroundPickerTitle: 'พื้นหลังของปุ่ม',
        borderColorField: WidgetSettingsBorderColorField.buttonBorderColor,
        borderPickerTitle: 'สีขอบของปุ่ม',
        borderWidthField: WidgetSettingsBorderWidthField.button,
      ),
      DashboardItemType.slider => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีหลักของสไลเดอร์',
        backgroundPickerTitle: 'พื้นหลังของสไลเดอร์',
        borderPickerTitle: 'สีขอบของสไลเดอร์',
        borderWidthField: WidgetSettingsBorderWidthField.slider,
      ),
      DashboardItemType.stepH ||
      DashboardItemType.stepV => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีหลักของตัวควบคุม',
        showPrimaryColor: false,
        backgroundPickerTitle: 'พื้นหลังของตัวควบคุม',
        borderPickerTitle: 'สีขอบของตัวควบคุม',
        borderWidthField: WidgetSettingsBorderWidthField.slider,
      ),
      DashboardItemType.gauge => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีหลักของเกจ',
        backgroundPickerTitle: 'พื้นหลังของเกจ',
        borderPickerTitle: 'สีขอบของเกจ',
        borderWidthField: WidgetSettingsBorderWidthField.gauge,
      ),
      DashboardItemType.toggle => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีหลักของสวิตช์',
        showSecondaryColor: true,
        secondaryPickerTitle: 'สีรอง/ปิดของสวิตช์',
        backgroundPickerTitle: 'พื้นหลังของสวิตช์',
        borderPickerTitle: 'สีขอบของสวิตช์',
        borderWidthField: WidgetSettingsBorderWidthField.toggle,
      ),
      DashboardItemType.valueLabel => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีข้อความของค่า',
        backgroundPickerTitle: 'พื้นหลังของแสดงค่า',
        borderPickerTitle: 'สีขอบของแสดงค่า',
        borderWidthField: WidgetSettingsBorderWidthField.valueLabel,
      ),
      DashboardItemType.trend => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีเส้นกราฟ',
        backgroundPickerTitle: 'พื้นหลังของกราฟ',
        borderPickerTitle: 'สีขอบของกราฟ',
        borderWidthField: WidgetSettingsBorderWidthField.slider,
      ),
      DashboardItemType.led => const WidgetSettingsCapabilities(
        primaryLabel: 'สีหลัก',
        primaryPickerTitle: 'สีหลักของไฟสถานะ',
        showSecondaryColor: true,
        secondaryPickerTitle: 'สีรอง/ปิดของไฟสถานะ',
        backgroundPickerTitle: 'พื้นหลังของไฟสถานะ',
        borderPickerTitle: 'สีขอบของไฟสถานะ',
        borderWidthField: WidgetSettingsBorderWidthField.toggle,
      ),
    };
  }

  final bool showPrimaryColor;
  final String primaryLabel;
  final String primaryPickerTitle;
  final bool showSecondaryColor;
  final String secondaryPickerTitle;
  final String backgroundPickerTitle;
  final WidgetSettingsBorderColorField borderColorField;
  final String borderPickerTitle;
  final WidgetSettingsBorderWidthField borderWidthField;
  final bool showGlow;

  bool get showBorderColor =>
      borderColorField != WidgetSettingsBorderColorField.none;

  bool get showBorderWidth =>
      borderWidthField != WidgetSettingsBorderWidthField.none;

  String get secondaryLabel => 'สีรอง/ปิด';

  bool get showBackgroundColor => true;

  bool get usesControlSurfaceColors => showBorderColor || showBackgroundColor;

  bool get isBindingModeConfigurable => false;

  bool get bindingIsRequired => true;

  String defaultBindingModeFor(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.button => 'read_write',
      DashboardItemType.toggle => 'read_write',
      DashboardItemType.slider => 'read_write',
      DashboardItemType.stepH => 'read_write',
      DashboardItemType.stepV => 'read_write',
      DashboardItemType.gauge => 'read',
      DashboardItemType.valueLabel => 'read',
      DashboardItemType.trend => 'read',
      DashboardItemType.led => 'read',
    };
  }

  bool supportsRange(DashboardItemType type) {
    return type == DashboardItemType.slider ||
        type == DashboardItemType.stepH ||
        type == DashboardItemType.stepV ||
        type == DashboardItemType.gauge ||
        type == DashboardItemType.valueLabel ||
        type == DashboardItemType.trend;
  }

  bool supportsStep(DashboardItemType type) {
    return type == DashboardItemType.slider ||
        type == DashboardItemType.stepH ||
        type == DashboardItemType.stepV;
  }

  bool isWritable(DashboardItemType type) {
    return type == DashboardItemType.button ||
        type == DashboardItemType.slider ||
        type == DashboardItemType.stepH ||
        type == DashboardItemType.stepV ||
        type == DashboardItemType.toggle;
  }

  static double defaultGlowStrengthForType(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.slider => 0.08,
      DashboardItemType.stepH || DashboardItemType.stepV => 0.08,
      DashboardItemType.valueLabel => 0.0,
      DashboardItemType.trend => 0.08,
      DashboardItemType.button ||
      DashboardItemType.gauge ||
      DashboardItemType.toggle => 0.12,
      DashboardItemType.led => 0.0,
    };
  }

  static Color defaultSurfaceColorForType({
    required DashboardItemType type,
    required Color accentColor,
    required bool enabled,
  }) {
    return switch (type) {
      DashboardItemType.valueLabel => accentColor,
      DashboardItemType.gauge => accentColor.withValues(alpha: 0.58),
      DashboardItemType.slider ||
      DashboardItemType.stepH ||
      DashboardItemType.stepV ||
      DashboardItemType.trend => accentColor.withValues(alpha: 0.34),
      DashboardItemType.led ||
      DashboardItemType.toggle => accentColor.withValues(alpha: 0.58),
      DashboardItemType.button =>
        enabled
            ? DashboardRuntimeTheme.cardColor
            : DashboardRuntimeTheme.surfaceColor,
    };
  }

  static Color defaultInnerColorForType(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.button => DashboardRuntimeTheme.cardHighlightColor,
      _ => DashboardRuntimeTheme.cardColor,
    };
  }

  static Color defaultButtonBorderColor({
    required Color accentColor,
    required Color secondaryAccentColor,
    required bool enabled,
  }) {
    final baseColor = enabled ? accentColor : secondaryAccentColor;
    return baseColor.withValues(alpha: enabled ? 0.26 : 0.22);
  }
}
