import '../models/dashboard_item.dart';
import 'dashboard_layout_engine.dart';
import 'dashboard_widget_factory.dart';

class DashboardAddWidgetService {
  const DashboardAddWidgetService._();

  static DashboardItem? createPlacedItem({
    required List<DashboardItem> items,
    required DashboardItemType type,
    required int seed,
    required int columns,
    required int maxRows,
    required int buttonMinW,
    required int buttonMaxW,
    required int buttonMinH,
    required int buttonMaxH,
    DashboardWidgetFactoryButtonRectResolver? buttonRectResolver,
  }) {
    final prototype = DashboardWidgetFactory.createItem(
      type: type,
      existingItems: items,
      seed: seed,
      buttonMinW: buttonMinW,
      buttonMaxW: buttonMaxW,
      buttonMinH: buttonMinH,
      buttonMaxH: buttonMaxH,
      buttonRectResolver: buttonRectResolver,
    );

    final freeRect = DashboardLayoutEngine.findFirstAvailableRect(
      items: items,
      item: prototype,
      columns: columns,
      maxRows: maxRows,
    );

    if (freeRect == null) {
      return null;
    }

    return prototype.copyWith(rect: freeRect);
  }
}
