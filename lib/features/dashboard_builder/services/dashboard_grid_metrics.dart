import '../models/dashboard_item.dart';

class DashboardGridMetrics {
  const DashboardGridMetrics._();

  static const double gridGap = 4;
  static const double targetCellSize = 14;
  static const int minColumns = 18;
  static const int maxColumns = 26;

  static int columnsForWidth(double width) {
    final rawColumns = ((width + gridGap) / (targetCellSize + gridGap)).floor();
    return rawColumns.clamp(minColumns, maxColumns);
  }

  static double cellWidthFor({required double width, required int columns}) {
    return (width - (gridGap * (columns - 1))) / columns;
  }

  static double rowHeightFor(double cellWidth) => cellWidth;

  static double stepFor(double cellExtent) => cellExtent + gridGap;

  static double itemWidthFor({
    required GridRect rect,
    required double cellWidth,
  }) {
    return (rect.w * cellWidth) + ((rect.w - 1) * gridGap);
  }

  static double itemHeightFor({
    required GridRect rect,
    required double rowHeight,
  }) {
    return (rect.h * rowHeight) + ((rect.h - 1) * gridGap);
  }
}
