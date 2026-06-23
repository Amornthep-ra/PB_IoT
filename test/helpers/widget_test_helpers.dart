// ignore_for_file: unused_import

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pb_iot/app.dart';
import 'package:pb_iot/features/dashboard/models/device_snapshot_model.dart';
import 'package:pb_iot/features/dashboard/models/widget_binding_model.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_runtime_controller.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_snapshot_refresher.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_runtime_value_storage.dart';
import 'package:pb_iot/features/dashboard/services/dashboard_service.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_item.dart';
import 'package:pb_iot/features/dashboard_builder/models/dashboard_theme_preset.dart';
import 'package:pb_iot/features/dashboard_builder/models/widget_settings_result.dart';
import 'package:pb_iot/features/dashboard_builder/screens/dashboard_builder_screen.dart';
import 'package:pb_iot/features/dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import 'package:pb_iot/features/dashboard_builder/services/dashboard_widget_factory.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/add_widget_sheet.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_home_view.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/dashboard_item_renderer.dart';
import 'package:pb_iot/features/dashboard_builder/widgets/widget_settings_sheet.dart';
import 'package:pb_iot/features/devices/screens/devices_screen.dart';
import 'package:pb_iot/features/notifications/models/alert_event_model.dart';
import 'package:pb_iot/features/notifications/models/alert_rule_model.dart';
import 'package:pb_iot/features/notifications/screens/alert_rule_editor_screen.dart';
import 'package:pb_iot/features/notifications/screens/notifications_screen.dart';
import 'package:pb_iot/features/notifications/services/notification_service.dart';
import 'package:pb_iot/features/projects/models/project_model.dart';
import 'package:pb_iot/features/projects/services/project_state.dart';
import 'package:pb_iot/models/session_model.dart';
import 'package:pb_iot/screens/account_session_screen.dart';
import 'package:pb_iot/screens/dashboard_screen.dart';
import 'package:pb_iot/screens/project_select_screen.dart';
import 'package:pb_iot/screens/token_login_screen.dart';
import 'package:pb_iot/services/auth_service.dart';
import 'package:pb_iot/services/session_state.dart';

void setUpWidgetTestEnvironment() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ProjectState.current = null;
    SessionState.current = null;
  });
}

Widget dashboardHomeTestApp({
  DashboardService? service,
  List<DashboardItem> items = const <DashboardItem>[],
  double bottomContentPadding = 0,
  ValueChanged<bool>? onScrollActivityChanged,
}) {
  seedProjectState();
  return DashboardHomeTestHost(
    service: service,
    items: items,
    bottomContentPadding: bottomContentPadding,
    onScrollActivityChanged: onScrollActivityChanged,
  );
}

Widget devicesTestApp({
  required DeviceSnapshotModel snapshot,
  List<DashboardItem> items = const <DashboardItem>[],
  double bottomContentPadding = 0,
}) {
  seedProjectState();
  return DevicesTestHost(
    key: ValueKey<Object>(Object.hash(snapshot.updatedAt, items.length)),
    snapshot: snapshot,
    items: items,
    bottomContentPadding: bottomContentPadding,
  );
}

Widget notificationsTestApp({
  List<DashboardItem> items = const <DashboardItem>[],
  double bottomContentPadding = 0,
}) {
  seedProjectState();
  return NotificationsTestHost(
    items: items,
    bottomContentPadding: bottomContentPadding,
  );
}

Widget settingsTestApp() {
  SessionState.current = const SessionModel(
    token: 'sf_7123456789845',
    displayName: 'ทดสอบ',
    authType: 'token',
    authenticated: true,
  );
  return MaterialApp(
    home: const AccountSessionScreen(),
    routes: {
      '/login': (_) => const Scaffold(body: Text('login opened')),
      '/projects': (_) => const Scaffold(body: Text('projects opened')),
    },
  );
}

Widget dashboardShellTestApp() {
  seedProjectState();
  return MaterialApp(
    home: const DashboardScreen(),
    routes: {
      '/dashboard-builder': (_) => const Scaffold(body: Text('builder opened')),
      '/account-session': (_) => const Scaffold(body: Text('settings opened')),
    },
  );
}

Widget dashboardBuilderTestApp() {
  seedProjectState();
  return const MaterialApp(home: DashboardBuilderScreen());
}

Widget dashboardBuilderStackTestApp() {
  seedProjectState();
  return MaterialApp(
    home: Builder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DashboardBuilderScreen(),
                  ),
                );
              },
              child: const Text('open builder'),
            ),
          ),
        );
      },
    ),
  );
}

Widget projectSelectTestApp() {
  return MaterialApp(
    home: const ProjectSelectScreen(),
    routes: {
      '/dashboard': (_) => const Scaffold(body: Text('dashboard opened')),
    },
  );
}

void seedProjects() {
  seedProjectState();
  SharedPreferences.setMockInitialValues({
    'projects_v1': jsonEncode([
      {
        'id': 'project_test',
        'name': 'Test',
        'iconKey': 'sprout',
        'createdAt': '2026-06-01T08:42:45.000',
        'updatedAt': '2026-06-01T08:42:45.000',
      },
    ]),
    'selected_project_id_v1': 'project_test',
  });
}

void seedProjectState() {
  ProjectState.current = ProjectModel(
    id: 'project_test',
    name: 'Test',
    iconKey: 'sprout',
    createdAt: DateTime(2026, 6, 1, 8, 42, 45),
    updatedAt: DateTime(2026, 6, 1, 8, 42, 45),
  );
}

class FakeDashboardService extends DashboardService {
  FakeDashboardService([this.snapshot = const DeviceSnapshotModel()]);

  final DeviceSnapshotModel snapshot;
  final List<RecordedBindingWrite> writes = <RecordedBindingWrite>[];

  @override
  Future<DeviceSnapshotModel> fetchRuntimeSnapshot() async {
    return snapshot;
  }

  @override
  DeviceSnapshotModel buildMockSnapshot() {
    return snapshot;
  }

  @override
  Future<void> writeBindingValue({
    required WidgetBindingModel binding,
    required Object? value,
  }) async {
    writes.add(
      RecordedBindingWrite(
        pin: binding.pin,
        writeKey: binding.writeKey,
        value: value,
      ),
    );
  }
}

class FailThenSuccessDashboardService extends DashboardService {
  FailThenSuccessDashboardService(this.successSnapshot);

  final DeviceSnapshotModel successSnapshot;
  int fetchCount = 0;

  @override
  Future<DeviceSnapshotModel> fetchRuntimeSnapshot() async {
    fetchCount += 1;
    if (fetchCount == 1) {
      throw const DashboardServiceException('backend unavailable');
    }
    return successSnapshot;
  }

  @override
  DeviceSnapshotModel buildMockSnapshot() {
    return const DeviceSnapshotModel(
      online: true,
      virtualPins: <String, dynamic>{'V10': 1, 'V13': 40},
    );
  }
}

class SequenceDashboardService extends DashboardService {
  SequenceDashboardService(this.responses);

  final List<Object> responses;
  int fetchCount = 0;

  @override
  Future<DeviceSnapshotModel> fetchRuntimeSnapshot() async {
    final index = fetchCount < responses.length
        ? fetchCount
        : responses.length - 1;
    fetchCount += 1;
    final response = responses[index];
    if (response is DeviceSnapshotModel) {
      return response;
    }
    if (response is DashboardServiceException) {
      throw response;
    }
    throw StateError('Unsupported response type: $response');
  }

  @override
  DeviceSnapshotModel buildMockSnapshot() {
    return const DeviceSnapshotModel();
  }
}

class FakeAuthService extends AuthService {
  FakeAuthService({this.session, this.throwOnFetch = false});

  final SessionModel? session;
  final bool throwOnFetch;
  int fetchCurrentSessionCount = 0;

  @override
  Future<SessionModel?> fetchCurrentSession() async {
    fetchCurrentSessionCount += 1;
    if (throwOnFetch) {
      throw const AuthException('session refresh failed');
    }
    return session;
  }
}

class FakeNotificationService extends NotificationService {
  FakeNotificationService({
    List<AlertRuleModel> rules = const <AlertRuleModel>[],
    List<AlertEventModel> events = const <AlertEventModel>[],
    List<AlertEventModel>? historyEvents,
  }) : _rules = List<AlertRuleModel>.from(rules),
       _events = List<AlertEventModel>.from(events),
       _historyEvents = List<AlertEventModel>.from(historyEvents ?? events);

  List<AlertRuleModel> _rules;
  List<AlertEventModel> _events;
  List<AlertEventModel> _historyEvents;

  @override
  Future<List<AlertRuleModel>> loadRules() async {
    return List<AlertRuleModel>.from(_rules);
  }

  @override
  Future<void> saveRules(List<AlertRuleModel> rules) async {
    _rules = List<AlertRuleModel>.from(rules);
  }

  @override
  Future<List<AlertEventModel>> loadEvents() async {
    return List<AlertEventModel>.from(_events);
  }

  @override
  Future<void> saveEvents(List<AlertEventModel> events) async {
    _events = List<AlertEventModel>.from(events);
  }

  @override
  Future<List<AlertEventModel>> loadHistoryEvents() async {
    return List<AlertEventModel>.from(_historyEvents);
  }

  @override
  Future<void> saveHistoryEvents(List<AlertEventModel> events) async {
    _historyEvents = List<AlertEventModel>.from(events);
  }

  @override
  Future<void> appendEvent(AlertEventModel event) async {
    _events = <AlertEventModel>[event, ..._events];
    _historyEvents = <AlertEventModel>[event, ..._historyEvents];
  }
}

class RecordedBindingWrite {
  const RecordedBindingWrite({
    required this.pin,
    required this.writeKey,
    required this.value,
  });

  final String? pin;
  final String? writeKey;
  final Object? value;
}

class FakeDashboardLayoutStorage extends DashboardBuilderLayoutStorageService {
  FakeDashboardLayoutStorage([this.items = const <DashboardItem>[]]);

  final List<DashboardItem> items;

  @override
  Future<List<DashboardItem>?> loadItems() async {
    return items;
  }
}

class DevicesTestHost extends StatefulWidget {
  const DevicesTestHost({
    super.key,
    required this.snapshot,
    required this.items,
    this.bottomContentPadding = 0,
  });

  final DeviceSnapshotModel snapshot;
  final List<DashboardItem> items;
  final double bottomContentPadding;

  @override
  State<DevicesTestHost> createState() => DevicesTestHostState();
}

class DevicesTestHostState extends State<DevicesTestHost> {
  late final DashboardRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  DashboardRuntimeController _buildController() {
    return DashboardRuntimeController(
      dashboardService: FakeDashboardService(widget.snapshot),
      layoutStorage: FakeDashboardLayoutStorage(widget.items),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DevicesScreen(
          runtimeController: _controller,
          bottomContentPadding: widget.bottomContentPadding,
        ),
      ),
    );
  }
}

class NotificationsTestHost extends StatefulWidget {
  const NotificationsTestHost({
    super.key,
    required this.items,
    this.bottomContentPadding = 0,
  });

  final List<DashboardItem> items;
  final double bottomContentPadding;

  @override
  State<NotificationsTestHost> createState() => NotificationsTestHostState();
}

class NotificationsTestHostState extends State<NotificationsTestHost> {
  late final DashboardRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardRuntimeController(
      dashboardService: FakeDashboardService(),
      layoutStorage: FakeDashboardLayoutStorage(widget.items),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NotificationsScreen(
          runtimeController: _controller,
          bottomContentPadding: widget.bottomContentPadding,
        ),
      ),
    );
  }
}

class DashboardHomeTestHost extends StatefulWidget {
  const DashboardHomeTestHost({
    super.key,
    this.service,
    this.items = const [],
    this.bottomContentPadding = 0,
    this.onScrollActivityChanged,
  });

  final DashboardService? service;
  final List<DashboardItem> items;
  final double bottomContentPadding;
  final ValueChanged<bool>? onScrollActivityChanged;

  @override
  State<DashboardHomeTestHost> createState() => DashboardHomeTestHostState();
}

class DashboardHomeTestHostState extends State<DashboardHomeTestHost> {
  late final DashboardRuntimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardRuntimeController(
      dashboardService: widget.service ?? FakeDashboardService(),
      layoutStorage: FakeDashboardLayoutStorage(widget.items),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DashboardHomeView(
          runtimeController: _controller,
          dashboardService: widget.service,
          bottomContentPadding: widget.bottomContentPadding,
          onScrollActivityChanged: widget.onScrollActivityChanged,
        ),
      ),
      routes: {
        '/dashboard-builder': (_) =>
            const Scaffold(body: Text('builder opened')),
      },
    );
  }
}

class WidgetSettingsSheetTestHost extends StatelessWidget {
  const WidgetSettingsSheetTestHost({
    super.key,
    required this.item,
    required this.onResult,
  });

  final DashboardItem item;
  final ValueChanged<WidgetSettingsResult> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<WidgetSettingsResult>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => WidgetSettingsSheet(item: item),
                      );
                  if (result != null) {
                    onResult(result);
                  }
                },
                child: const Text('open settings'),
              );
            },
          ),
        ),
      ),
    );
  }
}

DashboardItem devicesDashboardItem({
  required String id,
  required String title,
  required String dataKey,
}) {
  return DashboardItem(
    id: id,
    type: DashboardItemType.valueLabel,
    title: title,
    rect: const GridRect(x: 0, y: 0, w: 10, h: 6),
    minW: 8,
    maxW: 28,
    minH: 4,
    maxH: 14,
    accentColor: const Color(0xFF4E9070),
    dataKey: dataKey,
    bindingMode: 'read',
    dataType: 'number',
  );
}

DashboardItem alertEditorDashboardItem() {
  return DashboardItem(
    id: 'alert_button_1',
    type: DashboardItemType.button,
    title: 'ปุ่ม 1',
    rect: const GridRect(x: 0, y: 0, w: 10, h: 6),
    minW: 8,
    maxW: 28,
    minH: 4,
    maxH: 14,
    accentColor: const Color(0xFF4E9070),
    dataKey: 'V0',
    dataKeyLabel: 'คำสั่งสวิตช์',
    bindingMode: 'read',
    dataType: 'boolean',
  );
}

DashboardItem stepDashboardItem({
  required String id,
  required DashboardItemType type,
  required String title,
  required String dataKey,
  double value = 0,
  double stepValue = 1,
}) {
  return DashboardItem(
    id: id,
    type: type,
    title: title,
    rect: type == DashboardItemType.stepV
        ? const GridRect(x: 0, y: 0, w: 4, h: 12)
        : const GridRect(x: 0, y: 0, w: 12, h: 4),
    minW: type == DashboardItemType.stepV ? 3 : 8,
    maxW: type == DashboardItemType.stepV ? 5 : 18,
    minH: type == DashboardItemType.stepV ? 8 : 3,
    maxH: type == DashboardItemType.stepV ? 18 : 5,
    accentColor: const Color(0xFF6CB8F6),
    value: value,
    minValue: 0,
    maxValue: 100,
    stepValue: stepValue,
    dataSource: 'device_channel',
    dataKey: dataKey,
    dataKeyLabel: 'Stepper',
    bindingMode: 'read_write',
    dataType: 'number',
  );
}

String thaiShortMonth(int month) {
  const months = <String>[
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  return months[month - 1];
}
