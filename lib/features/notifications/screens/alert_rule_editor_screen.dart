import 'package:flutter/material.dart';

import '../../dashboard_builder/models/dashboard_item.dart';
import '../../dashboard_builder/services/dashboard_builder_layout_storage_service.dart';
import '../models/alert_rule_model.dart';
import '../services/notification_service.dart';

class AlertRuleEditorScreen extends StatefulWidget {
  const AlertRuleEditorScreen({
    super.key,
    this.initialRule,
  });

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

  bool _isLoading = true;
  bool _isSaving = false;
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
    final availableItems = (storedItems ?? const <DashboardItem>[])
        .where(_supportsAlertRules)
        .toList()
      ..sort((left, right) => left.title.compareTo(right.title));

    if (!mounted) {
      return;
    }

    setState(() {
      _availableItems = availableItems;
      if (_selectedItem == null) {
        _selectedWidgetId = availableItems.isNotEmpty ? availableItems.first.id : null;
      }
      _selectedCondition = _sanitizeCondition(
        item: _selectedItem,
        current: _selectedCondition,
      );
      _isLoading = false;
    });
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
      _selectedCondition != null && _conditionNeedsThreshold(_selectedCondition!);

  Future<void> _saveRule() async {
    if (_isSaving || _isLoading) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedItem = _selectedItem;
    final selectedCondition = _selectedCondition;
    if (selectedItem == null || selectedCondition == null) {
      return;
    }

    final threshold = _selectedConditionNeedsThreshold
        ? double.tryParse(_thresholdController.text.trim())
        : null;
    final now = DateTime.now();
    final currentRule = widget.initialRule;

    setState(() {
      _isSaving = true;
    });

    final allRules = List<AlertRuleModel>.from(
      await _notificationService.loadRules(),
    );
    final nextRule = AlertRuleModel(
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

  @override
  Widget build(BuildContext context) {
    final selectedItem = _selectedItem;
    final availableConditions = selectedItem == null
        ? const <AlertRuleCondition>[]
        : _conditionsForItem(selectedItem);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF20303A),
        title: Text(widget.isEditing ? 'Edit Alert' : 'Create Alert'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4E9070)),
              )
            : _availableItems.isEmpty
            ? _buildNoWidgetsState()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Alert name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'ตัวอย่าง: ความชื้นในดินต่ำ',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'กรอกชื่อการแจ้งเตือน';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const _FieldLabel('Widget'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedWidgetId,
                              decoration: _inputDecoration(),
                              items: _availableItems
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item.id,
                                      child: Text(_widgetDisplayName(item)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedWidgetId = value;
                                  _selectedCondition = _sanitizeCondition(
                                    item: _selectedItem,
                                    current: _selectedCondition,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            const _FieldLabel('Condition'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<AlertRuleCondition>(
                              value: _selectedCondition,
                              decoration: _inputDecoration(),
                              items: availableConditions
                                  .map(
                                    (condition) => DropdownMenuItem<AlertRuleCondition>(
                                      value: condition,
                                      child: Text(_conditionLabel(condition)),
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
                            if (_selectedConditionNeedsThreshold) ...[
                              const SizedBox(height: 16),
                              const _FieldLabel('Value'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _thresholdController,
                                textInputAction: TextInputAction.next,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: false,
                                ),
                                decoration: _inputDecoration(
                                  hintText: _thresholdHintForItem(selectedItem),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  if (!_selectedConditionNeedsThreshold) {
                                    return null;
                                  }
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'กรอกค่าที่ต้องการ';
                                  }
                                  if (double.tryParse(value!.trim()) == null) {
                                    return 'ระบุตัวเลขที่ถูกต้อง';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            const _FieldLabel('Severity'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<AlertRuleSeverity>(
                              value: _selectedSeverity,
                              decoration: _inputDecoration(),
                              items: AlertRuleSeverity.values
                                  .map(
                                    (severity) => DropdownMenuItem<AlertRuleSeverity>(
                                      value: severity,
                                      child: Text(_severityLabel(severity)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _selectedSeverity = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            const _FieldLabel('Alert message'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _messageController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: _inputDecoration(
                                hintText: 'ตัวอย่าง: ความชื้นในดินต่ำเกินไป',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'กรอกข้อความแจ้งเตือน';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildPreviewCard(selectedItem),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveRule,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4E9070),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                : (widget.isEditing ? 'Save changes' : 'Save alert'),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E9070).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: Color(0xFF4E9070),
                  size: 30,
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
    final widgetName = item == null ? 'Selected widget' : _widgetDisplayName(item);
    final buffer = StringBuffer(widgetName);

    if (condition != null) {
      buffer.write(' ');
      buffer.write(_conditionLabel(condition).toLowerCase());
    }
    if (_selectedConditionNeedsThreshold &&
        _thresholdController.text.trim().isNotEmpty) {
      buffer.write(' ');
      buffer.write(_thresholdController.text.trim());
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4E9070),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            buffer.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20303A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _messageController.text.trim().isEmpty
                ? 'ข้อความแจ้งเตือนของคุณจะแสดงที่นี่'
                : _messageController.text.trim(),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
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
      child: child,
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

InputDecoration _inputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDDE4EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDDE4EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF4E9070), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCC5A4E)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFCC5A4E), width: 1.4),
    ),
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
    return 'Enter a number';
  }
  final unit = (item.unit ?? '').trim();
  if (unit.isEmpty) {
    return 'Enter a number';
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

String _fallbackWidgetTitle(DashboardItem item) {
  final title = item.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return item.type.name;
}
