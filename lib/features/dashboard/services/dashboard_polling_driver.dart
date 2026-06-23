import 'dart:async';

import 'package:flutter/widgets.dart';

typedef DashboardPollingCallback = Future<void> Function();
typedef DashboardPeriodicTimerFactory =
    Timer Function(Duration duration, void Function(Timer timer) callback);

class DashboardPollingDriver {
  DashboardPollingDriver({
    required Duration pollInterval,
    required DashboardPollingCallback onPoll,
    DashboardPeriodicTimerFactory? periodicTimerFactory,
  }) : _pollInterval = pollInterval,
       _onPoll = onPoll,
       _periodicTimerFactory = periodicTimerFactory ?? Timer.periodic;

  final Duration _pollInterval;
  final DashboardPollingCallback _onPoll;
  final DashboardPeriodicTimerFactory _periodicTimerFactory;

  Timer? _pollTimer;
  bool _isDisposed = false;
  bool _isPollingEnabled = false;
  bool _isForegroundPollingAllowed = true;

  bool get isPollingEnabled => _isPollingEnabled;
  bool get isForegroundPollingAllowed => _isForegroundPollingAllowed;

  void start() {
    if (_isDisposed) {
      return;
    }
    _isPollingEnabled = true;
    _syncPollingTimer();
  }

  void stop() {
    _isPollingEnabled = false;
    _cancelTimer();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _cancelTimer();
  }

  void handleLifecycleState(AppLifecycleState state) {
    final shouldPoll =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (_isForegroundPollingAllowed == shouldPoll) {
      return;
    }

    final wasAllowed = _isForegroundPollingAllowed;
    _isForegroundPollingAllowed = shouldPoll;
    _syncPollingTimer();

    if (!wasAllowed && shouldPoll && _isPollingEnabled) {
      unawaited(_onPoll());
    }
  }

  void _syncPollingTimer() {
    if (_isDisposed || !_isPollingEnabled || !_isForegroundPollingAllowed) {
      _cancelTimer();
      return;
    }

    if (_pollTimer != null) {
      return;
    }

    _pollTimer = _periodicTimerFactory(_pollInterval, (_) {
      unawaited(_onPoll());
    });
  }

  void _cancelTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
