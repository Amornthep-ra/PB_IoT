# PB_IOT Project Context

This document summarizes the key project context for `PB_IoT` so future development, debugging, and handoff work can start quickly.

## Project Overview

`PB_IoT` is a Flutter application for managing and controlling PrinceBot IoT dashboards. The app is primarily designed for portrait mobile usage. Its main flow is token login, project selection, runtime dashboard display, dashboard widget building/editing, device viewing, and alert notification management.

Entry points:

- `lib/main.dart` locks the app to portrait orientation and calls `runApp(const PbIotApp())`.
- `lib/app.dart` defines the `MaterialApp`, route map, and startup session gate.

## Tech Stack

- Flutter / Dart
- Dart SDK: `^3.11.1`
- Main state patterns: in-memory singleton/static state and `ChangeNotifier`
- Local persistence: `shared_preferences`
- Remembered token storage: `flutter_secure_storage`
- HTTP: `dart:io` `HttpClient`
- Local notifications: `flutter_local_notifications`
- External links: `url_launcher`
- Color picker: `flutter_colorpicker`

## Common Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Run individual tests:

```sh
flutter test test/dashboard_item_renderer_test.dart
flutter test test/session_cookie_storage_test.dart
flutter test test/widget_test.dart
```

## Key Structure

```text
lib/
  main.dart
  app.dart
  models/
  screens/
  services/
  theme/
  widgets/
  features/
    dashboard/
    dashboard_builder/
    devices/
    notifications/
    projects/
```

Important files and responsibilities:

- `lib/app.dart` handles startup session restore, offline session fallback, and route mapping.
- `lib/screens/token_login_screen.dart` handles token login, remember-me behavior, and links to token request/privacy/delete-account pages.
- `lib/screens/project_select_screen.dart` handles create/edit/select/delete project flows.
- `lib/screens/dashboard_screen.dart` owns bottom navigation and the shared `DashboardRuntimeController`.
- `lib/screens/account_session_screen.dart` contains account/session settings.
- `lib/features/dashboard_builder/screens/dashboard_builder_screen.dart` is the main dashboard widget editor.
- `lib/features/dashboard_builder/widgets/dashboard_home_view.dart` is the runtime/home dashboard view.
- `lib/features/devices/screens/devices_screen.dart` is the devices tab.
- `lib/features/notifications/screens/notifications_screen.dart` is the notifications tab.

## Route Map

Defined in `PbIotApp`:

- `/login` -> `TokenLoginScreen`
- `/projects` -> `ProjectSelectScreen`
- `/dashboard` -> `DashboardScreen`
- `/dashboard-builder` -> `DashboardBuilderScreen`
- `/account-session` -> `AccountSessionScreen`

Startup begins in `_StartupSessionGate`:

1. Load remembered login data from `SessionCookieStorage`.
2. If no remembered login exists, or `rememberMe == false`, clear runtime/session state and go to `/login`.
3. If remembered login exists, call `AuthService.fetchCurrentSession()`.
4. If the session is valid, save a session snapshot and continue to the project gate.
5. On timeout/network failure, attempt to restore an offline session from `SessionSnapshotStorage`.
6. If a selected project exists, go to `/dashboard`; otherwise go to `/projects`.

## Authentication And Session

Main services:

- `lib/services/auth_service.dart`
- `lib/services/session_cookie_storage.dart`
- `lib/services/session_snapshot_storage.dart`
- `lib/services/session_state.dart`

API endpoints:

- `POST https://console.princebot.co.th/api/public/login`
- `POST https://console.princebot.co.th/api/public/logout`
- `GET https://console.princebot.co.th/api/public/session`

Important details:

- Login sends `token` and `displayName` as `application/x-www-form-urlencoded`.
- `Set-Cookie` response headers are converted into a cookie header and stored in `SharedPreferences`.
- Remembered tokens are stored in `FlutterSecureStorage`; legacy tokens are migrated from `SharedPreferences`.
- `SessionState.current` is the current global static session.
- Offline mode uses `SessionSnapshotStorage` so the app can still open when the server/network is unavailable.

## Project System

Main files:

- `lib/features/projects/services/project_storage_service.dart`
- `lib/features/projects/services/project_state.dart`
- `lib/features/projects/models/project_model.dart`

Storage keys:

- `projects_v1`
- `selected_project_id_v1`

Projects affect dashboard and notification storage scope through `ProjectState.current.id`. Several services append the project id to their base key, using a pattern like `${baseKey}_${projectId}`.

## Dashboard Runtime

Main controller/services:

- `lib/features/dashboard/services/dashboard_runtime_controller.dart`
- `lib/features/dashboard/services/dashboard_service.dart`
- `lib/features/dashboard/services/dashboard_runtime_value_storage.dart`
- `lib/features/dashboard/services/widget_binding_resolver.dart`

Runtime controller behavior:

- Extends `ChangeNotifier`.
- Loads dashboard layout from builder storage.
- Loads alert rules.
- Fetches the device snapshot from the server.
- Polls every 2 seconds while the app is in the foreground.
- Falls back to a mock snapshot when fetching fails.
- Evaluates alert rules when widget values change.
- Exposes `highlightItemIdNotifier` so other screens can request scroll/highlight behavior for a dashboard widget.

Dashboard API endpoints:

- `GET https://console.princebot.co.th/api/farm/status`
- `POST https://console.princebot.co.th/api/farm/virtual-pin`
- `POST https://console.princebot.co.th/api/farm/pump`
- `POST https://console.princebot.co.th/api/farm/fan`
- `POST https://console.princebot.co.th/api/farm/mode`
- `POST https://console.princebot.co.th/api/farm/threshold`

Binding write behavior:

- If a binding has `pin`, writes go to `/api/farm/virtual-pin`.
- If no pin is configured, writes are routed by `writeKey`, such as `control.pumpStatus`, `control.fanStatus`, `control.autoMode`, or `control.soilThreshold`.

## Dashboard Builder

Feature directory:

- `lib/features/dashboard_builder/`

Main models:

- `DashboardItem`
- `DashboardItemType`
- `GridRect`
- `DashboardThemePreset`
- `DashboardBuilderInteractionState`

Widget types:

- `button`
- `slider`
- `gauge`
- `toggle`
- `valueLabel`

Builder capabilities:

- Add widget
- Drag/resize on a grid
- Undo/redo
- Duplicate
- Multi-select
- Lock item
- Title positioning
- Theme presets/custom themes
- Binding settings
- Persisted draft/history
- Deletion flow that accounts for linked alert rules
- Queued/debounced control writes for interactive controls

Storage service:

- `lib/features/dashboard_builder/services/dashboard_builder_layout_storage_service.dart`

Base storage keys:

- `dashboard_builder_layout_v1`
- `dashboard_builder_title_v1`
- `dashboard_builder_theme_preset_v1`
- `dashboard_builder_theme_custom_v1`
- `dashboard_builder_history_v1`
- `dashboard_builder_draft_v1`

These values become project-scoped when `ProjectState.current.id` is available.

## Notifications

Feature directory:

- `lib/features/notifications/`

Main services:

- `NotificationService`
- `LocalAlertNotificationService`

Base storage keys:

- `alerts_rules_v1`
- `alerts_events_v1`
- `alerts_history_v1`

Main notification models:

- `AlertRuleModel`
- `AlertEventModel`
- `AppEventModel`

Core behavior:

- Rules and events are stored locally with project-scoped keys.
- `DashboardRuntimeController` evaluates alert rules from widget values.
- The app keeps both current events and history events.
- Supported operations include mark read, mark all read, delete history event, clear events, clear rules, and clear history.

## Theme And UI Style

Main theme utilities:

- `lib/theme/app_theme.dart`
- `lib/theme/app_responsive.dart`

Current UI direction:

- Soft glass / neumorphic feel
- Light background, commonly `#F2F5FA`
- Translucent or gradient surfaces
- Soft shadows
- Relatively rounded corners
- Thai text is used in many user-facing screens

When adding UI, prefer reusing:

- `AppGlassTheme.surfaceDecoration`
- `AppGlassTheme.accentDecoration`
- Existing spacing/radius/palette from the screen being edited
- Shared widgets under `lib/widgets/`

## Assets

Declared in `pubspec.yaml`:

- `assets/icons/`
- `assets/icons/logo/Princebot_IoT_V2.png`
- `assets/icons/logo/Princebot_IoT_V2C.png`
- `assets/icons/logo/Princebot_IoT_Login.png`
- `assets/icons/logo/Princebot_IoT_splash.png`
- `assets/icons/dashboard_builder/`
- `assets/icons/mascot/`
- `assets/icons/profile/`

Launcher icon configuration uses `flutter_launcher_icons` with this source image:

- `assets/icons/logo/Princebot_IoT_V2.png`

## Tests

Current tests:

- `test/widget_test.dart`
- `test/dashboard_item_renderer_test.dart`
- `test/session_cookie_storage_test.dart`

When changing storage, rendering, session behavior, or widget formatting logic, add or update focused tests.

## Development Notes And Risks

- The worktree may contain existing uncommitted changes. Do not revert or format the whole project unless explicitly requested.
- Several storage services are project-scoped through `ProjectState.current`; if values seem missing during debugging, check the selected project first.
- `SessionState.current` is mutable global state. Tests or flows that depend on session state should reset it explicitly.
- Network code uses raw `HttpClient` with a 10-second timeout.
- Runtime dashboard polling runs every 2 seconds; be careful with new listeners, side effects, and repeated notifications.
- `DashboardBuilderScreen` is large and highly stateful. Keep changes scoped and only extract helpers when they reduce real complexity.
- `DashboardItem` preserves backward compatibility with legacy title prefixes such as `NEW BUTTON`; do not remove that behavior without checking migration impact.
- Many user-facing screens use Thai copy. Preserve the existing tone and terminology when editing UI text.

## Suggested Development Workflow

1. Read the relevant feature files before editing.
2. Check `git status --short` to separate existing user work from new changes.
3. Make scoped changes.
4. Run `flutter analyze`.
5. Run the relevant tests, or `flutter test` when shared behavior is touched.
6. Summarize changed files and verification results.

