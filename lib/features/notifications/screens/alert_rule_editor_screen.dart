import 'dart:ui';

import 'package:flutter/material.dart';

import '../../dashboard_builder/models/dashboard_item.dart';
import '../../dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import '../../../theme/app_theme.dart';
import '../models/alert_rule_model.dart';
import '../services/local_alert_notification_service.dart';
import '../services/notification_service.dart';

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
      final hasMatchingItem = _selectedWidgetId != null &&
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
          const SnackBar(content: Text('Notifications are disabled.')),
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
          content: Text(sent ? 'Test alert sent.' : 'Unable to send test alert.'),
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

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEditing ? 'Edit Alert' : 'Create Alert',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Color(0xFF20303A),
                      ),
                    ),
                    const SizedBox(height: 6),
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlassHeader(),
                const SizedBox(height: 18),
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
                                    'Loading alert editor...',
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
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'เริ่มต้นสร้างกฎการแจ้งเตือนง่ายๆ โดยเลือกจากวิดเจ็ตบนหน้าแดชบอร์ด',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Color(0xFF667587),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _SectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FieldLabel('Alert name'),
                                      const SizedBox(height: 8),
                                      KeyedSubtree(
                                        key: _titleFieldKey,
                                        child: TextFormField(
                                          controller: _titleController,
                                          focusNode: _titleFocusNode,
                                          textInputAction: TextInputAction.next,
                                          decoration: _inputDecoration(
                                            hintText:
                                                'ตัวอย่าง: ความชื้นในดินต่ำ',
                                          ),
                                          onChanged: (_) => setState(() {}),
                                          validator: (value) {
                                            if ((value ?? '').trim().isEmpty) {
                                              return 'กรอกชื่อการแจ้งเตือน';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const _FieldLabel('Widget'),
                                      const SizedBox(height: 8),
                                      if (_sourceWidgetMissing) ...[
                                        _SourceMissingBanner(
                                          widgetTitle: widget
                                              .initialRule!
                                              .widgetTitle,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedWidgetId,
                                        isExpanded: true,
                                        decoration: _inputDecoration(),
                                        borderRadius: BorderRadius.circular(22),
                                        dropdownColor: const Color(0xFFF7FBFF),
                                        elevation: 0,
                                        icon: const Icon(
                                          Icons.expand_more_rounded,
                                          color: Color(0xFF6D7C8A),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF20303A),
                                        ),
                                        menuMaxHeight: 320,
                                        selectedItemBuilder: (context) =>
                                            _availableItems
                                                .map(
                                                  (item) => Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      _widgetDisplayName(item),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF20303A,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        items: _availableItems
                                            .map(
                                              (item) =>
                                                  DropdownMenuItem<String>(
                                                    value: item.id,
                                                    child: _WidgetOptionTile(
                                                      title: _widgetDisplayName(
                                                        item,
                                                      ),
                                                      subtitle:
                                                          _widgetBindingSummary(
                                                            item,
                                                          ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedWidgetId = value;
                                            _selectedCondition =
                                                _sanitizeCondition(
                                                  item: _selectedItem,
                                                  current: _selectedCondition,
                                                );
                                          });
                                        },
                                      ),
                                      if (selectedItem != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _widgetBindingSummary(selectedItem),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7B8895),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      const _FieldLabel('Condition'),
                                      const SizedBox(height: 8),
                                      KeyedSubtree(
                                        key: _conditionFieldKey,
                                        child:
                                            DropdownButtonFormField<
                                              AlertRuleCondition
                                            >(
                                              initialValue: _selectedCondition,
                                              isExpanded: true,
                                              decoration: _inputDecoration(),
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              dropdownColor: const Color(
                                                0xFFF7FBFF,
                                              ),
                                              elevation: 0,
                                              icon: const Icon(
                                                Icons.expand_more_rounded,
                                                color: Color(0xFF6D7C8A),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF20303A),
                                              ),
                                              menuMaxHeight: 320,
                                              items: availableConditions
                                                  .map(
                                                    (condition) =>
                                                        DropdownMenuItem<
                                                          AlertRuleCondition
                                                        >(
                                                          value: condition,
                                                          child: Text(
                                                            _conditionLabel(
                                                              condition,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFF20303A,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedCondition = value;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'เลือกเงื่อนไขการแจ้งเตือน';
                                                }
                                                return null;
                                              },
                                            ),
                                      ),
                                      if (_selectedConditionNeedsThreshold) ...[
                                        const SizedBox(height: 16),
                                        const _FieldLabel('Value'),
                                        const SizedBox(height: 8),
                                        KeyedSubtree(
                                          key: _thresholdFieldKey,
                                          child: TextFormField(
                                            controller: _thresholdController,
                                            focusNode: _thresholdFocusNode,
                                            textInputAction:
                                                TextInputAction.next,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                  signed: false,
                                                ),
                                            decoration: _inputDecoration(
                                              hintText: _thresholdHintForItem(
                                                selectedItem,
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                            validator: (value) {
                                              if (!_selectedConditionNeedsThreshold) {
                                                return null;
                                              }
                                              if ((value ?? '')
                                                  .trim()
                                                  .isEmpty) {
                                                return 'กรอกค่าที่ต้องการ';
                                              }
                                              if (double.tryParse(
                                                    value!.trim(),
                                                  ) ==
                                                  null) {
                                                return 'ระบุตัวเลขที่ถูกต้อง';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      const _FieldLabel('Severity'),
                                      const SizedBox(height: 8),
                                      _SeveritySelector(
                                        value: _selectedSeverity,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSeverity = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      const _FieldLabel('Alert message'),
                                      const SizedBox(height: 8),
                                      KeyedSubtree(
                                        key: _messageFieldKey,
                                        child: TextFormField(
                                          controller: _messageController,
                                          focusNode: _messageFocusNode,
                                          minLines: 2,
                                          maxLines: 4,
                                          decoration: _inputDecoration(
                                            hintText:
                                                'ตัวอย่าง: ความชื้นในดินต่ำเกินไป',
                                          ),
                                          onChanged: (_) => setState(() {}),
                                          validator: (value) {
                                            if ((value ?? '').trim().isEmpty) {
                                              return 'กรอกข้อความแจ้งเตือน';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildPreviewCard(selectedItem),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        (_isSaving || _isTestingAlert)
                                        ? null
                                        : _testAlert,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF4E9070),
                                      side: const BorderSide(
                                        color: Color(0xFF8FC8A9),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    icon: _isTestingAlert
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF4E9070),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.notifications_active_outlined,
                                          ),
                                    label: Text(
                                      _isTestingAlert
                                          ? 'Sending test...'
                                          : 'Test alert',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  decoration: AppGlassTheme.accentDecoration(
                                    radius: 18,
                                    colors: const <Color>[
                                      Color(0xFFB6D2F5),
                                      Color(0xFF82AEE8),
                                    ],
                                    borderColor: const Color(0xFF9EC3F0),
                                    glowColor: const Color(0xFF82AEE8),
                                  ),
                                  child: FilledButton.icon(
                                    onPressed: (_isSaving || _isTestingAlert)
                                        ? null
                                        : _saveRule,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined),
                                    label: Text(
                                      _isSaving
                                          ? 'Saving...'
                                          : (widget.isEditing
                                                ? 'Save changes'
                                                : 'Save alert'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoWidgetsState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: _SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: AppGlassTheme.surfaceDecoration(
                      radius: 18,
                      borderAlpha: 0.4,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.6),
                        const Color(0xFFDBF0E4).withValues(alpha: 0.28),
                      ],
                      shadows: AppGlassTheme.shadowSm,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: Color(0xFF4E9070),
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No widgets available yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20303A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ต้องสร้างและผูกวิดเจ็ตในโหมดปรับแต่งอย่างน้อย 1 รายการก่อน จึงจะเพิ่มกฎการแจ้งเตือนได้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF667587),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(DashboardItem? item) {
    final condition = _selectedCondition;
    final widgetName = item == null
        ? 'วิดเจ็ตที่เลือก'
        : _widgetDisplayName(item);
    final previewTrigger = _previewTriggerText(
      widgetName: widgetName,
      condition: condition,
      thresholdText: _thresholdController.text.trim(),
    );
    final previewMessage = _messageController.text.trim().isEmpty
        ? 'ยังไม่ได้ใส่ข้อความแจ้งเตือน'
        : _messageController.text.trim();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: AppGlassTheme.surfaceDecoration(
              radius: 999,
              borderAlpha: 0.32,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.48),
                const Color(0xFFDBF0E4).withValues(alpha: 0.2),
              ],
              shadows: const <BoxShadow>[],
            ),
            child: const Text(
              'Preview',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4E9070),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'จะแจ้งเตือนเมื่อ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8895),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            previewTrigger,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20303A),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ข้อความแจ้งเตือน',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8895),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            previewMessage,
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

String _previewTriggerText({
  required String widgetName,
  required AlertRuleCondition? condition,
  required String thresholdText,
}) {
  if (condition == null) {
    return widgetName;
  }

  switch (condition) {
    case AlertRuleCondition.lessThan:
      return thresholdText.isEmpty
          ? '$widgetName ต่ำกว่าค่าที่กำหนด'
          : '$widgetName ต่ำกว่า $thresholdText';
    case AlertRuleCondition.lessThanOrEqual:
      return thresholdText.isEmpty
          ? '$widgetName ไม่เกินค่าที่กำหนด'
          : '$widgetName ไม่เกิน $thresholdText';
    case AlertRuleCondition.greaterThan:
      return thresholdText.isEmpty
          ? '$widgetName สูงกว่าค่าที่กำหนด'
          : '$widgetName สูงกว่า $thresholdText';
    case AlertRuleCondition.greaterThanOrEqual:
      return thresholdText.isEmpty
          ? '$widgetName อย่างน้อยค่าที่กำหนด'
          : '$widgetName อย่างน้อย $thresholdText';
    case AlertRuleCondition.equalTo:
      return thresholdText.isEmpty
          ? '$widgetName เท่ากับค่าที่กำหนด'
          : '$widgetName เท่ากับ $thresholdText';
    case AlertRuleCondition.notEqualTo:
      return thresholdText.isEmpty
          ? '$widgetName ไม่เท่ากับค่าที่กำหนด'
          : '$widgetName ไม่เท่ากับ $thresholdText';
    case AlertRuleCondition.isOn:
      return '$widgetName เปิดอยู่';
    case AlertRuleCondition.isOff:
      return '$widgetName ปิดอยู่';
    case AlertRuleCondition.becameOn:
      return '$widgetName เปลี่ยนเป็นเปิด';
    case AlertRuleCondition.becameOff:
      return '$widgetName เปลี่ยนเป็นปิด';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

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
            borderAlpha: 0.5,
            colors: <Color>[
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF20303A),
      ),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({required this.value, required this.onChanged});

  final AlertRuleSeverity value;
  final ValueChanged<AlertRuleSeverity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AlertRuleSeverity.values.map((severity) {
        final selected = severity == value;
        final color = _severityColor(severity);
        final icon = _severityIcon(severity);

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(severity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: selected
                ? AppGlassTheme.accentDecoration(
                    radius: 16,
                    colors: <Color>[
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.72),
                    ],
                    borderColor: color.withValues(alpha: 0.78),
                    glowColor: color,
                  )
                : AppGlassTheme.surfaceDecoration(
                    radius: 16,
                    borderAlpha: 0.36,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.5),
                      color.withValues(alpha: 0.08),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : color),
                const SizedBox(width: 8),
                Text(
                  _severityLabel(severity),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF20303A),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

InputDecoration _inputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.52),
    hintStyle: const TextStyle(
      color: Color(0xFF8A97A5),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.68)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.68)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF8CB7E6), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCC5A4E), width: 1.1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCC5A4E), width: 1.5),
    ),
    errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );
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
    DashboardItemType.toggle => true,
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
    case DashboardItemType.slider:
      return const <AlertRuleCondition>[
        AlertRuleCondition.lessThan,
        AlertRuleCondition.lessThanOrEqual,
        AlertRuleCondition.greaterThan,
        AlertRuleCondition.greaterThanOrEqual,
        AlertRuleCondition.equalTo,
        AlertRuleCondition.notEqualTo,
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

String _conditionLabel(AlertRuleCondition condition) {
  switch (condition) {
    case AlertRuleCondition.lessThan:
      return '<';
    case AlertRuleCondition.lessThanOrEqual:
      return '<=';
    case AlertRuleCondition.greaterThan:
      return '>';
    case AlertRuleCondition.greaterThanOrEqual:
      return '>=';
    case AlertRuleCondition.equalTo:
      return '==';
    case AlertRuleCondition.notEqualTo:
      return '!=';
    case AlertRuleCondition.isOn:
      return 'Is ON';
    case AlertRuleCondition.isOff:
      return 'Is OFF';
    case AlertRuleCondition.becameOn:
      return 'Changed to ON';
    case AlertRuleCondition.becameOff:
      return 'Changed to OFF';
  }
}

IconData _severityIcon(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return Icons.info_outline_rounded;
    case AlertRuleSeverity.warning:
      return Icons.warning_amber_rounded;
    case AlertRuleSeverity.critical:
      return Icons.error_outline_rounded;
  }
}

Color _severityColor(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return const Color(0xFF4C8BC8);
    case AlertRuleSeverity.warning:
      return const Color(0xFFE28A3B);
    case AlertRuleSeverity.critical:
      return const Color(0xFFCC5A4E);
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

String _thresholdHintForItem(DashboardItem? item) {
  if (item == null) {
    return 'ใส่ค่าตัวเลข';
  }
  final unit = (item.unit ?? '').trim();
  if (unit.isEmpty) {
    return 'ใส่ค่าตัวเลข';
  }
  return 'Enter a value in $unit';
}

String _widgetDisplayName(DashboardItem item) {
  final title = item.title.trim();
  final typeLabel = item.type.name;
  if (title.isEmpty) {
    return typeLabel;
  }
  return '$title ($typeLabel)';
}

String _widgetBindingSummary(DashboardItem item) {
  final dataKeyLabel = (item.dataKeyLabel ?? '').trim();
  final dataKey = (item.dataKey ?? '').trim();
  final normalizedType = item.dataType.trim().toLowerCase();
  final typeLabel = switch (normalizedType) {
    'bool' || 'boolean' => 'boolean',
    'enum' || 'enumeration' => 'enum',
    'string' => 'text',
    _ => 'number',
  };
  final unit = (item.unit ?? '').trim();
  final bindingMode = item.bindingMode.trim().toLowerCase();
  final modeLabel = bindingMode == 'write' ? 'write' : 'read';

  final parts = <String>[
    if (dataKeyLabel.isNotEmpty) dataKeyLabel,
    if (dataKey.isNotEmpty &&
        dataKey.toLowerCase() != dataKeyLabel.toLowerCase())
      dataKey,
    typeLabel,
    if (unit.isNotEmpty) unit,
    modeLabel,
  ];
  return parts.join('  |  ');
}

String _fallbackWidgetTitle(DashboardItem item) {
  final title = item.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return item.type.name;
}

class _SourceMissingBanner extends StatelessWidget {
  const _SourceMissingBanner({required this.widgetTitle});

  final String widgetTitle;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFCC5A4E);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Widget ต้นทางถูกลบแล้ว',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20303A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'rule นี้เคยผูกกับ "$widgetTitle" '
                  'กรุณาเลือก widget ใหม่เพื่อบันทึก',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF667587),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetOptionTile extends StatelessWidget {
  const _WidgetOptionTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF20303A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7B8895),
          ),
        ),
      ],
    );
  }
}
