part of '../widget_settings_sheet.dart';

typedef _DesignBorderWidthField = WidgetSettingsBorderWidthField;
typedef _DesignBorderColorField = WidgetSettingsBorderColorField;

class _WidgetDesignConfig {
  const _WidgetDesignConfig({
    required this.primaryLabel,
    required this.primaryPickerTitle,
    this.showPrimaryColor = true,
    this.showSecondaryColor = false,
    this.secondaryPickerTitle = 'สีรอง/ปิด',
    this.backgroundPickerTitle = 'สีพื้นหลัง',
    this.borderColorField = _DesignBorderColorField.shellColor,
    this.borderPickerTitle = 'สีขอบ',
    this.borderWidthField = _DesignBorderWidthField.none,
    this.showGlow = true,
  });

  factory _WidgetDesignConfig.forType(DashboardItemType type) {
    final capabilities = WidgetSettingsCapabilities.forType(type);
    return _WidgetDesignConfig(
      primaryLabel: capabilities.primaryLabel,
      primaryPickerTitle: capabilities.primaryPickerTitle,
      showPrimaryColor: capabilities.showPrimaryColor,
      showSecondaryColor: capabilities.showSecondaryColor,
      secondaryPickerTitle: capabilities.secondaryPickerTitle,
      backgroundPickerTitle: capabilities.backgroundPickerTitle,
      borderColorField: capabilities.borderColorField,
      borderPickerTitle: capabilities.borderPickerTitle,
      borderWidthField: capabilities.borderWidthField,
      showGlow: capabilities.showGlow,
    );
  }

  final bool showPrimaryColor;
  final String primaryLabel;
  final String primaryPickerTitle;
  final bool showSecondaryColor;
  final String secondaryPickerTitle;
  final String backgroundPickerTitle;
  final _DesignBorderColorField borderColorField;
  final String borderPickerTitle;
  final _DesignBorderWidthField borderWidthField;
  final bool showGlow;

  bool get showBorderColor => borderColorField != _DesignBorderColorField.none;

  bool get showBorderWidth => borderWidthField != _DesignBorderWidthField.none;

  String get secondaryLabel => 'สีรอง/ปิด';

  bool get showBackgroundColor => true;

  bool get usesControlSurfaceColors => showBorderColor || showBackgroundColor;
}
