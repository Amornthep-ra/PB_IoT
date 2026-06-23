import '../../../models/dashboard_item.dart';
import 'widget_settings_binding_catalog.dart';
import 'widget_settings_capabilities.dart';
import 'widget_settings_draft.dart';

class WidgetSettingsPreviewMapper {
  const WidgetSettingsPreviewMapper._();

  static DashboardItem buildPreviewItem({
    required DashboardItem source,
    required WidgetSettingsDraft draft,
    required WidgetSettingsCapabilities capabilities,
    required GridRect previewRect,
    required double previewValue,
    required double minValue,
    required double maxValue,
    required double stepValue,
  }) {
    final previewUnit = draft.hasSelectedBinding ? draft.unit : source.unit;
    final previewDataKey = draft.bindingKey.trim().isEmpty
        ? source.dataKey
        : draft.bindingKey;
    final previewDataKeyLabel = draft.bindingKey.trim().isEmpty
        ? source.dataKeyLabel
        : draft.bindingLabel;

    return source.copyWith(
      rect: previewRect,
      title: '',
      value: previewValue,
      minValue: capabilities.supportsRange(source.type)
          ? minValue
          : source.minValue,
      maxValue: capabilities.supportsRange(source.type)
          ? maxValue
          : source.maxValue,
      stepValue: capabilities.supportsStep(source.type)
          ? stepValue
          : source.stepValue,
      unit: previewUnit,
      clearUnit: previewUnit == null,
      dataKey: previewDataKey,
      clearDataKey: previewDataKey == null || previewDataKey.trim().isEmpty,
      dataKeyLabel: previewDataKeyLabel,
      clearDataKeyLabel:
          previewDataKeyLabel == null || previewDataKeyLabel.trim().isEmpty,
      bindingMode: capabilities.isBindingModeConfigurable
          ? draft.bindingMode
          : capabilities.defaultBindingModeFor(source.type),
      dataType: WidgetSettingsBindingCatalog.normalizeDataType(draft.dataType),
      sendBehavior: capabilities.isWritable(source.type)
          ? draft.sendBehavior
          : source.sendBehavior,
      accentColor: draft.accentColor,
      titleColor: source.titleColor,
      titleFontSize: source.titleFontSize,
      titlePosition: source.titlePosition,
      secondaryAccentColor: capabilities.showSecondaryColor
          ? draft.secondaryAccentColor
          : source.secondaryAccentColor,
      clearSecondaryAccentColor: false,
      buttonShellColor: capabilities.showBorderColor
          ? draft.surfaceColor
          : source.buttonShellColor,
      clearButtonShellColor: false,
      buttonInnerColor: capabilities.showBackgroundColor
          ? draft.innerColor
          : source.buttonInnerColor,
      clearButtonInnerColor: false,
      buttonBorderColor:
          capabilities.borderColorField ==
              WidgetSettingsBorderColorField.buttonBorderColor
          ? draft.borderColor
          : source.buttonBorderColor,
      clearButtonBorderColor:
          capabilities.borderColorField !=
          WidgetSettingsBorderColorField.buttonBorderColor,
      buttonBorderWidth:
          capabilities.borderWidthField == WidgetSettingsBorderWidthField.button
          ? draft.buttonBorderWidth
          : source.buttonBorderWidth,
      clearButtonBorderWidth:
          capabilities.borderWidthField !=
          WidgetSettingsBorderWidthField.button,
      valueLabelBorderWidth:
          capabilities.borderWidthField ==
              WidgetSettingsBorderWidthField.valueLabel
          ? draft.valueLabelBorderWidth
          : source.valueLabelBorderWidth,
      clearValueLabelBorderWidth:
          capabilities.borderWidthField !=
          WidgetSettingsBorderWidthField.valueLabel,
      gaugeBorderWidth:
          capabilities.borderWidthField == WidgetSettingsBorderWidthField.gauge
          ? draft.gaugeBorderWidth
          : source.gaugeBorderWidth,
      clearGaugeBorderWidth:
          capabilities.borderWidthField != WidgetSettingsBorderWidthField.gauge,
      sliderBorderWidth:
          capabilities.borderWidthField == WidgetSettingsBorderWidthField.slider
          ? draft.sliderBorderWidth
          : source.sliderBorderWidth,
      clearSliderBorderWidth:
          capabilities.borderWidthField !=
          WidgetSettingsBorderWidthField.slider,
      toggleBorderWidth:
          capabilities.borderWidthField == WidgetSettingsBorderWidthField.toggle
          ? draft.toggleBorderWidth
          : source.toggleBorderWidth,
      clearToggleBorderWidth:
          capabilities.borderWidthField !=
          WidgetSettingsBorderWidthField.toggle,
      glowColor: draft.glowColorLinkedToAccent ? null : draft.glowColor,
      clearGlowColor: draft.glowColorLinkedToAccent,
      glowStrength: draft.glowStrength,
      clearGlowStrength: false,
      glowBlur: draft.glowBlur,
      clearGlowBlur: false,
      enabled:
          source.type == DashboardItemType.button ||
              source.type == DashboardItemType.toggle ||
              source.type == DashboardItemType.led
          ? draft.enabled
          : source.enabled,
    );
  }
}
