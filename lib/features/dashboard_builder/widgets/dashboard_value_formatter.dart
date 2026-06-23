import '../models/dashboard_item.dart';

String formatDashboardDisplayValue(DashboardItem item) {
  final key = item.dataKey?.trim();
  if ((item.type == DashboardItemType.slider ||
          item.type == DashboardItemType.stepH ||
          item.type == DashboardItemType.stepV ||
          item.type == DashboardItemType.gauge ||
          item.type == DashboardItemType.valueLabel ||
          item.type == DashboardItemType.trend) &&
      (key == null || key.isEmpty)) {
    return '--';
  }

  if (item.type == DashboardItemType.led && (key == null || key.isEmpty)) {
    return '--';
  }

  final valueText = _formatFullNumber(item.value);
  final unitText = item.unit?.trim() ?? '';
  if (unitText.isEmpty) {
    return valueText;
  }

  return _unitNeedsSpace(unitText)
      ? '$valueText $unitText'
      : '$valueText$unitText';
}

String _formatFullNumber(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

bool _unitNeedsSpace(String unit) {
  return !(unit.startsWith('%') || unit.startsWith('°'));
}
