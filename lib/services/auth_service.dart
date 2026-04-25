import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../models/session_model.dart';
import 'api_request_support.dart';
import 'session_cookie_storage.dart';

class AuthService {
  AuthService({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 10);
  }

  static const String _loginUrl =
      'https://console.princebot.co.th/api/public/login';
  static const String _logoutUrl =
      'https://console.princebot.co.th/api/public/logout';
  static const String _profilePhotoUrl =
      'https://console.princebot.co.th/api/public/profile-photo';
  static const String _sessionUrl =
      'https://console.princebot.co.th/api/public/session';
  static const String _serverBaseUrl = 'https://console.princebot.co.th';

  final HttpClient _httpClient;

  Future<SessionModel> login({
    required String token,
    required String displayName,
    required bool rememberMe,
  }) async {
    final request = await _httpClient
        .postUrl(Uri.parse(_loginUrl))
        .timeout(const Duration(seconds: 10));

    ApiRequestSupport.applyDefaultHeaders(request);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/x-www-form-urlencoded; charset=utf-8',
    );

    request.add(
      utf8.encode(
        Uri(
          queryParameters: <String, String>{
            'token': token,
            'displayName': displayName,
          },
        ).query,
      ),
    );

    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));
    final responseJson = _tryDecodeJson(
      responseBody,
      statusCode: response.statusCode,
      contentType: response.headers.contentType?.mimeType,
    );

    final setCookieHeaders =
        response.headers[HttpHeaders.setCookieHeader] ?? const <String>[];

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(responseJson) ??
            'Login failed. Please check your token and try again.',
        statusCode: response.statusCode,
      );
    }

    if (responseJson['success'] != true) {
      throw AuthException(
        _extractErrorMessage(responseJson) ??
            'Unable to login right now. Please try again.',
      );
    }

    await SessionCookieStorage.saveFromSetCookieHeaders(setCookieHeaders);
    if (rememberMe) {
      await SessionCookieStorage.saveRememberedLogin(
        token: token,
        displayName: displayName,
        rememberMe: true,
      );
    } else {
      await SessionCookieStorage.clearRememberedLogin();
    }

    // TODO: Persist any additional server session metadata here if backend session requirements expand.
    return SessionModel.fromLoginResponse(
      token: token,
      displayName: displayName,
      json: responseJson,
    );
  }

  Future<void> logout() async {
    final storedCookie = await SessionCookieStorage.loadCookieHeader();

    if (storedCookie == null || storedCookie.isEmpty) {
      return;
    }

    final request = await _httpClient
        .postUrl(Uri.parse(_logoutUrl))
        .timeout(const Duration(seconds: 10));

    ApiRequestSupport.applyDefaultHeaders(request, cookieHeader: storedCookie);

    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseJson = responseBody.trim().isEmpty
          ? const <String, dynamic>{}
          : _tryDecodeJson(
              responseBody,
              statusCode: response.statusCode,
              contentType: response.headers.contentType?.mimeType,
            );
      throw AuthException(
        _extractErrorMessage(responseJson) ?? 'Unable to logout right now.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<SessionModel?> fetchCurrentSession() async {
    final storedCookie = await SessionCookieStorage.loadCookieHeader();
    if (storedCookie == null || storedCookie.isEmpty) {
      return null;
    }

    final request = await _httpClient
        .getUrl(Uri.parse(_sessionUrl))
        .timeout(const Duration(seconds: 10));
    ApiRequestSupport.applyDefaultHeaders(request, cookieHeader: storedCookie);

    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));
    final responseJson = _tryDecodeJson(
      responseBody,
      statusCode: response.statusCode,
      contentType: response.headers.contentType?.mimeType,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    if (responseJson['authenticated'] != true) {
      return null;
    }

    return SessionModel.fromSessionResponse(responseJson);
  }

  Future<String> uploadProfilePhoto({required String filePath}) async {
    final storedCookie = await SessionCookieStorage.loadCookieHeader();
    if (storedCookie == null || storedCookie.isEmpty) {
      throw const AuthException(
        'Your session has expired. Please login again.',
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw const AuthException('Selected photo could not be found.');
    }

    final boundary =
        '----princebot-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'profile.jpg';
    final mimeType = _detectMimeType(fileName);
    final fileBytes = await file.readAsBytes();

    final request = await _httpClient
        .postUrl(Uri.parse(_profilePhotoUrl))
        .timeout(const Duration(seconds: 15));

    ApiRequestSupport.applyDefaultHeaders(request, cookieHeader: storedCookie);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );

    final builder = BytesBuilder();
    builder.add(utf8.encode('--$boundary\r\n'));
    builder.add(
      utf8.encode(
        'Content-Disposition: form-data; name="photo"; filename="$fileName"\r\n',
      ),
    );
    builder.add(utf8.encode('Content-Type: $mimeType\r\n\r\n'));
    builder.add(fileBytes);
    builder.add(utf8.encode('\r\n--$boundary--\r\n'));

    request.add(builder.takeBytes());

    final response = await request.close().timeout(const Duration(seconds: 15));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 15));
    final responseJson = _tryDecodeJson(
      responseBody,
      statusCode: response.statusCode,
      contentType: response.headers.contentType?.mimeType,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(responseJson) ??
            'Unable to upload profile photo right now.',
        statusCode: response.statusCode,
      );
    }

    if (responseJson['success'] != true) {
      throw AuthException(
        _extractErrorMessage(responseJson) ??
            'Unable to upload profile photo right now.',
      );
    }

    final photo = responseJson['photo'] is Map<String, dynamic>
        ? responseJson['photo'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawPath = photo['path']?.toString() ?? '';
    if (rawPath.isEmpty) {
      throw const AuthException('Invalid server response. Please try again.');
    }

    return _resolveProfilePhotoUrl(rawPath);
  }

  Future<void> deleteProfilePhoto({required String photoUrl}) async {
    final storedCookie = await SessionCookieStorage.loadCookieHeader();
    if (storedCookie == null || storedCookie.isEmpty) {
      throw const AuthException(
        'Your session has expired. Please login again.',
      );
    }

    final filename = _extractFileName(photoUrl);
    if (filename == null || filename.isEmpty) {
      throw const AuthException('Invalid profile photo path.');
    }

    final request = await _httpClient
        .deleteUrl(
          Uri.parse(
            _profilePhotoUrl,
          ).replace(queryParameters: <String, String>{'filename': filename}),
        )
        .timeout(const Duration(seconds: 10));

    ApiRequestSupport.applyDefaultHeaders(request, cookieHeader: storedCookie);

    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));
    final responseJson = _tryDecodeJson(
      responseBody,
      statusCode: response.statusCode,
      contentType: response.headers.contentType?.mimeType,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(responseJson) ??
            'Unable to remove profile photo right now.',
        statusCode: response.statusCode,
      );
    }

    if (responseJson['success'] != true) {
      throw AuthException(
        _extractErrorMessage(responseJson) ??
            'Unable to remove profile photo right now.',
      );
    }
  }

  Map<String, dynamic> _tryDecodeJson(
    String responseBody, {
    required int statusCode,
    String? contentType,
  }) {
    try {
      return ApiRequestSupport.decodeJsonObjectOrThrow(
        responseBody,
        statusCode: statusCode,
        contentType: contentType,
      );
    } on ApiResponseException catch (error) {
      throw AuthException(error.message, statusCode: error.statusCode);
    }
  }

  String? _extractErrorMessage(Map<String, dynamic> json) {
    return (json['error'] ?? json['message'] ?? json['detail'])?.toString();
  }

  String _detectMimeType(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _resolveProfilePhotoUrl(String rawPath) {
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    final normalizedPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    return '$_serverBaseUrl$normalizedPath';
  }

  String? _extractFileName(String photoUrl) {
    final uri = Uri.tryParse(photoUrl);
    if (uri == null || uri.pathSegments.isEmpty) {
      return null;
    }
    return uri.pathSegments.last;
  }
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
