import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageCacheStorage {
  ProfileImageCacheStorage._();

  static const String _profileImageUrlKey = 'profile_image_url';
  static const String _profileImagePathKey = 'profile_image_path';

  static Future<void> clear() async {
    final metadata = await _loadMetadata();
    await _deleteFileIfExists(_normalize(metadata.path));
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_profileImageUrlKey);
    await preferences.remove(_profileImagePathKey);
  }

  static Future<_ProfileImageMetadata> _loadMetadata() async {
    final preferences = await SharedPreferences.getInstance();
    return _ProfileImageMetadata(
      path: _normalize(preferences.getString(_profileImagePathKey)),
    );
  }

  static Future<void> _deleteFileIfExists(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class _ProfileImageMetadata {
  const _ProfileImageMetadata({required this.path});

  final String? path;
}
