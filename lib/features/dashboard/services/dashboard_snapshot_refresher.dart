import '../../../services/auth_service.dart';
import '../../../services/profile_avatar_preset_storage.dart';
import '../../../services/session_snapshot_storage.dart';
import '../../../services/session_state.dart';
import '../../dashboard/models/device_snapshot_model.dart';
import 'dashboard_service.dart';

class DashboardSnapshotRefreshResult {
  const DashboardSnapshotRefreshResult({
    this.snapshot,
    this.errorText,
    required this.didRecoverSession,
    required this.attemptedSessionRecovery,
  });

  final DeviceSnapshotModel? snapshot;
  final String? errorText;
  final bool didRecoverSession;
  final bool attemptedSessionRecovery;

  bool get isSuccess => snapshot != null && errorText == null;
}

class DashboardSnapshotRefresher {
  DashboardSnapshotRefresher({
    required DashboardService dashboardService,
    AuthService? authService,
    DateTime Function()? now,
  }) : _dashboardService = dashboardService,
       _authService = authService ?? AuthService(),
       _now = now ?? DateTime.now;

  static const Duration sessionRecoveryThrottle = Duration(seconds: 60);

  final DashboardService _dashboardService;
  final AuthService _authService;
  final DateTime Function() _now;

  bool _isRecoveringSession = false;
  DateTime? _lastSessionRecoveryAttemptAt;

  Future<DashboardSnapshotRefreshResult> refresh() async {
    final initialAttempt = await _fetchSnapshot();
    if (initialAttempt.snapshot != null) {
      return initialAttempt;
    }

    if (!_shouldAttemptSessionRecovery()) {
      return initialAttempt;
    }

    final recovered = await _recoverSession();
    if (!recovered) {
      return DashboardSnapshotRefreshResult(
        snapshot: null,
        errorText: initialAttempt.errorText,
        didRecoverSession: false,
        attemptedSessionRecovery: true,
      );
    }

    final retryAttempt = await _fetchSnapshot();
    return DashboardSnapshotRefreshResult(
      snapshot: retryAttempt.snapshot,
      errorText: retryAttempt.errorText,
      didRecoverSession: retryAttempt.snapshot != null,
      attemptedSessionRecovery: true,
    );
  }

  bool _shouldAttemptSessionRecovery() {
    final currentSession = SessionState.current;
    if (currentSession?.isOfflineMode != true) {
      return false;
    }
    if (_isRecoveringSession) {
      return false;
    }

    final lastAttemptAt = _lastSessionRecoveryAttemptAt;
    if (lastAttemptAt == null) {
      return true;
    }

    return _now().difference(lastAttemptAt) >= sessionRecoveryThrottle;
  }

  Future<DashboardSnapshotRefreshResult> _fetchSnapshot() async {
    try {
      final snapshot = await _dashboardService.fetchRuntimeSnapshot();
      return DashboardSnapshotRefreshResult(
        snapshot: snapshot,
        errorText: null,
        didRecoverSession: false,
        attemptedSessionRecovery: false,
      );
    } on DashboardServiceException catch (error) {
      return DashboardSnapshotRefreshResult(
        snapshot: null,
        errorText: error.message,
        didRecoverSession: false,
        attemptedSessionRecovery: false,
      );
    } catch (_) {
      return const DashboardSnapshotRefreshResult(
        snapshot: null,
        errorText: 'ไม่สามารถรีเฟรชข้อมูล Dashboard ได้ในขณะนี้',
        didRecoverSession: false,
        attemptedSessionRecovery: false,
      );
    }
  }

  Future<bool> _recoverSession() async {
    final currentSession = SessionState.current;
    if (currentSession == null) {
      return false;
    }

    _isRecoveringSession = true;
    _lastSessionRecoveryAttemptAt = _now();

    try {
      final refreshedSession = await _authService.fetchCurrentSession();
      if (refreshedSession == null) {
        return false;
      }

      var mergedSession = refreshedSession.copyWith(
        token: refreshedSession.token.trim().isNotEmpty
            ? refreshedSession.token
            : currentSession.token,
        displayName: refreshedSession.displayName.trim().isNotEmpty
            ? refreshedSession.displayName
            : currentSession.displayName,
      );
      mergedSession = await ProfileAvatarPresetStorage.applyStoredAvatar(
        mergedSession,
      );

      final synchronizedSession = mergedSession.copyWith(
        cachedProfileImagePath: '',
        isOfflineMode: false,
      );
      SessionState.current = synchronizedSession;
      await SessionSnapshotStorage.save(synchronizedSession);
      return true;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRecoveringSession = false;
    }
  }
}
