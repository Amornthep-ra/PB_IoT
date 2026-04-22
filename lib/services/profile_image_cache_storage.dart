import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';

class ProfileImageCacheStorage {
  ProfileImageCacheStorage._();

  static const String _profileImageUrlKey = 'profile_image_url';
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _cacheDirectoryName = 'princebot_profile_image_cache';
  static const String _cacheFileBaseName = 'profile_image';

  static Future<SessionModel> synchronizeSession(SessionModel session) async {
    final profileImageUrl = _normalize(session.profileImageUrl);
    final metadata = await _loadMetadata();

    if (profileImageUrl == null) {
      await clear();
      return session.copyWith(cachedProfileImagePath: '');
    }

    final cachedPath = _normalize(metadata.path);
    final hasMatchingCache =
        metadata.url == profileImageUrl &&
        cachedPath != null &&
        await File(cachedPath).exists();

    if (hasMatchingCache) {
      return session.copyWith(cachedProfileImagePath: cachedPath);
    }

    await _deleteFileIfExists(cachedPath);
    await _saveMetadata(url: profileImageUrl, path: '');
    return session.copyWith(cachedProfileImagePath: '');
  }

  static Future<SessionModel> cacheFromFile({
    required SessionModel session,
    required String sourcePath,
  }) async {
    final profileImageUrl = _normalize(session.profileImageUrl);
    if (profileImageUrl == null) {
      return session.copyWith(cachedProfileImagePath: '');
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return session.copyWith(cachedProfileImagePath: '');
    }

    final targetFile = await _resolveCacheFile(profileImageUrl);
    await targetFile.parent.create(recursive: true);
    await sourceFile.copy(targetFile.path);
    await _saveMetadata(url: profileImageUrl, path: targetFile.path);
    return session.copyWith(cachedProfileImagePath: targetFile.path);
  }

  static Future<SessionModel> refreshFromNetwork(SessionModel session) async {
    final profileImageUrl = _normalize(session.profileImageUrl);
    if (profileImageUrl == null) {
      await clear();
      return session.copyWith(cachedProfileImagePath: '');
    }

    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await httpClient
          .getUrl(Uri.parse(profileImageUrl))
          .timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return session;
      }

      final responseBytes = await consolidateHttpClientResponseBytes(
        response,
      ).timeout(const Duration(seconds: 15));
      if (responseBytes.isEmpty) {
        return session;
      }

      final targetFile = await _resolveCacheFile(profileImageUrl);
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(responseBytes, flush: true);
      await _saveMetadata(url: profileImageUrl, path: targetFile.path);
      return session.copyWith(cachedProfileImagePath: targetFile.path);
    } on TimeoutException {
      return session;
    } on SocketException {
      return session;
    } on HttpException {
      return session;
    } finally {
      httpClient.close(force: true);
    }
  }

  static Future<void> clear() async {
    final metadata = await _loadMetadata();
    await _deleteFileIfExists(_normalize(metadata.path));
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_profileImageUrlKey);
    await preferences.remove(_profileImagePathKey);
  }

  static String? resolveCachedPath(SessionModel? session) {
    final value = session?.cachedProfileImagePath?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Future<_ProfileImageMetadata> _loadMetadata() async {
    final preferences = await SharedPreferences.getInstance();
    return _ProfileImageMetadata(
      url: _normalize(preferences.getString(_profileImageUrlKey)),
      path: _normalize(preferences.getString(_profileImagePathKey)),
    );
  }

  static Future<void> _saveMetadata({
    required String url,
    required String path,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileImageUrlKey, url);
    await preferences.setString(_profileImagePathKey, path);
  }

  static Future<File> _resolveCacheFile(String profileImageUrl) async {
    final extension = _resolveFileExtension(profileImageUrl);
    final cacheRoot = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}$_cacheDirectoryName',
    );
    return File(
      '${cacheRoot.path}${Platform.pathSeparator}$_cacheFileBaseName$extension',
    );
  }

  static String _resolveFileExtension(String profileImageUrl) {
    final uri = Uri.tryParse(profileImageUrl);
    if (uri == null || uri.pathSegments.isEmpty) {
      return '.jpg';
    }

    final lastSegment = uri.pathSegments.last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == lastSegment.length - 1) {
      return '.jpg';
    }

    final extension = lastSegment.substring(dotIndex);
    final sanitized = extension.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '');
    return sanitized.isEmpty ? '.jpg' : sanitized;
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
  const _ProfileImageMetadata({required this.url, required this.path});

  final String? url;
  final String? path;
}
