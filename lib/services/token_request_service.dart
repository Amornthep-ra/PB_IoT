import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TokenRequestService {
  TokenRequestService({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 10);
  }

  static const String _resendApiKeyDefine = String.fromEnvironment(
    'RESEND_API_KEY',
  );
  static const String _resendFromEmailDefine = String.fromEnvironment(
    'RESEND_FROM_EMAIL',
    defaultValue: 'PrinceBot Smart Farm <onboarding@resend.dev>',
  );
  static const String _resendRequestToEmailDefine = String.fromEnvironment(
    'TOKEN_REQUEST_TO_EMAIL',
  );
  static const String _resendEmailsUrl = 'https://api.resend.com/emails';
  static const List<String> _requestUrls = <String>[
    'https://console.princebot.co.th/token/request',
  ];
  static const List<String> _forgotUrls = <String>[
    'https://console.princebot.co.th/forgot-token',
  ];

  final HttpClient _httpClient;

  String get _resendApiKey {
    final fromDefine = _resendApiKeyDefine.trim();
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return Platform.environment['RESEND_API_KEY']?.trim() ?? '';
  }

  String get _resendFromEmail {
    final fromDefine = _resendFromEmailDefine.trim();
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return Platform.environment['RESEND_FROM_EMAIL']?.trim() ??
        'PrinceBot Smart Farm <onboarding@resend.dev>';
  }

  String get _resendRequestToEmail {
    final fromDefine = _resendRequestToEmailDefine.trim();
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return Platform.environment['TOKEN_REQUEST_TO_EMAIL']?.trim() ?? '';
  }

  bool get _isResendConfigured => _resendApiKey.isNotEmpty;

  Future<void> requestToken({required String gmail, String? deviceId}) async {
    if (_isResendConfigured) {
      await _sendTokenEmailWithResend(
        gmail: gmail,
        deviceId: deviceId,
        type: _TokenEmailType.request,
      );
      return;
    }

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
    if (_isResendConfigured) {
      await _sendTokenEmailWithResend(
        gmail: gmail,
        type: _TokenEmailType.forgot,
      );
      return;
    }

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

  Future<void> _sendTokenEmailWithResend({
    required String gmail,
    required _TokenEmailType type,
    String? deviceId,
  }) async {
    final trimmedGmail = gmail.trim();
    final configuredRecipient = _resendRequestToEmail;
    final recipient = configuredRecipient.isNotEmpty
        ? configuredRecipient
        : trimmedGmail;
    final isAdminRecipient = recipient != trimmedGmail;
    final trimmedDeviceId = deviceId?.trim() ?? '';
    final subject = switch (type) {
      _TokenEmailType.request => 'PrinceBot Smart Farm token request',
      _TokenEmailType.forgot => 'PrinceBot Smart Farm token recovery request',
    };
    final intro = switch (type) {
      _TokenEmailType.request => 'New token request',
      _TokenEmailType.forgot => 'Forgot token request',
    };
    final actionText = isAdminRecipient
        ? 'Please create or resend the app token for this user.'
        : 'Your request has been received. Please wait for the PrinceBot team to create or resend your app token.';
    final escapedGmail = _escapeHtml(trimmedGmail);
    final escapedDeviceId = _escapeHtml(trimmedDeviceId);
    final deviceHtml = trimmedDeviceId.isEmpty
        ? ''
        : '<p style="margin:0 0 8px"><strong>Device ID:</strong> $escapedDeviceId</p>';
    final html =
        '''
<div style="font-family:Arial,sans-serif;line-height:1.5;color:#20303a">
  <h2 style="margin:0 0 12px">PrinceBot Smart Farm</h2>
  <p style="margin:0 0 12px">$intro</p>
  <p style="margin:0 0 8px"><strong>Email:</strong> $escapedGmail</p>
  $deviceHtml
  <p style="margin:12px 0 0">$actionText</p>
</div>
''';
    final text = StringBuffer()
      ..writeln('PrinceBot Smart Farm')
      ..writeln(intro)
      ..writeln('Email: $trimmedGmail');
    if (trimmedDeviceId.isNotEmpty) {
      text.writeln('Device ID: $trimmedDeviceId');
    }
    text.writeln(actionText);

    final payload = <String, dynamic>{
      'from': _resendFromEmail,
      'to': <String>[recipient],
      'subject': subject,
      'html': html,
      'text': text.toString(),
      'reply_to': trimmedGmail,
    };

    final request = await _httpClient
        .postUrl(Uri.parse(_resendEmailsUrl))
        .timeout(const Duration(seconds: 10));
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $_resendApiKey',
    );
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      ContentType.json.mimeType,
    );
    request.headers.set(HttpHeaders.userAgentHeader, 'princebot-smartfarm/1.0');
    request.add(utf8.encode(jsonEncode(payload)));

    final response = await request.close().timeout(const Duration(seconds: 10));
    await _readAndValidateResendResponse(response);
  }

  Future<void> _readAndValidateResendResponse(
    HttpClientResponse response,
  ) async {
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));
    final json = _tryDecodeJson(body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TokenRequestException(
        _friendlyResendErrorMessage(json, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    if (json.isNotEmpty && json['id'] == null) {
      throw const TokenRequestException(
        'Email service accepted the request but did not confirm delivery.',
      );
    }
  }

  List<Map<String, String>> _payloadVariants({
    required String gmail,
    String? deviceId,
  }) {
    final trimmedDeviceId = deviceId?.trim() ?? '';
    final payloads = <Map<String, String>>[
      <String, String>{'gmail': gmail},
      <String, String>{'email': gmail},
    ];

    if (trimmedDeviceId.isNotEmpty) {
      payloads.addAll(<Map<String, String>>[
        <String, String>{'gmail': gmail, 'deviceId': trimmedDeviceId},
        <String, String>{'email': gmail, 'deviceId': trimmedDeviceId},
        <String, String>{'gmail': gmail, 'device_id': trimmedDeviceId},
        <String, String>{'email': gmail, 'device_id': trimmedDeviceId},
      ]);
    }

    return payloads;
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
    request.add(utf8.encode(Uri(queryParameters: payload).query));

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
    final isRedirect =
        response.statusCode == 301 ||
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

  String _friendlyResendErrorMessage(
    Map<String, dynamic> json,
    int statusCode,
  ) {
    final resendMessage = _extractErrorMessage(json);
    final fallback = switch (statusCode) {
      400 || 422 =>
        'Email request is invalid. Please check sender and recipient settings.',
      401 || 403 =>
        'Email service is not configured correctly. Please check the Resend API key.',
      429 => 'Email service is busy. Please wait a moment and try again.',
      >= 500 =>
        'Email service is unavailable right now. Please try again later.',
      _ => 'Unable to send token email right now. Please try again.',
    };

    if (resendMessage == null || resendMessage.trim().isEmpty) {
      return fallback;
    }

    return '$fallback ($resendMessage)';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
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
      RegExp(
        r'Only Gmail addresses are allowed[^<\n\r]*',
        caseSensitive: false,
      ),
      RegExp(
        r'Token request is currently disabled[^<\n\r]*',
        caseSensitive: false,
      ),
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

enum _TokenEmailType { request, forgot }

class TokenRequestException implements Exception {
  const TokenRequestException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
