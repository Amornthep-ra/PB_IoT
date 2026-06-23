part of '../widget_settings_sheet.dart';

extension _WidgetSettingsAppearanceGlowControls on _WidgetSettingsSheetState {
  Widget _buildGlowSection() {
    if (!_designConfig.showGlow) {
      return const SizedBox.shrink();
    }

    final glowColor = _effectiveGlowColor;
    final strengthPercent =
        ((_glowStrength / _WidgetSettingsSheetState._maxGlowStrength) * 100)
            .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsLabel('แสงเรือง'),
        const SizedBox(height: 10),
        _buildFieldShell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _glowColorLinkedToAccent
                      ? 'ใช้สีหลักเป็นแสงเรือง'
                      : 'ใช้สีแสงเรืองเดิมที่บันทึกไว้',
                  style: const TextStyle(
                    color: DashboardRuntimeTheme.mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildGlowSlider(
                  label: 'ความแรง',
                  valueLabel: '$strengthPercent%',
                  value: _glowStrength,
                  min: _WidgetSettingsSheetState._minGlowStrength,
                  max: _WidgetSettingsSheetState._maxGlowStrength,
                  divisions: _WidgetSettingsSheetState._glowStrengthDivisions,
                  minLabel: '0%',
                  maxLabel: '100%',
                  activeColor: glowColor,
                  onChanged: (value) {
                    _setAppearanceState(() {
                      _glowStrength = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowSlider({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String minLabel,
    required String maxLabel,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: DashboardRuntimeTheme.labelTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: TextStyle(
                color:
                    Color.lerp(activeColor, Colors.white, 0.16) ?? activeColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            inactiveTrackColor: DashboardRuntimeTheme.surfaceBorderColor,
            activeTrackColor: activeColor,
            thumbColor: activeColor,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, right: 8),
          child: Row(
            children: [
              Text(
                minLabel,
                style: const TextStyle(
                  color: DashboardRuntimeTheme.mutedTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                maxLabel,
                style: const TextStyle(
                  color: DashboardRuntimeTheme.mutedTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
