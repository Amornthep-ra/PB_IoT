import '../../../../dashboard/services/dashboard_item_runtime_binding.dart';
import 'widget_settings_binding_catalog.dart';

class WidgetSettingsBindingValidator {
  const WidgetSettingsBindingValidator._();

  static String? canonicalKey(String raw) {
    return WidgetSettingsBindingCatalog.canonicalBindingKey(raw);
  }

  static bool isValidVirtualPin(String raw) {
    return WidgetSettingsBindingCatalog.normalizeVPinKey(raw) != null;
  }

  static bool isSupportedRuntimePath(String raw) {
    final normalized = WidgetSettingsBindingCatalog.canonicalBindingKey(raw);
    if (normalized == null) {
      return false;
    }
    return DashboardItemRuntimeBinding.canonicalReadKey(normalized) != null ||
        DashboardItemRuntimeBinding.canonicalWriteKey(normalized) != null ||
        DashboardItemRuntimeBinding.isVirtualPinBinding(normalized);
  }

  static bool isReservedCatalogKey(String raw) {
    return WidgetSettingsBindingCatalog.isCatalogKey(raw);
  }
}
