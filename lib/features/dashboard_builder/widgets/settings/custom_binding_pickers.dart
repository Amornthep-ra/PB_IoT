part of '../widget_settings_sheet.dart';

extension _CustomBindingPickers on _CustomBindingPageState {
  List<String> _unitOptionsForType() {
    final options = switch (_selectedType) {
      'bool' || 'string' => <String>['ไม่มี'],
      _ => <String>[
        'ไม่มี',
        '%',
        '°C',
        'ppm',
        'L',
        'kWh',
        'kW',
        'm/s',
        'pH',
        'cm',
        'mm',
      ],
    };

    return options.contains(_selectedUnit)
        ? options
        : <String>[...options, _selectedUnit];
  }

  bool get _isUnitSelectable =>
      _selectedType != 'bool' && _selectedType != 'string';
  String get _usageLabel {
    if (widget.usageCount <= 0) {
      return 'ยังไม่ได้ใช้งาน';
    }
    if (widget.usageCount == 1) {
      return 'ถูกใช้งานโดย 1 วิดเจ็ต';
    }
    return 'ถูกใช้งานโดย ${widget.usageCount} วิดเจ็ต';
  }

  double _pickerScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 390).clamp(0.86, 1.08);
  }

  Future<void> _openCustomVPinPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CustomVPinPickerSheet(
          selectedVPin: _keyController.text.trim(),
          lockedMap: widget.lockedMap,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    _setCustomBindingPickerState(() {
      _keyController.text = result;
    });
  }

  Future<void> _openCustomTypePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scale = _pickerScale(context);
        String typeSubtitle(String key) {
          return switch (key) {
            'number' => 'มีทศนิยมได้',
            'integer' => 'จำนวนเต็มเท่านั้น',
            'bool' => 'ค่า 0 หรือ 1',
            'string' => 'ข้อความ',
            _ => '',
          };
        }

        Widget typeTile(MapEntry<String, String> entry) {
          final selected = entry.key == _selectedType;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 3 * scale,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16 * scale),
              onTap: () => Navigator.of(context).pop(entry.key),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * scale,
                  vertical: 10 * scale,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? DashboardRuntimeTheme.surfaceBorderFocusColor
                            .withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(
                    color: selected
                        ? DashboardRuntimeTheme.surfaceBorderFocusColor
                              .withValues(alpha: 0.32)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: selected
                                  ? DashboardRuntimeTheme.headlineColor
                                  : DashboardRuntimeTheme.fieldTextColor,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14 * scale,
                            ),
                          ),
                          SizedBox(height: 2 * scale),
                          Text(
                            typeSubtitle(entry.key),
                            style: TextStyle(
                              color: DashboardRuntimeTheme.mutedTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    SizedBox(
                      width: 24 * scale,
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color:
                                  DashboardRuntimeTheme.surfaceBorderFocusColor,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                0,
                18 * scale,
                14 * scale,
              ),
              child: _buildStableGlassSheetShell(
                radius: 22 * scale,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8 * scale),
                      Container(
                        width: 38 * scale,
                        height: 3 * scale,
                        decoration: BoxDecoration(
                          color: DashboardRuntimeTheme.surfaceBorderColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        'เลือกประเภทข้อมูล',
                        style: TextStyle(
                          color: DashboardRuntimeTheme.headlineColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15 * scale,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Flexible(
                        child: ListView(
                          padding: EdgeInsets.only(bottom: 8 * scale),
                          shrinkWrap: true,
                          children: [
                            for (final entry in widget.dataTypeOptions)
                              typeTile(entry),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    _setCustomBindingPickerState(() {
      _selectedType = result;
      if (_selectedType == 'bool' || _selectedType == 'string') {
        _selectedUnit = 'ไม่มี';
      }
    });
  }

  Future<void> _openCustomUnitPicker() async {
    if (!_isUnitSelectable) {
      return;
    }

    final options = _unitOptionsForType();
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scale = _pickerScale(context);
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                0,
                18 * scale,
                14 * scale,
              ),
              child: _buildStableGlassSheetShell(
                radius: 22 * scale,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.56,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8 * scale),
                      Container(
                        width: 38 * scale,
                        height: 3 * scale,
                        decoration: BoxDecoration(
                          color: DashboardRuntimeTheme.surfaceBorderColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        'เลือกหน่วย',
                        style: TextStyle(
                          color: DashboardRuntimeTheme.headlineColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15 * scale,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Flexible(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            for (final unit in options)
                              ListTile(
                                dense: scale < 0.95,
                                visualDensity: scale < 0.95
                                    ? const VisualDensity(vertical: -1)
                                    : VisualDensity.standard,
                                onTap: () => Navigator.of(context).pop(unit),
                                title: Text(
                                  unit,
                                  style: TextStyle(
                                    color: unit == _selectedUnit
                                        ? DashboardRuntimeTheme.headlineColor
                                        : DashboardRuntimeTheme.fieldTextColor,
                                    fontWeight: unit == _selectedUnit
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                trailing: unit == _selectedUnit
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: DashboardRuntimeTheme
                                            .surfaceBorderFocusColor,
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    _setCustomBindingPickerState(() {
      _selectedUnit = result;
    });
  }
}
