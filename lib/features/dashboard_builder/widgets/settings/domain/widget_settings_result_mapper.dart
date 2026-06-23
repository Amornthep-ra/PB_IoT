import 'package:flutter/material.dart';

import '../../../models/dashboard_item.dart';
import '../../../models/widget_settings_result.dart';
import 'widget_settings_binding_catalog.dart';
import 'widget_settings_capabilities.dart';
import 'widget_settings_draft.dart';

class WidgetSettingsResultMapper {
  const WidgetSettingsResultMapper._();

  static WidgetSettingsResult buildResult({
    required DashboardItem source,
    required WidgetSettingsDraft draft,
    required WidgetSettingsCapabilities capabilities,
    required double minValue,
    required double maxValue,
    required double stepValue,
    required double value,
    required Color defaultSurfaceColor,
    required Color defaultInnerColor,
    required Color defaultButtonBorderColor,
    required double defaultButtonBorderWidth,
    required double defaultValueLabelBorderWidth,
    required double defaultGaugeBorderWidth,
    required double defaultSliderBorderWidth,
    required double defaultToggleBorderWidth,
    required double defaultGlowStrength,
    required double defaultGlowBlur,
  }) {
    final shouldClearSurfaceColor =
        capabilities.usesControlSurfaceColors &&
        draft.surfaceColor.toARGB32() == defaultSurfaceColor.toARGB32();
    final shouldClearInnerColor =
        capabilities.usesControlSurfaceColors &&
        draft.innerColor.toARGB32() == defaultInnerColor.toARGB32();
    final shouldClearButtonBorderColor =
        capabilities.borderColorField !=
            WidgetSettingsBorderColorField.buttonBorderColor ||
        draft.borderColor.toARGB32() == defaultButtonBorderColor.toARGB32();
    final shouldClearButtonBorderWidth =
        capabilities.borderWidthField !=
            WidgetSettingsBorderWidthField.button ||
        (draft.buttonBorderWidth - defaultButtonBorderWidth).abs() < 0.001;
    final shouldClearValueLabelBorderWidth =
        capabilities.borderWidthField !=
            WidgetSettingsBorderWidthField.valueLabel ||
        (draft.valueLabelBorderWidth - defaultValueLabelBorderWidth).abs() <
            0.001;
    final shouldClearGaugeBorderWidth =
        capabilities.borderWidthField != WidgetSettingsBorderWidthField.gauge ||
        (draft.gaugeBorderWidth - defaultGaugeBorderWidth).abs() < 0.001;
    final shouldClearSliderBorderWidth =
        capabilities.borderWidthField !=
            WidgetSettingsBorderWidthField.slider ||
        (draft.sliderBorderWidth - defaultSliderBorderWidth).abs() < 0.001;
    final shouldClearToggleBorderWidth =
        capabilities.borderWidthField !=
            WidgetSettingsBorderWidthField.toggle ||
        (draft.toggleBorderWidth - defaultToggleBorderWidth).abs() < 0.001;
    final shouldClearGlowColor = draft.glowColorLinkedToAccent;
    final shouldClearGlowStrength =
        (draft.glowStrength - defaultGlowStrength).abs() < 0.001;
    final shouldClearGlowBlur =
        (draft.glowBlur - defaultGlowBlur).abs() < 0.001;

    return WidgetSettingsResult(
      item: source.copyWith(
        title: draft.title.trim().isEmpty ? source.title : draft.title.trim(),
        value: value,
        unit: draft.hasSelectedBinding ? draft.unit : null,
        clearUnit: !draft.hasSelectedBinding || draft.unit == null,
        dataSource: 'device_channel',
        clearDataSource: false,
        dataKey: draft.bindingKey,
        clearDataKey: draft.bindingKey.trim().isEmpty,
        dataKeyLabel: draft.bindingKey.trim().isEmpty
            ? null
            : draft.bindingLabel,
        clearDataKeyLabel:
            draft.bindingKey.trim().isEmpty || draft.bindingLabel == null,
        bindingMode: capabilities.isBindingModeConfigurable
            ? draft.bindingMode
            : capabilities.defaultBindingModeFor(source.type),
        dataType: WidgetSettingsBindingCatalog.normalizeDataType(
          draft.dataType,
        ),
        minValue: capabilities.supportsRange(source.type)
            ? minValue
            : source.minValue,
        maxValue: capabilities.supportsRange(source.type)
            ? maxValue
            : source.maxValue,
        stepValue: capabilities.supportsStep(source.type)
            ? stepValue
            : source.stepValue,
        sendBehavior: capabilities.isWritable(source.type)
            ? draft.sendBehavior
            : source.sendBehavior,
        accentColor: draft.accentColor,
        titleColor: source.titleColor,
        titleFontSize: source.titleFontSize,
        titlePosition: source.titlePosition,
        locked: draft.locked,
        secondaryAccentColor: capabilities.showSecondaryColor
            ? draft.secondaryAccentColor
            : null,
        clearSecondaryAccentColor: !capabilities.showSecondaryColor,
        buttonShellColor:
            capabilities.showBorderColor && !shouldClearSurfaceColor
            ? draft.surfaceColor
            : null,
        clearButtonShellColor:
            !capabilities.showBorderColor || shouldClearSurfaceColor,
        buttonInnerColor:
            capabilities.showBackgroundColor && !shouldClearInnerColor
            ? draft.innerColor
            : null,
        clearButtonInnerColor:
            !capabilities.showBackgroundColor || shouldClearInnerColor,
        buttonBorderColor:
            capabilities.borderColorField ==
                    WidgetSettingsBorderColorField.buttonBorderColor &&
                !shouldClearButtonBorderColor
            ? draft.borderColor
            : null,
        clearButtonBorderColor: shouldClearButtonBorderColor,
        buttonBorderWidth:
            capabilities.borderWidthField ==
                    WidgetSettingsBorderWidthField.button &&
                !shouldClearButtonBorderWidth
            ? draft.buttonBorderWidth
            : null,
        clearButtonBorderWidth: shouldClearButtonBorderWidth,
        valueLabelBorderWidth:
            capabilities.borderWidthField ==
                    WidgetSettingsBorderWidthField.valueLabel &&
                !shouldClearValueLabelBorderWidth
            ? draft.valueLabelBorderWidth
            : null,
        clearValueLabelBorderWidth: shouldClearValueLabelBorderWidth,
        gaugeBorderWidth:
            capabilities.borderWidthField ==
                    WidgetSettingsBorderWidthField.gauge &&
                !shouldClearGaugeBorderWidth
            ? draft.gaugeBorderWidth
            : null,
        clearGaugeBorderWidth: shouldClearGaugeBorderWidth,
        sliderBorderWidth:
            capabilities.borderWidthField ==
                    WidgetSettingsBorderWidthField.slider &&
                !shouldClearSliderBorderWidth
            ? draft.sliderBorderWidth
            : null,
        clearSliderBorderWidth: shouldClearSliderBorderWidth,
        toggleBorderWidth:
            capabilities.borderWidthField ==
                    WidgetSettingsBorderWidthField.toggle &&
                !shouldClearToggleBorderWidth
            ? draft.toggleBorderWidth
            : null,
        clearToggleBorderWidth: shouldClearToggleBorderWidth,
        glowColor: !shouldClearGlowColor ? draft.glowColor : null,
        clearGlowColor: shouldClearGlowColor,
        glowStrength: !shouldClearGlowStrength ? draft.glowStrength : null,
        clearGlowStrength: shouldClearGlowStrength,
        glowBlur: !shouldClearGlowBlur ? draft.glowBlur : null,
        clearGlowBlur: shouldClearGlowBlur,
        enabled:
            source.type == DashboardItemType.button ||
                source.type == DashboardItemType.led
            ? draft.enabled
            : source.enabled,
      ),
    );
  }
}
