import '../models/dashboard_item.dart';
import '../models/widget_settings_result.dart';

class DashboardSettingsApplyResult {
  const DashboardSettingsApplyResult({
    required this.items,
    required this.selectedId,
  });

  final List<DashboardItem> items;
  final String? selectedId;
}

class DashboardSettingsService {
  const DashboardSettingsService._();

  static DashboardSettingsApplyResult? applyResult({
    required List<DashboardItem> items,
    required String itemId,
    required WidgetSettingsResult result,
  }) {
    if (result.remove) {
      return DashboardSettingsApplyResult(
        items: items.where((item) => item.id != itemId).toList(),
        selectedId: null,
      );
    }

    final updatedItem = result.item;
    if (updatedItem == null) {
      return null;
    }

    return DashboardSettingsApplyResult(
      items: items
          .map((item) => item.id == itemId ? updatedItem : item)
          .toList(),
      selectedId: itemId,
    );
  }
}
