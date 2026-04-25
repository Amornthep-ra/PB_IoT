import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/dashboard_layout_model.dart';
import '../models/dashboard_widget_model.dart';
import '../models/device_snapshot_model.dart';
import '../models/widget_binding_model.dart';
import 'widget_binding_resolver.dart';
import '../../../services/api_request_support.dart';
import '../../../services/session_cookie_storage.dart';
import 'dashboard_local_storage_service.dart';

class DashboardService {
  DashboardService({
    DashboardLocalStorageService? localStorageService,
    HttpClient? httpClient,
  }) : _localStorageService =
           localStorageService ?? DashboardLocalStorageService(),
       _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 10);
  }

  static const String _serverBaseUrl = 'https://console.princebot.co.th';
  static final Uri _statusUri = Uri.parse('$_serverBaseUrl/api/farm/status');
  static final Uri _virtualPinUri = Uri.parse(
    '$_serverBaseUrl/api/farm/virtual-pin',
  );
  static final Uri _pumpUri = Uri.parse('$_serverBaseUrl/api/farm/pump');
  static final Uri _fanUri = Uri.parse('$_serverBaseUrl/api/farm/fan');
  static final Uri _modeUri = Uri.parse('$_serverBaseUrl/api/farm/mode');
  static final Uri _thresholdUri = Uri.parse(
    '$_serverBaseUrl/api/farm/threshold',
  );

  final DashboardLocalStorageService _localStorageService;
  final HttpClient _httpClient;

  Future<DashboardLayoutModel> loadRuntimeLayout() async {
    final storedLayout = await _localStorageService.loadLayout();
    return storedLayout ?? buildDefaultLayout();
  }

  Future<void> saveRuntimeLayout(DashboardLayoutModel layout) {
    return _localStorageService.saveLayout(layout);
  }

  Future<DeviceSnapshotModel> fetchRuntimeSnapshot() async {
    try {
      final storedCookie = await SessionCookieStorage.loadCookieHeader();
      final request = await _httpClient
          .getUrl(_statusUri)
          .timeout(const Duration(seconds: 10));

      ApiRequestSupport.applyDefaultHeaders(
        request,
        cookieHeader: storedCookie,
      );

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));

      final responseJson = _tryDecodeJson(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DashboardServiceException(
          _friendlyErrorMessage(
            rawMessage: _extractErrorMessage(responseJson) ?? responseBody,
            statusCode: response.statusCode,
            operation: _DashboardErrorOperation.load,
          ),
        );
      }

      if (responseJson['ok'] != true) {
        throw DashboardServiceException(
          _friendlyErrorMessage(
            rawMessage: _extractErrorMessage(responseJson) ?? responseBody,
            statusCode: response.statusCode,
            operation: _DashboardErrorOperation.load,
          ),
        );
      }

      return DeviceSnapshotModel.fromJson(responseJson);
    } on DashboardServiceException {
      rethrow;
    } on TimeoutException {
      throw const DashboardServiceException(
        'เซิร์ฟเวอร์ตอบสนองช้า รอสักครู่แล้วลองใหม่อีกครั้ง',
      );
    } on SocketException {
      throw const DashboardServiceException(
        'ไม่มีอินเทอร์เน็ตหรือเชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบ Wi-Fi หรือสัญญาณมือถือแล้วลองใหม่อีกครั้ง',
      );
    } on IOException {
      throw const DashboardServiceException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง',
      );
    }
  }

  Future<void> writeBindingValue({
    required WidgetBindingModel binding,
    required Object? value,
  }) async {
    final normalized = _normalizeWriteValue(
      valueType: binding.valueType,
      value: value,
    );

    final pin = binding.pin?.trim();
    if (pin != null && pin.isNotEmpty) {
      await _postJson(_virtualPinUri, <String, dynamic>{
        'pin': pin,
        'value': normalized,
      });
      return;
    }

    final writeKey = binding.writeKey?.trim();
    switch (writeKey) {
      case 'control.pumpStatus':
        await _postJson(_pumpUri, <String, dynamic>{
          'value': _normalizeBinary(normalized),
        });
        return;
      case 'control.fanStatus':
        await _postJson(_fanUri, <String, dynamic>{
          'value': _normalizeBinary(normalized),
        });
        return;
      case 'control.autoMode':
        await _postJson(_modeUri, <String, dynamic>{
          'value': _normalizeBinary(normalized),
        });
        return;
      case 'control.soilThreshold':
        await _postJson(_thresholdUri, <String, dynamic>{
          'value': WidgetBindingResolver.coerceDouble(normalized) ?? 0,
        });
        return;
      default:
        throw const DashboardServiceException(
          'วิดเจ็ตนี้ยังไม่ได้ตั้งค่าการสั่งงาน ตรวจสอบการตั้งค่า widget binding',
        );
    }
  }

  DeviceSnapshotModel buildMockSnapshot() {
    return DeviceSnapshotModel(
      online: true,
      updatedAt: DateTime.now(),
      status: const <String, dynamic>{
        'temperature': 24,
        'humidity': 65,
        'soilMoisture': 78,
        'pumpStatus': true,
        'waterLevel': 82,
      },
      units: const <String, dynamic>{
        'temperature': '°C',
        'humidity': '%',
        'soilMoisture': '%',
        'waterLevel': '%',
        'soilThreshold': '%',
      },
      virtualPins: const <String, dynamic>{'V10': 1, 'V13': 40},
    );
  }

  DashboardLayoutModel buildDefaultLayout() {
    return DashboardLayoutModel(
      id: 'default-dashboard',
      name: 'PrinceBot Dashboard',
      widgets: const <DashboardWidgetModel>[
        DashboardWidgetModel(
          id: 'temperature-card',
          type: DashboardWidgetType.valueCard,
          title: 'Temperature',
          layout: DashboardWidgetLayout(x: 0, y: 0, w: 1, h: 1),
          binding: WidgetBindingModel(
            source: WidgetBindingSource.api,
            readKey: 'status.temperature',
            valueType: WidgetBindingValueType.number,
          ),
          options: <String, dynamic>{'suffix': '', 'fallbackText': '--'},
        ),
        DashboardWidgetModel(
          id: 'humidity-card',
          type: DashboardWidgetType.valueCard,
          title: 'Humidity',
          layout: DashboardWidgetLayout(x: 1, y: 0, w: 1, h: 1),
          binding: WidgetBindingModel(
            source: WidgetBindingSource.api,
            readKey: 'status.humidity',
            valueType: WidgetBindingValueType.number,
          ),
          options: <String, dynamic>{'suffix': '', 'fallbackText': '--'},
        ),
        DashboardWidgetModel(
          id: 'soil-moisture-progress',
          type: DashboardWidgetType.progressCard,
          title: 'Soil Moisture',
          layout: DashboardWidgetLayout(x: 0, y: 1, w: 2, h: 1),
          binding: WidgetBindingModel(
            source: WidgetBindingSource.api,
            readKey: 'status.soilMoisture',
            valueType: WidgetBindingValueType.number,
          ),
          options: <String, dynamic>{'suffix': ''},
        ),
        DashboardWidgetModel(
          id: 'device-status',
          type: DashboardWidgetType.statusCard,
          title: 'Device Status',
          layout: DashboardWidgetLayout(x: 0, y: 2, w: 2, h: 1),
          options: <String, dynamic>{
            'onlineText': 'Online',
            'offlineText': 'Offline',
          },
        ),
        DashboardWidgetModel(
          id: 'pump-switch',
          type: DashboardWidgetType.switchControl,
          title: 'Water Pump',
          layout: DashboardWidgetLayout(x: 0, y: 3, w: 2, h: 1),
          binding: WidgetBindingModel(
            source: WidgetBindingSource.mqtt,
            readKey: 'status.pumpStatus',
            writeKey: 'control.pumpStatus',
            pin: 'V10',
            valueType: WidgetBindingValueType.boolean,
          ),
          options: <String, dynamic>{'onLabel': 'ON', 'offLabel': 'OFF'},
        ),
      ],
    );
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

  String _friendlyErrorMessage({
    required String? rawMessage,
    required int? statusCode,
    required _DashboardErrorOperation operation,
  }) {
    final normalized = rawMessage?.toLowerCase() ?? '';
    final fallback = operation == _DashboardErrorOperation.write
        ? 'ส่งคำสั่งไปยังอุปกรณ์ไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วลองใหม่'
        : 'โหลดสถานะอุปกรณ์ไม่ได้ ลองรีเฟรช Dashboard อีกครั้ง';

    if (normalized.contains('imunify360') ||
        normalized.contains('bot-protection') ||
        normalized.contains('access denied')) {
      return 'ระบบความปลอดภัยของเซิร์ฟเวอร์บล็อกการเชื่อมต่อ ลองเปลี่ยนเครือข่ายหรือแจ้งผู้ดูแลระบบให้ตรวจสอบ IP';
    }

    if (statusCode == 401 ||
        statusCode == 403 ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden')) {
      return 'ไม่มีสิทธิ์เข้าถึงข้อมูล Dashboard กรุณาเข้าสู่ระบบใหม่อีกครั้ง';
    }

    if (statusCode == 408 ||
        statusCode == 504 ||
        normalized.contains('timeout') ||
        normalized.contains('timed out')) {
      return 'เซิร์ฟเวอร์ตอบสนองช้า รอสักครู่แล้วลองใหม่อีกครั้ง';
    }

    if (normalized.contains('socket') ||
        normalized.contains('network') ||
        normalized.contains('connection refused') ||
        normalized.contains('failed host lookup')) {
      return 'ไม่มีอินเทอร์เน็ตหรือเชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบ Wi-Fi หรือสัญญาณมือถือแล้วลองใหม่อีกครั้ง';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'เซิร์ฟเวอร์มีปัญหาชั่วคราว กรุณาลองใหม่ภายหลัง';
    }

    if (normalized.contains('not configured') ||
        normalized.contains('write binding')) {
      return 'วิดเจ็ตนี้ยังไม่ได้ตั้งค่าการสั่งงาน ตรวจสอบการตั้งค่า widget binding';
    }

    if (normalized.contains('unable to write widget value') ||
        normalized.contains('unable to send widget value')) {
      return 'ส่งคำสั่งไปยังอุปกรณ์ไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วลองใหม่';
    }

    if (normalized.contains('unable to load dashboard') ||
        normalized.contains('unable to refresh dashboard')) {
      return 'โหลดสถานะอุปกรณ์ไม่ได้ ลองรีเฟรช Dashboard อีกครั้ง';
    }

    return fallback;
  }

  Object _normalizeWriteValue({
    required WidgetBindingValueType valueType,
    required Object? value,
  }) {
    switch (valueType) {
      case WidgetBindingValueType.boolean:
        return WidgetBindingResolver.coerceBool(value) == true ? 1 : 0;
      case WidgetBindingValueType.number:
        return WidgetBindingResolver.coerceDouble(value) ?? 0;
      case WidgetBindingValueType.string:
      case WidgetBindingValueType.enumeration:
        return value?.toString() ?? '';
    }
  }

  int _normalizeBinary(Object value) {
    final boolValue = WidgetBindingResolver.coerceBool(value);
    if (boolValue != null) {
      return boolValue ? 1 : 0;
    }
    final numberValue = WidgetBindingResolver.coerceDouble(value);
    if (numberValue == null) {
      return 0;
    }
    return numberValue >= 0.5 ? 1 : 0;
  }

  Future<void> _postJson(Uri uri, Map<String, dynamic> payload) async {
    try {
      final storedCookie = await SessionCookieStorage.loadCookieHeader();
      final request = await _httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));

      ApiRequestSupport.applyDefaultHeaders(
        request,
        cookieHeader: storedCookie,
      );
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        ContentType.json.mimeType,
      );

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));
      final responseJson = _tryDecodeJson(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DashboardServiceException(
          _friendlyErrorMessage(
            rawMessage: _extractErrorMessage(responseJson) ?? responseBody,
            statusCode: response.statusCode,
            operation: _DashboardErrorOperation.write,
          ),
        );
      }
      if (responseJson.isNotEmpty && responseJson['ok'] == false) {
        throw DashboardServiceException(
          _friendlyErrorMessage(
            rawMessage: _extractErrorMessage(responseJson) ?? responseBody,
            statusCode: response.statusCode,
            operation: _DashboardErrorOperation.write,
          ),
        );
      }
    } on DashboardServiceException {
      rethrow;
    } on TimeoutException {
      throw const DashboardServiceException(
        'เซิร์ฟเวอร์ตอบสนองช้า รอสักครู่แล้วลองใหม่อีกครั้ง',
      );
    } on SocketException {
      throw const DashboardServiceException(
        'ไม่มีอินเทอร์เน็ตหรือเชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบ Wi-Fi หรือสัญญาณมือถือแล้วลองใหม่อีกครั้ง',
      );
    } on IOException {
      throw const DashboardServiceException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง',
      );
    }
  }
}

enum _DashboardErrorOperation { load, write }

class DashboardServiceException implements Exception {
  const DashboardServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
