import '../models/dashboard_item.dart';

String formatDashboardDisplayValue(DashboardItem item) {
  final key = item.dataKey?.trim();
  if ((item.type == DashboardItemType.slider ||
          item.type == DashboardItemType.stepH ||
          item.type == DashboardItemType.stepV ||
          item.type == DashboardItemType.gauge ||
          item.type == DashboardItemType.valueLabel) &&
      (key == null || key.isEmpty)) {
    return '--';
  }

  final valueText = _formatCompactNumber(item.value);
  final unitText = item.unit?.trim() ?? '';
  if (unitText.isEmpty) {
    return valueText;
  }

  return _unitNeedsSpace(unitText)
      ? '$valueText $unitText'
      : '$valueText$unitText';
}

String _formatCompactNumber(double value) {
  final absValue = value.abs();
  if (absValue >= 1000000) {
    return '${_formatScaledNumber(value / 1000000)}M';
  }
  if (absValue >= 1000) {
    return '${_formatScaledNumber(value / 1000)}K';
  }

  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

String _formatScaledNumber(double value) {
  final absValue = value.abs();
  final decimals = absValue >= 100 ? 0 : 1;
  final text = value.toStringAsFixed(decimals);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

bool _unitNeedsSpace(String unit) {
  return !(unit.startsWith('%') || unit.startsWith('°'));
}
