import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TokenRequestService {
  TokenRequestService({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 10);
  }

  static const List<String> _requestUrls = <String>[
    'https://princebot.co.th/token/request',
  ];
  static const List<String> _forgotUrls = <String>[
    'https://princebot.co.th/forgot-token',
  ];

  final HttpClient _httpClient;

  Future<void> requestToken({
    required String gmail,
    required String deviceId,
  }) async {
    TokenRequestException? lastError;
    final payloads = _payloadVariants(gmail: gmail, deviceId: deviceId);

    for (final url in _requestUrls) {
      for (final payload in payloads) {
        try {
          await _postRequestAsForm(url: url, payload: payload);
          return;
        } on TokenRequestException catch (error) {
          lastError = error;
          if (error.statusCode == 404) {
            continue;
          }
        }

        try {
          await _postRequestAsJson(url: url, payload: payload);
          return;
        } on TokenRequestException catch (error) {
          lastError = error;
          if (error.statusCode == 404) {
            continue;
          }
        }
      }
    }

    throw lastError ??
        const TokenRequestException(
          'Unable to create token right now. Please try again.',
        );
  }

  Future<void> forgotToken({required String gmail}) async {
    TokenRequestException? lastError;
    final payloads = <Map<String, String>>[
      <String, String>{'email': gmail},
      <String, String>{'gmail': gmail},
    ];

    for (final url in _forgotUrls) {
      for (final payload in payloads) {
        try {
          await _postRequestAsForm(url: url, payload: payload);
          return;
        } on TokenRequestException catch (error) {
          lastError = error;
          if (error.statusCode == 404) {
            continue;
          }
        }

        try {
          await _postRequestAsJson(url: url, payload: payload);
          return;
        } on TokenRequestException catch (error) {
          lastError = error;
          if (error.statusCode == 404) {
            continue;
          }
        }
      }
    }

    throw lastError ??
        const TokenRequestException(
          'Unable to send a new token right now. Please try again.',
        );
  }

  List<Map<String, String>> _payloadVariants({
    required String gmail,
    required String deviceId,
  }) {
    return <Map<String, String>>[
      <String, String>{'gmail': gmail, 'deviceId': deviceId},
      <String, String>{'email': gmail, 'deviceId': deviceId},
      <String, String>{'gmail': gmail, 'device_id': deviceId},
      <String, String>{'email': gmail, 'device_id': deviceId},
    ];
  }

  Future<void> _postRequestAsForm({
    required String url,
    required Map<String, String> payload,
  }) async {
    final request = await _httpClient
        .postUrl(Uri.parse(url))
        .timeout(const Duration(seconds: 10));
    request.followRedirects = false;
    request.maxRedirects = 0;

    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/x-www-form-urlencoded; charset=utf-8',
    );
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.add(
      utf8.encode(
        Uri(
          queryParameters: payload,
        ).query,
      ),
    );

    await _readAndValidateResponse(await request.close());
  }

  Future<void> _postRequestAsJson({
    required String url,
    required Map<String, String> payload,
  }) async {
    final request = await _httpClient
        .postUrl(Uri.parse(url))
        .timeout(const Duration(seconds: 10));
    request.followRedirects = false;
    request.maxRedirects = 0;

    request.headers.set(
      HttpHeaders.contentTypeHeader,
      ContentType.json.mimeType,
    );
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.add(utf8.encode(jsonEncode(payload)));

    await _readAndValidateResponse(await request.close());
  }

  Future<void> _readAndValidateResponse(HttpClientResponse response) async {
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));
    final json = _tryDecodeJson(body);
    final location = response.headers.value(HttpHeaders.locationHeader) ?? '';
    final isRedirect = response.statusCode == 301 ||
        response.statusCode == 302 ||
        response.statusCode == 303 ||
        response.statusCode == 307 ||
        response.statusCode == 308;

    if (isRedirect) {
      if (location.contains('/login') || location == '/login') {
        return;
      }
      throw const TokenRequestException(
        'Request was redirected to an unexpected location.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TokenRequestException(
        _extractErrorMessage(json) ??
            'Unable to create token right now. Please try again.',
        statusCode: response.statusCode,
      );
    }

    if (json.isNotEmpty && json['ok'] == false) {
      throw TokenRequestException(
        _extractErrorMessage(json) ??
            'Unable to create token right now. Please try again.',
      );
    }
    if (json.isNotEmpty && json['success'] == false) {
      throw TokenRequestException(
        _extractErrorMessage(json) ??
            'Unable to create token right now. Please try again.',
      );
    }

    if (json.isEmpty) {
      final htmlError = _extractHtmlError(body);
      throw TokenRequestException(
        htmlError ??
            'Server accepted request but did not confirm token email delivery.',
      );
    }
  }

  Map<String, dynamic> _tryDecodeJson(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const <String, dynamic>{};
    }
    return const <String, dynamic>{};
  }

  String? _extractErrorMessage(Map<String, dynamic> json) {
    return (json['error'] ?? json['message'] ?? json['detail'])?.toString();
  }

  String? _extractHtmlError(String body) {
    if (body.isEmpty) {
      return null;
    }

    final knownPatterns = <RegExp>[
      RegExp(r'Unable to send email:[^<\n\r]*', caseSensitive: false),
      RegExp(r'Please wait [^<\n\r]*', caseSensitive: false),
      RegExp(r'Invalid email format[^<\n\r]*', caseSensitive: false),
      RegExp(r'Invalid Device ID format[^<\n\r]*', caseSensitive: false),
      RegExp(r'Only Gmail addresses are allowed[^<\n\r]*', caseSensitive: false),
      RegExp(r'Token request is currently disabled[^<\n\r]*', caseSensitive: false),
    ];

    for (final pattern in knownPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(0)?.trim();
      }
    }

    return null;
  }
}

class TokenRequestException implements Exception {
  const TokenRequestException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
