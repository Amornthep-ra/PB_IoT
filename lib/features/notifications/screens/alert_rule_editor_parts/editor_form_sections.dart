part of '../alert_rule_editor_screen.dart';

extension _AlertRuleEditorFormSections on _AlertRuleEditorScreenState {
  Widget _buildEditorFormContent({
    required DashboardItem? selectedItem,
    required List<AlertRuleCondition> availableConditions,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 168),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('ชื่อการแจ้งเตือน'),
                        const SizedBox(height: 7),
                        KeyedSubtree(
                          key: _titleFieldKey,
                          child: TextFormField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              hintText: 'ตัวอย่าง: ความชื้นในดินต่ำ',
                            ),
                            onChanged: (_) => _setEditorUiState(() {}),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'กรอกชื่อการแจ้งเตือน';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('วิดเจ็ต'),
                        const SizedBox(height: 7),
                        if (_sourceWidgetMissing) ...[
                          _SourceMissingBanner(
                            widgetTitle: widget.initialRule!.widgetTitle,
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
                          selectedItemBuilder: (context) => _availableItems
                              .map(
                                (item) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _widgetDisplayName(item),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF20303A),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          items: _availableItems
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.id,
                                  child: _WidgetOptionTile(
                                    title: _widgetDisplayName(item),
                                    subtitle: _widgetBindingSummary(item),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            _setEditorUiState(() {
                              _selectedWidgetId = value;
                              _selectedCondition = _sanitizeCondition(
                                item: _selectedItem,
                                current: _selectedCondition,
                              );
                            });
                          },
                        ),
                        if (selectedItem != null) ...[
                          const SizedBox(height: 8),
                          _WidgetBindingChips(item: selectedItem),
                        ],
                        const SizedBox(height: 14),
                        const _FieldLabel('เงื่อนไข'),
                        const SizedBox(height: 7),
                        KeyedSubtree(
                          key: _conditionFieldKey,
                          child: DropdownButtonFormField<AlertRuleCondition>(
                            initialValue: _selectedCondition,
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
                            items: availableConditions
                                .map(
                                  (condition) =>
                                      DropdownMenuItem<AlertRuleCondition>(
                                        value: condition,
                                        child: Text(
                                          _conditionLabel(condition),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF20303A),
                                          ),
                                        ),
                                      ),
                                )
                                .toList(),
                            onChanged: (value) {
                              _setEditorUiState(() {
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
                          const SizedBox(height: 14),
                          const _FieldLabel('ค่า'),
                          const SizedBox(height: 7),
                          KeyedSubtree(
                            key: _thresholdFieldKey,
                            child: TextFormField(
                              controller: _thresholdController,
                              focusNode: _thresholdFocusNode,
                              textInputAction: TextInputAction.next,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: false,
                                  ),
                              decoration: _inputDecoration(
                                hintText: _thresholdHintForItem(selectedItem),
                              ),
                              onChanged: (_) => _setEditorUiState(() {}),
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
                          ),
                        ],
                        const SizedBox(height: 14),
                        const _FieldLabel('ระดับความสำคัญ'),
                        const SizedBox(height: 7),
                        _SeveritySelector(
                          value: _selectedSeverity,
                          onChanged: (value) {
                            _setEditorUiState(() {
                              _selectedSeverity = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('ข้อความแจ้งเตือน'),
                        const SizedBox(height: 7),
                        KeyedSubtree(
                          key: _messageFieldKey,
                          child: TextFormField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            minLines: 2,
                            maxLines: 4,
                            decoration: _inputDecoration(
                              hintText: 'ตัวอย่าง: ความชื้นในดินต่ำเกินไป',
                            ),
                            onChanged: (_) => _setEditorUiState(() {}),
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
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: _buildPreviewCard(selectedItem),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildStickyActionBar(),
      ],
    );
  }

  Widget _buildNoWidgetsState() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                'ยังไม่มีวิดเจ็ตที่ใช้ได้',
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

  Widget _buildStickyActionBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 22,
            borderAlpha: 0.52,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.76),
              const Color(0xFFF6FBFF).withValues(alpha: 0.44),
            ],
            shadows: AppGlassTheme.shadowMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_isSaving || _isTestingAlert) ? null : _testAlert,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4E9070),
                    side: const BorderSide(color: Color(0xFF8FC8A9)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
                      : const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    _isTestingAlert ? 'กำลังส่งทดสอบ...' : 'ทดสอบแจ้งเตือน',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: AppGlassTheme.accentDecoration(
                  radius: 16,
                  colors: const <Color>[Color(0xFFB6D2F5), Color(0xFF82AEE8)],
                  borderColor: const Color(0xFF9EC3F0),
                  glowColor: const Color(0xFF82AEE8),
                ),
                child: FilledButton.icon(
                  onPressed: (_isSaving || _isTestingAlert) ? null : _saveRule,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
                        ? 'กำลังบันทึก...'
                        : (widget.isEditing
                              ? 'บันทึกการแก้ไข'
                              : 'บันทึกการแจ้งเตือน'),
                  ),
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
              'ตัวอย่าง',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4E9070),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'จะแจ้งเตือนเมื่อ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8895),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            previewTrigger,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20303A),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ข้อความแจ้งเตือน',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8895),
            ),
          ),
          const SizedBox(height: 6),
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
