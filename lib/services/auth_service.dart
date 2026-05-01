import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  static const String _sessionUrl =
      'https://console.princebot.co.th/api/public/session';

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

}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
