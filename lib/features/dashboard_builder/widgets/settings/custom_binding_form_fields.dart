part of '../widget_settings_sheet.dart';

extension _CustomBindingFormFields on _CustomBindingPageState {
  Widget _buildCustomBindingFooter() {
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: AppGlassTheme.accentDecoration(
              radius: 999,
              colors: const <Color>[Color(0xFFEA7A70), Color(0xFFD95C54)],
              borderColor: const Color(0xFFC96868),
              glowColor: const Color(0xFFE08A82),
            ),
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
                foregroundColor: const Color(0xFFFFFBFB),
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: AppGlassTheme.accentDecoration(
              radius: 999,
              colors: const <Color>[Color(0xFF7EBFAF), Color(0xFF5E9E8B)],
              borderColor: const Color(0xFF6AA796),
              glowColor: const Color(0xFFA9D3C7),
            ),
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.isEditing ? 'บันทึก' : 'เพิ่ม',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBindingScaffold(BuildContext context) {
    const strongerLabelStyle = TextStyle(
      color: DashboardRuntimeTheme.headlineColor,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: DashboardRuntimeTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: DashboardRuntimeTheme.backgroundColor,
        elevation: 0,
        title: Text(
          _isVirtualPinMode
              ? (widget.isEditing
                    ? 'แก้ไข Custom Virtual Pin'
                    : 'เพิ่ม Custom Virtual Pin')
              : (widget.isEditing
                    ? 'แก้ไข Advanced Path Binding'
                    : 'เพิ่ม Advanced Path Binding'),
          style: const TextStyle(
            color: DashboardRuntimeTheme.headlineColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: DashboardRuntimeTheme.headlineColor,
        ),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _buildStableGlassSheetShell(
                          radius: 26,
                          opacity: 0.78,
                          elevated: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (widget.isEditing) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: _glassInsetDecoration(
                                        radius: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                            color: DashboardRuntimeTheme
                                                .labelTextColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _usageLabel,
                                              style: const TextStyle(
                                                color: DashboardRuntimeTheme
                                                    .fieldTextColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  _buildGlassControlShell(
                                    child: _isVirtualPinMode
                                        ? InkWell(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            onTap: _openCustomVPinPicker,
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText: 'แหล่งข้อมูล',
                                                labelStyle: strongerLabelStyle,
                                                filled: true,
                                                fillColor: DashboardRuntimeTheme
                                                    .surfaceColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: DashboardRuntimeTheme
                                                        .surfaceBorderColor,
                                                  ),
                                                ),
                                                disabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: DashboardRuntimeTheme
                                                        .surfaceBorderColor,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: DashboardRuntimeTheme
                                                        .surfaceBorderFocusColor,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _keyController.text
                                                          .trim(),
                                                      style: const TextStyle(
                                                        color:
                                                            DashboardRuntimeTheme
                                                                .fieldTextColor,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    size: 20,
                                                    color: DashboardRuntimeTheme
                                                        .mutedTextColor,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : KeyedSubtree(
                                            key: _keyFieldKey,
                                            child: TextFormField(
                                              controller: _keyController,
                                              focusNode: _keyFocusNode,
                                              style: const TextStyle(
                                                color: DashboardRuntimeTheme
                                                    .fieldTextColor,
                                                fontSize: 14,
                                              ),
                                              decoration: const InputDecoration(
                                                labelText: 'แหล่งข้อมูล',
                                                hintText:
                                                    'เช่น status.temperature หรือ control.soilThreshold',
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior
                                                        .always,
                                                labelStyle: strongerLabelStyle,
                                                hintStyle: TextStyle(
                                                  color: DashboardRuntimeTheme
                                                      .mutedTextColor,
                                                ),
                                                filled: true,
                                                fillColor: DashboardRuntimeTheme
                                                    .surfaceColor,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: DashboardRuntimeTheme
                                                        .surfaceBorderColor,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: DashboardRuntimeTheme
                                                        .surfaceBorderFocusColor,
                                                  ),
                                                ),
                                              ),
                                              validator: _validateBindingKey,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildGlassControlShell(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: _openCustomTypePicker,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'ประเภทข้อมูล',
                                          labelStyle: strongerLabelStyle,
                                          filled: true,
                                          fillColor: DashboardRuntimeTheme
                                              .surfaceColor,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderFocusColor,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                widget.dataTypeOptions
                                                    .firstWhere(
                                                      (entry) =>
                                                          entry.key ==
                                                          _selectedType,
                                                      orElse: () => MapEntry(
                                                        _selectedType,
                                                        _selectedType,
                                                      ),
                                                    )
                                                    .value,
                                                style: const TextStyle(
                                                  color: DashboardRuntimeTheme
                                                      .fieldTextColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 20,
                                              color: DashboardRuntimeTheme
                                                  .mutedTextColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  KeyedSubtree(
                                    key: _nameFieldKey,
                                    child: _buildGlassControlShell(
                                      child: TextFormField(
                                        controller: _nameController,
                                        focusNode: _nameFocusNode,
                                        style: const TextStyle(
                                          color: DashboardRuntimeTheme
                                              .fieldTextColor,
                                          fontSize: 14,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'ชื่อ',
                                          hintText:
                                              'ยกตัวอย่างเช่น Soil Threshold',
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.always,
                                          labelStyle: strongerLabelStyle,
                                          hintStyle: TextStyle(
                                            color: DashboardRuntimeTheme
                                                .mutedTextColor,
                                          ),
                                          filled: true,
                                          fillColor: DashboardRuntimeTheme
                                              .surfaceColor,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderFocusColor,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          final raw = (value ?? '').trim();
                                          if (raw.isEmpty) {
                                            return 'โปรดตั้งชื่อคีย์ข้อมูลก่อนใช้งาน';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  KeyedSubtree(
                                    key: _defaultFieldKey,
                                    child: _buildGlassControlShell(
                                      child: TextFormField(
                                        controller: _defaultController,
                                        focusNode: _defaultFocusNode,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                              signed: false,
                                            ),
                                        style: const TextStyle(
                                          color: DashboardRuntimeTheme
                                              .fieldTextColor,
                                          fontSize: 14,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'ค่าเริ่มต้น',
                                          labelStyle: strongerLabelStyle,
                                          filled: true,
                                          fillColor: DashboardRuntimeTheme
                                              .surfaceColor,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderFocusColor,
                                            ),
                                          ),
                                        ),
                                        validator: _validateDefaultValue,
                                      ),
                                    ),
                                  ),
                                  if (_selectedType != 'bool' &&
                                      _selectedType != 'string') ...[
                                    const SizedBox(height: 12),
                                    KeyedSubtree(
                                      key: _minFieldKey,
                                      child: _buildGlassControlShell(
                                        child: TextFormField(
                                          controller: _minController,
                                          focusNode: _minFocusNode,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                                signed: false,
                                              ),
                                          style: const TextStyle(
                                            color: DashboardRuntimeTheme
                                                .fieldTextColor,
                                            fontSize: 14,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'ค่าต่ำสุด',
                                            labelStyle: strongerLabelStyle,
                                            filled: true,
                                            fillColor: DashboardRuntimeTheme
                                                .surfaceColor,
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: DashboardRuntimeTheme
                                                    .surfaceBorderColor,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: DashboardRuntimeTheme
                                                    .surfaceBorderFocusColor,
                                              ),
                                            ),
                                          ),
                                          validator: (value) =>
                                              _validateMinMaxValue(
                                                value,
                                                'min',
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    KeyedSubtree(
                                      key: _maxFieldKey,
                                      child: _buildGlassControlShell(
                                        child: TextFormField(
                                          controller: _maxController,
                                          focusNode: _maxFocusNode,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                                signed: false,
                                              ),
                                          style: const TextStyle(
                                            color: DashboardRuntimeTheme
                                                .fieldTextColor,
                                            fontSize: 14,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'ค่าสูงสุด',
                                            labelStyle: strongerLabelStyle,
                                            filled: true,
                                            fillColor: DashboardRuntimeTheme
                                                .surfaceColor,
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: DashboardRuntimeTheme
                                                    .surfaceBorderColor,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: DashboardRuntimeTheme
                                                    .surfaceBorderFocusColor,
                                              ),
                                            ),
                                          ),
                                          validator: (value) =>
                                              _validateMinMaxValue(
                                                value,
                                                'max',
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildGlassControlShell(
                                    enabled: _isUnitSelectable,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: _isUnitSelectable
                                          ? _openCustomUnitPicker
                                          : null,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'หน่วย',
                                          labelStyle: strongerLabelStyle,
                                          hintText: 'เช่น %, C, ppm',
                                          hintStyle: TextStyle(
                                            color: DashboardRuntimeTheme
                                                .mutedTextColor,
                                          ),
                                          filled: true,
                                          fillColor: DashboardRuntimeTheme
                                              .surfaceColor,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderFocusColor,
                                            ),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderColor,
                                            ),
                                          ),
                                        ),
                                        isEmpty: _selectedUnit.trim().isEmpty,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _selectedUnit,
                                                style: TextStyle(
                                                  color: _isUnitSelectable
                                                      ? DashboardRuntimeTheme
                                                            .fieldTextColor
                                                      : DashboardRuntimeTheme
                                                            .mutedTextColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 20,
                                              color: _isUnitSelectable
                                                  ? DashboardRuntimeTheme
                                                        .mutedTextColor
                                                  : DashboardRuntimeTheme
                                                        .surfaceBorderColor,
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
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCustomBindingFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
