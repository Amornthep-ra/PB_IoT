import 'package:flutter/material.dart';

enum DashboardItemType { button, slider, gauge, toggle, valueLabel }

class DashboardItemTitlePosition {
  const DashboardItemTitlePosition._();

  static const String auto = 'auto';
  static const String topOutside = 'top_outside';
  static const String topInside = 'top_inside';
  static const String bottomOutside = 'bottom_outside';
  static const String left = 'left';
  static const String right = 'right';
  static const String hidden = 'hidden';
}

class GridRect {
  const GridRect({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final int x;
  final int y;
  final int w;
  final int h;

  int get right => x + w;
  int get bottom => y + h;

  GridRect copyWith({int? x, int? y, int? w, int? h}) {
    return GridRect(
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }
}

class DashboardItem {
  const DashboardItem({
    required this.id,
    required this.type,
    required this.title,
    required this.rect,
    required this.minW,
    required this.maxW,
    required this.minH,
    required this.maxH,
    required this.accentColor,
    this.titleColor,
    this.titleFontSize,
    String? titlePosition,
    this.secondaryAccentColor,
    this.buttonShellColor,
    this.buttonInnerColor,
    this.buttonBorderColor,
    this.buttonBorderWidth,
    this.valueLabelBorderWidth,
    this.gaugeBorderWidth,
    this.sliderBorderWidth,
    this.toggleBorderWidth,
    this.glowColor,
    this.glowStrength,
    this.glowBlur,
    this.value = 0,
    this.minValue = 0,
    this.maxValue = 100,
    this.series = const <double>[],
    this.unit,
    this.dataSource,
    this.dataKey,
    this.dataKeyLabel,
    String? bindingMode,
    String? dataType,
    double? stepValue,
    String? sendBehavior,
    this.enabled = false,
    bool? locked,
  }) : titlePosition = titlePosition ?? DashboardItemTitlePosition.auto,
        bindingMode = bindingMode ?? 'read',
        dataType = dataType ?? 'number',
        stepValue = stepValue ?? 1,
        sendBehavior = sendBehavior ?? 'on_release',
        _locked = locked;

  final String id;
  final DashboardItemType type;
  final String title;
  final GridRect rect;
  final int minW;
  final int maxW;
  final int minH;
  final int maxH;
  final Color accentColor;
  final Color? titleColor;
  final double? titleFontSize;
  final String titlePosition;
  final Color? secondaryAccentColor;
  final Color? buttonShellColor;
  final Color? buttonInnerColor;
  final Color? buttonBorderColor;
  final double? buttonBorderWidth;
  final double? valueLabelBorderWidth;
  final double? gaugeBorderWidth;
  final double? sliderBorderWidth;
  final double? toggleBorderWidth;
  final Color? glowColor;
  final double? glowStrength;
  final double? glowBlur;
  final double value;
  final double minValue;
  final double maxValue;
  final List<double> series;
  final String? unit;
  final String? dataSource;
  final String? dataKey;
  final String? dataKeyLabel;
  final String bindingMode;
  final String dataType;
  final double stepValue;
  final String sendBehavior;
  final bool enabled;
  final bool? _locked;
  bool get locked => _locked ?? false;

  DashboardItem copyWith({
    String? id,
    DashboardItemType? type,
    String? title,
    GridRect? rect,
    int? minW,
    int? maxW,
    int? minH,
    int? maxH,
    Color? accentColor,
    Color? titleColor,
    bool clearTitleColor = false,
    double? titleFontSize,
    bool clearTitleFontSize = false,
    String? titlePosition,
    Color? secondaryAccentColor,
    bool clearSecondaryAccentColor = false,
    Color? buttonShellColor,
    bool clearButtonShellColor = false,
    Color? buttonInnerColor,
    bool clearButtonInnerColor = false,
    Color? buttonBorderColor,
    bool clearButtonBorderColor = false,
    double? buttonBorderWidth,
    bool clearButtonBorderWidth = false,
    double? valueLabelBorderWidth,
    bool clearValueLabelBorderWidth = false,
    double? gaugeBorderWidth,
    bool clearGaugeBorderWidth = false,
    double? sliderBorderWidth,
    bool clearSliderBorderWidth = false,
    double? toggleBorderWidth,
    bool clearToggleBorderWidth = false,
    Color? glowColor,
    bool clearGlowColor = false,
    double? glowStrength,
    bool clearGlowStrength = false,
    double? glowBlur,
    bool clearGlowBlur = false,
    double? value,
    double? minValue,
    double? maxValue,
    List<double>? series,
    String? unit,
    bool clearUnit = false,
    String? dataSource,
    bool clearDataSource = false,
    String? dataKey,
    bool clearDataKey = false,
    String? dataKeyLabel,
    bool clearDataKeyLabel = false,
    String? bindingMode,
    String? dataType,
    double? stepValue,
    String? sendBehavior,
    bool? enabled,
    bool? locked,
  }) {
    return DashboardItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      rect: rect ?? this.rect,
      minW: minW ?? this.minW,
      maxW: maxW ?? this.maxW,
      minH: minH ?? this.minH,
      maxH: maxH ?? this.maxH,
      accentColor: accentColor ?? this.accentColor,
      titleColor: clearTitleColor ? null : (titleColor ?? this.titleColor),
      titleFontSize: clearTitleFontSize
          ? null
          : (titleFontSize ?? this.titleFontSize),
      titlePosition: titlePosition ?? this.titlePosition,
      secondaryAccentColor: clearSecondaryAccentColor
          ? null
          : (secondaryAccentColor ?? this.secondaryAccentColor),
      buttonShellColor: clearButtonShellColor
          ? null
          : (buttonShellColor ?? this.buttonShellColor),
      buttonInnerColor: clearButtonInnerColor
          ? null
          : (buttonInnerColor ?? this.buttonInnerColor),
      buttonBorderColor: clearButtonBorderColor
          ? null
          : (buttonBorderColor ?? this.buttonBorderColor),
      buttonBorderWidth: clearButtonBorderWidth
          ? null
          : (buttonBorderWidth ?? this.buttonBorderWidth),
      valueLabelBorderWidth: clearValueLabelBorderWidth
          ? null
          : (valueLabelBorderWidth ?? this.valueLabelBorderWidth),
      gaugeBorderWidth: clearGaugeBorderWidth
          ? null
          : (gaugeBorderWidth ?? this.gaugeBorderWidth),
      sliderBorderWidth: clearSliderBorderWidth
          ? null
          : (sliderBorderWidth ?? this.sliderBorderWidth),
      toggleBorderWidth: clearToggleBorderWidth
          ? null
          : (toggleBorderWidth ?? this.toggleBorderWidth),
      glowColor: clearGlowColor ? null : (glowColor ?? this.glowColor),
      glowStrength: clearGlowStrength
          ? null
          : (glowStrength ?? this.glowStrength),
      glowBlur: clearGlowBlur ? null : (glowBlur ?? this.glowBlur),
      value: value ?? this.value,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      series: series ?? this.series,
      unit: clearUnit ? null : (unit ?? this.unit),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      dataKey: clearDataKey ? null : (dataKey ?? this.dataKey),
      dataKeyLabel: clearDataKeyLabel
          ? null
          : (dataKeyLabel ?? this.dataKeyLabel),
      bindingMode: bindingMode ?? this.bindingMode,
      dataType: dataType ?? this.dataType,
      stepValue: stepValue ?? this.stepValue,
      sendBehavior: sendBehavior ?? this.sendBehavior,
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
    );
  }
}
