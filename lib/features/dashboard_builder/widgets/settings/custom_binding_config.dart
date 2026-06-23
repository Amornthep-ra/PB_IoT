part of '../widget_settings_sheet.dart';

class _CustomBindingConfig {
  const _CustomBindingConfig({
    required this.dataKey,
    required this.dataKeyLabel,
    required this.dataType,
    required this.unit,
    this.defaultValue,
    this.minValue,
    this.maxValue,
  });

  final String dataKey;
  final String dataKeyLabel;
  final String dataType;
  final String unit;
  final double? defaultValue;
  final double? minValue;
  final double? maxValue;
}
