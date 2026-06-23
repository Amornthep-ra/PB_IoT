import 'package:flutter/material.dart';

import '../../../models/dashboard_item.dart';
import 'widget_settings_binding_catalog.dart';
import 'widget_settings_capabilities.dart';

class WidgetSettingsDraft {
  WidgetSettingsDraft({
    required this.title,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.stepValue,
    required this.accentColor,
    required this.secondaryAccentColor,
    required this.surfaceColor,
    required this.innerColor,
    required this.borderColor,
    required this.glowColor,
    required this.glowColorLinkedToAccent,
    required this.borderLinkedToState,
    required this.valueLabelBorderLinkedToText,
    required this.buttonBorderWidth,
    required this.valueLabelBorderWidth,
    required this.gaugeBorderWidth,
    required this.sliderBorderWidth,
    required this.toggleBorderWidth,
    required this.glowStrength,
    required this.glowBlur,
    required this.enabled,
    required this.locked,
    required this.bindingKey,
    required this.bindingLabel,
    required this.bindingMode,
    required this.dataType,
    required this.unit,
    required this.sendBehavior,
  });

  factory WidgetSettingsDraft.fromItem({
    required DashboardItem item,
    required WidgetSettingsCapabilities capabilities,
    required Color defaultSecondaryAccentColor,
    required double defaultButtonBorderWidth,
    required double defaultValueLabelBorderWidth,
    required double defaultGaugeBorderWidth,
    required double defaultSliderBorderWidth,
    required double defaultToggleBorderWidth,
    required double defaultGlowBlur,
  }) {
    final bindingKey =
        WidgetSettingsBindingCatalog.canonicalBindingKey(item.dataKey ?? '') ??
        '';
    final catalogEntry = WidgetSettingsBindingCatalog.entryFor(bindingKey);
    var bindingLabel = item.dataKeyLabel?.trim();
    var unit = bindingKey.trim().isEmpty ? null : item.unit;
    if (catalogEntry != null &&
        (bindingLabel == null || bindingLabel.isEmpty)) {
      bindingLabel = WidgetSettingsBindingCatalog.sourceLabelForKey(
        catalogEntry.key,
      );
      if (unit == null &&
          catalogEntry.unit != null &&
          catalogEntry.unit!.trim().isNotEmpty) {
        unit = catalogEntry.unit!.trim();
      }
    }

    final secondaryAccentColor =
        item.secondaryAccentColor ?? defaultSecondaryAccentColor;
    final surfaceColor =
        item.buttonShellColor ??
        WidgetSettingsCapabilities.defaultSurfaceColorForType(
          type: item.type,
          accentColor: item.accentColor,
          enabled: item.enabled,
        );
    final innerColor =
        item.buttonInnerColor ??
        WidgetSettingsCapabilities.defaultInnerColorForType(item.type);
    final borderColor =
        item.buttonBorderColor ??
        WidgetSettingsCapabilities.defaultButtonBorderColor(
          accentColor: item.accentColor,
          secondaryAccentColor: secondaryAccentColor,
          enabled: item.enabled,
        );

    return WidgetSettingsDraft(
      title: item.title,
      value: item.value,
      minValue: item.minValue,
      maxValue: item.maxValue,
      stepValue: item.stepValue,
      accentColor: item.accentColor,
      secondaryAccentColor: secondaryAccentColor,
      surfaceColor: surfaceColor,
      innerColor: innerColor,
      borderColor: borderColor,
      glowColor: item.glowColor ?? item.accentColor,
      glowColorLinkedToAccent: item.glowColor == null,
      borderLinkedToState:
          item.type == DashboardItemType.button &&
          (item.buttonBorderColor == null ||
              item.buttonBorderColor!.toARGB32() ==
                  WidgetSettingsCapabilities.defaultButtonBorderColor(
                    accentColor: item.accentColor,
                    secondaryAccentColor: secondaryAccentColor,
                    enabled: item.enabled,
                  ).toARGB32()),
      valueLabelBorderLinkedToText:
          item.type == DashboardItemType.valueLabel &&
          (item.buttonShellColor == null ||
              item.buttonShellColor!.toARGB32() == item.accentColor.toARGB32()),
      buttonBorderWidth: (item.buttonBorderWidth ?? defaultButtonBorderWidth)
          .toDouble(),
      valueLabelBorderWidth:
          (item.valueLabelBorderWidth ?? defaultValueLabelBorderWidth)
              .toDouble(),
      gaugeBorderWidth: (item.gaugeBorderWidth ?? defaultGaugeBorderWidth)
          .toDouble(),
      sliderBorderWidth: (item.sliderBorderWidth ?? defaultSliderBorderWidth)
          .toDouble(),
      toggleBorderWidth: (item.toggleBorderWidth ?? defaultToggleBorderWidth)
          .toDouble(),
      glowStrength:
          item.glowStrength ??
          WidgetSettingsCapabilities.defaultGlowStrengthForType(item.type),
      glowBlur: item.glowBlur ?? defaultGlowBlur,
      enabled: item.enabled,
      locked: item.locked,
      bindingKey: bindingKey,
      bindingLabel: bindingLabel,
      bindingMode: WidgetSettingsBindingCatalog.normalizeBindingMode(
        item.bindingMode,
      ),
      dataType: catalogEntry != null
          ? WidgetSettingsBindingCatalog.normalizeDataType(
              catalogEntry.dataType,
            )
          : WidgetSettingsBindingCatalog.normalizeDataType(item.dataType),
      unit: unit,
      sendBehavior: item.type == DashboardItemType.button
          ? WidgetSettingsBindingCatalog.normalizeButtonMode(item.sendBehavior)
          : WidgetSettingsBindingCatalog.normalizeSendBehavior(
              item.sendBehavior,
            ),
    );
  }

  String title;
  double value;
  double minValue;
  double maxValue;
  double stepValue;
  Color accentColor;
  Color secondaryAccentColor;
  Color surfaceColor;
  Color innerColor;
  Color borderColor;
  Color glowColor;
  bool glowColorLinkedToAccent;
  bool borderLinkedToState;
  bool valueLabelBorderLinkedToText;
  double buttonBorderWidth;
  double valueLabelBorderWidth;
  double gaugeBorderWidth;
  double sliderBorderWidth;
  double toggleBorderWidth;
  double glowStrength;
  double glowBlur;
  bool enabled;
  bool locked;
  String bindingKey;
  String? bindingLabel;
  String bindingMode;
  String dataType;
  String? unit;
  String sendBehavior;

  bool get hasSelectedBinding => bindingKey.trim().isNotEmpty;

  Color get effectiveGlowColor =>
      glowColorLinkedToAccent ? accentColor : glowColor;

  void applyBindingEntry(WidgetSettingsBindingEntry entry) {
    bindingKey = entry.key;
    bindingLabel = WidgetSettingsBindingCatalog.sourceLabelForKey(entry.key);
    dataType = WidgetSettingsBindingCatalog.normalizeDataType(entry.dataType);
    unit = entry.unit?.trim().isNotEmpty == true ? entry.unit!.trim() : null;
    if (entry.defaultValue != null) {
      value = entry.defaultValue!;
    }
    if (entry.minValue != null) {
      minValue = entry.minValue!;
    }
    if (entry.maxValue != null) {
      maxValue = entry.maxValue!;
    }
  }

  void applyCustomBinding(WidgetSettingsCustomBindingEntry entry) {
    bindingKey = entry.key;
    bindingLabel = entry.name;
    dataType = WidgetSettingsBindingCatalog.normalizeDataType(entry.dataType);
    unit = entry.unit.trim().isEmpty ? null : entry.unit.trim();
    if (entry.defaultValue != null) {
      value = entry.defaultValue!;
    }
    if (entry.minValue != null) {
      minValue = entry.minValue!;
    }
    if (entry.maxValue != null) {
      maxValue = entry.maxValue!;
    }
  }
}
