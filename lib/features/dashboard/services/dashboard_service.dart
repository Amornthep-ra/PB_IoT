import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/dashboard_layout_model.dart';
import '../models/dashboard_widget_model.dart';
import '../models/device_snapshot_model.dart';
import '../models/widget_binding_model.dart';
import 'widget_binding_resolver.dart';
import '../../../services/session_cookie_storage.dart';
import 'dashboard_local_storage_service.dart';

class DashboardService {
  DashboardService({
    DashboardLocalStorageService? localStorageService,
    HttpClient? httpClient,
  })  : _localStorageService =
            localStorageService ?? DashboardLocalStorageService(),
        _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 10);
  }

  static final Uri _statusUri =
      Uri.parse('https://princebot.co.th/api/farm/status');
  static final Uri _virtualPinUri =
      Uri.parse('https://princebot.co.th/api/farm/virtual-pin');
  static final Uri _pumpUri = Uri.parse('https://princebot.co.th/api/farm/pump');
  static final Uri _fanUri = Uri.parse('https://princebot.co.th/api/farm/fan');
  static final Uri _modeUri = Uri.parse('https://princebot.co.th/api/farm/mode');
  static final Uri _thresholdUri =
      Uri.parse('https://princebot.co.th/api/farm/threshold');

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
    final storedCookie = await SessionCookieStorage.loadCookieHeader();
    final request = await _httpClient
        .getUrl(_statusUri)
        .timeout(const Duration(seconds: 10));

    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (storedCookie != null && storedCookie.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, storedCookie);
    }

    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));

    final responseJson = _tryDecodeJson(responseBody);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DashboardServiceException(
        _extractErrorMessage(responseJson) ?? 'Unable to load dashboard status.',
      );
    }

    if (responseJson['ok'] != true) {
      throw DashboardServiceException(
        _extractErrorMessage(responseJson) ?? 'Unable to load dashboard status.',
      );
    }

    return DeviceSnapshotModel.fromJson(responseJson);
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
          'This widget is not configured for write binding.',
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
      virtualPins: const <String, dynamic>{
        'V10': 1,
        'V13': 40,
      },
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
          options: <String, dynamic>{
            'suffix': '',
            'fallbackText': '--',
          },
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
          options: <String, dynamic>{
            'suffix': '',
            'fallbackText': '--',
          },
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
          options: <String, dynamic>{
            'suffix': '',
          },
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
          options: <String, dynamic>{
            'onLabel': 'ON',
            'offLabel': 'OFF',
          },
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
    final storedCookie = await SessionCookieStorage.loadCookieHeader();
    final request = await _httpClient
        .postUrl(uri)
        .timeout(const Duration(seconds: 10));

    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.headers.set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);
    if (storedCookie != null && storedCookie.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, storedCookie);
    }

    request.add(utf8.encode(jsonEncode(payload)));
    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));
    final responseJson = _tryDecodeJson(responseBody);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DashboardServiceException(
        _extractErrorMessage(responseJson) ?? 'Unable to write widget value.',
      );
    }
    if (responseJson.isNotEmpty && responseJson['ok'] == false) {
      throw DashboardServiceException(
        _extractErrorMessage(responseJson) ?? 'Unable to write widget value.',
      );
    }
  }
}

class DashboardServiceException implements Exception {
  const DashboardServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
