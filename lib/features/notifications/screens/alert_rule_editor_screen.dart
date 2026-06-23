import 'dart:ui';

import 'package:flutter/material.dart';

import '../../dashboard_builder/models/dashboard_item.dart';
import '../../dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import '../../../theme/app_theme.dart';
import '../models/alert_rule_model.dart';
import '../services/local_alert_notification_service.dart';
import '../services/notification_service.dart';

part 'alert_rule_editor_parts/editor_form_sections.dart';
part 'alert_rule_editor_parts/editor_support_widgets.dart';

class AlertRuleEditorScreen extends StatefulWidget {
  const AlertRuleEditorScreen({super.key, this.initialRule});

  final AlertRuleModel? initialRule;

  bool get isEditing => initialRule != null;

  @override
  State<AlertRuleEditorScreen> createState() => _AlertRuleEditorScreenState();
}

class _AlertRuleEditorScreenState extends State<AlertRuleEditorScreen> {
  final NotificationService _notificationService = NotificationService();
  final DashboardBuilderLayoutStorageService _layoutStorage =
      DashboardBuilderLayoutStorageService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _titleFieldKey = GlobalKey();
  final GlobalKey _conditionFieldKey = GlobalKey();
  final GlobalKey _thresholdFieldKey = GlobalKey();
  final GlobalKey _messageFieldKey = GlobalKey();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _thresholdFocusNode = FocusNode();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTestingAlert = false;
  List<DashboardItem> _availableItems = const <DashboardItem>[];
  String? _selectedWidgetId;
  AlertRuleCondition? _selectedCondition;
  AlertRuleSeverity _selectedSeverity = AlertRuleSeverity.warning;

  @override
  void initState() {
    super.initState();
    _primeInitialValues();
    _loadAvailableItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _thresholdController.dispose();
    _titleFocusNode.dispose();
    _thresholdFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _primeInitialValues() {
    final rule = widget.initialRule;
    if (rule == null) {
      return;
    }

    _titleController.text = rule.title;
    _messageController.text = rule.message;
    if (rule.thresholdValue != null) {
      final threshold = rule.thresholdValue!;
      _thresholdController.text = threshold.truncateToDouble() == threshold
          ? threshold.toInt().toString()
          : threshold.toString();
    }
    _selectedWidgetId = rule.widgetId;
    _selectedCondition = rule.condition;
    _selectedSeverity = rule.severity;
  }

  Future<void> _loadAvailableItems() async {
    final storedItems = await _layoutStorage.loadItems();
    final availableItems =
        (storedItems ?? const <DashboardItem>[])
            .where(_supportsAlertRules)
            .toList()
          ..sort((left, right) => left.title.compareTo(right.title));

    if (!mounted) {
      return;
    }

    setState(() {
      _availableItems = availableItems;
      final hasMatchingItem =
          _selectedWidgetId != null &&
          availableItems.any((item) => item.id == _selectedWidgetId);
      if (!hasMatchingItem) {
        if (widget.initialRule == null) {
          // New rule: default to the first available widget for convenience.
          _selectedWidgetId = availableItems.isNotEmpty
              ? availableItems.first.id
              : null;
        } else {
          // Editing an existing rule whose source widget was deleted.
          // Force the user to pick a widget explicitly instead of silently
          // rebinding the rule to an unrelated widget.
          _selectedWidgetId = null;
        }
      }
      _selectedCondition = _sanitizeCondition(
        item: _selectedItem,
        current: _selectedCondition,
      );
      _isLoading = false;
    });
  }

  bool get _sourceWidgetMissing {
    final initialRule = widget.initialRule;
    if (initialRule == null || _isLoading) {
      return false;
    }
    return !_availableItems.any((item) => item.id == initialRule.widgetId);
  }

  DashboardItem? get _selectedItem {
    final id = _selectedWidgetId;
    if (id == null) {
      return null;
    }

    for (final item in _availableItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  bool get _selectedConditionNeedsThreshold =>
      _selectedCondition != null &&
      _conditionNeedsThreshold(_selectedCondition!);

  Future<void> _saveRule() async {
    if (_isSaving || _isLoading || _isTestingAlert) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      await _scrollToFirstInvalidField();
      return;
    }

    final selectedItem = _selectedItem;
    final selectedCondition = _selectedCondition;
    if (selectedItem == null || selectedCondition == null) {
      return;
    }

    final now = DateTime.now();
    final currentRule = widget.initialRule;

    setState(() {
      _isSaving = true;
    });

    final allRules = List<AlertRuleModel>.from(
      await _notificationService.loadRules(),
    );
    final nextRule = _buildRuleFromForm(
      selectedItem: selectedItem,
      selectedCondition: selectedCondition,
      now: now,
      currentRule: currentRule,
    );

    final existingIndex = allRules.indexWhere((rule) => rule.id == nextRule.id);
    if (existingIndex >= 0) {
      allRules[existingIndex] = nextRule;
    } else {
      allRules.insert(0, nextRule);
    }
    await _notificationService.saveRules(allRules);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  AlertRuleModel _buildRuleFromForm({
    required DashboardItem selectedItem,
    required AlertRuleCondition selectedCondition,
    required DateTime now,
    AlertRuleModel? currentRule,
  }) {
    final threshold = _conditionNeedsThreshold(selectedCondition)
        ? double.tryParse(_thresholdController.text.trim())
        : null;

    return AlertRuleModel(
      id: currentRule?.id ?? 'rule_${now.microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      widgetId: selectedItem.id,
      widgetTitle: selectedItem.title.trim().isEmpty
          ? _fallbackWidgetTitle(selectedItem)
          : selectedItem.title.trim(),
      widgetType: selectedItem.type,
      dataKey: (selectedItem.dataKey ?? '').trim(),
      dataType: selectedItem.dataType,
      condition: selectedCondition,
      thresholdValue: threshold,
      message: _messageController.text.trim(),
      enabled: currentRule?.enabled ?? true,
      severity: _selectedSeverity,
      createdAt: currentRule?.createdAt ?? now,
      updatedAt: currentRule == null ? null : now,
    );
  }

  Future<void> _testAlert() async {
    if (_isSaving || _isLoading || _isTestingAlert) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      await _scrollToFirstInvalidField();
      return;
    }

    final selectedItem = _selectedItem;
    final selectedCondition = _selectedCondition;
    if (selectedItem == null || selectedCondition == null) {
      return;
    }

    setState(() {
      _isTestingAlert = true;
    });

    try {
      final localNotificationService = LocalAlertNotificationService.instance;
      final notificationsEnabled = await localNotificationService
          .areNotificationsEnabled();
      final canNotify = notificationsEnabled
          ? true
          : await localNotificationService.requestNotificationsPermission();

      if (!mounted) {
        return;
      }

      if (!canNotify) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยังไม่ได้เปิดสิทธิ์การแจ้งเตือน')),
        );
        return;
      }

      final draftRule = _buildRuleFromForm(
        selectedItem: selectedItem,
        selectedCondition: selectedCondition,
        now: DateTime.now(),
        currentRule: widget.initialRule,
      );
      final sent = await localNotificationService.showTestAlertNotification(
        title: 'PB IoT Test Alert',
        message: draftRule.message,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'ส่งการแจ้งเตือนทดสอบแล้ว'
                : 'ไม่สามารถส่งการแจ้งเตือนทดสอบได้',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTestingAlert = false;
        });
      }
    }
  }

  Future<void> _scrollToFirstInvalidField() async {
    final titleText = _titleController.text.trim();
    if (titleText.isEmpty) {
      await _scrollToField(_titleFieldKey, focusNode: _titleFocusNode);
      return;
    }

    if (_selectedCondition == null) {
      await _scrollToField(_conditionFieldKey);
      return;
    }

    if (_selectedConditionNeedsThreshold) {
      final thresholdText = _thresholdController.text.trim();
      if (thresholdText.isEmpty || double.tryParse(thresholdText) == null) {
        await _scrollToField(
          _thresholdFieldKey,
          focusNode: _thresholdFocusNode,
        );
        return;
      }
    }

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      await _scrollToField(_messageFieldKey, focusNode: _messageFocusNode);
    }
  }

  Future<void> _scrollToField(
    GlobalKey fieldKey, {
    FocusNode? focusNode,
  }) async {
    final context = fieldKey.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      alignment: 0.18,
    );

    if (focusNode != null && mounted) {
      focusNode.requestFocus();
    }
  }

  BoxDecoration get _pageDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFF7FBFF), Color(0xFFF1F5FA), Color(0xFFEEF3F8)],
    ),
  );

  void _setEditorUiState(VoidCallback fn) {
    setState(fn);
  }

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 28,
            borderAlpha: 0.58,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.82),
              const Color(0xFFF7FBFF).withValues(alpha: 0.46),
            ],
            shadows: AppGlassTheme.shadowMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 16,
                  borderAlpha: 0.4,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.66),
                    const Color(0xFFDCEBFF).withValues(alpha: 0.26),
                  ],
                  shadows: AppGlassTheme.shadowSm,
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF20303A),
                  ),
                  splashRadius: 20,
                  tooltip: 'กลับ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEditing
                          ? 'แก้ไขการแจ้งเตือน'
                          : 'สร้างการแจ้งเตือน',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20303A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isEditing
                          ? 'แก้ไขกฎการแจ้งเตือนได้ โดยไม่มีผลต่อการทำงานในปัจจุบัน'
                          : 'สร้างกฎแจ้งเตือนใหม่จากวิดเจ็ตของคุณ',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF667587),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = _selectedItem;
    final availableConditions = selectedItem == null
        ? const <AlertRuleCondition>[]
        : _conditionsForItem(selectedItem);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: _pageDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlassHeader(),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: _SectionCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Color(0xFF4E9070),
                                    ),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'กำลังโหลดตัวแก้ไขการแจ้งเตือน...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF20303A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : _availableItems.isEmpty
                      ? _buildNoWidgetsState()
                      : _buildEditorFormContent(
                          selectedItem: selectedItem,
                          availableConditions: availableConditions,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _supportsAlertRules(DashboardItem item) {
  final dataKey = (item.dataKey ?? '').trim();
  if (dataKey.isEmpty) {
    return false;
  }

  return switch (item.type) {
    DashboardItemType.gauge => true,
    DashboardItemType.valueLabel => true,
    DashboardItemType.slider => true,
    DashboardItemType.stepH => true,
    DashboardItemType.stepV => true,
    DashboardItemType.trend => true,
    DashboardItemType.toggle => true,
    DashboardItemType.led => true,
    DashboardItemType.button => true,
  };
}

List<AlertRuleCondition> _conditionsForItem(DashboardItem item) {
  switch (item.type) {
    case DashboardItemType.toggle:
    case DashboardItemType.button:
      return const <AlertRuleCondition>[
        AlertRuleCondition.isOn,
        AlertRuleCondition.isOff,
        AlertRuleCondition.becameOn,
        AlertRuleCondition.becameOff,
      ];
    case DashboardItemType.gauge:
    case DashboardItemType.valueLabel:
    case DashboardItemType.trend:
    case DashboardItemType.slider:
    case DashboardItemType.stepH:
    case DashboardItemType.stepV:
      return const <AlertRuleCondition>[
        AlertRuleCondition.lessThan,
        AlertRuleCondition.lessThanOrEqual,
        AlertRuleCondition.greaterThan,
        AlertRuleCondition.greaterThanOrEqual,
        AlertRuleCondition.equalTo,
        AlertRuleCondition.notEqualTo,
      ];
    case DashboardItemType.led:
      return const <AlertRuleCondition>[
        AlertRuleCondition.isOn,
        AlertRuleCondition.isOff,
        AlertRuleCondition.becameOn,
        AlertRuleCondition.becameOff,
      ];
  }
}

AlertRuleCondition? _sanitizeCondition({
  required DashboardItem? item,
  required AlertRuleCondition? current,
}) {
  if (item == null) {
    return null;
  }

  final available = _conditionsForItem(item);
  if (current != null && available.contains(current)) {
    return current;
  }
  if (available.isEmpty) {
    return null;
  }
  return available.first;
}

bool _conditionNeedsThreshold(AlertRuleCondition condition) {
  switch (condition) {
    case AlertRuleCondition.lessThan:
    case AlertRuleCondition.lessThanOrEqual:
    case AlertRuleCondition.greaterThan:
    case AlertRuleCondition.greaterThanOrEqual:
    case AlertRuleCondition.equalTo:
    case AlertRuleCondition.notEqualTo:
      return true;
    case AlertRuleCondition.isOn:
    case AlertRuleCondition.isOff:
    case AlertRuleCondition.becameOn:
    case AlertRuleCondition.becameOff:
      return false;
  }
}

String _fallbackWidgetTitle(DashboardItem item) {
  final title = item.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return item.type.name;
}
