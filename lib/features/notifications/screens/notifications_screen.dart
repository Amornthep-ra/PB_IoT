import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard_builder/models/dashboard_item.dart';
import '../../dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import '../../../theme/app_theme.dart';
import '../models/alert_event_model.dart';
import '../models/alert_rule_model.dart';
import '../services/notification_service.dart';
import 'alert_event_detail_screen.dart';
import 'alert_rule_editor_screen.dart';

enum _AlertsPage { currentEvents, allHistory }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.runtimeController});

  final DashboardRuntimeController runtimeController;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final DashboardBuilderLayoutStorageService _layoutStorage =
      DashboardBuilderLayoutStorageService();

  static const String _clearHistoryMessage =
      'ล้างข้อมูลเฉพาะหน้านี้เท่านั้น ประวัติทั้งหมดจะยังคงถูกบันทึกไว้ใน History';

  bool _isLoading = true;
  bool _isUpdatingEvents = false;
  List<AlertEventModel> _events = const <AlertEventModel>[];
  List<AlertEventModel> _historyEvents = const <AlertEventModel>[];
  List<AlertRuleModel> _rules = const <AlertRuleModel>[];
  Set<String> _availableWidgetIds = const <String>{};
  _AlertsPage _selectedPage = _AlertsPage.currentEvents;
  bool _isRulesExpanded = true;
  bool _didChooseRulesExpansion = false;
  bool get _showLegacyHeader => false;
  DashboardRuntimeController get _runtimeController => widget.runtimeController;

  @override
  void initState() {
    super.initState();
    _runtimeController.addListener(_handleRuntimeChanged);
    unawaited(_runtimeController.initialize());
    _loadData();
  }

  @override
  void dispose() {
    _runtimeController.removeListener(_handleRuntimeChanged);
    super.dispose();
  }

  void _handleRuntimeChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadData(showLoading: false));
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final events = List<AlertEventModel>.from(
      await _notificationService.loadEvents(),
    )..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final historyEvents = List<AlertEventModel>.from(
      await _notificationService.loadHistoryEvents(),
    )..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final rules =
        List<AlertRuleModel>.from(await _notificationService.loadRules())
          ..sort((left, right) {
            final leftAt = left.updatedAt ?? left.createdAt;
            final rightAt = right.updatedAt ?? right.createdAt;
            return rightAt.compareTo(leftAt);
          });

    final items = await _layoutStorage.loadItems();
    final availableWidgetIds = (items ?? const <DashboardItem>[])
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    if (!mounted) {
      return;
    }

    setState(() {
      _events = List<AlertEventModel>.unmodifiable(events);
      _historyEvents = List<AlertEventModel>.unmodifiable(historyEvents);
      _rules = List<AlertRuleModel>.unmodifiable(rules);
      _availableWidgetIds = Set<String>.unmodifiable(availableWidgetIds);
      if (!_didChooseRulesExpansion) {
        _isRulesExpanded = rules.length <= 3;
      }
      _isLoading = false;
    });
  }

  Future<void> _openRuleEditor({AlertRuleModel? rule}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AlertRuleEditorScreen(initialRule: rule),
      ),
    );
    if (result == true && mounted) {
      await _runtimeController.reloadAlertRules();
      await _loadData();
    }
  }

  Future<void> _markEventRead(AlertEventModel event) async {
    if (_isUpdatingEvents || event.isRead) {
      return;
    }

    setState(() {
      _isUpdatingEvents = true;
      _events = _events
          .map(
            (entry) => entry.id == event.id
                ? entry.copyWith(isRead: true)
                : entry,
          )
          .toList(growable: false);
      _historyEvents = _historyEvents
          .map(
            (entry) => entry.id == event.id
                ? entry.copyWith(isRead: true)
                : entry,
          )
          .toList(growable: false);
    });

    try {
      await _notificationService.markEventRead(event.id, isRead: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEvents = false;
        });
      }
    }
  }

  Future<void> _markAllEventsRead() async {
    if (_isUpdatingEvents || _unreadCount == 0) {
      return;
    }

    setState(() {
      _isUpdatingEvents = true;
      _events = _events
          .map((event) => event.isRead ? event : event.copyWith(isRead: true))
          .toList(growable: false);
      _historyEvents = _historyEvents
          .map((event) => event.isRead ? event : event.copyWith(isRead: true))
          .toList(growable: false);
    });

    try {
      await _notificationService.markAllEventsRead();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEvents = false;
        });
      }
    }
  }

  Future<void> _clearCurrentEvents() async {
    if (_isUpdatingEvents || _events.isEmpty) {
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
                        'Clear Event History',
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
                  _clearHistoryMessage,
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
                      child: const Text('Cancel'),
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
                        child: const Text('Clear'),
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

    setState(() {
      _isUpdatingEvents = true;
      _events = const <AlertEventModel>[];
    });

    try {
      await _notificationService.clearEvents();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEvents = false;
        });
      }
    }
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
    for (final rule in _rules) {
      if (rule.id == event.ruleId) {
        final dataKey = rule.dataKey.trim();
        return dataKey.isEmpty ? null : dataKey;
      }
    }
    return null;
  }

  Future<bool> _confirmHistoryAction({
    required String title,
    required String message,
    required String confirmLabel,
    IconData icon = Icons.delete_outline_rounded,
    Color accentColor = const Color(0xFFCC5A4E),
  }) async {
    final result = await showDialog<bool>(
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
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20303A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: const TextStyle(
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
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.24),
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
                        child: Text(confirmLabel),
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
    return result == true;
  }

  Future<void> _deleteHistoryEvent(AlertEventModel event) async {
    if (_isUpdatingEvents) {
      return;
    }

    final shouldDelete = await _confirmHistoryAction(
      title: 'Delete History Item',
      message:
          'ลบรายการนี้ออกจาก All History ใช่หรือไม่? รายการนี้จะไม่ถูกเก็บในประวัติย้อนหลังแล้ว',
      confirmLabel: 'Delete',
    );
    if (!shouldDelete || !mounted) {
      return;
    }

    final previousHistory = List<AlertEventModel>.from(_historyEvents);
    setState(() {
      _isUpdatingEvents = true;
      _historyEvents = _historyEvents
          .where((entry) => entry.id != event.id)
          .toList(growable: false);
    });

    try {
      await _notificationService.deleteHistoryEvent(event.id);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEvents = false;
        });
      }
    }

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    _showHistoryFeedback(
      message: 'ลบออกจาก All History แล้ว',
      icon: Icons.delete_outline_rounded,
      accentColor: const Color(0xFFCC5A4E),
      onUndo: () async {
        await _notificationService.saveHistoryEvents(previousHistory);
        if (!mounted) {
          return;
        }
        setState(() {
          _historyEvents = List<AlertEventModel>.unmodifiable(previousHistory);
        });
      },
    );
  }

  Future<void> _clearAllHistory() async {
    if (_isUpdatingEvents || _historyEvents.isEmpty) {
      return;
    }

    final shouldClear = await _confirmHistoryAction(
      title: 'Clear All History',
      message:
          'ล้างประวัติทั้งหมดในหน้า All History ใช่หรือไม่? คุณยังสามารถกดย้อนกลับได้ทันทีจากแถบข้อความด้านล่าง',
      confirmLabel: 'Clear all',
      icon: Icons.delete_sweep_outlined,
      accentColor: const Color(0xFFE28A3B),
    );
    if (!shouldClear || !mounted) {
      return;
    }

    final previousHistory = List<AlertEventModel>.from(_historyEvents);
    setState(() {
      _isUpdatingEvents = true;
      _historyEvents = const <AlertEventModel>[];
    });

    try {
      await _notificationService.clearHistoryEvents();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEvents = false;
        });
      }
    }

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    _showHistoryFeedback(
      message: 'ล้าง All History แล้ว',
      icon: Icons.delete_sweep_outlined,
      accentColor: const Color(0xFFE28A3B),
      onUndo: () async {
        await _notificationService.saveHistoryEvents(previousHistory);
        if (!mounted) {
          return;
        }
        setState(() {
          _historyEvents = List<AlertEventModel>.unmodifiable(previousHistory);
        });
      },
    );
  }

  Future<void> _deleteRule(AlertRuleModel rule) async {
    await _deleteRules(<AlertRuleModel>[rule]);
  }

  Future<void> _deleteRules(List<AlertRuleModel> selectedRules) async {
    if (_isUpdatingEvents) {
      return;
    }
    if (selectedRules.isEmpty) {
      return;
    }

    final selectedRuleIds = selectedRules.map((rule) => rule.id).toSet();
    if (selectedRules.length > 1) {
      final shouldDelete = await _confirmHistoryAction(
        title: 'Delete Alert Rules',
        message:
            'ลบกฎการแจ้งเตือน ${selectedRules.length} รายการหรือไม่? กฎเหล่านี้จะไม่สร้างเหตุการณ์การแจ้งเตือนอีกต่อไป',
        confirmLabel: 'Delete',
      );
      if (!shouldDelete || !mounted) {
        return;
      }

      final previousRules = List<AlertRuleModel>.from(_rules);
      final nextRules = _rules
          .where((entry) => !selectedRuleIds.contains(entry.id))
          .toList(growable: false);

      setState(() {
        _isUpdatingEvents = true;
        _rules = List<AlertRuleModel>.unmodifiable(nextRules);
      });

      try {
        await _notificationService.saveRules(nextRules);
        await _runtimeController.reloadAlertRules();
      } finally {
        if (mounted) {
          setState(() {
            _isUpdatingEvents = false;
          });
        }
      }

      _showHistoryFeedback(
        message: 'Deleted ${selectedRules.length} Alert Rules',
        icon: Icons.rule_folder_outlined,
        accentColor: const Color(0xFFCC5A4E),
        onUndo: () async {
          await _notificationService.saveRules(previousRules);
          await _runtimeController.reloadAlertRules();
          if (!mounted) {
            return;
          }
          setState(() {
            _rules = List<AlertRuleModel>.unmodifiable(previousRules);
          });
        },
      );
      return;
    }

    final rule = selectedRules.single;

    final shouldDelete = await _confirmHistoryAction(
      title: 'Delete Alert Rule',
      message:
          'ลบกฎแจ้งเตือน "${rule.title}" ใช่หรือไม่? หลังลบแล้วระบบจะไม่สร้างเหตุการณ์จากกฎนี้อีก',
      confirmLabel: 'Delete',
    );
    if (!shouldDelete || !mounted) {
      return;
    }

    final previousRules = List<AlertRuleModel>.from(_rules);
    final nextRules = _rules
        .where((entry) => entry.id != rule.id)
        .toList(growable: false);

    setState(() {
      _isUpdatingEvents = true;
      _rules = List<AlertRuleModel>.unmodifiable(nextRules);
    });

    try {
      await _notificationService.saveRules(nextRules);
      await _runtimeController.reloadAlertRules();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEvents = false;
        });
      }
    }

    _showHistoryFeedback(
      message: 'ลบ Alert Rule แล้ว',
      icon: Icons.rule_folder_outlined,
      accentColor: const Color(0xFFCC5A4E),
      onUndo: () async {
        await _notificationService.saveRules(previousRules);
        await _runtimeController.reloadAlertRules();
        if (!mounted) {
          return;
        }
        setState(() {
          _rules = List<AlertRuleModel>.unmodifiable(previousRules);
        });
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
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        duration: const Duration(seconds: 4),
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3F8),
            borderRadius: BorderRadius.circular(24),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
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

  int get _unreadCount => _events.where((event) => !event.isRead).length;

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 28,
            borderAlpha: 0.6,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.82),
              const Color(0xFFF7FBFF).withValues(alpha: 0.48),
            ],
            shadows: AppGlassTheme.shadowMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alerts',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF20303A),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'สรุปแจ้งเตือนทั้งหมดและประวัติย้อนหลัง',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF667587),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: '${_rules.length} rules',
                    color: const Color(0xFF4E9070),
                  ),
                  _StatChip(
                    label: '${_events.length} current',
                    color: const Color(0xFF4C8BC8),
                  ),
                  _StatChip(
                    label: '${_historyEvents.length} all history',
                    color: const Color(0xFF7D6AD6),
                  ),
                  if (_unreadCount > 0)
                    _StatChip(
                      label: '$_unreadCount unread',
                      color: const Color(0xFFE28A3B),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlassHeader(),
            const SizedBox(height: 18),
            if (_showLegacyHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alerts',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF20303A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : () => _openRuleEditor(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4E9070),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_alert_rounded, size: 18),
                    label: const Text('Create Alert'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'ตั้งค่าการแจ้งเตือนอย่างง่าย และดูรายการแจ้งเตือนย้อนหลังได้ในขณะใช้งานแอป',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF667587),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: '${_rules.length} rules',
                    color: const Color(0xFF4E9070),
                  ),
                  _StatChip(
                    label: '${_events.length} current',
                    color: const Color(0xFF4C8BC8),
                  ),
                  _StatChip(
                    label: '${_historyEvents.length} all history',
                    color: const Color(0xFF7D6AD6),
                  ),
                  if (_unreadCount > 0)
                    _StatChip(
                      label: '$_unreadCount unread',
                      color: const Color(0xFFE28A3B),
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: const _GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Color(0xFF4E9070),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Loading alerts...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF667587)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ruleDataKeysById = <String, String>{
      for (final rule in _rules) rule.id: rule.dataKey,
    };

    return RefreshIndicator(
      color: const Color(0xFF4E9070),
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _RulesSection(
            rules: _rules,
            availableWidgetIds: _availableWidgetIds,
            onCreateRule: () => _openRuleEditor(),
            onEditRule: (rule) => _openRuleEditor(rule: rule),
            onDeleteRule: _deleteRule,
            onDeleteRules: _deleteRules,
            isExpanded: _isRulesExpanded,
            onToggleExpanded: () {
              setState(() {
                _didChooseRulesExpansion = true;
                _isRulesExpanded = !_isRulesExpanded;
              });
            },
          ),
          const SizedBox(height: 18),
          _AlertsPageSwitcher(
            selectedPage: _selectedPage,
            onChanged: (page) {
              setState(() {
                _selectedPage = page;
              });
            },
          ),
          const SizedBox(height: 14),
          if (_selectedPage == _AlertsPage.currentEvents)
            _EventsSection(
              title: 'Event History',
              subtitle:
                  'ลบข้อมูลเฉพาะหน้านี้เท่านั้น ประวัติรวมทั้งหมดจะยังคงอยู่ครบถ้วน',
              events: _events,
              ruleDataKeysById: ruleDataKeysById,
              unreadCount: _unreadCount,
              isUpdating: _isUpdatingEvents,
              allowClear: true,
              onClear: _clearCurrentEvents,
              onMarkAllRead: _markAllEventsRead,
              onOpenEvent: _openEventDetail,
            )
          else
            _EventsSection(
              title: 'All History',
              subtitle:
                  'เก็บบันทึกถาวร หน้านี้บันทึกทุกเหตุการณ์และไม่สามารถลบได้',
              events: _historyEvents,
              ruleDataKeysById: ruleDataKeysById,
              unreadCount: 0,
              isUpdating: _isUpdatingEvents,
              allowClear: true,
              onClear: _clearAllHistory,
              onMarkAllRead: null,
              onOpenEvent: _openEventDetail,
              onDeleteEvent: _deleteHistoryEvent,
            ),
        ],
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({
    required this.rules,
    required this.availableWidgetIds,
    required this.onCreateRule,
    required this.onEditRule,
    required this.onDeleteRule,
    required this.onDeleteRules,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final List<AlertRuleModel> rules;
  final Set<String> availableWidgetIds;
  final VoidCallback onCreateRule;
  final ValueChanged<AlertRuleModel> onEditRule;
  final ValueChanged<AlertRuleModel> onDeleteRule;
  final ValueChanged<List<AlertRuleModel>> onDeleteRules;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Alert Rules',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20303A),
                        ),
                      ),
                    ),
                    if (rules.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _CompactInfoChip(
                        label: '${rules.length} rules',
                        color: const Color(0xFF4C8BC8),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 16,
                  borderAlpha: 0.34,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.3),
                    const Color(0xFF4C8BC8).withValues(alpha: 0.1),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: IconButton(
                  onPressed: rules.isEmpty ? null : onToggleExpanded,
                  tooltip: isExpanded
                      ? 'Collapse alert rules'
                      : 'Expand alert rules',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  color: const Color(0xFF4C8BC8),
                  disabledColor: const Color(0xFFB7C0C8),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: AppGlassTheme.accentDecoration(
                  radius: 16,
                  colors: const <Color>[Color(0xFFB6D2F5), Color(0xFF82AEE8)],
                  borderColor: const Color(0xFF9EC3F0),
                  glowColor: const Color(0xFF82AEE8),
                ),
                child: IconButton(
                  onPressed: onCreateRule,
                  tooltip: 'Create alert rule',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add_alert_rounded),
                  color: Colors.white,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 16,
                  borderAlpha: 0.34,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.3),
                    const Color(0xFFCC5A4E).withValues(alpha: 0.12),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: IconButton(
                  onPressed: rules.isEmpty
                      ? null
                      : () => _openDeleteRulePicker(context),
                  tooltip: 'Delete alert rule',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFCC5A4E),
                  disabledColor: const Color(0xFFB7C0C8),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
              ),
            ],
          ),
          if (rules.isEmpty) ...[
            const SizedBox(height: 10),
            _EmptyRulesCard(onCreateRule: onCreateRule)
          ] else if (isExpanded) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                for (var index = 0; index < rules.length; index++) ...[
                  _AlertRuleCard(
                    rule: rules[index],
                    sourceMissing: !availableWidgetIds.contains(
                      rules[index].widgetId,
                    ),
                    onTap: () => onEditRule(rules[index]),
                  ),
                  if (index != rules.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDeleteRulePicker(BuildContext context) async {
    if (rules.length == 1) {
      onDeleteRule(rules.single);
      return;
    }

    final selectedRules = await showModalBottomSheet<List<AlertRuleModel>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 26,
                  borderAlpha: 0.58,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.86),
                    const Color(0xFFF5FBFF).withValues(alpha: 0.56),
                  ],
                  shadows: AppGlassTheme.shadowMd,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: AppGlassTheme.surfaceDecoration(
                            radius: 12,
                            borderAlpha: 0.32,
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.34),
                              const Color(0xFFCC5A4E).withValues(alpha: 0.12),
                            ],
                            shadows: const <BoxShadow>[],
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFCC5A4E),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Delete Alert Rule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF20303A),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(
                            sheetContext,
                          ).pop(List<AlertRuleModel>.of(rules)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFCC5A4E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'เลือกทั้งหมด',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final rule = rules[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(
                              sheetContext,
                            ).pop(<AlertRuleModel>[rule]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: AppGlassTheme.surfaceDecoration(
                                radius: 16,
                                borderAlpha: 0.3,
                                colors: <Color>[
                                  Colors.white.withValues(alpha: 0.44),
                                  const Color(
                                    0xFFF7FAFF,
                                  ).withValues(alpha: 0.2),
                                ],
                                shadows: const <BoxShadow>[],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _alertTitleWithDataKey(
                                            title: rule.title,
                                            dataKey: rule.dataKey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF20303A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          rule.widgetTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF667587),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFCC5A4E),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selectedRules != null && selectedRules.isNotEmpty) {
      onDeleteRules(selectedRules);
    }
  }
}

class _AlertsPageSwitcher extends StatelessWidget {
  const _AlertsPageSwitcher({
    required this.selectedPage,
    required this.onChanged,
  });

  final _AlertsPage selectedPage;
  final ValueChanged<_AlertsPage> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 16,
            borderAlpha: 0.46,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.72),
              const Color(0xFFF4F8FF).withValues(alpha: 0.34),
            ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: Row(
            children: [
              _SwitcherButton(
                label: 'Event History',
                isSelected: selectedPage == _AlertsPage.currentEvents,
                onTap: () => onChanged(_AlertsPage.currentEvents),
              ),
              const SizedBox(width: 4),
              _SwitcherButton(
                label: 'All History',
                isSelected: selectedPage == _AlertsPage.allHistory,
                onTap: () => onChanged(_AlertsPage.allHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitcherButton extends StatelessWidget {
  const _SwitcherButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: isSelected
              ? AppGlassTheme.accentDecoration(
                  radius: 12,
                  colors: const <Color>[Color(0xFFB6D2F5), Color(0xFF82AEE8)],
                  borderColor: const Color(0xFF9EC3F0),
                  glowColor: const Color(0xFF82AEE8),
                )
              : AppGlassTheme.surfaceDecoration(
                  radius: 12,
                  borderAlpha: 0.22,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.28),
                    const Color(0xFFF7FAFF).withValues(alpha: 0.16),
                  ],
                  shadows: const <BoxShadow>[],
                ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF6E7A86),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({
    required this.title,
    required this.subtitle,
    required this.events,
    required this.ruleDataKeysById,
    required this.unreadCount,
    required this.isUpdating,
    required this.allowClear,
    required this.onClear,
    required this.onMarkAllRead,
    required this.onOpenEvent,
    this.onDeleteEvent,
  });

  final String title;
  final String subtitle;
  final List<AlertEventModel> events;
  final Map<String, String> ruleDataKeysById;
  final int unreadCount;
  final bool isUpdating;
  final bool allowClear;
  final VoidCallback? onClear;
  final VoidCallback? onMarkAllRead;
  final ValueChanged<AlertEventModel> onOpenEvent;
  final ValueChanged<AlertEventModel>? onDeleteEvent;

  @override
  Widget build(BuildContext context) {
    final isHistorySection = onDeleteEvent != null;
    final shouldShowSubtitle =
        title != 'Event History' && subtitle.trim().isNotEmpty;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20303A),
                  ),
                ),
              ),
              if (allowClear && (events.isNotEmpty || unreadCount > 0)) ...[
                const SizedBox(width: 8),
                if (events.isNotEmpty)
                  TextButton(
                    onPressed: isUpdating ? null : onClear,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(onDeleteEvent == null ? 'Clear' : 'Clear all'),
                  ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: isUpdating ? null : onMarkAllRead,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Mark all read'),
                  ),
              ],
            ],
          ),
          if (shouldShowSubtitle) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF667587),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (events.isEmpty)
            _EmptyEventsCard(
              title: isHistorySection
                  ? 'No saved history yet'
                  : 'No current events',
              message: isHistorySection
                  ? 'ระบบจะบันทึกทุกเหตุการณ์ไว้ในประวัติอัตโนมัติ'
                  : allowClear
                  ? 'Event ใหม่จะแสดงที่นี่ จนกว่าคุณจะกด Clear หน้านี้'
                  : 'บันทึกทุกเหตุการณ์ลงคลังข้อมูลอัตโนมัติ',
            )
          else
            Column(
              children: [
                for (var index = 0; index < events.length; index++) ...[
                  _AlertEventCard(
                    event: events[index],
                    ruleDataKey: ruleDataKeysById[events[index].ruleId],
                    onTap: () => onOpenEvent(events[index]),
                    onDelete: onDeleteEvent == null
                        ? null
                        : () => onDeleteEvent!(events[index]),
                  ),
                  if (index != events.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyRulesCard extends StatelessWidget {
  const _EmptyRulesCard({required this.onCreateRule});

  final VoidCallback onCreateRule;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E9070).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.rule_folder_outlined,
                  color: Color(0xFF4E9070),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'No alert rules yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20303A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ลองสร้างกฎการแจ้งเตือนจากวิดเจ็ตดูซิ เช่น ตั้งให้เตือนเมื่อดินแห้ง หรือเมื่อปั๊มน้ำเริ่มทำงาน',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF667587),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: AppGlassTheme.accentDecoration(
              radius: 16,
              colors: const <Color>[Color(0xFFB6D2F5), Color(0xFF82AEE8)],
              borderColor: const Color(0xFF9EC3F0),
              glowColor: const Color(0xFF82AEE8),
            ),
            child: TextButton.icon(
              onPressed: onCreateRule,
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Create alert rule'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF4E9070),
            size: 30,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20303A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF667587),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRuleCard extends StatelessWidget {
  const _AlertRuleCard({
    required this.rule,
    required this.sourceMissing,
    required this.onTap,
  });

  final AlertRuleModel rule;
  final bool sourceMissing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _severityPalette(rule.severity);
    final summary = _ruleSummary(rule);
    final alertMessage = rule.message.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: AppGlassTheme.surfaceDecoration(
                        radius: 16,
                        borderAlpha: 0.44,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.62),
                          palette.color.withValues(alpha: 0.14),
                        ],
                        shadows: AppGlassTheme.shadowSm,
                      ),
                      alignment: Alignment.center,
                      child: Icon(palette.icon, color: palette.color, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _alertTitleWithDataKey(
                          title: rule.title,
                          dataKey: rule.dataKey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20303A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (alertMessage.isNotEmpty) ...[
                        Text(
                          alertMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4E9070),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.45,
                          color: Color(0xFF667587),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: AppGlassTheme.accentDecoration(
                    radius: 999,
                    colors: <Color>[
                      palette.color.withValues(alpha: 0.82),
                      palette.color.withValues(alpha: 0.62),
                    ],
                    borderColor: palette.color.withValues(alpha: 0.72),
                    glowColor: palette.color,
                  ),
                  child: Text(
                    _severityLabel(rule.severity),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                _InfoChip(
                  label: rule.widgetTitle,
                  color: const Color(0xFF4E9070),
                ),
                _InfoChip(
                  label: rule.enabled ? 'Enabled' : 'Disabled',
                  color: rule.enabled
                      ? const Color(0xFF4E9070)
                      : const Color(0xFF97A3AF),
                ),
                if (sourceMissing)
                  const _InfoChip(
                    label: 'Source missing',
                    color: Color(0xFFCC5A4E),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertEventCard extends StatelessWidget {
  const _AlertEventCard({
    required this.event,
    required this.ruleDataKey,
    required this.onTap,
    this.onDelete,
  });

  final AlertEventModel event;
  final String? ruleDataKey;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = _severityPalette(event.severity);
    final displayTitle = _alertTitleWithDataKey(
      title: event.ruleTitle,
      dataKey: _eventDataKey(event, fallback: ruleDataKey),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _GlassCard(
        borderAlpha: event.isRead ? 0.5 : 0.66,
        colors: event.isRead
            ? null
            : <Color>[
                const Color(0xFFFFF7F5).withValues(alpha: 0.9),
                const Color(0xFFFFDAD4).withValues(alpha: 0.46),
              ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _formatTimestamp(event.createdAt),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A8794),
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: AppGlassTheme.surfaceDecoration(
                          radius: 12,
                          borderAlpha: 0.26,
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.28),
                            const Color(0xFFF7FAFF).withValues(alpha: 0.16),
                          ],
                          shadows: const <BoxShadow>[],
                        ),
                        child: IconButton(
                          onPressed: onDelete,
                          tooltip: 'Delete',
                          constraints: const BoxConstraints.tightFor(
                            width: 30,
                            height: 30,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          splashRadius: 15,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFCC5A4E),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: AppGlassTheme.surfaceDecoration(
                        radius: 16,
                        borderAlpha: 0.44,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.62),
                          palette.color.withValues(alpha: 0.14),
                        ],
                        shadows: AppGlassTheme.shadowSm,
                      ),
                      alignment: Alignment.center,
                      child: Icon(palette.icon, color: palette.color, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: event.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: const Color(0xFF20303A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.35,
                          color: Color(0xFF667587),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _EventSeverityChip(
                  label: _severityLabel(event.severity),
                  color: palette.color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: _CompactInfoChip(
                    label: event.widgetTitle,
                    color: const Color(0xFF4E9070),
                  ),
                ),
                if (!event.isRead) ...[
                  const SizedBox(width: 6),
                  const _CompactInfoChip(
                    label: 'New',
                    color: Color(0xFFE28A3B),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: event.isRead
                        ? AppGlassTheme.surfaceDecoration(
                            radius: 999,
                            borderAlpha: 0.24,
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.3),
                              const Color(0xFFF7FAFF).withValues(alpha: 0.18),
                            ],
                            shadows: const <BoxShadow>[],
                          )
                        : AppGlassTheme.accentDecoration(
                            radius: 999,
                            colors: const <Color>[
                              Color(0xFFE7867A),
                              Color(0xFFCC5A4E),
                            ],
                            borderColor: const Color(0xFFD46C60),
                            glowColor: const Color(0xFFCC5A4E),
                          ),
                    child: Text(
                      event.isRead ? 'อ่านแล้ว' : 'ยังไม่อ่าน',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: event.isRead
                            ? const Color(0xFF5F6E7D)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: AppGlassTheme.surfaceDecoration(
                      radius: 999,
                      borderAlpha: 0.2,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.28),
                        const Color(0xFFF7FAFF).withValues(alpha: 0.12),
                      ],
                      shadows: const <BoxShadow>[],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF7A8794),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.borderAlpha = 0.5,
    this.colors,
  });

  final Widget child;
  final double borderAlpha;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: borderAlpha,
            colors:
                colors ??
                <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.76),
                  const Color(0xFFF5FBFF).withValues(alpha: 0.38),
                ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 999,
            borderAlpha: 0.28,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.42),
              color.withValues(alpha: 0.1),
            ],
            shadows: const <BoxShadow>[],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventSeverityChip extends StatelessWidget {
  const _EventSeverityChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppGlassTheme.accentDecoration(
        radius: 999,
        colors: <Color>[
          color.withValues(alpha: 0.82),
          color.withValues(alpha: 0.62),
        ],
        borderColor: color.withValues(alpha: 0.72),
        glowColor: color,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CompactInfoChip extends StatelessWidget {
  const _CompactInfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 999,
            borderAlpha: 0.28,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.42),
              color.withValues(alpha: 0.1),
            ],
            shadows: const <BoxShadow>[],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 999,
            borderAlpha: 0.32,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.5),
              color.withValues(alpha: 0.12),
            ],
            shadows: const <BoxShadow>[],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityPalette {
  const _SeverityPalette({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

_SeverityPalette _severityPalette(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return const _SeverityPalette(
        icon: Icons.info_outline_rounded,
        color: Color(0xFF4C8BC8),
      );
    case AlertRuleSeverity.warning:
      return const _SeverityPalette(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFE28A3B),
      );
    case AlertRuleSeverity.critical:
      return const _SeverityPalette(
        icon: Icons.error_outline_rounded,
        color: Color(0xFFCC5A4E),
      );
  }
}

String _severityLabel(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return 'Info';
    case AlertRuleSeverity.warning:
      return 'Warning';
    case AlertRuleSeverity.critical:
      return 'Critical';
  }
}

String _conditionLabel(AlertRuleCondition condition) {
  switch (condition) {
    case AlertRuleCondition.lessThan:
      return 'less than';
    case AlertRuleCondition.lessThanOrEqual:
      return 'less than or equal to';
    case AlertRuleCondition.greaterThan:
      return 'greater than';
    case AlertRuleCondition.greaterThanOrEqual:
      return 'greater than or equal to';
    case AlertRuleCondition.equalTo:
      return 'equal to';
    case AlertRuleCondition.notEqualTo:
      return 'not equal to';
    case AlertRuleCondition.isOn:
      return 'is ON';
    case AlertRuleCondition.isOff:
      return 'is OFF';
    case AlertRuleCondition.becameOn:
      return 'changes to ON';
    case AlertRuleCondition.becameOff:
      return 'changes to OFF';
  }
}

String _alertTitleWithDataKey({
  required String title,
  required String? dataKey,
}) {
  final normalizedTitle = title.trim();
  final normalizedDataKey = dataKey?.trim() ?? '';
  if (normalizedDataKey.isEmpty) {
    return normalizedTitle;
  }
  if (normalizedTitle.toLowerCase().contains(
    '(${normalizedDataKey.toLowerCase()})',
  )) {
    return normalizedTitle;
  }
  return '$normalizedTitle ($normalizedDataKey)';
}

String? _eventDataKey(AlertEventModel event, {String? fallback}) {
  final payloadDataKey = event.payload['dataKey']?.toString().trim() ?? '';
  if (payloadDataKey.isNotEmpty) {
    return payloadDataKey;
  }
  final fallbackDataKey = fallback?.trim() ?? '';
  return fallbackDataKey.isEmpty ? null : fallbackDataKey;
}

String _ruleSummary(AlertRuleModel rule) {
  final buffer = StringBuffer(rule.widgetTitle);
  buffer.write(' ');
  buffer.write(_conditionLabel(rule.condition));
  if (rule.thresholdValue != null) {
    final threshold = rule.thresholdValue!;
    buffer.write(' ');
    buffer.write(
      threshold.truncateToDouble() == threshold
          ? threshold.toInt().toString()
          : threshold.toString(),
    );
  }
  return buffer.toString();
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(local.year, local.month, local.day);
  final difference = today.difference(eventDay).inDays;

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  if (difference <= 0) {
    return 'Today $hour:$minute';
  }
  if (difference == 1) {
    return 'Yesterday $hour:$minute';
  }

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/$hour:$minute';
}
