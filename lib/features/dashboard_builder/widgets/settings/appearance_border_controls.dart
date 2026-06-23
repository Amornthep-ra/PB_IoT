part of '../widget_settings_sheet.dart';

extension _WidgetSettingsAppearanceBorderControls on _WidgetSettingsSheetState {
  Widget _buildBorderWidthSection() {
    final field = _designConfig.borderWidthField;
    if (field == _DesignBorderWidthField.none) {
      return const SizedBox.shrink();
    }

    final value = _borderWidthValueFor(field);
    final activeColor = _borderWidthAccentFor(field);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsLabel('ความหนาขอบ'),
        const SizedBox(height: 10),
        _buildFieldShell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 2),
                    const Spacer(),
                    Text(
                      '${value.toStringAsFixed(1)}px',
                      style: TextStyle(
                        color:
                            Color.lerp(activeColor, Colors.white, 0.16) ??
                            activeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    inactiveTrackColor:
                        DashboardRuntimeTheme.surfaceBorderColor,
                    activeTrackColor: activeColor,
                    thumbColor: activeColor,
                  ),
                  child: Slider(
                    value: value,
                    min: _WidgetSettingsSheetState._minValueLabelBorderWidth,
                    max: _WidgetSettingsSheetState._maxValueLabelBorderWidth,
                    divisions: _WidgetSettingsSheetState
                        ._valueLabelBorderWidthDivisions,
                    onChanged: (nextValue) {
                      _setAppearanceState(() {
                        _setBorderWidthValueFor(field, nextValue);
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2, right: 8),
                  child: Row(
                    children: [
                      Text(
                        '0px',
                        style: TextStyle(
                          color: DashboardRuntimeTheme.mutedTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '4px',
                        style: TextStyle(
                          color: DashboardRuntimeTheme.mutedTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _borderWidthAccentFor(_DesignBorderWidthField field) {
    return switch (field) {
      _DesignBorderWidthField.button => _buttonBorderColor,
      _DesignBorderWidthField.gauge => _accentColor,
      _ => _buttonShellColor,
    };
  }

  double _borderWidthValueFor(_DesignBorderWidthField field) {
    return switch (field) {
      _DesignBorderWidthField.button => _buttonBorderWidth,
      _DesignBorderWidthField.valueLabel => _valueLabelBorderWidth,
      _DesignBorderWidthField.gauge => _gaugeBorderWidth,
      _DesignBorderWidthField.slider => _sliderBorderWidth,
      _DesignBorderWidthField.toggle => _toggleBorderWidth,
      _DesignBorderWidthField.none => 0,
    };
  }

  void _setBorderWidthValueFor(_DesignBorderWidthField field, double value) {
    switch (field) {
      case _DesignBorderWidthField.button:
        _buttonBorderWidth = value;
      case _DesignBorderWidthField.valueLabel:
        _valueLabelBorderWidth = value;
      case _DesignBorderWidthField.gauge:
        _gaugeBorderWidth = value;
      case _DesignBorderWidthField.slider:
        _sliderBorderWidth = value;
      case _DesignBorderWidthField.toggle:
        _toggleBorderWidth = value;
      case _DesignBorderWidthField.none:
        break;
    }
  }
}
