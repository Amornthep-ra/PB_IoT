part of '../widget_settings_sheet.dart';

extension _WidgetSettingsAppearanceColorControls on _WidgetSettingsSheetState {
  String _hexFromColor(Color color) {
    return color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  Color? _parseHexColor(String input) {
    final sanitized = input.replaceAll('#', '').trim();
    if (sanitized.length != 6) {
      return null;
    }

    final value = int.tryParse(sanitized, radix: 16);
    if (value == null) {
      return null;
    }

    return Color(0xFF000000 | value);
  }

  Future<void> _openColorPicker({
    required String title,
    required Color initialColor,
    required ValueChanged<Color> onColorPicked,
    VoidCallback? onResetToAuto,
  }) async {
    final hexController = TextEditingController(
      text: '#${_hexFromColor(initialColor)}',
    );
    Color draftColor = initialColor;

    final result = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void syncHex(Color color) {
              final nextText = '#${_hexFromColor(color)}';
              hexController.value = TextEditingValue(
                text: nextText,
                selection: TextSelection.collapsed(offset: nextText.length),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Material(
                color: Colors.transparent,
                child: _buildGlassSheetShell(
                  radius: 24,
                  blur: 18,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 3,
                            decoration: BoxDecoration(
                              color: DashboardRuntimeTheme.surfaceBorderColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: DashboardRuntimeTheme.headlineColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (onResetToAuto != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _setAppearanceState(onResetToAuto);
                              },
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                              ),
                              label: const Text('ใช้อัตโนมัติตามธีม'),
                              style: TextButton.styleFrom(
                                foregroundColor: DashboardRuntimeTheme
                                    .surfaceBorderFocusColor,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: ColorPicker(
                            pickerColor: draftColor,
                            onColorChanged: (color) {
                              final nextColor = color.withAlpha(255);
                              setSheetState(() {
                                draftColor = nextColor;
                                syncHex(nextColor);
                              });
                            },
                            enableAlpha: false,
                            displayThumbColor: true,
                            portraitOnly: true,
                            labelTypes: const [],
                            pickerAreaHeightPercent: 0.7,
                            hexInputBar: false,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _SettingsLabel('ค่าสี Hex'),
                        const SizedBox(height: 8),
                        _buildFieldShell(
                          child: TextField(
                            controller: hexController,
                            style: const TextStyle(
                              color: DashboardRuntimeTheme.fieldTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            decoration: _fieldDecoration(
                              hint: '#34C759',
                              prefixIcon: Icons.palette_outlined,
                            ),
                            onChanged: (value) {
                              final parsed = _parseHexColor(value);
                              if (parsed == null) {
                                return;
                              }
                              setSheetState(() {
                                draftColor = parsed;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFFBFB),
                                  side: const BorderSide(
                                    color: Color(0xFFC96868),
                                    width: 1,
                                  ),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: const Color(0xFFC96868),
                                ),
                                child: const Text(
                                  'ยกเลิก',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final parsed = _parseHexColor(
                                    hexController.text,
                                  );
                                  Navigator.of(
                                    context,
                                  ).pop(parsed ?? draftColor);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: draftColor,
                                  foregroundColor:
                                      ThemeData.estimateBrightnessForColor(
                                            draftColor,
                                          ) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF0D160E),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'ใช้สีนี้',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    hexController.dispose();

    if (result == null) {
      return;
    }

    _setAppearanceState(() {
      onColorPicked(result);
    });
  }

  Widget _buildCustomColorTrigger({
    required String badge,
    required String label,
    required Color color,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: accent.withValues(alpha: 0.08),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: DashboardRuntimeTheme.insetSurfaceDecoration(radius: 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(color, Colors.white, 0.18)!, color],
                ),
                border: Border.all(color: const Color(0x40F1F5EB)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.colorize_rounded,
                size: 14,
                color: Color(0xFF0D160E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '#${_hexFromColor(color)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color.lerp(
                    accent,
                    DashboardRuntimeTheme.mutedTextColor,
                    0.48,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: accent.withValues(alpha: 0.74),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTile({
    required String title,
    required String badge,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: DashboardRuntimeTheme.labelTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _buildCustomColorTrigger(
          badge: badge,
          label: label,
          color: color,
          accent: color,
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildColorStyleSection() {
    final tiles = <Widget>[];
    final config = _designConfig;

    if (config.showPrimaryColor) {
      tiles.add(
        _buildColorTile(
          title: config.primaryLabel,
          badge: 'MAIN',
          label: 'สีหลัก',
          color: _accentColor,
          onTap: () => _openColorPicker(
            title: config.primaryPickerTitle,
            initialColor: _accentColor,
            onColorPicked: (color) {
              _accentColor = color;
              if (_buttonBorderLinkedToState) {
                _buttonBorderColor = _effectiveDefaultButtonBorderColor();
              }
              if (_valueLabelBorderLinkedToText) {
                _buttonShellColor = color;
              }
            },
          ),
        ),
      );
    }

    if (config.showSecondaryColor) {
      tiles.add(
        _buildColorTile(
          title: config.secondaryLabel,
          badge: 'OFF',
          label: 'สีรอง/ปิด',
          color: _secondaryAccentColor,
          onTap: () => _openColorPicker(
            title: config.secondaryPickerTitle,
            initialColor: _secondaryAccentColor,
            onColorPicked: (color) {
              _secondaryAccentColor = color;
              if (_buttonBorderLinkedToState) {
                _buttonBorderColor = _effectiveDefaultButtonBorderColor();
              }
            },
          ),
        ),
      );
    }

    if (config.showBackgroundColor) {
      tiles.add(
        _buildColorTile(
          title: 'พื้นหลัง',
          badge: 'BG',
          label: 'สีพื้นหลัง',
          color: _buttonInnerColor,
          onTap: () => _openColorPicker(
            title: config.backgroundPickerTitle,
            initialColor: _buttonInnerColor,
            onColorPicked: (color) => _buttonInnerColor = color,
          ),
        ),
      );
    }

    if (config.showBorderColor) {
      final borderColor =
          config.borderColorField == _DesignBorderColorField.buttonBorderColor
          ? _buttonBorderColor
          : _buttonShellColor;
      tiles.add(
        _buildColorTile(
          title: 'สีขอบ',
          badge: 'LINE',
          label: 'สีขอบ',
          color: borderColor,
          onTap: () => _openColorPicker(
            title: config.borderPickerTitle,
            initialColor: borderColor,
            onColorPicked: (color) {
              if (config.borderColorField ==
                  _DesignBorderColorField.buttonBorderColor) {
                _buttonBorderColor = color;
                _buttonBorderLinkedToState =
                    color.toARGB32() ==
                    _effectiveDefaultButtonBorderColor().toARGB32();
              } else {
                _buttonShellColor = color;
                if (_isValueLabelWidget) {
                  _valueLabelBorderLinkedToText =
                      color.toARGB32() == _accentColor.toARGB32();
                }
              }
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsLabel('รูปแบบสี'),
        const SizedBox(height: 10),
        _buildColorTileGrid(tiles),
      ],
    );
  }

  Widget _buildColorTileGrid(List<Widget> tiles) {
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    for (var index = 0; index < tiles.length; index += 2) {
      final hasPair = index + 1 < tiles.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tiles[index]),
            if (hasPair) ...[
              const SizedBox(width: 10),
              Expanded(child: tiles[index + 1]),
            ] else ...[
              const SizedBox(width: 10),
              const Expanded(child: SizedBox.shrink()),
            ],
          ],
        ),
      );
      if (index + 2 < tiles.length) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return Column(children: rows);
  }
}
