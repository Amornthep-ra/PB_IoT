import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../models/widget_settings_result.dart';
import '../../../theme/app_theme.dart';
import 'dashboard_item_renderer.dart';

BoxDecoration _glassSheetDecoration({
  required double radius,
  Color? tint,
  double opacity = 0.88,
  bool elevated = true,
}) {
  final base = (tint ?? DashboardRuntimeTheme.cardColor).withValues(
    alpha: opacity,
  );
  return AppGlassTheme.surfaceDecoration(
    radius: radius,
    colors: <Color>[
      Color.alphaBlend(Colors.white.withValues(alpha: 0.14), base),
      Color.alphaBlend(Colors.white.withValues(alpha: 0.04), base),
    ],
    borderAlpha: elevated ? 0.18 : 0.12,
    shadows: elevated ? AppGlassTheme.shadowMd : AppGlassTheme.shadowSm,
  );
}

Widget _buildGlassSheetShell({
  required Widget child,
  required double radius,
  double blur = 18,
  Color? tint,
  double opacity = 0.88,
  bool elevated = true,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: _glassSheetDecoration(
          radius: radius,
          tint: tint,
          opacity: opacity,
          elevated: elevated,
        ),
        child: child,
      ),
    ),
  );
}

BoxDecoration _glassInsetDecoration({required double radius, Color? color}) {
  final base = (color ?? DashboardRuntimeTheme.surfaceColor).withValues(
    alpha: 0.82,
  );
  return AppGlassTheme.surfaceDecoration(
    radius: radius,
    colors: <Color>[
      Color.alphaBlend(Colors.white.withValues(alpha: 0.08), base),
      Color.alphaBlend(Colors.transparent, base),
    ],
    borderAlpha: 0.1,
    shadows: AppGlassTheme.shadowSm,
  );
}

Widget _buildGlassControlShell({
  required Widget child,
  double radius = 14,
  bool enabled = true,
}) {
  return DecoratedBox(
    decoration: _glassInsetDecoration(
      radius: radius,
      color: enabled
          ? DashboardRuntimeTheme.surfaceColor
          : DashboardRuntimeTheme.surfaceColor.withValues(alpha: 0.62),
    ),
    child: child,
  );
}

InputDecoration _glassFormInputDecoration({
  String? labelText,
  TextStyle? labelStyle,
  String? hintText,
  TextStyle? hintStyle,
  Widget? prefixIcon,
  Widget? suffixIcon,
  FloatingLabelBehavior? floatingLabelBehavior,
}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: labelStyle,
    hintText: hintText,
    hintStyle:
        hintStyle ??
        const TextStyle(
          color: DashboardRuntimeTheme.mutedTextColor,
          fontSize: 12,
        ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    floatingLabelBehavior: floatingLabelBehavior,
    filled: true,
    fillColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

class WidgetSettingsSheet extends StatefulWidget {
  const WidgetSettingsSheet({
    super.key,
    required this.item,
    this.allItems = const <DashboardItem>[],
    this.isFullscreen = false,
  });

  final DashboardItem item;
  final List<DashboardItem> allItems;
  final bool isFullscreen;

  @override
  State<WidgetSettingsSheet> createState() => _WidgetSettingsSheetState();
}

enum _WidgetSettingsPage { setting, design }

enum _BindingCatalogKind { command, state, metric, duration }

class _BindingCatalogEntry {
  const _BindingCatalogEntry({
    required this.key,
    required this.name,
    required this.dataType,
    required this.rangeLabel,
    required this.description,
    required this.recommendedFor,
    required this.kind,
    this.defaultValue,
    this.minValue,
    this.maxValue,
    this.unit,
  });

  final String key;
  final String name;
  final String dataType;
  final String rangeLabel;
  final String description;
  final List<DashboardItemType> recommendedFor;
  final _BindingCatalogKind kind;
  final double? defaultValue;
  final double? minValue;
  final double? maxValue;
  final String? unit;
}

class _CustomBindingCatalogEntry {
  const _CustomBindingCatalogEntry({
    required this.key,
    required this.name,
    required this.dataType,
    required this.unit,
    this.defaultValue,
    this.minValue,
    this.maxValue,
  });

  final String key;
  final String name;
  final String dataType;
  final String unit;
  final double? defaultValue;
  final double? minValue;
  final double? maxValue;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'name': name,
      'dataType': dataType,
      'unit': unit,
      'defaultValue': defaultValue,
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }

  factory _CustomBindingCatalogEntry.fromJson(Map<String, dynamic> json) {
    return _CustomBindingCatalogEntry(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dataType: json['dataType']?.toString() ?? 'number',
      unit: json['unit']?.toString() ?? '',
      defaultValue: (json['defaultValue'] as num?)?.toDouble(),
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
    );
  }
}

class _WidgetSettingsSheetState extends State<WidgetSettingsSheet> {
  static const String _customBindingStorageKey =
      'dashboard_builder_custom_data_keys_v1';
  static const Color _defaultTitleColor = DashboardRuntimeTheme.headlineColor;
  static const Color _defaultButtonOffColor = Color(0xFFE5A39D);
  static const Color _defaultAccentColor = Color(0xFF1F9443);
  static const Color _defaultButtonInnerColor =
      DashboardRuntimeTheme.cardHighlightColor;
  static const double _minButtonTitleFontSize = 7;
  static const double _maxButtonTitleFontSize = 12;
  static const double _minTileTitleFontSize = 8;
  static const double _maxTileTitleFontSize = 18;
  static const List<_BindingCatalogEntry> _bindingCatalog =
      <_BindingCatalogEntry>[
        _BindingCatalogEntry(
          key: 'V0',
          name: 'Switch Command',
          dataType: 'bool',
          rangeLabel: '0-1',
          description: '0 = Off, 1 = On',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.button,
            DashboardItemType.toggle,
          ],
          kind: _BindingCatalogKind.command,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        _BindingCatalogEntry(
          key: 'V1',
          name: 'Switch State',
          dataType: 'integer',
          rangeLabel: '0-1',
          description: '0 = Off, 1 = On',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.toggle,
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
          ],
          kind: _BindingCatalogKind.state,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1,
        ),
        _BindingCatalogEntry(
          key: 'V2',
          name: 'Seconds',
          dataType: 'integer',
          rangeLabel: '0-1000000',
          description: 'ค่าระยะเวลาเป็นวินาทีแบบจำนวนเต็ม',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.slider,
            DashboardItemType.valueLabel,
            DashboardItemType.gauge,
          ],
          kind: _BindingCatalogKind.duration,
          defaultValue: 0,
          minValue: 0,
          maxValue: 1000000,
        ),
        _BindingCatalogEntry(
          key: 'V3',
          name: 'Temperature',
          dataType: 'number',
          rangeLabel: '0-100',
          description: 'ค่าอุณหภูมิ',
          recommendedFor: <DashboardItemType>[
            DashboardItemType.gauge,
            DashboardItemType.valueLabel,
          ],
          kind: _BindingCatalogKind.metric,
          defaultValue: 0,
          minValue: 0,
          maxValue: 100,
          unit: '°C',
        ),
      ];

  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  late final TextEditingController _minValueController;
  late final TextEditingController _maxValueController;
  late final TextEditingController _stepController;
  late final FocusNode _titleFocusNode;
  final GlobalKey _bindingFieldKey = GlobalKey();
  Color _accentColor = _defaultAccentColor;
  Color _titleColor = _defaultTitleColor;
  Color _secondaryAccentColor = _defaultButtonOffColor;
  Color _buttonShellColor = DashboardRuntimeTheme.surfaceColor;
  Color _buttonInnerColor = _defaultButtonInnerColor;
  Color _buttonBorderColor = DashboardRuntimeTheme.surfaceBorderColor;
  Color _glowColor = _defaultAccentColor;
  bool _glowColorLinkedToAccent = true;
  bool _buttonBorderLinkedToState = false;
  bool _valueLabelBorderLinkedToText = false;
  double _buttonBorderWidth = _defaultButtonBorderWidth;
  double _valueLabelBorderWidth = _defaultValueLabelBorderWidth;
  double _gaugeBorderWidth = _defaultGaugeBorderWidth;
  double _sliderBorderWidth = _defaultSliderBorderWidth;
  double _toggleBorderWidth = _defaultToggleBorderWidth;
  double _glowStrength = _defaultGlowStrength;
  double _glowBlur = _defaultGlowBlur;
  double _titleFontSize = _minTileTitleFontSize;
  bool _buttonEnabled = false;
  String? _selectedUnit;
  String _selectedBindingKey = '';
  String? _selectedBindingName;
  String _selectedTitlePosition = DashboardItemTitlePosition.auto;
  String _selectedBindingMode = 'read';
  String _selectedDataType = 'number';
  String _selectedSendBehavior = 'on_release';
  List<_CustomBindingCatalogEntry> _customBindingCatalog =
      const <_CustomBindingCatalogEntry>[];
  _WidgetSettingsPage _activePage = _WidgetSettingsPage.setting;
  bool _showBindingValidationError = false;

  static const double _defaultButtonBorderWidth = 1.2;
  static const double _defaultValueLabelBorderWidth = 1.2;
  static const double _defaultGaugeBorderWidth = 1.0;
  static const double _defaultSliderBorderWidth = 1.0;
  static const double _defaultToggleBorderWidth = 1.0;
  static const double _minValueLabelBorderWidth = 0.0;
  static const double _maxValueLabelBorderWidth = 4.0;
  static const int _valueLabelBorderWidthDivisions = 20;
  static const double _defaultGlowStrength = 0.12;
  static const double _defaultSliderGlowStrength = 0.08;
  static const double _defaultValueLabelGlowStrength = 0.0;
  static const double _minGlowStrength = 0.0;
  static const double _maxGlowStrength = 0.35;
  static const int _glowStrengthDivisions = 35;
  static const double _defaultGlowBlur = 18.0;
  static const double _minGlowBlur = 0.0;
  static const double _maxGlowBlur = 40.0;
  static const int _glowBlurDivisions = 40;

  double get _recommendedTitleFontSize => 10;

  double get _defaultGlowStrengthForCurrentType =>
      _defaultGlowStrengthForType(widget.item.type);

  Color get _effectiveGlowColor =>
      _glowColorLinkedToAccent ? _accentColor : _glowColor;

  static double _defaultGlowStrengthForType(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.slider => _defaultSliderGlowStrength,
      DashboardItemType.valueLabel => _defaultValueLabelGlowStrength,
      DashboardItemType.button ||
      DashboardItemType.gauge ||
      DashboardItemType.toggle => _defaultGlowStrength,
    };
  }

  String get _widgetSettingsSubtitle {
    return '';
  }

  Size get _miniPreviewSize => switch (widget.item.type) {
    DashboardItemType.button => const Size(72, 72),
    DashboardItemType.slider => const Size(150, 60),
    DashboardItemType.gauge => const Size(92, 92),
    DashboardItemType.toggle => const Size(118, 62),
    DashboardItemType.valueLabel => const Size(132, 72),
  };

  GridRect get _miniPreviewRect => switch (widget.item.type) {
    DashboardItemType.button => const GridRect(x: 0, y: 0, w: 7, h: 7),
    DashboardItemType.slider => const GridRect(x: 0, y: 0, w: 14, h: 5),
    DashboardItemType.gauge => const GridRect(x: 0, y: 0, w: 8, h: 8),
    DashboardItemType.toggle => const GridRect(x: 0, y: 0, w: 11, h: 5),
    DashboardItemType.valueLabel => const GridRect(x: 0, y: 0, w: 12, h: 6),
  };

  EdgeInsets get _miniPreviewInsets => switch (widget.item.type) {
    DashboardItemType.slider => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 2,
    ),
    DashboardItemType.button => const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 6,
    ),
    DashboardItemType.toggle => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
    DashboardItemType.valueLabel => const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 7,
    ),
    DashboardItemType.gauge => const EdgeInsets.all(8),
  };

  double get _miniPreviewRadius => switch (widget.item.type) {
    DashboardItemType.slider => 16,
    DashboardItemType.gauge => 24,
    DashboardItemType.button => 24,
    _ => 20,
  };

  Offset get _miniPreviewVisualOffset => switch (widget.item.type) {
    DashboardItemType.slider => const Offset(0, -3),
    _ => Offset.zero,
  };

  BoxDecoration get _miniPreviewCardDecoration {
    final isHorizontalWidget =
        widget.item.type == DashboardItemType.slider ||
        widget.item.type == DashboardItemType.button ||
        widget.item.type == DashboardItemType.toggle ||
        widget.item.type == DashboardItemType.valueLabel;

    return AppGlassTheme.surfaceDecoration(
      radius: _miniPreviewRadius,
      colors: <Color>[const Color(0xFFF8FFFC), const Color(0xFFE7F3EE)],
      borderAlpha: isHorizontalWidget ? 0.36 : 0.42,
      shadows: isHorizontalWidget
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ]
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x180F172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
    );
  }

  double get _previewMinValue {
    final parsedMin =
        double.tryParse(_minValueController.text.trim()) ??
        widget.item.minValue;
    final parsedMax =
        double.tryParse(_maxValueController.text.trim()) ??
        widget.item.maxValue;
    return parsedMin <= parsedMax ? parsedMin : parsedMax;
  }

  double get _previewMaxValue {
    final parsedMin =
        double.tryParse(_minValueController.text.trim()) ??
        widget.item.minValue;
    final parsedMax =
        double.tryParse(_maxValueController.text.trim()) ??
        widget.item.maxValue;
    return parsedMax >= parsedMin ? parsedMax : parsedMin;
  }

  double get _previewStepValue {
    return ((double.tryParse(_stepController.text.trim()) ??
                widget.item.stepValue)
            .clamp(0.0001, 1000000))
        .toDouble();
  }

  double get _previewValue {
    final nextValue = _coerceByDataType(
      (_isButtonWidget || _isToggleWidget
              ? (_buttonEnabled ? 1.0 : 0.0)
              : (double.tryParse(_valueController.text.trim()) ??
                        widget.item.value)
                    .clamp(_previewMinValue, _previewMaxValue))
          .toDouble(),
    );
    return nextValue;
  }

  double get _previewDisplayValue {
    final baseValue = _previewValue.clamp(_previewMinValue, _previewMaxValue);
    final span = _previewMaxValue - _previewMinValue;

    if ((_isSliderWidget || _isGaugeWidget) && span > 0) {
      final normalized = (baseValue - _previewMinValue) / span;
      if (normalized <= 0.02) {
        return (_previewMinValue + (span * 0.62))
            .clamp(_previewMinValue, _previewMaxValue)
            .toDouble();
      }
    }

    return baseValue.toDouble();
  }

  DashboardItem get _previewItem {
    final previewUnit = _hasSelectedBinding ? _selectedUnit : widget.item.unit;
    final previewDataKey = _selectedBindingKey.trim().isEmpty
        ? widget.item.dataKey
        : _selectedBindingKey;
    final previewDataKeyLabel = _selectedBindingKey.trim().isEmpty
        ? widget.item.dataKeyLabel
        : _selectedBindingName;

    return widget.item.copyWith(
      rect: _miniPreviewRect,
      title: '',
      value: _previewDisplayValue,
      minValue: (_isSliderWidget || _isGaugeWidget || _isValueLabelWidget)
          ? _previewMinValue
          : widget.item.minValue,
      maxValue: (_isSliderWidget || _isGaugeWidget || _isValueLabelWidget)
          ? _previewMaxValue
          : widget.item.maxValue,
      stepValue: _isSliderWidget ? _previewStepValue : widget.item.stepValue,
      unit: previewUnit,
      clearUnit: previewUnit == null,
      dataKey: previewDataKey,
      clearDataKey: previewDataKey == null || previewDataKey.trim().isEmpty,
      dataKeyLabel: previewDataKeyLabel,
      clearDataKeyLabel:
          previewDataKeyLabel == null || previewDataKeyLabel.trim().isEmpty,
      bindingMode: _isBindingModeConfigurable
          ? _selectedBindingMode
          : _defaultBindingModeForType(widget.item.type),
      dataType: _selectedDataType,
      sendBehavior: _isWritableWidget
          ? _selectedSendBehavior
          : widget.item.sendBehavior,
      accentColor: _accentColor,
      titleColor: _titleColor,
      titleFontSize: _titleFontSize,
      titlePosition: _selectedTitlePosition,
      secondaryAccentColor: (_isButtonWidget || _isToggleWidget)
          ? _secondaryAccentColor
          : widget.item.secondaryAccentColor,
      clearSecondaryAccentColor: false,
      buttonShellColor:
          (_isButtonWidget ||
              _isValueLabelWidget ||
              _isGaugeWidget ||
              _isSliderWidget ||
              _isToggleWidget)
          ? _buttonShellColor
          : widget.item.buttonShellColor,
      clearButtonShellColor: false,
      buttonInnerColor:
          (_isButtonWidget ||
              _isValueLabelWidget ||
              _isGaugeWidget ||
              _isSliderWidget ||
              _isToggleWidget)
          ? _buttonInnerColor
          : widget.item.buttonInnerColor,
      clearButtonInnerColor: false,
      buttonBorderColor: _isButtonWidget
          ? _buttonBorderColor
          : widget.item.buttonBorderColor,
      clearButtonBorderColor: !_isButtonWidget,
      buttonBorderWidth: _isButtonWidget
          ? _buttonBorderWidth
          : widget.item.buttonBorderWidth,
      clearButtonBorderWidth: !_isButtonWidget,
      valueLabelBorderWidth: _isValueLabelWidget
          ? _valueLabelBorderWidth
          : widget.item.valueLabelBorderWidth,
      clearValueLabelBorderWidth: !_isValueLabelWidget,
      gaugeBorderWidth: _isGaugeWidget
          ? _gaugeBorderWidth
          : widget.item.gaugeBorderWidth,
      clearGaugeBorderWidth: !_isGaugeWidget,
      sliderBorderWidth: _isSliderWidget
          ? _sliderBorderWidth
          : widget.item.sliderBorderWidth,
      clearSliderBorderWidth: !_isSliderWidget,
      toggleBorderWidth: _isToggleWidget
          ? _toggleBorderWidth
          : widget.item.toggleBorderWidth,
      clearToggleBorderWidth: !_isToggleWidget,
      glowColor: _glowColorLinkedToAccent ? null : _glowColor,
      clearGlowColor: _glowColorLinkedToAccent,
      glowStrength: _glowStrength,
      clearGlowStrength: false,
      glowBlur: _glowBlur,
      clearGlowBlur: false,
      enabled: (_isButtonWidget || _isToggleWidget)
          ? _buttonEnabled
          : widget.item.enabled,
    );
  }

  Widget _buildMiniWidgetPreview() {
    final previewSize = _miniPreviewSize;
    final previewInsets = _miniPreviewInsets;
    final previewBody = SizedBox(
      width: previewSize.width,
      height: previewSize.height,
      child: IgnorePointer(
        child: DashboardItemRenderer(
          item: _previewItem,
          enableInteraction: false,
        ),
      ),
    );

    return Center(
      child: SizedBox(
        width: previewSize.width + previewInsets.horizontal,
        height: previewSize.height + previewInsets.vertical,
        child: DecoratedBox(
          decoration: _miniPreviewCardDecoration,
          child: Padding(
            padding: previewInsets,
            child: Center(
              child: Transform.translate(
                offset: _miniPreviewVisualOffset,
                child: previewBody,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _effectiveDefaultButtonShellColor({bool? enabled}) {
    return (enabled ?? _buttonEnabled)
        ? DashboardRuntimeTheme.cardColor
        : DashboardRuntimeTheme.surfaceColor;
  }

  Color _effectiveDefaultButtonBorderColor({bool? enabled}) {
    final isEnabled = enabled ?? _buttonEnabled;
    final baseColor = isEnabled ? _accentColor : _secondaryAccentColor;
    return baseColor.withValues(alpha: isEnabled ? 0.26 : 0.22);
  }

  Color _effectiveDefaultGaugeBorderColor() {
    return _accentColor.withValues(alpha: 0.58);
  }

  Color _effectiveDefaultGaugeBackgroundColor() {
    return DashboardRuntimeTheme.cardColor;
  }

  Color _effectiveDefaultSliderBorderColor() {
    return _accentColor.withValues(alpha: 0.34);
  }

  Color _effectiveDefaultSliderBackgroundColor() {
    return DashboardRuntimeTheme.cardColor;
  }

  Color _effectiveDefaultToggleBorderColor() {
    return _accentColor.withValues(alpha: 0.58);
  }

  Color _effectiveDefaultToggleBackgroundColor() {
    return DashboardRuntimeTheme.cardColor;
  }

  Color _effectiveDefaultValueLabelBackgroundColor() {
    return DashboardRuntimeTheme.cardColor;
  }

  Color _effectiveDefaultValueLabelShellColor() {
    return _accentColor;
  }

  Color _effectiveDefaultButtonInnerColor() {
    return DashboardRuntimeTheme.cardHighlightColor;
  }

  double get _minTitleFontSize {
    if (_isButtonWidget) {
      return _minButtonTitleFontSize;
    }

    return (_recommendedTitleFontSize - 2).clamp(
      _minTileTitleFontSize,
      _maxTileTitleFontSize,
    );
  }

  double get _maxTitleFontSize {
    if (_isButtonWidget) {
      return _maxButtonTitleFontSize;
    }

    return (_recommendedTitleFontSize + 4).clamp(
      _minTileTitleFontSize,
      _maxTileTitleFontSize,
    );
  }

  int get _titleFontDivisions =>
      ((_maxTitleFontSize - _minTitleFontSize) * 2).round();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _valueController = TextEditingController(
      text: widget.item.value.toStringAsFixed(0),
    );
    _minValueController = TextEditingController(
      text: widget.item.minValue.toStringAsFixed(0),
    );
    _maxValueController = TextEditingController(
      text: widget.item.maxValue.toStringAsFixed(0),
    );
    _stepController = TextEditingController(
      text: widget.item.stepValue.toStringAsFixed(0),
    );
    _titleFocusNode = FocusNode()..addListener(_handleFocusChanged);
    _accentColor = widget.item.accentColor;
    _titleColor = widget.item.titleColor ?? _defaultTitleColor;
    _titleFontSize = (widget.item.titleFontSize ?? _recommendedTitleFontSize)
        .clamp(_minTitleFontSize, _maxTitleFontSize);
    _glowColorLinkedToAccent = widget.item.glowColor == null;
    _glowColor = widget.item.glowColor ?? widget.item.accentColor;
    _glowStrength =
        (widget.item.glowStrength ?? _defaultGlowStrengthForCurrentType)
            .clamp(_minGlowStrength, _maxGlowStrength)
            .toDouble();
    _glowBlur = (widget.item.glowBlur ?? _defaultGlowBlur)
        .clamp(_minGlowBlur, _maxGlowBlur)
        .toDouble();
    _secondaryAccentColor =
        widget.item.secondaryAccentColor ?? _defaultButtonOffColor;
    _buttonEnabled = widget.item.enabled;
    _buttonShellColor =
        widget.item.buttonShellColor ??
        (_isValueLabelWidget
            ? _effectiveDefaultValueLabelShellColor()
            : _isGaugeWidget
            ? _effectiveDefaultGaugeBorderColor()
            : _isSliderWidget
            ? _effectiveDefaultSliderBorderColor()
            : _isToggleWidget
            ? _effectiveDefaultToggleBorderColor()
            : _effectiveDefaultButtonShellColor(enabled: _buttonEnabled));
    _buttonInnerColor =
        widget.item.buttonInnerColor ??
        (_isValueLabelWidget
            ? _effectiveDefaultValueLabelBackgroundColor()
            : _isGaugeWidget
            ? _effectiveDefaultGaugeBackgroundColor()
            : _isSliderWidget
            ? _effectiveDefaultSliderBackgroundColor()
            : _isToggleWidget
            ? _effectiveDefaultToggleBackgroundColor()
            : _effectiveDefaultButtonInnerColor());
    _buttonBorderColor =
        widget.item.buttonBorderColor ??
        _effectiveDefaultButtonBorderColor(enabled: _buttonEnabled);
    _buttonBorderLinkedToState =
        _isButtonWidget &&
        (widget.item.buttonBorderColor == null ||
            widget.item.buttonBorderColor!.toARGB32() ==
                _effectiveDefaultButtonBorderColor(
                  enabled: _buttonEnabled,
                ).toARGB32());
    _buttonBorderWidth =
        (widget.item.buttonBorderWidth ?? _defaultButtonBorderWidth).clamp(
          _minValueLabelBorderWidth,
          _maxValueLabelBorderWidth,
        );
    _valueLabelBorderLinkedToText =
        _isValueLabelWidget &&
        (widget.item.buttonShellColor == null ||
            widget.item.buttonShellColor!.toARGB32() ==
                widget.item.accentColor.toARGB32());
    _valueLabelBorderWidth =
        (widget.item.valueLabelBorderWidth ?? _defaultValueLabelBorderWidth)
            .clamp(_minValueLabelBorderWidth, _maxValueLabelBorderWidth);
    _gaugeBorderWidth =
        (widget.item.gaugeBorderWidth ?? _defaultGaugeBorderWidth).clamp(
          _minValueLabelBorderWidth,
          _maxValueLabelBorderWidth,
        );
    _sliderBorderWidth =
        (widget.item.sliderBorderWidth ?? _defaultSliderBorderWidth).clamp(
          _minValueLabelBorderWidth,
          _maxValueLabelBorderWidth,
        );
    _toggleBorderWidth =
        (widget.item.toggleBorderWidth ?? _defaultToggleBorderWidth).clamp(
          _minValueLabelBorderWidth,
          _maxValueLabelBorderWidth,
        );
    _selectedBindingKey = _resolveInitialBindingKey();
    _selectedUnit = _selectedBindingKey.trim().isEmpty
        ? null
        : widget.item.unit;
    _selectedBindingName = widget.item.dataKeyLabel?.trim();
    final initialCatalogEntry = _catalogEntryFor(_selectedBindingKey);
    if (initialCatalogEntry != null &&
        (_selectedBindingName == null || _selectedBindingName!.isEmpty)) {
      _selectedBindingName = initialCatalogEntry.name;
      if (_selectedUnit == null &&
          initialCatalogEntry.unit != null &&
          initialCatalogEntry.unit!.trim().isNotEmpty) {
        _selectedUnit = initialCatalogEntry.unit!.trim();
      }
    }
    _selectedTitlePosition = _normalizeTitlePosition(widget.item.titlePosition);
    _selectedBindingMode = _normalizeBindingMode(widget.item.bindingMode);
    _selectedDataType = initialCatalogEntry != null
        ? _normalizeDataType(initialCatalogEntry.dataType)
        : _normalizeDataType(widget.item.dataType);
    _selectedSendBehavior = _isButtonWidget
        ? _normalizeButtonMode(widget.item.sendBehavior)
        : _normalizeSendBehavior(widget.item.sendBehavior);
    if (!_isBindingModeConfigurable) {
      _selectedBindingMode = _defaultBindingModeForType(widget.item.type);
    }
    if (!_bindingModeOptions().any(
      (option) => option.key == _selectedBindingMode,
    )) {
      _selectedBindingMode = _bindingModeOptions().first.key;
    }
    if (!_dataTypeOptions().any((option) => option.key == _selectedDataType)) {
      _selectedDataType = _dataTypeOptions().first.key;
    }
    final sendOptions = _sendBehaviorOptions();
    if (sendOptions.isNotEmpty &&
        !sendOptions.any((option) => option.key == _selectedSendBehavior)) {
      _selectedSendBehavior = sendOptions.first.key;
    }
    _loadCustomBindingCatalog();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _stepController.dispose();
    _titleFocusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  bool get _isButtonWidget => widget.item.type == DashboardItemType.button;
  bool get _isSliderWidget => widget.item.type == DashboardItemType.slider;
  bool get _isGaugeWidget => widget.item.type == DashboardItemType.gauge;
  bool get _isToggleWidget => widget.item.type == DashboardItemType.toggle;
  bool get _isValueLabelWidget =>
      widget.item.type == DashboardItemType.valueLabel;
  bool get _isWritableWidget =>
      _isButtonWidget || _isSliderWidget || _isToggleWidget;
  bool get _hasSelectedBinding => _selectedBindingKey.trim().isNotEmpty;
  bool get _isBindingModeConfigurable => false;
  bool get _bindingIsRequired => true;

  String _defaultBindingModeForType(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.button => 'read_write',
      DashboardItemType.toggle => 'read_write',
      DashboardItemType.slider => 'read_write',
      DashboardItemType.gauge => 'read',
      DashboardItemType.valueLabel => 'read',
    };
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  String? get _bindingAssistiveMessage {
    if (_hasSelectedBinding) {
      return 'เชื่อมข้อมูลแล้ว พร้อมใช้งานวิดเจ็ตนี้';
    }
    if (!_bindingIsRequired) {
      return null;
    }
    if (_showBindingValidationError) {
      return 'กรุณาเลือก V Pin ก่อนเพื่อให้วิดเจ็ตนี้ทำงานได้';
    }
    return 'ยังไม่ได้เลือก V Pin เลือกก่อนเพื่อเชื่อมข้อมูล';
  }

  Color get _bindingAssistiveColor {
    if (_showBindingValidationError && !_hasSelectedBinding) {
      return const Color(0xFFCC5A4E);
    }
    return _hasSelectedBinding
        ? const Color(0xFF4E9070)
        : DashboardRuntimeTheme.mutedTextColor;
  }

  String _displayUnit(String? unit) {
    final normalized = unit?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'None';
    }
    return normalized;
  }

  String _normalizeTitlePosition(String value) {
    final normalized = value.trim().toLowerCase();
    const allowed = <String>{
      DashboardItemTitlePosition.topOutside,
      DashboardItemTitlePosition.bottomOutside,
    };
    if (!allowed.contains(normalized)) {
      return DashboardItemTitlePosition.topOutside;
    }
    return normalized;
  }

  List<MapEntry<String, String>> _titlePositionOptions() {
    return const <MapEntry<String, String>>[
      MapEntry(DashboardItemTitlePosition.topOutside, 'Top'),
      MapEntry(DashboardItemTitlePosition.bottomOutside, 'Bottom'),
    ];
  }

  String _resolveInitialBindingKey() {
    final current = widget.item.dataKey?.trim();
    if (current != null && current.isNotEmpty) {
      return current.toUpperCase();
    }
    return '';
  }

  _BindingCatalogEntry? _catalogEntryFor(String key) {
    final normalizedKey = key.trim().toUpperCase();
    for (final entry in _bindingCatalog) {
      if (entry.key == normalizedKey) {
        return entry;
      }
    }
    return null;
  }

  bool _isCatalogKey(String key) => _catalogEntryFor(key) != null;

  String _widgetTypeLabel(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.button => 'Button',
      DashboardItemType.slider => 'Slider',
      DashboardItemType.gauge => 'Gauge',
      DashboardItemType.toggle => 'Toggle',
      DashboardItemType.valueLabel => 'Value',
    };
  }

  String _dataTypeLabel(String raw) {
    return switch (_normalizeDataType(raw)) {
      'integer' => 'Integer',
      'bool' => 'Boolean',
      'string' => 'String',
      _ => 'Number',
    };
  }

  String _bindingMetaLine({
    required String dataType,
    String? rangeLabel,
    String? unit,
  }) {
    final parts = <String>[_dataTypeLabel(dataType)];
    final normalizedRange = rangeLabel?.trim();
    if (normalizedRange != null && normalizedRange.isNotEmpty) {
      parts.add(normalizedRange);
    }
    final normalizedUnit = unit?.trim();
    if (normalizedUnit != null &&
        normalizedUnit.isNotEmpty &&
        normalizedUnit.toLowerCase() != 'none') {
      parts.add(normalizedUnit);
    }
    return parts.join(', ');
  }

  String _currentBindingRangeLabel() {
    final dataType = _normalizeDataType(_selectedDataType);
    if (dataType == 'bool') {
      return '0-1';
    }
    if (dataType == 'string') {
      return '';
    }
    final min = double.tryParse(_minValueController.text.trim());
    final max = double.tryParse(_maxValueController.text.trim());
    if (min == null || max == null) {
      return '';
    }
    String format(double value) {
      return value % 1 == 0
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);
    }

    return '${format(min)}-${format(max)}';
  }

  String _bindingLabelFor(String key) {
    final normalizedKey = key.trim().toUpperCase();
    if (normalizedKey.isEmpty) {
      return 'None';
    }
    final catalogEntry = _catalogEntryFor(normalizedKey);
    if (catalogEntry != null) {
      return '${catalogEntry.name} (${catalogEntry.key})';
    }
    final customEntry = _customBindingEntryFor(normalizedKey);
    if (customEntry != null) {
      return '${customEntry.name} (${customEntry.key})';
    }
    final customName = _selectedBindingName?.trim();
    if (customName != null && customName.isNotEmpty) {
      return '$customName ($normalizedKey)';
    }
    return 'Custom ($normalizedKey)';
  }

  String _bindingSubtitleFor(String key) {
    final normalizedKey = key.trim().toUpperCase();
    if (normalizedKey.isEmpty) {
      return 'เลือกคีย์ข้อมูลที่ต้องการใช้สำหรับวิดเจ็ตนี้';
    }
    final catalogEntry = _catalogEntryFor(normalizedKey);
    if (catalogEntry != null) {
      return _bindingMetaLine(
        dataType: catalogEntry.dataType,
        rangeLabel: catalogEntry.rangeLabel,
        unit: catalogEntry.unit,
      );
    }
    final customEntry = _customBindingEntryFor(normalizedKey);
    if (customEntry != null) {
      return _bindingMetaLine(
        dataType: customEntry.dataType,
        rangeLabel: _customBindingRangeLabel(customEntry),
        unit: customEntry.unit,
      );
    }
    return _bindingMetaLine(
      dataType: _selectedDataType,
      rangeLabel: _currentBindingRangeLabel(),
      unit: _selectedUnit,
    );
  }

  bool _isRecommendedCatalogEntry(_BindingCatalogEntry entry) {
    return entry.recommendedFor.contains(widget.item.type);
  }

  List<_BindingCatalogEntry> _sortedBindingCatalog() {
    final entries = List<_BindingCatalogEntry>.from(_bindingCatalog);
    entries.sort((left, right) {
      final leftIndex = int.tryParse(left.key.replaceFirst('V', '')) ?? 0;
      final rightIndex = int.tryParse(right.key.replaceFirst('V', '')) ?? 0;
      return leftIndex.compareTo(rightIndex);
    });
    return entries;
  }

  List<_CustomBindingCatalogEntry> _customBindingsFromItems() {
    final entries = <String, _CustomBindingCatalogEntry>{};
    for (final item in widget.allItems) {
      final key = _normalizeVPinKey(item.dataKey ?? '');
      if (key == null || _isCatalogKey(key)) {
        continue;
      }
      final label = item.dataKeyLabel?.trim();
      entries[key] = _CustomBindingCatalogEntry(
        key: key,
        name: (label == null || label.isEmpty) ? item.title.trim() : label,
        dataType: _normalizeDataType(item.dataType),
        unit: item.unit?.trim() ?? '',
        defaultValue: item.value,
        minValue: item.minValue,
        maxValue: item.maxValue,
      );
    }
    return entries.values.toList();
  }

  List<_CustomBindingCatalogEntry> _sortedCustomBindingCatalog() {
    return _mergeCustomBindingCatalogs(
      _customBindingCatalog,
      _customBindingsFromItems(),
    );
  }

  _CustomBindingCatalogEntry? _customBindingEntryFor(String key) {
    final normalizedKey = key.trim().toUpperCase();
    for (final entry in _sortedCustomBindingCatalog()) {
      if (entry.key == normalizedKey) {
        return entry;
      }
    }
    return null;
  }

  String _formatBindingNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _rangeLabelForValues({
    required String dataType,
    double? minValue,
    double? maxValue,
  }) {
    final normalizedType = _normalizeDataType(dataType);
    if (normalizedType == 'bool') {
      return '0-1';
    }
    if (normalizedType == 'string' || minValue == null || maxValue == null) {
      return '';
    }
    return '${_formatBindingNumber(minValue)}-${_formatBindingNumber(maxValue)}';
  }

  String _customBindingRangeLabel(_CustomBindingCatalogEntry entry) {
    return _rangeLabelForValues(
      dataType: entry.dataType,
      minValue: entry.minValue,
      maxValue: entry.maxValue,
    );
  }

  Map<String, int> _customBindingUsageCountMap({
    bool excludeCurrentItem = false,
  }) {
    final counts = <String, int>{};
    for (final item in widget.allItems) {
      if (excludeCurrentItem && item.id == widget.item.id) {
        continue;
      }
      final key = _normalizeVPinKey(item.dataKey ?? '');
      if (key == null || _isCatalogKey(key)) {
        continue;
      }
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  String _customBindingUsageLabel(
    String key, {
    bool excludeCurrentItem = false,
  }) {
    final count =
        _customBindingUsageCountMap(
          excludeCurrentItem: excludeCurrentItem,
        )[key] ??
        0;
    if (count <= 0) {
      return 'ยังไม่ได้ใช้งาน';
    }
    if (count == 1) {
      return 'ถูกใช้งานโดย 1 วิดเจ็ต';
    }
    return 'ถูกใช้งานโดย $count วิดเจ็ต';
  }

  Future<List<_CustomBindingCatalogEntry>>
  _loadStoredCustomBindingCatalog() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_customBindingStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <_CustomBindingCatalogEntry>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return const <_CustomBindingCatalogEntry>[];
    }
    final entries = <_CustomBindingCatalogEntry>[];
    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      final normalized = Map<String, dynamic>.from(entry);
      final parsed = _CustomBindingCatalogEntry.fromJson(normalized);
      if (parsed.key.trim().isEmpty || parsed.name.trim().isEmpty) {
        continue;
      }
      entries.add(parsed);
    }
    return entries;
  }

  Future<void> _saveStoredCustomBindingCatalog(
    List<_CustomBindingCatalogEntry> entries,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = entries.map((entry) => entry.toJson()).toList();
    await preferences.setString(_customBindingStorageKey, jsonEncode(payload));
  }

  List<_CustomBindingCatalogEntry> _mergeCustomBindingCatalogs(
    List<_CustomBindingCatalogEntry> stored,
    List<_CustomBindingCatalogEntry> fromItems,
  ) {
    final merged = <String, _CustomBindingCatalogEntry>{};
    for (final entry in stored) {
      final normalizedKey = _normalizeVPinKey(entry.key);
      if (normalizedKey == null || _isCatalogKey(normalizedKey)) {
        continue;
      }
      merged[normalizedKey] = _CustomBindingCatalogEntry(
        key: normalizedKey,
        name: entry.name.trim(),
        dataType: _normalizeDataType(entry.dataType),
        unit: entry.unit.trim(),
        defaultValue: entry.defaultValue,
        minValue: entry.minValue,
        maxValue: entry.maxValue,
      );
    }
    for (final entry in fromItems) {
      merged[entry.key] = entry;
    }
    final result = merged.values.toList();
    result.sort((left, right) {
      final leftIndex = int.tryParse(left.key.replaceFirst('V', '')) ?? 0;
      final rightIndex = int.tryParse(right.key.replaceFirst('V', '')) ?? 0;
      return leftIndex.compareTo(rightIndex);
    });
    return result;
  }

  Future<void> _loadCustomBindingCatalog() async {
    final stored = await _loadStoredCustomBindingCatalog();
    final merged = _mergeCustomBindingCatalogs(
      stored,
      _customBindingsFromItems(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _customBindingCatalog = merged;
    });
    final storedJson = jsonEncode(
      stored.map((entry) => entry.toJson()).toList(),
    );
    final mergedJson = jsonEncode(
      merged.map((entry) => entry.toJson()).toList(),
    );
    if (storedJson != mergedJson) {
      await _saveStoredCustomBindingCatalog(merged);
    }
  }

  Future<void> _upsertCustomBindingCatalogEntry(
    _CustomBindingCatalogEntry entry,
  ) async {
    final current = List<_CustomBindingCatalogEntry>.from(
      _customBindingCatalog,
    );
    final index = current.indexWhere((candidate) => candidate.key == entry.key);
    if (index >= 0) {
      current[index] = entry;
    } else {
      current.add(entry);
    }
    current.sort((left, right) {
      final leftIndex = int.tryParse(left.key.replaceFirst('V', '')) ?? 0;
      final rightIndex = int.tryParse(right.key.replaceFirst('V', '')) ?? 0;
      return leftIndex.compareTo(rightIndex);
    });
    setState(() {
      _customBindingCatalog = current;
    });
    await _saveStoredCustomBindingCatalog(current);
  }

  Future<void> _deleteCustomBindingCatalogEntry(String key) async {
    final normalizedKey = _normalizeVPinKey(key);
    if (normalizedKey == null) {
      return;
    }
    final current = _customBindingCatalog
        .where((entry) => entry.key != normalizedKey)
        .toList();
    setState(() {
      _customBindingCatalog = current;
    });
    await _saveStoredCustomBindingCatalog(current);
  }

  Future<bool> _confirmDeleteCustomBinding({
    required String key,
    required String name,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: _buildGlassSheetShell(
            radius: 28,
            blur: 20,
            tint: DashboardRuntimeTheme.cardHighlightColor,
            opacity: 0.96,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: DashboardRuntimeTheme.errorTextColor,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delete Custom Data Key?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: DashboardRuntimeTheme.headlineColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: _glassInsetDecoration(radius: 18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      child: Text(
                        'Remove $name ($key) from your custom Data Key list?',
                        style: const TextStyle(
                          color: DashboardRuntimeTheme.labelTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC96868)),
                            foregroundColor: const Color(0xFFFFFBFB),
                            backgroundColor: const Color(0xFFC96868),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFEA7A70), Color(0xFFD95C54)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFD95C54,
                                ).withValues(alpha: 0.22),
                                offset: const Offset(0, 10),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return confirmed == true;
  }

  String? _catalogUsageNote(_BindingCatalogEntry entry) {
    if (_isRecommendedCatalogEntry(entry)) {
      return null;
    }
    return 'ไม่ค่อยเหมาะกับ${_widgetTypeLabel(widget.item.type)}';
  }

  IconData _catalogIcon(_BindingCatalogEntry entry) {
    return switch (entry.kind) {
      _BindingCatalogKind.command => Icons.play_circle_outline_rounded,
      _BindingCatalogKind.state => Icons.toggle_on_outlined,
      _BindingCatalogKind.metric => Icons.insights_outlined,
      _BindingCatalogKind.duration => Icons.timer_outlined,
    };
  }

  String _normalizeBindingMode(String raw) {
    const allowed = <String>{'read', 'write', 'read_write'};
    final normalized = raw.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'read';
  }

  String _normalizeDataType(String raw) {
    const allowed = <String>{'number', 'integer', 'bool', 'string'};
    final normalized = raw.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'number';
  }

  String _normalizeSendBehavior(String raw) {
    const allowed = <String>{'on_release', 'on_drag', 'push', 'switch'};
    final normalized = raw.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'on_release';
  }

  String _normalizeButtonMode(String raw) {
    final normalized = _normalizeSendBehavior(raw);
    if (normalized == 'push') {
      return 'push';
    }
    return 'switch';
  }

  List<MapEntry<String, String>> _bindingModeOptions() {
    if (_isWritableWidget) {
      return const <MapEntry<String, String>>[
        MapEntry('read_write', 'Read + Write'),
        MapEntry('read', 'Read only'),
        MapEntry('write', 'Write only'),
      ];
    }
    return const <MapEntry<String, String>>[MapEntry('read', 'Read only')];
  }

  List<MapEntry<String, String>> _dataTypeOptions() {
    return const <MapEntry<String, String>>[
      MapEntry('number', 'Number (decimal)'),
      MapEntry('integer', 'Integer'),
      MapEntry('bool', 'Boolean (0/1)'),
      MapEntry('string', 'String'),
    ];
  }

  List<MapEntry<String, String>> _sendBehaviorOptions() {
    if (_isButtonWidget) {
      return _buttonModeOptions();
    }
    if (_isSliderWidget) {
      return const <MapEntry<String, String>>[
        MapEntry('on_release', 'Send on Release'),
        MapEntry('on_drag', 'Send on Drag'),
      ];
    }
    if (_isWritableWidget) {
      return const <MapEntry<String, String>>[
        MapEntry('on_release', 'Send on Press'),
      ];
    }
    return const <MapEntry<String, String>>[];
  }

  List<MapEntry<String, String>> _buttonModeOptions() {
    return const <MapEntry<String, String>>[
      MapEntry('switch', 'Switch'),
      MapEntry('push', 'Push'),
    ];
  }

  String _labelFromOptions(
    List<MapEntry<String, String>> options,
    String current,
  ) {
    for (final option in options) {
      if (option.key == current) {
        return option.value;
      }
    }
    return current;
  }

  double _coerceByDataType(double value) {
    final effectiveDataType = _normalizeDataType(_selectedDataType);
    switch (effectiveDataType) {
      case 'bool':
        return value >= 0.5 ? 1.0 : 0.0;
      case 'integer':
        return value.roundToDouble();
      case 'number':
      case 'string':
        return value;
    }
    return value;
  }

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

  Map<String, String> _reservedBindingMap() {
    return const <String, String>{
      'V0': 'Switch Command',
      'V1': 'Switch State',
      'V2': 'Seconds',
      'V3': 'Temperature',
    };
  }

  bool _isReservedBindingKey(String key) {
    final normalized = _normalizeVPinKey(key);
    if (normalized == null) {
      return false;
    }
    return _reservedBindingMap().containsKey(normalized);
  }

  Map<String, String> _lockedCustomBindingMapForEditor() {
    final locked = <String, String>{};
    final currentCustomKey = !_isCatalogKey(_selectedBindingKey)
        ? _normalizeVPinKey(_selectedBindingKey)
        : null;
    final entries = _mergeCustomBindingCatalogs(
      _customBindingCatalog,
      _customBindingsFromItems(),
    );
    for (final entry in entries) {
      if (entry.key == currentCustomKey) {
        continue;
      }
      locked[entry.key] = entry.name;
    }
    return locked;
  }

  Future<String?> _openVPinPicker({
    required BuildContext context,
    required String currentVPin,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scale = _pickerScale(context);
        final selected = _normalizeVPinKey(currentVPin) ?? '';
        final catalogEntries = _sortedBindingCatalog();
        final customEntries = _sortedCustomBindingCatalog();
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
              child: _buildGlassSheetShell(
                radius: 22 * scale,
                blur: 18,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
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
                        'Select Data Key (V Pin)',
                        style: TextStyle(
                          color: DashboardRuntimeTheme.headlineColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15 * scale,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Flexible(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            14 * scale,
                            4 * scale,
                            14 * scale,
                            14 * scale,
                          ),
                          shrinkWrap: true,
                          children: [
                            _buildBindingPickerActionCard(
                              scale: scale,
                              icon: Icons.add_circle_outline_rounded,
                              accentColor: DashboardRuntimeTheme.buttonEndColor,
                              title:
                                  selected.isNotEmpty &&
                                      !_isCatalogKey(selected)
                                  ? 'Edit Custom Data Key'
                                  : 'Add Custom Data Key',
                              subtitle:
                                  'Define a key name, data type, range, and unit for this widget binding.',
                              onTap: () =>
                                  Navigator.of(context).pop('__custom__'),
                            ),
                            SizedBox(height: 14 * scale),
                            if (customEntries.isNotEmpty) ...[
                              _buildPickerSectionLabel(
                                label: 'Custom Keys',
                                scale: scale,
                              ),
                              for (final entry in customEntries) ...[
                                _buildBindingPickerOptionCard(
                                  scale: scale,
                                  icon: Icons.tune_rounded,
                                  iconColor: DashboardRuntimeTheme
                                      .surfaceBorderFocusColor,
                                  title: '${entry.name} (${entry.key})',
                                  details: <String>[
                                    _bindingMetaLine(
                                      dataType: entry.dataType,
                                      rangeLabel: _customBindingRangeLabel(
                                        entry,
                                      ),
                                      unit: entry.unit,
                                    ),
                                    _customBindingUsageLabel(entry.key),
                                  ],
                                  isSelected: entry.key == selected,
                                  onTap: () =>
                                      Navigator.of(context).pop(entry.key),
                                  trailing:
                                      ((_customBindingUsageCountMap()[entry
                                                  .key] ??
                                              0) ==
                                          0)
                                      ? IconButton(
                                          tooltip: 'Delete Custom Data Key',
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop('__delete__:${entry.key}'),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18 * scale,
                                            color: const Color(0xFFD95C54),
                                          ),
                                        )
                                      : (entry.key == selected
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: const Color(0xFF2E6F57),
                                                size: 20 * scale,
                                              )
                                            : Icon(
                                                Icons.lock_outline_rounded,
                                                size: 16 * scale,
                                                color: DashboardRuntimeTheme
                                                    .surfaceBorderColor,
                                              )),
                                ),
                                SizedBox(height: 10 * scale),
                              ],
                            ],
                            _buildPickerSectionLabel(
                              label: 'Starter Keys',
                              scale: scale,
                            ),
                            for (final entry in catalogEntries) ...[
                              _buildBindingPickerOptionCard(
                                scale: scale,
                                icon: _catalogIcon(entry),
                                iconColor: _isRecommendedCatalogEntry(entry)
                                    ? DashboardRuntimeTheme
                                          .surfaceBorderFocusColor
                                    : DashboardRuntimeTheme.labelTextColor,
                                title: '${entry.name} (${entry.key})',
                                details: <String>[
                                  _bindingMetaLine(
                                    dataType: entry.dataType,
                                    rangeLabel: entry.rangeLabel,
                                    unit: entry.unit,
                                  ),
                                  if (entry.description.trim().isNotEmpty)
                                    entry.description.trim(),
                                  if (_catalogUsageNote(entry) != null)
                                    _catalogUsageNote(entry)!,
                                ],
                                isSelected: entry.key == selected,
                                onTap: () =>
                                    Navigator.of(context).pop(entry.key),
                              ),
                              SizedBox(height: 10 * scale),
                            ],
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
        /*
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18 * scale, 0, 18 * scale, 14 * scale),
              child: _buildGlassSheetShell(
                radius: 22 * scale,
                blur: 18,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
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
                        'Select Data Key (V Pin)',
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
                            ListTile(
                              dense: scale < 0.95,
                              visualDensity: scale < 0.95
                                  ? const VisualDensity(vertical: -1)
                                  : VisualDensity.standard,
                              onTap: () => Navigator.of(context).pop('__custom__'),
                              leading: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: DashboardRuntimeTheme.buttonEndColor,
                                size: 18,
                              ),
                              title: Text(
                                selected.isNotEmpty && !_isCatalogKey(selected)
                                    ? 'แก้ไขคีย์ข้อมูลกำหนดเอง'
                                    : 'Add Custom Data Key',
                                style: TextStyle(
                                  color: DashboardRuntimeTheme.buttonEndColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14 * scale,
                                ),
                              ),
                              subtitle: Text(
                                'ตั้งชื่อ ประเภทข้อมูล ช่วง และหน่วยได้ตามต้องการ',
                                style: TextStyle(
                                  color: DashboardRuntimeTheme.labelTextColor,
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            for (final entry in customEntries)
                              ListTile(
                                dense: scale < 0.95,
                                visualDensity: scale < 0.95
                                    ? const VisualDensity(vertical: -1)
                                    : VisualDensity.standard,
                                onTap: () => Navigator.of(context).pop(entry.key),
                                leading: const Icon(
                                  Icons.tune_rounded,
                                  color: DashboardRuntimeTheme.surfaceBorderFocusColor,
                                  size: 18,
                                ),
                                title: Text(
                                  '${entry.name} (${entry.key})',
                                  style: TextStyle(
                                    color: entry.key == selected
                                        ? DashboardRuntimeTheme.headlineColor
                                        : DashboardRuntimeTheme.fieldTextColor,
                                    fontWeight: entry.key == selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _bindingMetaLine(
                                        dataType: entry.dataType,
                                        rangeLabel: _customBindingRangeLabel(entry),
                                        unit: entry.unit,
                                      ),
                                      style: TextStyle(
                                        color: DashboardRuntimeTheme.labelTextColor,
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _customBindingUsageLabel(
                                        entry.key,
                                      ),
                                      style: TextStyle(
                                        color: DashboardRuntimeTheme.mutedTextColor,
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ((_customBindingUsageCountMap()[entry.key] ??
                                            0) ==
                                        0)
                                    ? IconButton(
                                        tooltip: 'Delete Custom Data Key',
                                        onPressed: () => Navigator.of(context).pop(
                                          '__delete__:${entry.key}',
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Color(0xFFD95C54),
                                        ),
                                      )
                                    : (entry.key == selected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderFocusColor,
                                            )
                                          : const Icon(
                                              Icons.lock_outline_rounded,
                                              size: 16,
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderColor,
                                            )),
                              ),
                            for (final entry in catalogEntries)
                              ListTile(
                                dense: scale < 0.95,
                                visualDensity: scale < 0.95
                                    ? const VisualDensity(vertical: -1)
                                    : VisualDensity.standard,
                                onTap: () => Navigator.of(context).pop(entry.key),
                                leading: Icon(
                                  _catalogIcon(entry),
                                  color: _isRecommendedCatalogEntry(entry)
                                      ? DashboardRuntimeTheme.surfaceBorderFocusColor
                                      : DashboardRuntimeTheme.labelTextColor,
                                  size: 18,
                                ),
                                title: Text(
                                  '${entry.name} (${entry.key})',
                                  style: TextStyle(
                                    color: entry.key == selected
                                        ? DashboardRuntimeTheme.headlineColor
                                        : DashboardRuntimeTheme.fieldTextColor,
                                    fontWeight: entry.key == selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _bindingMetaLine(
                                        dataType: entry.dataType,
                                        rangeLabel: entry.rangeLabel,
                                        unit: entry.unit,
                                      ),
                                      style: TextStyle(
                                        color: DashboardRuntimeTheme.labelTextColor,
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (entry.description.trim().isNotEmpty ||
                                        _catalogUsageNote(entry) != null)
                                      Text(
                                        [
                                          if (entry.description.trim().isNotEmpty)
                                            entry.description.trim(),
                                          if (_catalogUsageNote(entry) != null)
                                            _catalogUsageNote(entry)!,
                                        ].join(' • '),
                                        style: TextStyle(
                                          color: DashboardRuntimeTheme.mutedTextColor,
                                          fontSize: 11 * scale,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: entry.key == selected
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        */
      },
    );
  }

  Future<_CustomBindingConfig?> _openCustomBindingDialog() async {
    final lockedMap = _lockedCustomBindingMapForEditor();
    final currentCustomEntry = _customBindingEntryFor(_selectedBindingKey);
    var selectedVPin =
        _normalizeVPinKey(_selectedBindingKey) ??
        currentCustomEntry?.key ??
        'V4';
    if (_isReservedBindingKey(selectedVPin) ||
        lockedMap.containsKey(selectedVPin)) {
      for (var i = 4; i <= 255; i += 1) {
        final candidate = 'V$i';
        if (!_isReservedBindingKey(candidate) &&
            !lockedMap.containsKey(candidate)) {
          selectedVPin = candidate;
          break;
        }
      }
    }
    return Navigator.of(context).push<_CustomBindingConfig>(
      MaterialPageRoute<_CustomBindingConfig>(
        builder: (context) => _CustomBindingPage(
          initialVPin: selectedVPin,
          lockedMap: lockedMap,
          initialType: currentCustomEntry?.dataType ?? _selectedDataType,
          initialName:
              currentCustomEntry?.name ??
              ((!_isCatalogKey(_selectedBindingKey) &&
                      (_selectedBindingName?.trim().isNotEmpty ?? false))
                  ? _selectedBindingName!.trim()
                  : ''),
          initialDefaultValue: currentCustomEntry?.defaultValue != null
              ? _formatBindingNumber(currentCustomEntry!.defaultValue!)
              : _valueController.text.trim(),
          initialMinValue: currentCustomEntry?.minValue != null
              ? _formatBindingNumber(currentCustomEntry!.minValue!)
              : _minValueController.text.trim(),
          initialMaxValue: currentCustomEntry?.maxValue != null
              ? _formatBindingNumber(currentCustomEntry!.maxValue!)
              : _maxValueController.text.trim(),
          initialUnit:
              currentCustomEntry?.unit ??
              (_hasSelectedBinding ? (_selectedUnit ?? '') : ''),
          isEditing: currentCustomEntry != null,
          usageCount: currentCustomEntry == null
              ? 0
              : (_customBindingUsageCountMap()[currentCustomEntry.key] ?? 0),
          dataTypeOptions: _dataTypeOptions(),
        ),
      ),
    );
  }

  double _pickerScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 390).clamp(0.86, 1.08);
  }

  Widget _buildPickerSectionLabel({
    required String label,
    required double scale,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        6 * scale,
        16 * scale,
        8 * scale,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: DashboardRuntimeTheme.labelTextColor,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBindingPickerActionCard({
    required double scale,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      decoration: AppGlassTheme.accentDecoration(
        radius: 18 * scale,
        colors: <Color>[
          Color.lerp(accentColor, Colors.white, 0.35) ?? accentColor,
          Color.lerp(accentColor, Colors.black, 0.10) ?? accentColor,
        ],
        borderColor: Colors.white.withValues(alpha: 0.65),
        glowColor: accentColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18 * scale),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 13 * scale,
            ),
            child: Row(
              children: [
                Container(
                  width: 36 * scale,
                  height: 36 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14 * scale),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13 * scale,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w500,
                          fontSize: 11 * scale,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 22 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBindingPickerOptionCard({
    required double scale,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> details,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final decoration = isSelected
        ? AppGlassTheme.accentDecoration(
            radius: 18 * scale,
            colors: const <Color>[Color(0xFFBFE4D4), Color(0xFF9FD1BB)],
            borderColor: const Color(0xFF85B89F),
            glowColor: const Color(0xFFA9D3C7),
          )
        : _glassInsetDecoration(radius: 18 * scale);

    final titleColor = isSelected
        ? const Color(0xFF123329)
        : DashboardRuntimeTheme.fieldTextColor;
    final detailColor = isSelected
        ? const Color(0xFF325246)
        : DashboardRuntimeTheme.labelTextColor;

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18 * scale),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34 * scale,
                  height: 34 * scale,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.48)
                        : Colors.white.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(14 * scale),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.55)
                          : DashboardRuntimeTheme.surfaceBorderColor.withValues(
                              alpha: 0.45,
                            ),
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 18 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w700,
                          fontSize: 13 * scale,
                        ),
                      ),
                      for (final detail in details.where(
                        (text) => text.trim().isNotEmpty,
                      )) ...[
                        SizedBox(height: 2 * scale),
                        Text(
                          detail,
                          style: TextStyle(
                            color: detailColor,
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8 * scale),
                trailing ??
                    (isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: const Color(0xFF2E6F57),
                            size: 20 * scale,
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: DashboardRuntimeTheme.mutedTextColor,
                            size: 20 * scale,
                          )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyCatalogBinding(_BindingCatalogEntry entry) {
    _selectedBindingKey = entry.key;
    _selectedBindingName = entry.name;
    _showBindingValidationError = false;
    _selectedDataType = _normalizeDataType(entry.dataType);
    _selectedUnit = entry.unit?.trim().isNotEmpty == true
        ? entry.unit!.trim()
        : null;
    if (entry.defaultValue != null) {
      _valueController.text = entry.defaultValue!.toStringAsFixed(
        entry.dataType == 'integer' || entry.dataType == 'bool' ? 0 : 2,
      );
    }
    if (entry.minValue != null) {
      _minValueController.text = entry.minValue!.toStringAsFixed(
        entry.dataType == 'integer' || entry.dataType == 'bool' ? 0 : 2,
      );
    }
    if (entry.maxValue != null) {
      _maxValueController.text = entry.maxValue!.toStringAsFixed(
        entry.dataType == 'integer' || entry.dataType == 'bool' ? 0 : 2,
      );
    }
  }

  void _applyCustomBinding(_CustomBindingConfig customResult) {
    _selectedBindingKey = customResult.dataKey.toUpperCase();
    _selectedBindingName = customResult.dataKeyLabel.trim();
    _showBindingValidationError = false;
    _selectedDataType = _normalizeDataType(customResult.dataType);
    if (customResult.unit.trim().isEmpty ||
        customResult.unit.trim().toLowerCase() == 'none') {
      _selectedUnit = null;
    } else {
      _selectedUnit = customResult.unit.trim();
    }
    if (customResult.defaultValue != null) {
      _valueController.text = customResult.defaultValue!.toStringAsFixed(
        customResult.dataType == 'integer' || customResult.dataType == 'bool'
            ? 0
            : 2,
      );
    }
    if (customResult.minValue != null) {
      _minValueController.text = customResult.minValue!.toStringAsFixed(
        customResult.dataType == 'integer' || customResult.dataType == 'bool'
            ? 0
            : 2,
      );
    }
    if (customResult.maxValue != null) {
      _maxValueController.text = customResult.maxValue!.toStringAsFixed(
        customResult.dataType == 'integer' || customResult.dataType == 'bool'
            ? 0
            : 2,
      );
    }
  }

  void _applyStoredCustomBinding(_CustomBindingCatalogEntry entry) {
    _selectedBindingKey = entry.key;
    _selectedBindingName = entry.name;
    _showBindingValidationError = false;
    _selectedDataType = _normalizeDataType(entry.dataType);
    _selectedUnit = entry.unit.trim().isEmpty ? null : entry.unit.trim();
    if (entry.defaultValue != null) {
      _valueController.text = _formatBindingNumber(entry.defaultValue!);
    }
    if (entry.minValue != null) {
      _minValueController.text = _formatBindingNumber(entry.minValue!);
    }
    if (entry.maxValue != null) {
      _maxValueController.text = _formatBindingNumber(entry.maxValue!);
    }
  }

  Future<void> _openBindingPicker() async {
    final selectedBinding = await _openVPinPicker(
      context: context,
      currentVPin: _selectedBindingKey,
    );
    if (selectedBinding == null || !mounted) {
      return;
    }
    if (selectedBinding.startsWith('__delete__:')) {
      final key = selectedBinding
          .replaceFirst('__delete__:', '')
          .trim()
          .toUpperCase();
      final entry = _customBindingEntryFor(key);
      if (entry == null) {
        return;
      }
      final confirmed = await _confirmDeleteCustomBinding(
        key: entry.key,
        name: entry.name,
      );
      if (!confirmed || !mounted) {
        return;
      }
      await _deleteCustomBindingCatalogEntry(entry.key);
      if (!mounted) {
        return;
      }
      if (_normalizeVPinKey(_selectedBindingKey) == entry.key) {
        setState(() {
          _selectedBindingKey = '';
          _selectedBindingName = null;
          _selectedUnit = null;
        });
      }
      return;
    }
    if (selectedBinding == '__custom__') {
      final customResult = await _openCustomBindingDialog();
      if (customResult == null || !mounted) {
        return;
      }
      final customEntry = _CustomBindingCatalogEntry(
        key: customResult.dataKey.toUpperCase(),
        name: customResult.dataKeyLabel.trim(),
        dataType: _normalizeDataType(customResult.dataType),
        unit: customResult.unit.trim(),
        defaultValue: customResult.defaultValue,
        minValue: customResult.minValue,
        maxValue: customResult.maxValue,
      );
      await _upsertCustomBindingCatalogEntry(customEntry);
      if (!mounted) {
        return;
      }
      setState(() {
        _applyCustomBinding(customResult);
      });
      return;
    }
    final catalogEntry = _catalogEntryFor(selectedBinding);
    if (catalogEntry != null) {
      setState(() {
        _applyCatalogBinding(catalogEntry);
      });
      return;
    }
    final customEntry = _customBindingEntryFor(selectedBinding);
    if (customEntry == null) {
      return;
    }
    setState(() {
      _applyStoredCustomBinding(customEntry);
    });
  }

  Future<void> _openOptionPicker({
    required String title,
    required List<MapEntry<String, String>> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scale = _pickerScale(context);
        final horizontalPadding = 18.0 * scale;
        final bottomPadding = 14.0 * scale;
        final headerFontSize = 15.0 * scale;
        final radius = 22.0 * scale;
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                bottomPadding,
              ),
              child: _buildGlassSheetShell(
                radius: radius,
                blur: 18,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.62,
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
                        title,
                        style: TextStyle(
                          color: DashboardRuntimeTheme.headlineColor,
                          fontWeight: FontWeight.w700,
                          fontSize: headerFontSize,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Flexible(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            for (final option in options)
                              ListTile(
                                dense: scale < 0.95,
                                visualDensity: scale < 0.95
                                    ? const VisualDensity(vertical: -1)
                                    : VisualDensity.standard,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale,
                                  vertical: 2 * scale,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    16 * scale,
                                  ),
                                ),
                                tileColor: option.key == selectedValue
                                    ? DashboardRuntimeTheme.buttonGlowColor
                                          .withValues(alpha: 0.18)
                                    : Colors.transparent,
                                onTap: () =>
                                    Navigator.of(context).pop(option.key),
                                title: Text(
                                  option.value,
                                  style: TextStyle(
                                    color: option.key == selectedValue
                                        ? DashboardRuntimeTheme.headlineColor
                                        : DashboardRuntimeTheme.fieldTextColor,
                                    fontWeight: option.key == selectedValue
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                trailing: option.key == selectedValue
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: DashboardRuntimeTheme
                                            .surfaceBorderFocusColor,
                                      )
                                    : null,
                              ),
                            SizedBox(height: 8 * scale),
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
    if (result == null) {
      return;
    }
    setState(() {
      onSelected(result);
    });
  }

  void _save() async {
    if (_bindingIsRequired && !_hasSelectedBinding) {
      if (_activePage != _WidgetSettingsPage.setting) {
        setState(() {
          _activePage = _WidgetSettingsPage.setting;
          _showBindingValidationError = true;
        });
      } else {
        setState(() {
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
    final shouldClearButtonShellColor =
        (_isButtonWidget ||
            _isValueLabelWidget ||
            _isGaugeWidget ||
            _isSliderWidget ||
            _isToggleWidget) &&
        _buttonShellColor.toARGB32() ==
            (_isValueLabelWidget
                ? _effectiveDefaultValueLabelShellColor().toARGB32()
                : _isGaugeWidget
                ? _effectiveDefaultGaugeBorderColor().toARGB32()
                : _isSliderWidget
                ? _effectiveDefaultSliderBorderColor().toARGB32()
                : _isToggleWidget
                ? _effectiveDefaultToggleBorderColor().toARGB32()
                : _effectiveDefaultButtonShellColor().toARGB32());
    final shouldClearButtonInnerColor =
        (_isButtonWidget ||
            _isValueLabelWidget ||
            _isGaugeWidget ||
            _isSliderWidget ||
            _isToggleWidget) &&
        _buttonInnerColor.toARGB32() ==
            (_isValueLabelWidget
                ? _effectiveDefaultValueLabelBackgroundColor().toARGB32()
                : _isGaugeWidget
                ? _effectiveDefaultGaugeBackgroundColor().toARGB32()
                : _isSliderWidget
                ? _effectiveDefaultSliderBackgroundColor().toARGB32()
                : _isToggleWidget
                ? _effectiveDefaultToggleBackgroundColor().toARGB32()
                : _effectiveDefaultButtonInnerColor().toARGB32());
    final shouldClearButtonBorderColor =
        !_isButtonWidget ||
        _buttonBorderColor.toARGB32() ==
            _effectiveDefaultButtonBorderColor().toARGB32();
    final shouldClearButtonBorderWidth =
        !_isButtonWidget ||
        (_buttonBorderWidth - _defaultButtonBorderWidth).abs() < 0.001;
    final shouldClearValueLabelBorderWidth =
        !_isValueLabelWidget ||
        (_valueLabelBorderWidth - _defaultValueLabelBorderWidth).abs() < 0.001;
    final shouldClearGaugeBorderWidth =
        !_isGaugeWidget ||
        (_gaugeBorderWidth - _defaultGaugeBorderWidth).abs() < 0.001;
    final shouldClearSliderBorderWidth =
        !_isSliderWidget ||
        (_sliderBorderWidth - _defaultSliderBorderWidth).abs() < 0.001;
    final shouldClearToggleBorderWidth =
        !_isToggleWidget ||
        (_toggleBorderWidth - _defaultToggleBorderWidth).abs() < 0.001;
    final shouldClearGlowColor = _glowColorLinkedToAccent;
    final shouldClearGlowStrength =
        (_glowStrength - _defaultGlowStrengthForCurrentType).abs() < 0.001;
    final shouldClearGlowBlur = (_glowBlur - _defaultGlowBlur).abs() < 0.001;

    Navigator.of(context).pop(
      WidgetSettingsResult(
        item: widget.item.copyWith(
          title: _titleController.text.trim().isEmpty
              ? widget.item.title
              : _titleController.text.trim(),
          value: nextValue,
          unit: _hasSelectedBinding ? _selectedUnit : null,
          clearUnit: !_hasSelectedBinding || _selectedUnit == null,
          dataSource: 'device_channel',
          clearDataSource: false,
          dataKey: _selectedBindingKey,
          clearDataKey: _selectedBindingKey.trim().isEmpty,
          dataKeyLabel: _selectedBindingKey.trim().isEmpty
              ? null
              : _selectedBindingName,
          clearDataKeyLabel:
              _selectedBindingKey.trim().isEmpty ||
              _selectedBindingName == null,
          bindingMode: _isBindingModeConfigurable
              ? _selectedBindingMode
              : _defaultBindingModeForType(widget.item.type),
          dataType: _selectedDataType,
          minValue:
              (_isSliderWidget ||
                  widget.item.type == DashboardItemType.gauge ||
                  widget.item.type == DashboardItemType.valueLabel)
              ? minValue
              : widget.item.minValue,
          maxValue:
              (_isSliderWidget ||
                  widget.item.type == DashboardItemType.gauge ||
                  widget.item.type == DashboardItemType.valueLabel)
              ? maxValue
              : widget.item.maxValue,
          stepValue: _isSliderWidget ? stepValue : widget.item.stepValue,
          sendBehavior: _isWritableWidget
              ? _selectedSendBehavior
              : widget.item.sendBehavior,
          accentColor: _accentColor,
          titleColor: _titleColor,
          titleFontSize: _titleFontSize,
          titlePosition: _selectedTitlePosition,
          secondaryAccentColor: (_isButtonWidget || _isToggleWidget)
              ? _secondaryAccentColor
              : null,
          clearSecondaryAccentColor: !(_isButtonWidget || _isToggleWidget),
          buttonShellColor:
              (_isButtonWidget ||
                      _isValueLabelWidget ||
                      _isGaugeWidget ||
                      _isSliderWidget ||
                      _isToggleWidget) &&
                  !shouldClearButtonShellColor
              ? _buttonShellColor
              : null,
          clearButtonShellColor:
              (!(_isButtonWidget ||
                  _isValueLabelWidget ||
                  _isGaugeWidget ||
                  _isSliderWidget ||
                  _isToggleWidget)) ||
              shouldClearButtonShellColor,
          buttonInnerColor:
              (_isButtonWidget ||
                      _isValueLabelWidget ||
                      _isGaugeWidget ||
                      _isSliderWidget ||
                      _isToggleWidget) &&
                  !shouldClearButtonInnerColor
              ? _buttonInnerColor
              : null,
          clearButtonInnerColor:
              (!(_isButtonWidget ||
                  _isValueLabelWidget ||
                  _isGaugeWidget ||
                  _isSliderWidget ||
                  _isToggleWidget)) ||
              shouldClearButtonInnerColor,
          buttonBorderColor: _isButtonWidget && !shouldClearButtonBorderColor
              ? _buttonBorderColor
              : null,
          clearButtonBorderColor: shouldClearButtonBorderColor,
          buttonBorderWidth: _isButtonWidget && !shouldClearButtonBorderWidth
              ? _buttonBorderWidth
              : null,
          clearButtonBorderWidth: shouldClearButtonBorderWidth,
          valueLabelBorderWidth:
              _isValueLabelWidget && !shouldClearValueLabelBorderWidth
              ? _valueLabelBorderWidth
              : null,
          clearValueLabelBorderWidth: shouldClearValueLabelBorderWidth,
          gaugeBorderWidth: _isGaugeWidget && !shouldClearGaugeBorderWidth
              ? _gaugeBorderWidth
              : null,
          clearGaugeBorderWidth: shouldClearGaugeBorderWidth,
          sliderBorderWidth: _isSliderWidget && !shouldClearSliderBorderWidth
              ? _sliderBorderWidth
              : null,
          clearSliderBorderWidth: shouldClearSliderBorderWidth,
          toggleBorderWidth: _isToggleWidget && !shouldClearToggleBorderWidth
              ? _toggleBorderWidth
              : null,
          clearToggleBorderWidth: shouldClearToggleBorderWidth,
          glowColor: !shouldClearGlowColor ? _glowColor : null,
          clearGlowColor: shouldClearGlowColor,
          glowStrength: !shouldClearGlowStrength ? _glowStrength : null,
          clearGlowStrength: shouldClearGlowStrength,
          glowBlur: !shouldClearGlowBlur ? _glowBlur : null,
          clearGlowBlur: shouldClearGlowBlur,
          enabled: _isButtonWidget ? _buttonEnabled : widget.item.enabled,
        ),
      ),
    );
  }

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
                        const _SettingsLabel('Hex Color'),
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
                                  'Cancel',
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
                                  'Apply',
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

    setState(() {
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

  Widget _buildFieldShell({required Widget child, bool focused = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: _glassInsetDecoration(
        radius: 16,
        color: focused
            ? DashboardRuntimeTheme.cardHighlightColor.withValues(alpha: 0.82)
            : DashboardRuntimeTheme.surfaceColor,
      ),
      child: child,
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

  Widget _buildBottomActionBar() {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1.0).clamp(1.0, 1.25);
    final isNarrow = media.size.width < 360 || textScale > 1.12;
    final horizontalPadding = media.size.width < 360 ? 12.0 : 14.0;
    final buttonHeight = (48.0 * textScale).clamp(46.0, 56.0).toDouble();
    final buttonFontSize = (15.0 * textScale).clamp(14.0, 17.0).toDouble();

    Widget buildButton({
      required VoidCallback onPressed,
      required BoxDecoration decoration,
      required String label,
      Color foregroundColor = Colors.white,
    }) {
      return DecoratedBox(
        decoration: decoration,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: foregroundColor,
            minimumSize: Size.fromHeight(buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: buttonFontSize,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        media.padding.bottom > 0 ? 12 : 14,
      ),
      decoration: _glassSheetDecoration(
        radius: 24,
        tint: DashboardRuntimeTheme.cardColor,
        opacity: 0.92,
        elevated: false,
      ),
      child: isNarrow
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: buildButton(
                    onPressed: _save,
                    decoration: AppGlassTheme.accentDecoration(
                      radius: 16,
                      colors: const <Color>[
                        Color(0xFF7EBFAF),
                        Color(0xFF5E9E8B),
                      ],
                      borderColor: const Color(0xFF6AA796),
                      glowColor: const Color(0xFFA9D3C7),
                    ),
                    label: 'Save',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: buildButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const WidgetSettingsResult(remove: true)),
                    decoration: AppGlassTheme.accentDecoration(
                      radius: 16,
                      colors: const <Color>[
                        Color(0xFFEA7A70),
                        Color(0xFFD95C54),
                      ],
                      borderColor: const Color(0xFFC96868),
                      glowColor: const Color(0xFFE08A82),
                    ),
                    foregroundColor: const Color(0xFFFFFBFB),
                    label: 'Remove',
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: buildButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const WidgetSettingsResult(remove: true)),
                    decoration: AppGlassTheme.accentDecoration(
                      radius: 16,
                      colors: const <Color>[
                        Color(0xFFEA7A70),
                        Color(0xFFD95C54),
                      ],
                      borderColor: const Color(0xFFC96868),
                      glowColor: const Color(0xFFE08A82),
                    ),
                    foregroundColor: const Color(0xFFFFFBFB),
                    label: 'Remove',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildButton(
                    onPressed: _save,
                    decoration: AppGlassTheme.accentDecoration(
                      radius: 16,
                      colors: const <Color>[
                        Color(0xFF7EBFAF),
                        Color(0xFF5E9E8B),
                      ],
                      borderColor: const Color(0xFF6AA796),
                      glowColor: const Color(0xFFA9D3C7),
                    ),
                    label: 'Save',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPageSwitch() {
    Widget buildTab({
      required _WidgetSettingsPage page,
      required String label,
      required IconData icon,
    }) {
      final isActive = _activePage == page;
      final activeGradient = page == _WidgetSettingsPage.setting
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7EBFAF), Color(0xFF5E9E8B)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD7B37A), Color(0xFFB88951)],
            );
      final activeBorderColor = page == _WidgetSettingsPage.setting
          ? const Color(0xFF6AA796)
          : const Color(0xFFC69861);
      final activeGlowColor = page == _WidgetSettingsPage.setting
          ? const Color(0xFFA9D3C7)
          : const Color(0xFFE4C796);
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _activePage = page;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: isActive
                ? AppGlassTheme.accentDecoration(
                    radius: 12,
                    colors: activeGradient.colors,
                    borderColor: activeBorderColor,
                    glowColor: activeGlowColor,
                  )
                : _glassInsetDecoration(radius: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? Colors.white
                      : DashboardRuntimeTheme.mutedTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : DashboardRuntimeTheme.mutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          buildTab(
            page: _WidgetSettingsPage.setting,
            label: 'Content',
            icon: Icons.settings_outlined,
          ),
          const SizedBox(width: 6),
          buildTab(
            page: _WidgetSettingsPage.design,
            label: 'Design',
            icon: Icons.palette_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildColorStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsLabel('Color Style'),
        const SizedBox(height: 10),
        if (_isButtonWidget)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'ON State',
                      badge: 'ON',
                      label: 'ON color',
                      color: _accentColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom ON Color',
                        initialColor: _accentColor,
                        onColorPicked: (color) {
                          _accentColor = color;
                          if (_buttonBorderLinkedToState) {
                            _buttonBorderColor =
                                _effectiveDefaultButtonBorderColor();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorTile(
                      title: 'OFF State',
                      badge: 'OFF',
                      label: 'OFF color',
                      color: _secondaryAccentColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom OFF Color',
                        initialColor: _secondaryAccentColor,
                        onColorPicked: (color) {
                          _secondaryAccentColor = color;
                          if (_buttonBorderLinkedToState) {
                            _buttonBorderColor =
                                _effectiveDefaultButtonBorderColor();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Outer Surface',
                      badge: 'BG',
                      label: 'Outer background',
                      color: _buttonShellColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Shell Background',
                        initialColor: _buttonShellColor,
                        onColorPicked: (color) => _buttonShellColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorTile(
                      title: 'Inner Surface',
                      badge: 'CORE',
                      label: 'Inner background',
                      color: _buttonInnerColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Inner Background',
                        initialColor: _buttonInnerColor,
                        onColorPicked: (color) => _buttonInnerColor = color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Border',
                      badge: 'LINE',
                      label: 'Border color',
                      color: _buttonBorderColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Button Border',
                        initialColor: _buttonBorderColor,
                        onColorPicked: (color) {
                          _buttonBorderColor = color;
                          _buttonBorderLinkedToState =
                              color.toARGB32() ==
                              _effectiveDefaultButtonBorderColor().toARGB32();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          )
        else if (_isSliderWidget)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Slider',
                      badge: 'MAIN',
                      label: 'Slider color',
                      color: _accentColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Slider Color',
                        initialColor: _accentColor,
                        onColorPicked: (color) => _accentColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorTile(
                      title: 'Background',
                      badge: 'BG',
                      label: 'Background color',
                      color: _buttonInnerColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Slider Background',
                        initialColor: _buttonInnerColor,
                        onColorPicked: (color) => _buttonInnerColor = color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Border',
                      badge: 'LINE',
                      label: 'Border color',
                      color: _buttonShellColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Slider Border',
                        initialColor: _buttonShellColor,
                        onColorPicked: (color) => _buttonShellColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          )
        else if (_isToggleWidget)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'ON',
                      badge: 'ON',
                      label: 'On color',
                      color: _accentColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Toggle ON Color',
                        initialColor: _accentColor,
                        onColorPicked: (color) => _accentColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorTile(
                      title: 'OFF',
                      badge: 'OFF',
                      label: 'Off color',
                      color: _secondaryAccentColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Toggle OFF Color',
                        initialColor: _secondaryAccentColor,
                        onColorPicked: (color) => _secondaryAccentColor = color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Background',
                      badge: 'BG',
                      label: 'Background color',
                      color: _buttonInnerColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Toggle Background',
                        initialColor: _buttonInnerColor,
                        onColorPicked: (color) => _buttonInnerColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorTile(
                      title: 'Border',
                      badge: 'LINE',
                      label: 'Border color',
                      color: _buttonShellColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Toggle Border',
                        initialColor: _buttonShellColor,
                        onColorPicked: (color) => _buttonShellColor = color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Border',
                      badge: 'LINE',
                      label: 'Border color',
                      color: _buttonBorderColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Button Border',
                        initialColor: _buttonBorderColor,
                        onColorPicked: (color) => _buttonBorderColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          )
        else if (_isValueLabelWidget)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Value Text',
                      badge: 'TEXT',
                      label: 'Text color',
                      color: _accentColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Value Text Color',
                        initialColor: _accentColor,
                        onColorPicked: (color) {
                          _accentColor = color;
                          if (_valueLabelBorderLinkedToText) {
                            _buttonShellColor = color;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorTile(
                      title: 'Background',
                      badge: 'BG',
                      label: 'Background color',
                      color: _buttonInnerColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Value Label Background',
                        initialColor: _buttonInnerColor,
                        onColorPicked: (color) => _buttonInnerColor = color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Border',
                      badge: 'LINE',
                      label: 'Border color',
                      color: _buttonShellColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Value Label Border',
                        initialColor: _buttonShellColor,
                        onColorPicked: (color) {
                          _buttonShellColor = color;
                          _valueLabelBorderLinkedToText =
                              color.toARGB32() == _accentColor.toARGB32();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          )
        else if (_isGaugeWidget)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Gauge',
                      badge: 'ARC',
                      label: 'Gauge/value color',
                      color: _accentColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Gauge Color',
                        initialColor: _accentColor,
                        onColorPicked: (color) => _accentColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorTile(
                      title: 'Background',
                      badge: 'BG',
                      label: 'Background color',
                      color: _buttonInnerColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Gauge Background',
                        initialColor: _buttonInnerColor,
                        onColorPicked: (color) => _buttonInnerColor = color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Border',
                      badge: 'LINE',
                      label: 'Border color',
                      color: _buttonShellColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Gauge Border',
                        initialColor: _buttonShellColor,
                        onColorPicked: (color) => _buttonShellColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          )
        else
          _buildColorTile(
            title: 'Accent',
            badge: 'MAIN',
            label: 'Accent color',
            color: _accentColor,
            onTap: () => _openColorPicker(
              title: 'Custom Accent Color',
              initialColor: _accentColor,
              onColorPicked: (color) => _accentColor = color,
            ),
          ),
      ],
    );
  }

  Widget _buildBorderWidthSection() {
    if (_isButtonWidget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsLabel('Border Width'),
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
                        '${_buttonBorderWidth.toStringAsFixed(1)}px',
                        style: TextStyle(
                          color:
                              Color.lerp(
                                _buttonBorderColor,
                                Colors.white,
                                0.16,
                              ) ??
                              _buttonBorderColor,
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
                      activeTrackColor: _buttonBorderColor,
                      thumbColor: _buttonBorderColor,
                    ),
                    child: Slider(
                      value: _buttonBorderWidth,
                      min: _minValueLabelBorderWidth,
                      max: _maxValueLabelBorderWidth,
                      divisions: _valueLabelBorderWidthDivisions,
                      onChanged: (value) {
                        setState(() {
                          _buttonBorderWidth = value;
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

    if (_isSliderWidget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsLabel('Border Width'),
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
                        '${_sliderBorderWidth.toStringAsFixed(1)}px',
                        style: TextStyle(
                          color:
                              Color.lerp(
                                _buttonShellColor,
                                Colors.white,
                                0.16,
                              ) ??
                              _buttonShellColor,
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
                      activeTrackColor: _buttonShellColor,
                      thumbColor: _buttonShellColor,
                    ),
                    child: Slider(
                      value: _sliderBorderWidth,
                      min: _minValueLabelBorderWidth,
                      max: _maxValueLabelBorderWidth,
                      divisions: _valueLabelBorderWidthDivisions,
                      onChanged: (value) {
                        setState(() {
                          _sliderBorderWidth = value;
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

    if (_isToggleWidget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsLabel('Border Width'),
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
                        '${_toggleBorderWidth.toStringAsFixed(1)}px',
                        style: TextStyle(
                          color:
                              Color.lerp(
                                _buttonShellColor,
                                Colors.white,
                                0.16,
                              ) ??
                              _buttonShellColor,
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
                      activeTrackColor: _buttonShellColor,
                      thumbColor: _buttonShellColor,
                    ),
                    child: Slider(
                      value: _toggleBorderWidth,
                      min: _minValueLabelBorderWidth,
                      max: _maxValueLabelBorderWidth,
                      divisions: _valueLabelBorderWidthDivisions,
                      onChanged: (value) {
                        setState(() {
                          _toggleBorderWidth = value;
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

    if (_isValueLabelWidget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsLabel('Border Width'),
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
                        '${_valueLabelBorderWidth.toStringAsFixed(1)}px',
                        style: TextStyle(
                          color:
                              Color.lerp(
                                _buttonShellColor,
                                Colors.white,
                                0.16,
                              ) ??
                              _buttonShellColor,
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
                      activeTrackColor: _buttonShellColor,
                      thumbColor: _buttonShellColor,
                    ),
                    child: Slider(
                      value: _valueLabelBorderWidth,
                      min: _minValueLabelBorderWidth,
                      max: _maxValueLabelBorderWidth,
                      divisions: _valueLabelBorderWidthDivisions,
                      onChanged: (value) {
                        setState(() {
                          _valueLabelBorderWidth = value;
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

    if (_isGaugeWidget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsLabel('Border Width'),
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
                        '${_gaugeBorderWidth.toStringAsFixed(1)}px',
                        style: TextStyle(
                          color:
                              Color.lerp(_accentColor, Colors.white, 0.16) ??
                              _accentColor,
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
                      activeTrackColor: _accentColor,
                      thumbColor: _accentColor,
                    ),
                    child: Slider(
                      value: _gaugeBorderWidth,
                      min: _minValueLabelBorderWidth,
                      max: _maxValueLabelBorderWidth,
                      divisions: _valueLabelBorderWidthDivisions,
                      onChanged: (value) {
                        setState(() {
                          _gaugeBorderWidth = value;
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

    return const SizedBox.shrink();
  }

  Widget _buildGlowSection() {
    final glowColor = _effectiveGlowColor;
    final strengthPercent = ((_glowStrength / _maxGlowStrength) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsLabel('Glow'),
        const SizedBox(height: 10),
        _buildFieldShell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildColorTile(
                        title: 'Glow Color',
                        badge: _glowColorLinkedToAccent ? 'AUTO' : 'GLOW',
                        label: _glowColorLinkedToAccent
                            ? 'Auto from main color'
                            : 'Custom glow',
                        color: glowColor,
                        onTap: () => _openColorPicker(
                          title: 'Custom Glow Color',
                          initialColor: glowColor,
                          onColorPicked: (color) {
                            _glowColorLinkedToAccent = false;
                            _glowColor = color;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mode',
                            style: TextStyle(
                              color: DashboardRuntimeTheme.labelTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _glowColorLinkedToAccent = true;
                              });
                            },
                            icon: Icon(
                              _glowColorLinkedToAccent
                                  ? Icons.check_circle_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _glowColorLinkedToAccent ? 'Auto' : 'Use Auto',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: glowColor,
                              side: BorderSide(
                                color: glowColor.withValues(alpha: 0.44),
                              ),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildGlowSlider(
                  label: 'Strength',
                  valueLabel: '$strengthPercent%',
                  value: _glowStrength,
                  min: _minGlowStrength,
                  max: _maxGlowStrength,
                  divisions: _glowStrengthDivisions,
                  minLabel: '0%',
                  maxLabel: '100%',
                  activeColor: glowColor,
                  onChanged: (value) {
                    setState(() {
                      _glowStrength = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildGlowSlider(
                  label: 'Softness',
                  valueLabel: '${_glowBlur.toStringAsFixed(0)}px',
                  value: _glowBlur,
                  min: _minGlowBlur,
                  max: _maxGlowBlur,
                  divisions: _glowBlurDivisions,
                  minLabel: '0px',
                  maxLabel: '40px',
                  activeColor: glowColor,
                  onChanged: (value) {
                    setState(() {
                      _glowBlur = value;
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

  Widget _buildTitleSection({
    required bool includeStyle,
    required bool includeTitleField,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeTitleField) ...[
          const _SettingsLabel('Widget Title'),
          const SizedBox(height: 8),
          _buildFieldShell(
            focused: _titleFocusNode.hasFocus,
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              maxLines: 1,
              style: const TextStyle(
                color: DashboardRuntimeTheme.fieldTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration:
                  _fieldDecoration(
                    hint: 'ตั้งชื่อวิดเจ็ตของคุณ',
                    prefixIcon: Icons.title_rounded,
                  ).copyWith(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 18,
                    ),
                  ),
            ),
          ),
        ],
        if (includeStyle) ...[
          const SizedBox(height: 12),
          _buildColorStyleSection(),
          const SizedBox(height: 12),
          _buildBorderWidthSection(),
          const SizedBox(height: 12),
          _buildGlowSection(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompactWidth = constraints.maxWidth < 360;

              if (isCompactWidth) {
                return Column(
                  children: [
                    _buildColorTile(
                      title: 'Title Color',
                      badge: 'TEXT',
                      label: 'Text color',
                      color: _titleColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Title Color',
                        initialColor: _titleColor,
                        onColorPicked: (color) => _titleColor = color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTitleSizeControl(compact: true),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildColorTile(
                      title: 'Title Color',
                      badge: 'TEXT',
                      label: 'Text color',
                      color: _titleColor,
                      onTap: () => _openColorPicker(
                        title: 'Custom Title Color',
                        initialColor: _titleColor,
                        onColorPicked: (color) => _titleColor = color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTitleSizeControl(compact: true)),
                ],
              );
            },
          ),
        ],
      ],
    );

    if (!includeStyle) {
      return content;
    }

    return DecoratedBox(
      decoration: _glassSheetDecoration(
        radius: 18,
        opacity: 0.74,
        elevated: false,
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: content),
    );
  }

  Widget _buildTitleSizeControl({bool compact = false}) {
    final fontSize = _titleFontSize.round();

    return Container(
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, compact ? 6 : 8),
      decoration: DashboardRuntimeTheme.insetSurfaceDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Title size',
                style: TextStyle(
                  color: DashboardRuntimeTheme.headlineColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${fontSize}px',
                style: TextStyle(
                  color: Color.lerp(_titleColor, Colors.white, 0.16),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              inactiveTrackColor: DashboardRuntimeTheme.surfaceBorderColor,
              activeTrackColor: _titleColor,
              thumbColor: _titleColor,
            ),
            child: Slider(
              value: _titleFontSize,
              min: _minTitleFontSize,
              max: _maxTitleFontSize,
              divisions: _titleFontDivisions,
              onChanged: (value) {
                setState(() {
                  _titleFontSize = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(
                  '${_minTitleFontSize.round()}px',
                  style: const TextStyle(
                    color: DashboardRuntimeTheme.mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Range',
                  style: const TextStyle(
                    color: DashboardRuntimeTheme.mutedTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_maxTitleFontSize.round()}px',
                  style: const TextStyle(
                    color: DashboardRuntimeTheme.mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonModeSelector() {
    final options = _buttonModeOptions();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: DashboardRuntimeTheme.insetSurfaceDecoration(radius: 14),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i += 1) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedSendBehavior = options[i].key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  // Use distinct soft tones so Switch and Push feel different while
                  // staying within the app's muted neumorphic palette.
                  decoration: (() {
                    final isSelected = _selectedSendBehavior == options[i].key;
                    final isSwitch = options[i].key == 'switch';
                    final activeGradient = isSwitch
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF7CAED6), Color(0xFF5F8FBC)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFC89ACD), Color(0xFFA977B3)],
                          );
                    final activeGlow = isSwitch
                        ? const Color(0xFFAFCDE5)
                        : const Color(0xFFDDB8E1);
                    return BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: isSelected ? activeGradient : null,
                      color: isSelected
                          ? null
                          : DashboardRuntimeTheme.surfaceColor,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: activeGlow.withValues(alpha: 0.24),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    );
                  })(),
                  alignment: Alignment.center,
                  child: Text(
                    options[i].value,
                    style: TextStyle(
                      color: _selectedSendBehavior == options[i].key
                          ? Colors.white
                          : DashboardRuntimeTheme.mutedTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return _glassFormInputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        prefixIcon,
        size: 16,
        color: DashboardRuntimeTheme.labelTextColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.viewInsets.bottom;
    final textScale = media.textScaler.scale(1.0).clamp(1.0, 1.25);
    final isFullscreen = widget.isFullscreen;
    final topPadding = isFullscreen
        ? 0.0
        : (media.size.height * 0.12).clamp(52.0, 112.0).toDouble();
    final sheetHorizontalPadding = media.size.width < 360 ? 14.0 : 18.0;
    final sheetTopPadding = media.size.width < 360 ? 10.0 : 12.0;
    final footerHeight = (86.0 + ((textScale - 1.0) * 28.0))
        .clamp(86.0, 114.0)
        .toDouble();
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: inset),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: isFullscreen
                ? BorderRadius.zero
                : const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FBFF),
                DashboardRuntimeTheme.backgroundColor,
              ],
            ),
            boxShadow: isFullscreen
                ? const <BoxShadow>[]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x20677E92),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
          ),
          child: SafeArea(
            top: isFullscreen,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    sheetHorizontalPadding,
                    sheetTopPadding,
                    sheetHorizontalPadding,
                    footerHeight,
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (!isFullscreen)
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: DashboardRuntimeTheme
                                        .surfaceBorderColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildGlassControlShell(
                                radius: 999,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  tooltip: 'Close',
                                  iconSize: 18,
                                  splashRadius: 18,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 36,
                                    height: 36,
                                  ),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: DashboardRuntimeTheme.mutedTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Column(
                            children: [
                              _buildMiniWidgetPreview(),
                              const SizedBox(height: 12),
                              DecoratedBox(
                                decoration: _glassInsetDecoration(radius: 999),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    _widgetTypeLabel(widget.item.type),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          DashboardRuntimeTheme.labelTextColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Widget Settings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: DashboardRuntimeTheme.headlineColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (_widgetSettingsSubtitle.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _widgetSettingsSubtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: DashboardRuntimeTheme.mutedTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPageSwitch(),
                        const SizedBox(height: 14),
                        if (_activePage == _WidgetSettingsPage.setting) ...[
                          _buildTitleSection(
                            includeStyle: false,
                            includeTitleField: true,
                          ),
                          const SizedBox(height: 14),
                          const _SettingsLabel('Data Key (V Pin)'),
                          const SizedBox(height: 8),
                          KeyedSubtree(
                            key: _bindingFieldKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldShell(
                                  focused:
                                      _showBindingValidationError &&
                                      !_hasSelectedBinding,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _openBindingPicker,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.hub_outlined,
                                            size: 15,
                                            color:
                                                _showBindingValidationError &&
                                                    !_hasSelectedBinding
                                                ? const Color(0xFFCC5A4E)
                                                : DashboardRuntimeTheme
                                                      .labelTextColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _bindingLabelFor(
                                                    _selectedBindingKey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: DashboardRuntimeTheme
                                                        .fieldTextColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _bindingSubtitleFor(
                                                    _selectedBindingKey,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: DashboardRuntimeTheme
                                                        .labelTextColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                if (_bindingAssistiveMessage != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _bindingAssistiveMessage!,
                                    style: TextStyle(
                                      color: _bindingAssistiveColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_isButtonWidget) ...[
                            const _SettingsLabel('Button Mode'),
                            const SizedBox(height: 8),
                            _buildButtonModeSelector(),
                            const SizedBox(height: 14),
                          ],
                          if (_isSliderWidget) ...[
                            const _SettingsLabel('Range'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFieldShell(
                                    child: TextField(
                                      controller: _minValueController,
                                      style: const TextStyle(
                                        color: DashboardRuntimeTheme
                                            .fieldTextColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: _fieldDecoration(
                                        hint: 'Min',
                                        prefixIcon: Icons.south_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildFieldShell(
                                    child: TextField(
                                      controller: _maxValueController,
                                      style: const TextStyle(
                                        color: DashboardRuntimeTheme
                                            .fieldTextColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: _fieldDecoration(
                                        hint: 'Max',
                                        prefixIcon: Icons.north_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const _SettingsLabel('Step'),
                            const SizedBox(height: 8),
                            _buildFieldShell(
                              child: TextField(
                                controller: _stepController,
                                style: const TextStyle(
                                  color: DashboardRuntimeTheme.fieldTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _fieldDecoration(
                                  hint: 'Step value',
                                  prefixIcon: Icons.straighten_rounded,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const _SettingsLabel('Unit'),
                          const SizedBox(height: 8),
                          _buildFieldShell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.straighten_rounded,
                                    size: 15,
                                    color: DashboardRuntimeTheme.mutedTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _displayUnit(_selectedUnit),
                                      style: const TextStyle(
                                        color: DashboardRuntimeTheme
                                            .mutedTextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: DashboardRuntimeTheme
                                        .surfaceBorderColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildTitleSection(
                            includeStyle: true,
                            includeTitleField: false,
                          ),
                          const SizedBox(height: 14),
                          const _SettingsLabel('Title Position'),
                          const SizedBox(height: 8),
                          _buildFieldShell(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openOptionPicker(
                                title: 'Title Position',
                                options: _titlePositionOptions(),
                                selectedValue: _selectedTitlePosition,
                                onSelected: (value) {
                                  _selectedTitlePosition = value;
                                },
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.open_with_rounded,
                                      size: 15,
                                      color:
                                          DashboardRuntimeTheme.labelTextColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _labelFromOptions(
                                          _titlePositionOptions(),
                                          _selectedTitlePosition,
                                        ),
                                        style: const TextStyle(
                                          color: DashboardRuntimeTheme
                                              .fieldTextColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color:
                                          DashboardRuntimeTheme.mutedTextColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildBottomActionBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: DashboardRuntimeTheme.headlineColor,
        letterSpacing: -0.1,
      ),
    );
  }
}

class _CustomBindingPage extends StatefulWidget {
  const _CustomBindingPage({
    required this.initialVPin,
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

  final String initialVPin;
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
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _defaultFieldKey = GlobalKey();
  final GlobalKey _minFieldKey = GlobalKey();
  final GlobalKey _maxFieldKey = GlobalKey();
  late final TextEditingController _nameController;
  late final TextEditingController _defaultController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _defaultFocusNode = FocusNode();
  final FocusNode _minFocusNode = FocusNode();
  final FocusNode _maxFocusNode = FocusNode();
  late String _selectedVPin;
  late String _selectedType;
  String _selectedUnit = 'None';

  @override
  void initState() {
    super.initState();
    _selectedVPin = widget.initialVPin;
    _selectedType = widget.initialType;
    _nameController = TextEditingController(text: widget.initialName);
    _defaultController = TextEditingController(
      text: widget.initialDefaultValue,
    );
    _minController = TextEditingController(text: widget.initialMinValue);
    _maxController = TextEditingController(text: widget.initialMaxValue);
    _selectedUnit = widget.initialUnit.trim().isEmpty
        ? 'None'
        : widget.initialUnit.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _defaultController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _nameFocusNode.dispose();
    _defaultFocusNode.dispose();
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
    super.dispose();
  }

  List<String> _unitOptionsForType() {
    final options = switch (_selectedType) {
      'bool' || 'string' => <String>['None'],
      _ => <String>[
        'None',
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

  bool _isLockedVPin(String vpin) {
    return _starterVPins.contains(vpin) ||
        (widget.lockedMap.containsKey(vpin) && _selectedVPin != vpin);
  }

  String? _lockedVPinReason(String vpin) {
    if (_starterVPins.contains(vpin)) {
      return '$vpin - Starter Data Key';
    }
    final label = widget.lockedMap[vpin]?.trim();
    if (label == null || label.isEmpty) {
      return null;
    }
    return '$vpin - $label';
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

  double _pickerScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 390).clamp(0.86, 1.08);
  }

  Future<void> _openCustomVPinPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scale = _pickerScale(context);
        final allVPins = <String>[for (var i = 0; i <= 255; i += 1) 'V$i'];
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
              child: _buildGlassSheetShell(
                radius: 22 * scale,
                blur: 18,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
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
                        'Select Data Key (VPin)',
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
                            for (final vpin in allVPins)
                              ListTile(
                                dense: scale < 0.95,
                                visualDensity: scale < 0.95
                                    ? const VisualDensity(vertical: -1)
                                    : VisualDensity.standard,
                                enabled: !_isLockedVPin(vpin),
                                onTap: _isLockedVPin(vpin)
                                    ? null
                                    : () => Navigator.of(context).pop(vpin),
                                title: Text(
                                  _lockedVPinReason(vpin) ?? vpin,
                                  style: TextStyle(
                                    color: _isLockedVPin(vpin)
                                        ? DashboardRuntimeTheme.mutedTextColor
                                        : (_selectedVPin == vpin
                                              ? DashboardRuntimeTheme
                                                    .headlineColor
                                              : DashboardRuntimeTheme
                                                    .fieldTextColor),
                                    fontWeight: _selectedVPin == vpin
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                trailing: _isLockedVPin(vpin)
                                    ? const Icon(
                                        Icons.lock_rounded,
                                        size: 16,
                                        color: DashboardRuntimeTheme
                                            .mutedTextColor,
                                      )
                                    : (_selectedVPin == vpin
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: DashboardRuntimeTheme
                                                  .surfaceBorderFocusColor,
                                            )
                                          : null),
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

    setState(() {
      _selectedVPin = result;
    });
  }

  Future<void> _openCustomTypePicker() async {
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
              child: DecoratedBox(
                decoration: DashboardRuntimeTheme.cardDecoration(
                  radius: 22 * scale,
                  color: DashboardRuntimeTheme.cardColor,
                ),
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
                        'Select Type',
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
                            for (final entry in widget.dataTypeOptions)
                              ListTile(
                                dense: scale < 0.95,
                                visualDensity: scale < 0.95
                                    ? const VisualDensity(vertical: -1)
                                    : VisualDensity.standard,
                                onTap: () =>
                                    Navigator.of(context).pop(entry.key),
                                title: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: entry.key == _selectedType
                                        ? DashboardRuntimeTheme.headlineColor
                                        : DashboardRuntimeTheme.fieldTextColor,
                                    fontWeight: entry.key == _selectedType
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                trailing: entry.key == _selectedType
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

    setState(() {
      _selectedType = result;
      if (_selectedType == 'bool' || _selectedType == 'string') {
        _selectedUnit = 'None';
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
              child: DecoratedBox(
                decoration: DashboardRuntimeTheme.cardDecoration(
                  radius: 22 * scale,
                  color: DashboardRuntimeTheme.cardColor,
                ),
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
                        'Select Unit',
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

    setState(() {
      _selectedUnit = result;
    });
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
        dataKey: _selectedVPin,
        dataKeyLabel: _nameController.text.trim(),
        dataType: _selectedType,
        minValue: minValue,
        maxValue: maxValue,
        defaultValue: defaultValue,
        unit: _selectedUnit == 'None' ? '' : _selectedUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allVPins = <String>[for (var i = 0; i <= 255; i += 1) 'V$i'];
    final selectableVPins = allVPins
        .where((vpin) => !_isLockedVPin(vpin))
        .toList();

    if (!selectableVPins.contains(_selectedVPin) &&
        selectableVPins.isNotEmpty) {
      _selectedVPin = selectableVPins.first;
    }

    const strongerLabelStyle = TextStyle(
      color: DashboardRuntimeTheme.headlineColor,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: DashboardRuntimeTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: DashboardRuntimeTheme.backgroundColor,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Edit Custom Data Key' : 'Add Custom Data Key',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildGlassSheetShell(
                radius: 26,
                blur: 20,
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
                            decoration: _glassInsetDecoration(radius: 14),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: DashboardRuntimeTheme.labelTextColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _usageLabel,
                                    style: const TextStyle(
                                      color:
                                          DashboardRuntimeTheme.fieldTextColor,
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _openCustomVPinPicker,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data Key (คีย์ข้อมูล)',
                                labelStyle: strongerLabelStyle,
                                filled: true,
                                fillColor: DashboardRuntimeTheme.surfaceColor,
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
                                      _selectedVPin,
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
                                    color: DashboardRuntimeTheme.mutedTextColor,
                                  ),
                                ],
                              ),
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
                                labelText: 'Type (ประเภทข้อมูล)',
                                labelStyle: strongerLabelStyle,
                                filled: true,
                                fillColor: DashboardRuntimeTheme.surfaceColor,
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
                                                entry.key == _selectedType,
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
                                    color: DashboardRuntimeTheme.mutedTextColor,
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
                                color: DashboardRuntimeTheme.fieldTextColor,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Name (ตั้งชื่อของคีย์ข้อมูล)',
                                hintText: 'ยกตัวอย่างเช่น knob_value',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                labelStyle: strongerLabelStyle,
                                hintStyle: TextStyle(
                                  color: DashboardRuntimeTheme.mutedTextColor,
                                ),
                                filled: true,
                                fillColor: DashboardRuntimeTheme.surfaceColor,
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
                                color: DashboardRuntimeTheme.fieldTextColor,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Default Value (ค่าเริ่มต้น)',
                                labelStyle: strongerLabelStyle,
                                filled: true,
                                fillColor: DashboardRuntimeTheme.surfaceColor,
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
                                  color: DashboardRuntimeTheme.fieldTextColor,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Min Value (ค่าต่ำสุด)',
                                  labelStyle: strongerLabelStyle,
                                  filled: true,
                                  fillColor: DashboardRuntimeTheme.surfaceColor,
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
                                    _validateMinMaxValue(value, 'min'),
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
                                  color: DashboardRuntimeTheme.fieldTextColor,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Max Value (ค่าสูงสุด)',
                                  labelStyle: strongerLabelStyle,
                                  filled: true,
                                  fillColor: DashboardRuntimeTheme.surfaceColor,
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
                                    _validateMinMaxValue(value, 'max'),
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
                                labelText: 'Unit (ระบุหรือไม่ก็ได้)',
                                labelStyle: strongerLabelStyle,
                                hintText: 'e.g. %, C, ppm',
                                hintStyle: TextStyle(
                                  color: DashboardRuntimeTheme.mutedTextColor,
                                ),
                                filled: true,
                                fillColor: DashboardRuntimeTheme.surfaceColor,
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
                                        ? DashboardRuntimeTheme.mutedTextColor
                                        : DashboardRuntimeTheme
                                              .surfaceBorderColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: DecoratedBox(
                                decoration: AppGlassTheme.accentDecoration(
                                  radius: 999,
                                  colors: const <Color>[
                                    Color(0xFFEA7A70),
                                    Color(0xFFD95C54),
                                  ],
                                  borderColor: const Color(0xFFC96868),
                                  glowColor: const Color(0xFFE08A82),
                                ),
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide.none,
                                    foregroundColor: const Color(0xFFFFFBFB),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DecoratedBox(
                                decoration: AppGlassTheme.accentDecoration(
                                  radius: 999,
                                  colors: const <Color>[
                                    Color(0xFF7EBFAF),
                                    Color(0xFF5E9E8B),
                                  ],
                                  borderColor: const Color(0xFF6AA796),
                                  glowColor: const Color(0xFFA9D3C7),
                                ),
                                child: FilledButton(
                                  onPressed: _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    widget.isEditing ? 'Save' : 'Add',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomBindingConfig {
  const _CustomBindingConfig({
    required this.dataKey,
    required this.dataKeyLabel,
    required this.dataType,
    required this.unit,
    this.defaultValue,
    this.minValue,
    this.maxValue,
  });

  final String dataKey;
  final String dataKeyLabel;
  final String dataType;
  final String unit;
  final double? defaultValue;
  final double? minValue;
  final double? maxValue;
}
