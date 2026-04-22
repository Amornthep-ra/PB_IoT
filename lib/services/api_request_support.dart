import 'dart:convert';
import 'dart:io';

class ApiRequestSupport {
  ApiRequestSupport._();

  static const String browserLikeUserAgent =
      'Mozilla/5.0 (Linux; Android 14; PrinceBotSmartFarm) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/135.0.0.0 Mobile Safari/537.36';

  static void applyDefaultHeaders(
    HttpClientRequest request, {
    bool expectsJson = true,
    String? cookieHeader,
  }) {
    request.headers.set(HttpHeaders.userAgentHeader, browserLikeUserAgent);
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
    if (expectsJson) {
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    }
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
    }
  }

  static Map<String, dynamic> decodeJsonObjectOrThrow(
    String responseBody, {
    required int statusCode,
    String? contentType,
    String fallbackMessage = 'Invalid server response. Please try again.',
  }) {
    final trimmedBody = responseBody.trim();
    if (trimmedBody.isEmpty) {
      throw ApiResponseException(fallbackMessage, statusCode: statusCode);
    }

    final normalizedContentType = contentType?.toLowerCase() ?? '';
    if (_looksLikeBlockedAutomationResponse(trimmedBody)) {
      throw ApiResponseException(
        'Server security blocked this request. Please try another network or contact the server administrator.',
        statusCode: statusCode,
        detail: trimmedBody,
      );
    }

    final looksLikeJson =
        normalizedContentType.contains('application/json') ||
        trimmedBody.startsWith('{') ||
        trimmedBody.startsWith('[');
    if (!looksLikeJson) {
      throw ApiResponseException(
        fallbackMessage,
        statusCode: statusCode,
        detail: trimmedBody,
      );
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      // Fall through to the exception below.
    }

    throw ApiResponseException(
      fallbackMessage,
      statusCode: statusCode,
      detail: trimmedBody,
    );
  }

  static bool _looksLikeBlockedAutomationResponse(String responseBody) {
    final normalized = responseBody.toLowerCase();
    return normalized.contains('imunify360') &&
        normalized.contains('bot-protection');
  }
}

class ApiResponseException implements Exception {
  const ApiResponseException(
    this.message, {
    this.statusCode,
    this.detail,
  });

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => message;
}
