import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionCookieStorage {
  SessionCookieStorage._();

  static const String _cookieHeaderKey = 'session_cookie_header';
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedTokenKey = 'remembered_token';
  static const String _rememberedDisplayNameKey = 'remembered_display_name';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> saveFromSetCookieHeaders(
    List<String> setCookieHeaders,
  ) async {
    final cookieHeader = _extractCookieHeader(setCookieHeaders);
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cookieHeaderKey, cookieHeader);
  }

  static Future<String?> loadCookieHeader() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_cookieHeaderKey);
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cookieHeaderKey);
  }

  static Future<void> saveRememberedLogin({
    required String token,
    required String displayName,
    required bool rememberMe,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberMeKey, rememberMe);
    await preferences.setString(_rememberedDisplayNameKey, displayName);
    await preferences.remove(_rememberedTokenKey);
    await _secureStorage.write(key: _rememberedTokenKey, value: token);
  }

  static Future<RememberedLogin?> loadRememberedLogin() async {
    final preferences = await SharedPreferences.getInstance();

    final rememberMe = preferences.getBool(_rememberMeKey) ?? false;
    if (!rememberMe) {
      return null;
    }

    final token = await _loadRememberedToken(preferences);
    final displayName = preferences.getString(_rememberedDisplayNameKey) ?? '';

    return RememberedLogin(
      rememberMe: rememberMe,
      token: token,
      displayName: displayName,
    );
  }

  static Future<void> clearRememberedLogin() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_rememberMeKey);
    await preferences.remove(_rememberedTokenKey);
    await preferences.remove(_rememberedDisplayNameKey);
    await _secureStorage.delete(key: _rememberedTokenKey);
  }

  static Future<String> _loadRememberedToken(
    SharedPreferences preferences,
  ) async {
    final secureToken = await _secureStorage.read(key: _rememberedTokenKey);
    if (secureToken != null) {
      return secureToken;
    }

    final legacyToken = preferences.getString(_rememberedTokenKey);
    if (legacyToken == null) {
      return '';
    }

    await _secureStorage.write(key: _rememberedTokenKey, value: legacyToken);
    await preferences.remove(_rememberedTokenKey);
    return legacyToken;
  }

  static String? _extractCookieHeader(List<String> setCookieHeaders) {
    if (setCookieHeaders.isEmpty) {
      return null;
    }

    final cookiePairs = <String>[];
    for (final header in setCookieHeaders) {
      final firstSegment = header.split(';').first.trim();
      if (firstSegment.isNotEmpty) {
        cookiePairs.add(firstSegment);
      }
    }

    if (cookiePairs.isEmpty) {
      return null;
    }

    return cookiePairs.join('; ');
  }
}

class RememberedLogin {
  const RememberedLogin({
    required this.rememberMe,
    required this.token,
    required this.displayName,
  });

  final bool rememberMe;
  final String token;
  final String displayName;
}
