part of '../widget_settings_sheet.dart';

enum _CustomBindingEditorMode { virtualPin, advanced }

class _CustomBindingPage extends StatefulWidget {
  const _CustomBindingPage({
    required this.mode,
    required this.initialKey,
    required this.lockedMap,
    required this.initialType,
    required this.initialName,
    required this.initialDefaultValue,
    required this.initialMinValue,
    required this.initialMaxValue,
    required this.initialUnit,
    required this.isEditing,
    required this.usageCount,
    required this.dataTypeOptions,
  });

  final _CustomBindingEditorMode mode;
  final String initialKey;
  final Map<String, String> lockedMap;
  final String initialType;
  final String initialName;
  final String initialDefaultValue;
  final String initialMinValue;
  final String initialMaxValue;
  final String initialUnit;
  final bool isEditing;
  final int usageCount;
  final List<MapEntry<String, String>> dataTypeOptions;

  @override
  State<_CustomBindingPage> createState() => _CustomBindingPageState();
}

class _CustomBindingPageState extends State<_CustomBindingPage> {
  static const Set<String> _starterVPins = <String>{'V0', 'V1', 'V2', 'V3'};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _keyFieldKey = GlobalKey();
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _defaultFieldKey = GlobalKey();
  final GlobalKey _minFieldKey = GlobalKey();
  final GlobalKey _maxFieldKey = GlobalKey();
  late final TextEditingController _keyController;
  late final TextEditingController _nameController;
  late final TextEditingController _defaultController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final Map<FocusNode, GlobalKey> _focusFieldKeys;
  final FocusNode _keyFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _defaultFocusNode = FocusNode();
  final FocusNode _minFocusNode = FocusNode();
  final FocusNode _maxFocusNode = FocusNode();
  late String _selectedType;
  String _selectedUnit = 'ไม่มี';

  bool get _isVirtualPinMode =>
      widget.mode == _CustomBindingEditorMode.virtualPin;

  String? _normalizeVPinKey(String raw) {
    final match = RegExp(r'^V(\d{1,3})$').firstMatch(raw.trim().toUpperCase());
    if (match == null) {
      return null;
    }
    final index = int.tryParse(match.group(1)!);
    if (index == null || index < 0 || index > 255) {
      return null;
    }
    return 'V$index';
  }

  String? _canonicalBindingKey(String raw) {
    return DashboardItemRuntimeBinding.canonicalizeBindingKey(raw);
  }

  String get _resolvedBindingKey {
    if (_isVirtualPinMode) {
      return _normalizeVPinKey(_keyController.text) ??
          _keyController.text.trim();
    }
    return _canonicalBindingKey(_keyController.text) ??
        _keyController.text.trim();
  }

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialKey);
    _selectedType = widget.initialType;
    _nameController = TextEditingController(text: widget.initialName);
    _defaultController = TextEditingController(
      text: widget.initialDefaultValue,
    );
    _minController = TextEditingController(text: widget.initialMinValue);
    _maxController = TextEditingController(text: widget.initialMaxValue);
    _selectedUnit = widget.initialUnit.trim().isEmpty
        ? 'ไม่มี'
        : widget.initialUnit.trim();
    _focusFieldKeys = <FocusNode, GlobalKey>{
      _keyFocusNode: _keyFieldKey,
      _nameFocusNode: _nameFieldKey,
      _defaultFocusNode: _defaultFieldKey,
      _minFocusNode: _minFieldKey,
      _maxFocusNode: _maxFieldKey,
    };
    for (final focusNode in _focusFieldKeys.keys) {
      focusNode.addListener(_handleInputFocusChanged);
    }
  }

  @override
  void dispose() {
    for (final focusNode in _focusFieldKeys.keys) {
      focusNode.removeListener(_handleInputFocusChanged);
    }
    _keyController.dispose();
    _nameController.dispose();
    _defaultController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _keyFocusNode.dispose();
    _nameFocusNode.dispose();
    _defaultFocusNode.dispose();
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
    super.dispose();
  }

  void _setCustomBindingPickerState(VoidCallback fn) {
    setState(fn);
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      await _scrollToFirstInvalidField();
      return;
    }

    var minValue = double.tryParse(_minController.text.trim());
    var maxValue = double.tryParse(_maxController.text.trim());
    var defaultValue = double.tryParse(_defaultController.text.trim());

    if (_selectedType == 'bool') {
      minValue = 0;
      maxValue = 1;
      defaultValue = (_defaultController.text.trim() == '1') ? 1 : 0;
    }

    if (_selectedType != 'string') {
      if (minValue == null || maxValue == null || defaultValue == null) {
        return;
      }
      if (minValue > maxValue) {
        final tmp = minValue;
        minValue = maxValue;
        maxValue = tmp;
      }
      if (defaultValue < minValue || defaultValue > maxValue) {
        defaultValue = defaultValue.clamp(minValue, maxValue);
      }
    }

    Navigator.of(context).pop(
      _CustomBindingConfig(
        dataKey: _resolvedBindingKey,
        dataKeyLabel: _nameController.text.trim(),
        dataType: _selectedType,
        minValue: minValue,
        maxValue: maxValue,
        defaultValue: defaultValue,
        unit: _selectedUnit == 'ไม่มี' ? '' : _selectedUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildCustomBindingScaffold(context);
}
