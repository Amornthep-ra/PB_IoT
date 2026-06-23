part of '../widget_settings_sheet.dart';

extension _WidgetSettingsResultHelpers on _WidgetSettingsSheetState {
  String _defaultBindingModeForType(DashboardItemType type) {
    return _capabilities.defaultBindingModeFor(type);
  }

  String _resolveInitialBindingKey() {
    final current = widget.item.dataKey?.trim();
    if (current != null && current.isNotEmpty) {
      return _canonicalBindingKey(current) ?? current;
    }
    return '';
  }

  String _normalizeBindingMode(String raw) {
    return WidgetSettingsBindingCatalog.normalizeBindingMode(raw);
  }

  String _normalizeDataType(String raw) {
    return WidgetSettingsBindingCatalog.normalizeDataType(raw);
  }

  String _normalizeSendBehavior(String raw) {
    return WidgetSettingsBindingCatalog.normalizeSendBehavior(raw);
  }

  String _normalizeButtonMode(String raw) {
    return WidgetSettingsBindingCatalog.normalizeButtonMode(raw);
  }

  double _coerceByDataType(double value) {
    return WidgetSettingsBindingCatalog.coerceByDataType(
      value: value,
      dataType: _selectedDataType,
    );
  }

  String? _normalizeVPinKey(String raw) {
    return WidgetSettingsBindingCatalog.normalizeVPinKey(raw);
  }

  void _save() async {
    if (_bindingIsRequired && !_hasSelectedBinding) {
      if (_activePage != _WidgetSettingsPage.setting) {
        _setSettingsResultState(() {
          _activePage = _WidgetSettingsPage.setting;
          _showBindingValidationError = true;
        });
      } else {
        _setSettingsResultState(() {
          _showBindingValidationError = true;
        });
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      final fieldContext = _bindingFieldKey.currentContext;
      if (fieldContext != null && fieldContext.mounted) {
        await Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          alignment: 0.18,
        );
      }
      return;
    }

    final parsedMin =
        double.tryParse(_minValueController.text.trim()) ??
        widget.item.minValue;
    final parsedMax =
        double.tryParse(_maxValueController.text.trim()) ??
        widget.item.maxValue;
    final minValue = parsedMin <= parsedMax ? parsedMin : parsedMax;
    final maxValue = parsedMax >= parsedMin ? parsedMax : parsedMin;
    final stepValue =
        ((double.tryParse(_stepController.text.trim()) ?? widget.item.stepValue)
                .clamp(0.0001, 1000000))
            .toDouble();
    final nextValue = _coerceByDataType(
      (_isButtonWidget
              ? (_buttonEnabled ? 1.0 : 0.0)
              : (double.tryParse(_valueController.text.trim()) ??
                        widget.item.value)
                    .clamp(minValue, maxValue))
          .toDouble(),
    );
    _syncDraftFromCurrentState();
    final result = WidgetSettingsResultMapper.buildResult(
      source: widget.item,
      draft: _draft,
      capabilities: _capabilities,
      minValue: minValue,
      maxValue: maxValue,
      stepValue: stepValue,
      value: nextValue,
      defaultSurfaceColor: _effectiveDefaultSurfaceColor(),
      defaultInnerColor: _effectiveDefaultInnerSurfaceColor(),
      defaultButtonBorderColor: _effectiveDefaultButtonBorderColor(),
      defaultButtonBorderWidth:
          _WidgetSettingsSheetState._defaultButtonBorderWidth,
      defaultValueLabelBorderWidth:
          _WidgetSettingsSheetState._defaultValueLabelBorderWidth,
      defaultGaugeBorderWidth:
          _WidgetSettingsSheetState._defaultGaugeBorderWidth,
      defaultSliderBorderWidth:
          _WidgetSettingsSheetState._defaultSliderBorderWidth,
      defaultToggleBorderWidth:
          _WidgetSettingsSheetState._defaultToggleBorderWidth,
      defaultGlowStrength: _defaultGlowStrengthForCurrentType,
      defaultGlowBlur: _WidgetSettingsSheetState._defaultGlowBlur,
    );

    Navigator.of(context).pop(result);
  }
}
