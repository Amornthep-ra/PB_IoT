import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';

class ProfileAvatarPresetStorage {
  ProfileAvatarPresetStorage._();

  static const String _selectedAvatarMapKey = 'selected_profile_avatar_map_v1';

  static Future<SessionModel> applyStoredAvatar(SessionModel session) async {
    final avatarId = await loadForSession(session);
    if (avatarId == null) {
      return session;
    }

    return session.copyWith(
      profileAvatarId: avatarId,
      profileImageUrl: '',
      cachedProfileImagePath: '',
    );
  }

  static Future<String?> loadForSession(SessionModel session) async {
    final accountKey = _accountKey(session);
    if (accountKey == null) {
      return null;
    }

    final avatarMap = await _loadMap();
    final avatarId = avatarMap[accountKey]?.trim();
    return avatarId == null || avatarId.isEmpty ? null : avatarId;
  }

  static Future<void> saveForSession({
    required SessionModel session,
    required String avatarId,
  }) async {
    final accountKey = _accountKey(session);
    if (accountKey == null) {
      return;
    }

    final avatarMap = await _loadMap();
    avatarMap[accountKey] = avatarId;
    await _saveMap(avatarMap);
  }

  static Future<void> removeForSession(SessionModel session) async {
    final accountKey = _accountKey(session);
    if (accountKey == null) {
      return;
    }

    final avatarMap = await _loadMap();
    avatarMap.remove(accountKey);
    await _saveMap(avatarMap);
  }

  static String? _accountKey(SessionModel session) {
    final userId = session.userId?.trim();
    if (userId != null && userId.isNotEmpty) {
      return 'user:$userId';
    }

    final token = session.token.trim();
    if (token.isNotEmpty) {
      return 'token:$token';
    }

    final deviceId = session.mqttDeviceId?.trim();
    if (deviceId != null && deviceId.isNotEmpty) {
      return 'device:$deviceId';
    }

    return null;
  }

  static Future<Map<String, String>> _loadMap() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_selectedAvatarMapKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, String>{};
      }

      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  static Future<void> _saveMap(Map<String, String> avatarMap) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_selectedAvatarMapKey, jsonEncode(avatarMap));
  }
}
