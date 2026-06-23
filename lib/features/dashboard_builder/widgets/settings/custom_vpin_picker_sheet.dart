part of '../widget_settings_sheet.dart';

class _CustomVPinPickerSheet extends StatefulWidget {
  const _CustomVPinPickerSheet({
    required this.selectedVPin,
    required this.lockedMap,
  });

  final String selectedVPin;
  final Map<String, String> lockedMap;

  @override
  State<_CustomVPinPickerSheet> createState() => _CustomVPinPickerSheetState();
}

class _CustomVPinPickerSheetState extends State<_CustomVPinPickerSheet> {
  static const Set<String> _starterVPins = <String>{'V0', 'V1', 'V2', 'V3'};

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  double _pickerScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 390).clamp(0.86, 1.08);
  }

  bool _isLockedVPin(String vpin) {
    return _starterVPins.contains(vpin) ||
        (widget.lockedMap.containsKey(vpin) && widget.selectedVPin != vpin);
  }

  String? _lockedVPinReason(String vpin) {
    if (_starterVPins.contains(vpin)) {
      return '$vpin - คีย์เริ่มต้น';
    }
    final label = widget.lockedMap[vpin]?.trim();
    if (label == null || label.isEmpty) {
      return null;
    }
    return '$vpin - $label';
  }

  Future<void> _closeWithVPin(String vpin) async {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(vpin);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pickerScale(context);
    final allVPins = <String>[for (var i = 0; i <= 255; i += 1) 'V$i'];
    final filteredVPins = allVPins.where((vpin) {
      final searchText = <String>[
        vpin,
        _lockedVPinReason(vpin) ?? '',
        widget.lockedMap[vpin] ?? '',
      ].join(' ').toLowerCase();
      return _searchQuery.isEmpty ||
          searchText.contains(_searchQuery.trim().toLowerCase());
    }).toList();
    final selectableVPins = filteredVPins
        .where((vpin) => !_isLockedVPin(vpin))
        .toList();
    final lockedVPins = filteredVPins
        .where((vpin) => _isLockedVPin(vpin))
        .toList();

    Widget sectionLabel(String label) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          14 * scale,
          12 * scale,
          14 * scale,
          4 * scale,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: DashboardRuntimeTheme.labelTextColor,
            fontSize: 11 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    Widget vpinTile(String vpin) {
      final locked = _isLockedVPin(vpin);
      final selected = widget.selectedVPin == vpin;
      return ListTile(
        dense: scale < 0.95,
        visualDensity: scale < 0.95
            ? const VisualDensity(vertical: -1)
            : VisualDensity.standard,
        enabled: !locked,
        onTap: locked ? null : () => _closeWithVPin(vpin),
        title: Text(
          _lockedVPinReason(vpin) ?? vpin,
          style: TextStyle(
            color: locked
                ? DashboardRuntimeTheme.mutedTextColor
                : (selected
                      ? DashboardRuntimeTheme.headlineColor
                      : DashboardRuntimeTheme.fieldTextColor),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14 * scale,
          ),
        ),
        trailing: locked
            ? const Icon(
                Icons.lock_rounded,
                size: 16,
                color: DashboardRuntimeTheme.mutedTextColor,
              )
            : (selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: DashboardRuntimeTheme.surfaceBorderFocusColor,
                    )
                  : null),
      );
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18 * scale, 0, 18 * scale, 14 * scale),
          child: _buildStableGlassSheetShell(
            radius: 22 * scale,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.76,
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
                    'เลือกข้อมูลที่เชื่อมต่อ (V Pin)',
                    style: TextStyle(
                      color: DashboardRuntimeTheme.headlineColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15 * scale,
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  Container(
                    decoration: _glassInsetDecoration(radius: 16),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        color: DashboardRuntimeTheme.fieldTextColor,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ค้นหา V Pin',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: DashboardRuntimeTheme.labelTextColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14 * scale,
                          vertical: 14 * scale,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear_rounded, size: 18),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Flexible(
                    child: filteredVPins.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 18 * scale,
                              ),
                              child: Text(
                                'ไม่พบข้อมูลที่ตรงกับคำค้น',
                                style: TextStyle(
                                  color: DashboardRuntimeTheme.mutedTextColor,
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: [
                              if (selectableVPins.isNotEmpty)
                                sectionLabel('เลือกได้'),
                              for (final vpin in selectableVPins)
                                vpinTile(vpin),
                              if (lockedVPins.isNotEmpty)
                                sectionLabel('ใช้งานไม่ได้'),
                              for (final vpin in lockedVPins) vpinTile(vpin),
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
  }
}
