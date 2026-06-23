part of '../notifications_screen.dart';

extension _NotificationRuntimeHelpers on _NotificationsScreenState {
  void _handleRuntimeChanged() {
    _screenController.handleRuntimeChanged();
  }

  Future<void> _openRuleEditor({AlertRuleModel? rule}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AlertRuleEditorScreen(initialRule: rule),
      ),
    );
    if (result == true && mounted) {
      await _runtimeController.reloadAlertRules();
      await _screenController.loadData();
    }
  }

  Future<void> _markEventRead(AlertEventModel event) async {
    await _screenController.markEventRead(event);
  }

  Future<void> _markAllEventsRead() async {
    await _screenController.markAllEventsRead();
  }

  Future<void> _clearCurrentEvents() async {
    if (!_screenController.canMutateEvents() ||
        !_screenController.hasCurrentEvents()) {
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xF9FFFFFF),
                  offset: Offset(-8, -8),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: Color(0x1D9CA9B5),
                  offset: Offset(10, 12),
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: Color(0x14677E92),
                  offset: Offset(0, 18),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE28A3B).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.delete_sweep_outlined,
                        color: Color(0xFFE28A3B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'ล้างเหตุการณ์ล่าสุด',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20303A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  _NotificationsScreenState._clearHistoryMessage,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF667587),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6E7A86),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE28A3B),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE28A3B,
                            ).withValues(alpha: 0.24),
                            offset: const Offset(0, 8),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(88, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('ล้าง'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldClear != true || !mounted) {
      return;
    }

    _screenController.removeCurrentEventsOptimistically();
    await _screenController.persistCurrentEventsCleared();
  }

  Future<void> _openEventDetail(AlertEventModel event) async {
    if (!event.isRead) {
      await _markEventRead(event);
    }
    if (!mounted) {
      return;
    }

    final fallbackDataKey = _ruleDataKeyForEvent(event);
    final eventForDetail =
        _eventDataKey(event) == null && fallbackDataKey != null
        ? event.copyWith(
            payload: <String, dynamic>{
              ...event.payload,
              'dataKey': fallbackDataKey,
            },
          )
        : event;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlertEventDetailScreen(event: eventForDetail),
      ),
    );
  }

  String? _ruleDataKeyForEvent(AlertEventModel event) {
    for (final rule in _screenController.rules) {
      if (rule.id == event.ruleId) {
        final dataKey = rule.dataKey.trim();
        return dataKey.isEmpty ? null : dataKey;
      }
    }
    return null;
  }

  Future<void> _deleteHistoryEvent(AlertEventModel event) async {
    if (!_screenController.canMutateEvents()) {
      return;
    }

    final shouldDelete = await _confirmHistoryAction(
      title: 'ลบรายการประวัติ',
      message:
          'ลบรายการนี้ออกจากประวัติทั้งหมดใช่หรือไม่? รายการนี้จะไม่ถูกเก็บในประวัติย้อนหลังแล้ว',
      confirmLabel: 'ลบ',
    );
    if (!shouldDelete || !mounted) {
      return;
    }

    final previousHistory = List<AlertEventModel>.from(
      _screenController.historyEvents,
    );
    _screenController.removeHistoryEventOptimistically(event);
    await _screenController.persistHistoryEventDeleted(event.id);

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    _showHistoryFeedback(
      message: 'ลบออกจากประวัติทั้งหมดแล้ว',
      icon: Icons.delete_outline_rounded,
      accentColor: const Color(0xFFCC5A4E),
      onUndo: () async {
        await _screenController.restoreHistory(previousHistory);
      },
    );
  }

  Future<void> _clearAllHistory() async {
    if (!_screenController.canMutateEvents() ||
        !_screenController.hasHistoryEvents()) {
      return;
    }

    final shouldClear = await _confirmHistoryAction(
      title: 'ล้างประวัติทั้งหมด',
      message:
          'ล้างประวัติทั้งหมดใช่หรือไม่? คุณยังสามารถกดย้อนกลับได้ทันทีจากแถบข้อความด้านล่าง',
      confirmLabel: 'ล้างทั้งหมด',
      icon: Icons.delete_sweep_outlined,
      accentColor: const Color(0xFFE28A3B),
    );
    if (!shouldClear || !mounted) {
      return;
    }

    final previousHistory = List<AlertEventModel>.from(
      _screenController.historyEvents,
    );
    _screenController.clearHistoryOptimistically();
    await _screenController.persistAllHistoryCleared();

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    _showHistoryFeedback(
      message: 'ล้างประวัติทั้งหมดแล้ว',
      icon: Icons.delete_sweep_outlined,
      accentColor: const Color(0xFFE28A3B),
      onUndo: () async {
        await _screenController.restoreHistory(previousHistory);
      },
    );
  }

  Future<void> _deleteRule(AlertRuleModel rule) async {
    await _deleteRules(<AlertRuleModel>[rule]);
  }

  Future<void> _deleteRules(List<AlertRuleModel> selectedRules) async {
    if (!_screenController.canMutateEvents()) {
      return;
    }
    if (selectedRules.isEmpty) {
      return;
    }

    final selectedRuleIds = selectedRules.map((rule) => rule.id).toSet();
    if (selectedRules.length > 1) {
      final shouldDelete = await _confirmHistoryAction(
        title: 'ลบกฎแจ้งเตือน',
        message:
            'ลบกฎการแจ้งเตือน ${selectedRules.length} รายการหรือไม่? กฎเหล่านี้จะไม่สร้างเหตุการณ์การแจ้งเตือนอีกต่อไป',
        confirmLabel: 'ลบ',
      );
      if (!shouldDelete || !mounted) {
        return;
      }

      final previousRules = List<AlertRuleModel>.from(_screenController.rules);
      final nextRules = _screenController.rules
          .where((entry) => !selectedRuleIds.contains(entry.id))
          .toList(growable: false);
      await _screenController.applyRulesSnapshot(nextRules);

      _showHistoryFeedback(
        message: 'ลบกฎแจ้งเตือน ${selectedRules.length} รายการแล้ว',
        icon: Icons.rule_folder_outlined,
        accentColor: const Color(0xFFCC5A4E),
        onUndo: () async {
          await _screenController.restoreRules(previousRules);
        },
      );
      return;
    }

    final rule = selectedRules.single;

    final shouldDelete = await _confirmHistoryAction(
      title: 'ลบกฎแจ้งเตือน',
      message:
          'ลบกฎแจ้งเตือน "${rule.title}" ใช่หรือไม่? หลังลบแล้วระบบจะไม่สร้างเหตุการณ์จากกฎนี้อีก',
      confirmLabel: 'ลบ',
    );
    if (!shouldDelete || !mounted) {
      return;
    }

    final previousRules = List<AlertRuleModel>.from(_screenController.rules);
    final nextRules = _screenController.rules
        .where((entry) => entry.id != rule.id)
        .toList(growable: false);
    await _screenController.applyRulesSnapshot(nextRules);

    _showHistoryFeedback(
      message: 'ลบกฎแจ้งเตือนแล้ว',
      icon: Icons.rule_folder_outlined,
      accentColor: const Color(0xFFCC5A4E),
      onUndo: () async {
        await _screenController.restoreRules(previousRules);
      },
    );
  }

  void _showHistoryFeedback({
    required String message,
    required IconData icon,
    required Color accentColor,
    required Future<void> Function() onUndo,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        duration: const Duration(seconds: 4),
        content: Container(
          key: const ValueKey<String>('notification_history_feedback_surface'),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F9).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
            boxShadow: const [
              BoxShadow(
                color: Color(0xF7FFFFFF),
                offset: Offset(-6, -6),
                blurRadius: 12,
              ),
              BoxShadow(
                color: Color(0x1697A4B0),
                offset: Offset(8, 10),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20303A),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  unawaited(onUndo());
                },
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Undo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
