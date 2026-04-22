import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';

class SessionSnapshotStorage {
  SessionSnapshotStorage._();

  static const String _sessionSnapshotKey = 'session_snapshot_v1';

  static Future<void> save(SessionModel session) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'token': session.token,
      'displayName': session.displayName,
      'userId': session.userId,
      'email': session.email,
      'transport': session.transport,
      'authType': session.authType,
      'authenticated': session.authenticated,
      'mqttDeviceId': session.mqttDeviceId,
      'profileImageUrl': session.profileImageUrl,
      'cachedProfileImagePath': session.cachedProfileImagePath,
    };
    await preferences.setString(_sessionSnapshotKey, jsonEncode(payload));
  }

  static Future<SessionModel?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_sessionSnapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return SessionModel(
        token: decoded['token']?.toString() ?? '',
        displayName: decoded['displayName']?.toString() ?? '',
        userId: decoded['userId']?.toString(),
        email: decoded['email']?.toString(),
        transport: decoded['transport']?.toString(),
        authType: decoded['authType']?.toString(),
        authenticated: decoded['authenticated'] == true,
        mqttDeviceId: decoded['mqttDeviceId']?.toString(),
        profileImageUrl: decoded['profileImageUrl']?.toString(),
        cachedProfileImagePath: decoded['cachedProfileImagePath']?.toString(),
        isOfflineMode: true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionSnapshotKey);
  }
}
