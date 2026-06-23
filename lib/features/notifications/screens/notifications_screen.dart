import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard_builder/models/dashboard_item.dart';
import '../../dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import '../../../theme/app_responsive.dart';
import '../../../theme/app_theme.dart';
import '../models/alert_event_model.dart';
import '../models/alert_rule_model.dart';
import '../services/local_alert_notification_service.dart';
import '../services/notification_service.dart';
import 'alert_event_detail_screen.dart';
import 'alert_rule_editor_screen.dart';

part 'notification_parts/notification_content_widgets.dart';
part 'notification_parts/notification_shared_widgets.dart';
part 'notification_parts/notification_rules_widgets.dart';
part 'notification_parts/notification_switcher_widgets.dart';
part 'notification_parts/notification_events_widgets.dart';
part 'notification_parts/notification_empty_states.dart';
part 'notification_parts/notification_rule_card.dart';
part 'notification_parts/notification_event_card.dart';
part 'notification_parts/notification_state_controller.dart';
part 'notification_parts/notification_runtime_helpers.dart';

enum _AlertsPage { currentEvents, allHistory }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.runtimeController,
    this.bottomContentPadding = 0,
    this.isActive = true,
  });

  final DashboardRuntimeController runtimeController;
  final double bottomContentPadding;
  final bool isActive;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _notificationPromptSeenKey =
      'notification_permission_prompt_seen_v1';
  static const String _clearHistoryMessage =
      'ล้างข้อมูลเฉพาะหน้านี้เท่านั้น ประวัติทั้งหมดจะยังคงถูกบันทึกไว้ใน History';

  late final _NotificationsScreenController _screenController;
  bool get _showLegacyHeader => false;
  DashboardRuntimeController get _runtimeController => widget.runtimeController;

  @override
  void initState() {
    super.initState();
    _screenController = _NotificationsScreenController(
      runtimeController: _runtimeController,
    )..addListener(_handleControllerChanged);
    _runtimeController.addListener(_handleRuntimeChanged);
    unawaited(_runtimeController.initialize());
    unawaited(_screenController.loadData());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        unawaited(_maybeRequestNotificationPermission());
      }
    });
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      unawaited(_maybeRequestNotificationPermission());
    }
  }

  @override
  void dispose() {
    _runtimeController.removeListener(_handleRuntimeChanged);
    _screenController.removeListener(_handleControllerChanged);
    _screenController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _maybeRequestNotificationPermission() async {
    final preferences = await SharedPreferences.getInstance();
    final localNotificationService = LocalAlertNotificationService.instance;
    final needsPrompt = await _screenController
        .shouldRequestNotificationPermission(
          preferences: preferences,
          promptSeenKey: _notificationPromptSeenKey,
          localNotificationService: localNotificationService,
        );
    if (!needsPrompt || !mounted) {
      return;
    }

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: NotificationPermissionPromptCard(
            onDismiss: () => Navigator.of(context).pop(false),
            onAllow: () => Navigator.of(context).pop(true),
          ),
        );
      },
    );

    await preferences.setBool(_notificationPromptSeenKey, true);
    if (shouldRequest == true) {
      await localNotificationService.requestNotificationsPermission();
    }
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
                      child: const Text('ยกเลิก'),
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

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
                          'การแจ้งเตือน',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF20303A),
                          ),
                        ),
                        SizedBox(height: 4),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: '${_screenController.events.length} รายการล่าสุด',
                    color: const Color(0xFF4C8BC8),
                  ),
                  _StatChip(
                    label:
                        '${_screenController.historyEvents.length} ประวัติทั้งหมด',
                    color: const Color(0xFF7D6AD6),
                  ),
                  if (_screenController.unreadCount > 0)
                    _StatChip(
                      label: '${_screenController.unreadCount} ยังไม่อ่าน',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = AppResponsiveLayout.isTabletWidth(
          constraints.maxWidth,
        );
        final contentWidth = isTablet
            ? AppResponsiveLayout.dashboardShellWidth(constraints.maxWidth)
            : double.infinity;
        final content = SizedBox(
          key: const ValueKey<String>('notifications_content_shell'),
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGlassHeader(),
              const SizedBox(height: 16),
              if (_showLegacyHeader) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'การแจ้งเตือน',
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
                      onPressed: _screenController.isLoading
                          ? null
                          : () => _openRuleEditor(),
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
                      label: const Text('สร้างการแจ้งเตือน'),
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
                      label: '${_screenController.rules.length} กฎ',
                      color: const Color(0xFF4E9070),
                    ),
                    _StatChip(
                      label: '${_screenController.events.length} รายการล่าสุด',
                      color: const Color(0xFF4C8BC8),
                    ),
                    _StatChip(
                      label:
                          '${_screenController.historyEvents.length} ประวัติทั้งหมด',
                      color: const Color(0xFF7D6AD6),
                    ),
                    if (_screenController.unreadCount > 0)
                      _StatChip(
                        label: '${_screenController.unreadCount} ยังไม่อ่าน',
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
        );

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 0 : 20,
              isTablet ? 36 : 18,
              isTablet ? 0 : 20,
              24,
            ),
            child: isTablet
                ? Align(alignment: Alignment.topCenter, child: content)
                : content,
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_screenController.isLoading) {
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
                  'กำลังโหลดการแจ้งเตือน...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF667587)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ruleDataKeysById = <String, String>{
      for (final rule in _screenController.rules) rule.id: rule.dataKey,
    };

    return RefreshIndicator(
      color: const Color(0xFF4E9070),
      onRefresh: _screenController.loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: widget.bottomContentPadding),
        children: [
          _RulesSection(
            rules: _screenController.rules,
            availableWidgetIds: _screenController.availableWidgetIds,
            onCreateRule: () => _openRuleEditor(),
            onEditRule: (rule) => _openRuleEditor(rule: rule),
            onDeleteRule: _deleteRule,
            onDeleteRules: _deleteRules,
            isExpanded: _screenController.isRulesExpanded,
            onToggleExpanded: _screenController.toggleRulesExpanded,
          ),
          const SizedBox(height: 16),
          if (_screenController.selectedPage == _AlertsPage.currentEvents)
            _EventsSection(
              title: 'เหตุการณ์ล่าสุด',
              subtitle:
                  'ลบข้อมูลเฉพาะหน้านี้เท่านั้น ประวัติรวมทั้งหมดจะยังคงอยู่ครบถ้วน',
              events: _screenController.events,
              ruleDataKeysById: ruleDataKeysById,
              unreadCount: _screenController.unreadCount,
              isUpdating: _screenController.isUpdatingEvents,
              allowClear: true,
              onClear: _clearCurrentEvents,
              onMarkAllRead: _markAllEventsRead,
              onOpenEvent: _openEventDetail,
              selectedPage: _screenController.selectedPage,
              onPageChanged: _screenController.setSelectedPage,
            )
          else
            _EventsSection(
              title: 'ประวัติทั้งหมด',
              subtitle:
                  'ระบบจะบันทึกทุกเหตุการณ์ไว้ที่นี่ และคุณสามารถล้างหรือลบรายการได้เมื่อต้องการ',
              events: _screenController.historyEvents,
              ruleDataKeysById: ruleDataKeysById,
              unreadCount: 0,
              isUpdating: _screenController.isUpdatingEvents,
              allowClear: true,
              onClear: _clearAllHistory,
              onMarkAllRead: null,
              onOpenEvent: _openEventDetail,
              onDeleteEvent: _deleteHistoryEvent,
              selectedPage: _screenController.selectedPage,
              onPageChanged: _screenController.setSelectedPage,
            ),
        ],
      ),
    );
  }
}

class NotificationPermissionPromptCard extends StatelessWidget {
  const NotificationPermissionPromptCard({
    super.key,
    required this.onDismiss,
    required this.onAllow,
  });

  final VoidCallback onDismiss;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppResponsiveLayout.tabletContentMaxWidth,
      ),
      child: Container(
        key: const ValueKey<String>('notification_permission_prompt_surface'),
        width: double.infinity,
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
                    color: const Color(0xFF4E9070).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF4E9070),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Enable notifications?',
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
              'ให้ PB IoT ส่งการแจ้งเตือนบนมือถือเมื่อมีเหตุการณ์สำคัญ',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF667587),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
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
                  child: const Text('ไม่ใช่ตอนนี้'),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E9070),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4E9070).withValues(alpha: 0.24),
                        offset: const Offset(0, 8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: onAllow,
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
                    child: const Text('อนุญาต'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String? _eventDataKey(AlertEventModel event, {String? fallback}) {
  final payloadDataKey = event.payload['dataKey']?.toString().trim() ?? '';
  if (payloadDataKey.isNotEmpty) {
    return payloadDataKey;
  }
  final fallbackDataKey = fallback?.trim() ?? '';
  return fallbackDataKey.isEmpty ? null : fallbackDataKey;
}
