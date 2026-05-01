import 'dart:async';

import 'package:flutter/material.dart';

import 'features/dashboard_builder/screens/dashboard_builder_screen.dart';
import 'features/projects/services/project_storage_service.dart';
import 'screens/account_session_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/project_select_screen.dart';
import 'screens/token_login_screen.dart';
import 'services/auth_service.dart';
import 'features/dashboard/services/dashboard_runtime_value_storage.dart';
import 'services/profile_avatar_preset_storage.dart';
import 'services/session_cookie_storage.dart';
import 'services/session_snapshot_storage.dart';
import 'services/session_state.dart';

class PbIotApp extends StatelessWidget {
  const PbIotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PB IoT',
      debugShowCheckedModeBanner: false,
      home: const _StartupSessionGate(),
      routes: {
        '/login': (_) => const TokenLoginScreen(),
        '/projects': (_) => const ProjectSelectScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/dashboard-builder': (_) => const DashboardBuilderScreen(),
        '/account-session': (_) => const AccountSessionScreen(),
      },
    );
  }
}

class _StartupSessionGate extends StatefulWidget {
  const _StartupSessionGate();

  @override
  State<_StartupSessionGate> createState() => _StartupSessionGateState();
}

class _StartupSessionGateState extends State<_StartupSessionGate> {
  final AuthService _authService = AuthService();
  final ProjectStorageService _projectStorageService = ProjectStorageService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final rememberedLogin = await SessionCookieStorage.loadRememberedLogin();
      if (rememberedLogin == null || rememberedLogin.rememberMe == false) {
        await DashboardRuntimeValueStorage().clear();
        await SessionSnapshotStorage.clear();
        SessionState.current = null;
        _goToLogin();
        return;
      }
      final restoredSession = await _authService.fetchCurrentSession();
      if (restoredSession == null) {
        await DashboardRuntimeValueStorage().clear();
        await SessionSnapshotStorage.clear();
        SessionState.current = null;
        _goToLogin(sessionExpired: true);
        return;
      } else {
        final restoredWithAvatar =
            await ProfileAvatarPresetStorage.applyStoredAvatar(restoredSession);
        final synchronizedSession = restoredWithAvatar.copyWith(
          cachedProfileImagePath: '',
          isOfflineMode: false,
        );
        await SessionSnapshotStorage.save(synchronizedSession);
        SessionState.current = synchronizedSession;
      }

      if (!mounted) {
        return;
      }

      await _goToSelectedProjectOrProjectGate();
    } on TimeoutException {
      await _restoreOfflineSessionOrGoToLogin();
    } on AuthException {
      await DashboardRuntimeValueStorage().clear();
      await SessionSnapshotStorage.clear();
      SessionState.current = null;
      _goToLogin(sessionExpired: true);
    } catch (_) {
      await _restoreOfflineSessionOrGoToLogin();
    }
  }

  Future<void> _restoreOfflineSessionOrGoToLogin() async {
    final snapshot = await SessionSnapshotStorage.load();
    if (snapshot == null) {
      await DashboardRuntimeValueStorage().clear();
      SessionState.current = null;
      _goToLogin();
      return;
    }

    final synchronizedSession = snapshot.copyWith(
      cachedProfileImagePath: '',
      isOfflineMode: true,
    );
    SessionState.current = synchronizedSession;

    if (!mounted) {
      return;
    }

    await _goToSelectedProjectOrProjectGate();
  }

  Future<void> _goToSelectedProjectOrProjectGate() async {
    final selectedProject = await _projectStorageService.loadSelectedProject();
    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      selectedProject == null ? '/projects' : '/dashboard',
    );
  }

  void _goToLogin({bool sessionExpired = false}) {
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      '/login',
      arguments: sessionExpired
          ? TokenLoginScreen.sessionExpiredRouteArgument
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10162B),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/icons/logo/Princebot_IoT_splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
