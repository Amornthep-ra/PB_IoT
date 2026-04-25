import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../projects/services/project_state.dart';
import '../models/dashboard_layout_model.dart';

class DashboardLocalStorageService {
  DashboardLocalStorageService({
    SharedPreferences? preferences,
    this.storageKey = _defaultStorageKey,
  }) : _preferences = preferences;

  static const String _defaultStorageKey = 'dashboard_layout_v1';

  final SharedPreferences? _preferences;
  final String storageKey;

  String get _effectiveStorageKey => _projectScopedKey(storageKey);

  Future<DashboardLayoutModel?> loadLayout() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(_effectiveStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return DashboardLayoutModel.fromJson(decoded);
  }

  Future<void> saveLayout(DashboardLayoutModel layout) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setString(
      _effectiveStorageKey,
      jsonEncode(layout.toJson()),
    );
  }

  Future<void> clearLayout() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_effectiveStorageKey);
  }

  String _projectScopedKey(String baseKey) {
    final projectId = ProjectState.current?.id.trim();
    if (projectId == null || projectId.isEmpty) {
      return baseKey;
    }
    return '${baseKey}_$projectId';
  }
}
