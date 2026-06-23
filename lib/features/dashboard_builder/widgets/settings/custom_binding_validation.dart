part of '../widget_settings_sheet.dart';

extension _CustomBindingValidation on _CustomBindingPageState {
  String? _validateBindingKey(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return _isVirtualPinMode
          ? 'Please select a Virtual Pin.'
          : 'Please enter a runtime binding path.';
    }

    if (_isVirtualPinMode) {
      final normalized = _normalizeVPinKey(raw);
      if (normalized == null) {
        return 'Virtual Pin must be in Vx format, for example V4.';
      }
      if (_CustomBindingPageState._starterVPins.contains(normalized)) {
        return '$normalized is reserved by the default catalog.';
      }
      final lockedName = widget.lockedMap[normalized];
      if (lockedName != null && widget.initialKey != normalized) {
        return '$normalized is already used by $lockedName.';
      }
      return null;
    }

    final supported = DashboardItemRuntimeBinding.isSupportedBindingKey(
      raw,
      allowRead: true,
      allowWrite: true,
    );
    if (!supported) {
      return 'Use a supported binding such as status.temperature, online, virtualPins.V3, or control.soilThreshold.';
    }
    return null;
  }

  void _handleInputFocusChanged() {
    FocusNode? focusedNode;
    for (final entry in _focusFieldKeys.entries) {
      if (entry.key.hasFocus) {
        focusedNode = entry.key;
        break;
      }
    }
    if (focusedNode == null) {
      return;
    }

    final activeFocusNode = focusedNode;
    final fieldKey = _focusFieldKeys[activeFocusNode]!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !activeFocusNode.hasFocus) {
        return;
      }
      _scrollFocusedFieldIntoView(fieldKey);
    });
  }

  Future<void> _scrollFocusedFieldIntoView(GlobalKey fieldKey) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }
    final context = fieldKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: 0.22,
    );
  }

  String? _validateDefaultValue(String? value) {
    final raw = (value ?? '').trim();
    if (_selectedType == 'string') {
      return null;
    }
    if (_selectedType == 'bool') {
      if (raw != '0' && raw != '1') {
        return 'Boolean default must be 0 or 1.';
      }
      return null;
    }
    if (raw.isEmpty || double.tryParse(raw) == null) {
      return 'Please enter a numeric default value.';
    }
    if (_selectedType == 'integer' && int.tryParse(raw) == null) {
      return 'Integer type requires whole number.';
    }
    return null;
  }

  String? _validateMinMaxValue(String? value, String label) {
    if ((value ?? '').trim().isEmpty ||
        double.tryParse((value ?? '').trim()) == null) {
      return 'Please enter numeric $label value.';
    }
    return null;
  }

  Future<void> _scrollToFirstInvalidField() async {
    if (_validateBindingKey(_keyController.text) != null) {
      await _scrollToField(_keyFieldKey, focusNode: _keyFocusNode);
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      await _scrollToField(_nameFieldKey, focusNode: _nameFocusNode);
      return;
    }

    if (_validateDefaultValue(_defaultController.text) != null) {
      await _scrollToField(_defaultFieldKey, focusNode: _defaultFocusNode);
      return;
    }

    if (_selectedType != 'bool' && _selectedType != 'string') {
      if (_validateMinMaxValue(_minController.text, 'min') != null) {
        await _scrollToField(_minFieldKey, focusNode: _minFocusNode);
        return;
      }
      if (_validateMinMaxValue(_maxController.text, 'max') != null) {
        await _scrollToField(_maxFieldKey, focusNode: _maxFocusNode);
      }
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
}
