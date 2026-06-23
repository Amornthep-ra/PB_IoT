import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/services/dashboard_item_runtime_binding.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../models/widget_settings_result.dart';
import '../../../theme/app_theme.dart';
import 'dashboard_item_renderer.dart';
import 'settings/domain/widget_settings_binding_catalog.dart';
import 'settings/domain/widget_settings_binding_validator.dart';
import 'settings/domain/widget_settings_capabilities.dart';
import 'settings/domain/widget_settings_draft.dart';
import 'settings/domain/widget_settings_preview_mapper.dart';
import 'settings/domain/widget_settings_result_mapper.dart';

part 'settings/appearance_settings_section.dart';
part 'settings/design_config.dart';
part 'settings/appearance_color_controls.dart';
part 'settings/appearance_border_controls.dart';
part 'settings/appearance_glow_controls.dart';
part 'settings/appearance_title_controls.dart';
part 'settings/custom_binding_config.dart';
part 'settings/custom_binding_page.dart';
part 'settings/custom_binding_validation.dart';
part 'settings/custom_binding_pickers.dart';
part 'settings/custom_binding_form_fields.dart';
part 'settings/custom_vpin_picker_sheet.dart';
part 'settings/binding_picker_section.dart';
part 'settings/settings_result_helpers.dart';

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

Widget _buildStableGlassSheetShell({
  required Widget child,
  required double radius,
  Color? tint,
  double opacity = 0.88,
  bool elevated = true,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: DecoratedBox(
      decoration: _glassSheetDecoration(
        radius: radius,
        tint: tint,
        opacity: opacity,
        elevated: elevated,
      ),
      child: child,
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

typedef _BindingSourceGroup = WidgetSettingsBindingSourceGroup;
typedef _BindingCatalogEntry = WidgetSettingsBindingEntry;
typedef _CustomBindingCatalogEntry = WidgetSettingsCustomBindingEntry;

class _WidgetSettingsSheetState extends State<WidgetSettingsSheet> {
  static const String _customBindingStorageKey =
      'dashboard_builder_custom_data_keys_v1';
  static const Color _defaultButtonOffColor = Color(0xFFE5A39D);
  static const Color _defaultAccentColor = Color(0xFF1F9443);
  static const Color _defaultButtonInnerColor =
      DashboardRuntimeTheme.cardHighlightColor;
  static const List<_BindingCatalogEntry> _bindingCatalog =
      WidgetSettingsBindingCatalog.entries;

  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  late final TextEditingController _minValueController;
  late final TextEditingController _maxValueController;
  late final TextEditingController _stepController;
  late final FocusNode _titleFocusNode;
  final GlobalKey _bindingFieldKey = GlobalKey();
  late WidgetSettingsDraft _draft;
  Color _accentColor = _defaultAccentColor;
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
  bool _buttonEnabled = false;
  bool _locked = false;
  String? _selectedUnit;
  String _selectedBindingKey = '';
  String? _selectedBindingName;
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

  double get _defaultGlowStrengthForCurrentType =>
      _defaultGlowStrengthForType(widget.item.type);

  Color get _effectiveGlowColor =>
      _glowColorLinkedToAccent ? _accentColor : _glowColor;

  WidgetSettingsCapabilities get _capabilities =>
      WidgetSettingsCapabilities.forType(widget.item.type);

  _WidgetDesignConfig get _designConfig =>
      _WidgetDesignConfig.forType(widget.item.type);

  static double _defaultGlowStrengthForType(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.slider => _defaultSliderGlowStrength,
      DashboardItemType.stepH ||
      DashboardItemType.stepV => _defaultSliderGlowStrength,
      DashboardItemType.valueLabel => _defaultValueLabelGlowStrength,
      DashboardItemType.trend => _defaultSliderGlowStrength,
      DashboardItemType.button ||
      DashboardItemType.gauge ||
      DashboardItemType.toggle => _defaultGlowStrength,
      DashboardItemType.led => 0.0,
    };
  }

  String get _widgetSettingsSubtitle {
    return '';
  }

  Size get _miniPreviewSize => switch (widget.item.type) {
    DashboardItemType.button => const Size(72, 72),
    DashboardItemType.slider => const Size(136, 54),
    DashboardItemType.stepH => const Size(128, 54),
    DashboardItemType.stepV => const Size(54, 128),
    DashboardItemType.gauge => const Size(92, 92),
    DashboardItemType.toggle => const Size(118, 62),
    DashboardItemType.valueLabel => const Size(132, 72),
    DashboardItemType.trend => const Size(150, 76),
    DashboardItemType.led => const Size(82, 64),
  };

  GridRect get _miniPreviewRect => switch (widget.item.type) {
    DashboardItemType.button => const GridRect(x: 0, y: 0, w: 7, h: 7),
    DashboardItemType.slider => const GridRect(x: 0, y: 0, w: 12, h: 4),
    DashboardItemType.stepH => const GridRect(x: 0, y: 0, w: 12, h: 4),
    DashboardItemType.stepV => const GridRect(x: 0, y: 0, w: 4, h: 12),
    DashboardItemType.gauge => const GridRect(x: 0, y: 0, w: 8, h: 8),
    DashboardItemType.toggle => const GridRect(x: 0, y: 0, w: 11, h: 5),
    DashboardItemType.valueLabel => const GridRect(x: 0, y: 0, w: 12, h: 6),
    DashboardItemType.trend => const GridRect(x: 0, y: 0, w: 14, h: 7),
    DashboardItemType.led => const GridRect(x: 0, y: 0, w: 8, h: 5),
  };

  EdgeInsets get _miniPreviewInsets => switch (widget.item.type) {
    DashboardItemType.slider => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 3,
    ),
    DashboardItemType.stepH => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    DashboardItemType.stepV => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 8,
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
    DashboardItemType.trend => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 5,
    ),
    DashboardItemType.led => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
    DashboardItemType.gauge => const EdgeInsets.all(8),
  };

  double get _miniPreviewRadius => switch (widget.item.type) {
    DashboardItemType.slider => 16,
    DashboardItemType.stepH || DashboardItemType.stepV => 18,
    DashboardItemType.gauge => 24,
    DashboardItemType.button => 24,
    DashboardItemType.led => 22,
    _ => 20,
  };

  Offset get _miniPreviewVisualOffset => switch (widget.item.type) {
    DashboardItemType.slider => const Offset(0, -3),
    DashboardItemType.stepH => const Offset(0, -2),
    _ => Offset.zero,
  };

  BoxDecoration get _miniPreviewCardDecoration {
    final isHorizontalWidget =
        widget.item.type == DashboardItemType.slider ||
        widget.item.type == DashboardItemType.stepH ||
        widget.item.type == DashboardItemType.stepV ||
        widget.item.type == DashboardItemType.button ||
        widget.item.type == DashboardItemType.toggle ||
        widget.item.type == DashboardItemType.valueLabel ||
        widget.item.type == DashboardItemType.trend ||
        widget.item.type == DashboardItemType.led;

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

  WidgetSettingsDraft _buildDraftSnapshot() {
    return WidgetSettingsDraft(
      title: _titleController.text,
      value: double.tryParse(_valueController.text.trim()) ?? widget.item.value,
      minValue:
          double.tryParse(_minValueController.text.trim()) ??
          widget.item.minValue,
      maxValue:
          double.tryParse(_maxValueController.text.trim()) ??
          widget.item.maxValue,
      stepValue:
          double.tryParse(_stepController.text.trim()) ?? widget.item.stepValue,
      accentColor: _accentColor,
      secondaryAccentColor: _secondaryAccentColor,
      surfaceColor: _buttonShellColor,
      innerColor: _buttonInnerColor,
      borderColor: _buttonBorderColor,
      glowColor: _glowColor,
      glowColorLinkedToAccent: _glowColorLinkedToAccent,
      borderLinkedToState: _buttonBorderLinkedToState,
      valueLabelBorderLinkedToText: _valueLabelBorderLinkedToText,
      buttonBorderWidth: _buttonBorderWidth,
      valueLabelBorderWidth: _valueLabelBorderWidth,
      gaugeBorderWidth: _gaugeBorderWidth,
      sliderBorderWidth: _sliderBorderWidth,
      toggleBorderWidth: _toggleBorderWidth,
      glowStrength: _glowStrength,
      glowBlur: _glowBlur,
      enabled: _buttonEnabled,
      locked: _locked,
      bindingKey: _selectedBindingKey,
      bindingLabel: _selectedBindingName,
      bindingMode: _selectedBindingMode,
      dataType: _selectedDataType,
      unit: _selectedUnit,
      sendBehavior: _selectedSendBehavior,
    );
  }

  void _syncDraftFromCurrentState() {
    _draft = _buildDraftSnapshot();
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
    _syncDraftFromCurrentState();
    return WidgetSettingsPreviewMapper.buildPreviewItem(
      source: widget.item,
      draft: _draft,
      capabilities: _capabilities,
      previewRect: _miniPreviewRect,
      previewValue: _previewDisplayValue,
      minValue: _previewMinValue,
      maxValue: _previewMaxValue,
      stepValue: _previewStepValue,
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
          isEditMode: false,
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

  Color _effectiveDefaultSurfaceColor() {
    return _isValueLabelWidget
        ? _effectiveDefaultValueLabelShellColor()
        : _isGaugeWidget
        ? _effectiveDefaultGaugeBorderColor()
        : _isSliderLikeNumericControl
        ? _effectiveDefaultSliderBorderColor()
        : _isTrendWidget
        ? _effectiveDefaultSliderBorderColor()
        : _isLedWidget
        ? _effectiveDefaultToggleBorderColor()
        : _isToggleWidget
        ? _effectiveDefaultToggleBorderColor()
        : _effectiveDefaultButtonShellColor();
  }

  Color _effectiveDefaultInnerSurfaceColor() {
    return _isValueLabelWidget
        ? _effectiveDefaultValueLabelBackgroundColor()
        : _isGaugeWidget
        ? _effectiveDefaultGaugeBackgroundColor()
        : _isSliderLikeNumericControl
        ? _effectiveDefaultSliderBackgroundColor()
        : _isTrendWidget
        ? _effectiveDefaultSliderBackgroundColor()
        : _isLedWidget
        ? _effectiveDefaultToggleBackgroundColor()
        : _isToggleWidget
        ? _effectiveDefaultToggleBackgroundColor()
        : _effectiveDefaultButtonInnerColor();
  }

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
    _locked = widget.item.locked;
    _buttonShellColor =
        widget.item.buttonShellColor ??
        (_isValueLabelWidget
            ? _effectiveDefaultValueLabelShellColor()
            : _isGaugeWidget
            ? _effectiveDefaultGaugeBorderColor()
            : _isSliderLikeNumericControl
            ? _effectiveDefaultSliderBorderColor()
            : _isTrendWidget
            ? _effectiveDefaultSliderBorderColor()
            : _isLedWidget
            ? _effectiveDefaultToggleBorderColor()
            : _isToggleWidget
            ? _effectiveDefaultToggleBorderColor()
            : _effectiveDefaultButtonShellColor(enabled: _buttonEnabled));
    _buttonInnerColor =
        widget.item.buttonInnerColor ??
        (_isValueLabelWidget
            ? _effectiveDefaultValueLabelBackgroundColor()
            : _isGaugeWidget
            ? _effectiveDefaultGaugeBackgroundColor()
            : _isSliderLikeNumericControl
            ? _effectiveDefaultSliderBackgroundColor()
            : _isTrendWidget
            ? _effectiveDefaultSliderBackgroundColor()
            : _isLedWidget
            ? _effectiveDefaultToggleBackgroundColor()
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
      _selectedBindingName = _bindingSourceLabelForKey(initialCatalogEntry.key);
      if (_selectedUnit == null &&
          initialCatalogEntry.unit != null &&
          initialCatalogEntry.unit!.trim().isNotEmpty) {
        _selectedUnit = initialCatalogEntry.unit!.trim();
      }
    }
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
    _syncDraftFromCurrentState();
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
  bool get _isStepperWidget =>
      widget.item.type == DashboardItemType.stepH ||
      widget.item.type == DashboardItemType.stepV;
  bool get _isSliderLikeNumericControl => _isSliderWidget || _isStepperWidget;
  bool get _isGaugeWidget => widget.item.type == DashboardItemType.gauge;
  bool get _isToggleWidget => widget.item.type == DashboardItemType.toggle;
  bool get _isValueLabelWidget =>
      widget.item.type == DashboardItemType.valueLabel;
  bool get _isTrendWidget => widget.item.type == DashboardItemType.trend;
  bool get _isLedWidget => widget.item.type == DashboardItemType.led;
  bool get _isWritableWidget => _capabilities.isWritable(widget.item.type);
  bool get _hasSelectedBinding => _selectedBindingKey.trim().isNotEmpty;
  bool get _isBindingModeConfigurable =>
      _capabilities.isBindingModeConfigurable;
  bool get _bindingIsRequired => _capabilities.bindingIsRequired;

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
      return 'กรุณาเลือกแหล่งข้อมูลก่อนเพื่อให้วิดเจ็ตนี้ทำงานได้';
    }
    return 'ยังไม่ได้เลือกแหล่งข้อมูล เลือกก่อนเพื่อเชื่อมข้อมูล';
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
      return 'ไม่มี';
    }
    return normalized;
  }

  _BindingCatalogEntry? _catalogEntryFor(String key) {
    return WidgetSettingsBindingCatalog.entryFor(key);
  }

  bool _isCatalogKey(String key) =>
      WidgetSettingsBindingCatalog.isCatalogKey(key);

  String? _canonicalBindingKey(String raw) {
    return WidgetSettingsBindingValidator.canonicalKey(raw);
  }

  String _bindingSourceGroupLabel(_BindingSourceGroup group) {
    return WidgetSettingsBindingCatalog.sourceGroupLabel(group);
  }

  String _bindingSourceLabelForKey(String key) {
    return WidgetSettingsBindingCatalog.sourceLabelForKey(key);
  }

  String _widgetTypeLabel(DashboardItemType type) {
    return switch (type) {
      DashboardItemType.button => 'ปุ่ม',
      DashboardItemType.slider => 'สไลเดอร์',
      DashboardItemType.stepH => 'ปรับค่า H',
      DashboardItemType.stepV => 'ปรับค่า V',
      DashboardItemType.gauge => 'เกจ',
      DashboardItemType.toggle => 'สวิตช์',
      DashboardItemType.valueLabel => 'แสดงค่า',
      DashboardItemType.trend => 'กราฟแนวโน้ม',
      DashboardItemType.led => 'ไฟสถานะ',
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
        normalizedUnit.toLowerCase() != 'ไม่มี') {
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
    final normalizedKey = _canonicalBindingKey(key) ?? key.trim();
    if (normalizedKey.isEmpty) {
      return 'ไม่มี';
    }
    final customName = _selectedBindingName?.trim();
    if (customName != null && customName.isNotEmpty) {
      return customName;
    }
    return _bindingSourceLabelForKey(normalizedKey);
  }

  String _bindingSubtitleFor(String key) {
    final normalizedKey = _canonicalBindingKey(key) ?? key.trim();
    if (normalizedKey.isEmpty) {
      return 'เลือกแหล่งข้อมูลที่ต้องการใช้สำหรับวิดเจ็ตนี้';
    }
    final sourceLabel = _bindingSourceLabelForKey(normalizedKey);
    final catalogEntry = _catalogEntryFor(normalizedKey);
    if (catalogEntry != null) {
      return '$sourceLabel · ${_bindingMetaLine(dataType: catalogEntry.dataType, rangeLabel: catalogEntry.rangeLabel, unit: catalogEntry.unit)}';
    }
    final customEntry = _customBindingEntryFor(normalizedKey);
    if (customEntry != null) {
      return '$sourceLabel · ${_bindingMetaLine(dataType: customEntry.dataType, rangeLabel: _customBindingRangeLabel(customEntry), unit: customEntry.unit)}';
    }
    return '$sourceLabel · ${_bindingMetaLine(dataType: _selectedDataType, rangeLabel: _currentBindingRangeLabel(), unit: _selectedUnit)}';
  }

  bool _isRecommendedCatalogEntry(_BindingCatalogEntry entry) {
    return entry.recommendedFor.contains(widget.item.type);
  }

  List<_BindingCatalogEntry> _sortedBindingCatalog() {
    final entries = List<_BindingCatalogEntry>.from(_bindingCatalog);
    entries.sort((left, right) {
      final groupCompare = left.group.index.compareTo(right.group.index);
      if (groupCompare != 0) {
        return groupCompare;
      }
      return _compareBindingKeys(left.key, right.key);
    });
    return entries;
  }

  List<_CustomBindingCatalogEntry> _customBindingsFromItems() {
    final entries = <String, _CustomBindingCatalogEntry>{};
    for (final item in widget.allItems) {
      final key = _canonicalBindingKey(item.dataKey ?? '');
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
    final normalizedKey = _canonicalBindingKey(key) ?? key.trim();
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
      final key = _canonicalBindingKey(item.dataKey ?? '');
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
      final normalizedKey = _canonicalBindingKey(entry.key);
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
      return _compareBindingKeys(left.key, right.key);
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
      return _compareBindingKeys(left.key, right.key);
    });
    setState(() {
      _customBindingCatalog = current;
    });
    await _saveStoredCustomBindingCatalog(current);
  }

  Future<void> _deleteCustomBindingCatalogEntry(String key) async {
    final normalizedKey = _canonicalBindingKey(key);
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
                          'ลบคีย์ข้อมูลที่กำหนดเอง?',
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
                            'ยกเลิก',
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
                              'ลบ',
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

  List<MapEntry<String, String>> _bindingModeOptions() {
    if (_isWritableWidget) {
      return const <MapEntry<String, String>>[
        MapEntry('read_write', 'อ่าน + เขียน'),
        MapEntry('read', 'อ่านอย่างเดียว'),
        MapEntry('write', 'เขียนอย่างเดียว'),
      ];
    }
    return const <MapEntry<String, String>>[MapEntry('read', 'อ่านอย่างเดียว')];
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
        MapEntry('on_release', 'ส่งเมื่อปล่อย'),
        MapEntry('on_drag', 'ส่งระหว่างลาก'),
      ];
    }
    if (_isWritableWidget) {
      return const <MapEntry<String, String>>[
        MapEntry('on_release', 'ส่งเมื่อกด'),
      ];
    }
    return const <MapEntry<String, String>>[];
  }

  List<MapEntry<String, String>> _buttonModeOptions() {
    return const <MapEntry<String, String>>[
      MapEntry('switch', 'สวิตช์'),
      MapEntry('push', 'กดค้าง'),
    ];
  }

  Map<String, String> _reservedBindingMap() {
    return Map<String, String>.fromEntries(
      _bindingCatalog.map((entry) => MapEntry(entry.key, entry.name)),
    );
  }

  bool _isReservedBindingKey(String key) {
    final normalized = _canonicalBindingKey(key);
    if (normalized == null) {
      return false;
    }
    return _reservedBindingMap().containsKey(normalized);
  }

  Map<String, String> _lockedCustomBindingMapForEditor() {
    final locked = <String, String>{};
    final currentCustomKey = !_isCatalogKey(_selectedBindingKey)
        ? _canonicalBindingKey(_selectedBindingKey)
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

  Future<_CustomBindingConfig?> _openCustomBindingDialogForMode(
    _CustomBindingEditorMode mode,
  ) async {
    final lockedMap = _lockedCustomBindingMapForEditor();
    final currentCustomEntry = _customBindingEntryFor(_selectedBindingKey);
    var selectedKey =
        _canonicalBindingKey(_selectedBindingKey) ??
        currentCustomEntry?.key ??
        (mode == _CustomBindingEditorMode.virtualPin
            ? 'V4'
            : 'status.temperature');
    if (mode == _CustomBindingEditorMode.virtualPin &&
        (_isReservedBindingKey(selectedKey) ||
            lockedMap.containsKey(selectedKey))) {
      for (var i = 4; i <= 255; i += 1) {
        final candidate = 'V$i';
        if (!_isReservedBindingKey(candidate) &&
            !lockedMap.containsKey(candidate)) {
          selectedKey = candidate;
          break;
        }
      }
    }
    return Navigator.of(context).push<_CustomBindingConfig>(
      MaterialPageRoute<_CustomBindingConfig>(
        builder: (context) => _CustomBindingPage(
          mode: mode,
          initialKey: selectedKey,
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

  void _applyCatalogBinding(_BindingCatalogEntry entry) {
    _selectedBindingKey = entry.key;
    _selectedBindingName = _bindingSourceLabelForKey(entry.key);
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
    _selectedBindingKey = customResult.dataKey;
    _selectedBindingName = customResult.dataKeyLabel.trim();
    _showBindingValidationError = false;
    _selectedDataType = _normalizeDataType(customResult.dataType);
    if (customResult.unit.trim().isEmpty ||
        customResult.unit.trim().toLowerCase() == 'ไม่มี') {
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
    final selectedBinding = await _openBindingSourcePicker(
      context: context,
      currentBindingKey: _selectedBindingKey,
    );
    if (selectedBinding == null || !mounted) {
      return;
    }
    if (selectedBinding.startsWith('__delete__:')) {
      final key = selectedBinding.replaceFirst('__delete__:', '').trim();
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
      if (_canonicalBindingKey(_selectedBindingKey) == entry.key) {
        setState(() {
          _selectedBindingKey = '';
          _selectedBindingName = null;
          _selectedUnit = null;
        });
      }
      return;
    }
    if (selectedBinding == '__custom_vpin__' ||
        selectedBinding == '__advanced__') {
      final customResult = await _openCustomBindingDialogForMode(
        selectedBinding == '__custom_vpin__'
            ? _CustomBindingEditorMode.virtualPin
            : _CustomBindingEditorMode.advanced,
      );
      if (customResult == null || !mounted) {
        return;
      }
      final customEntry = _CustomBindingCatalogEntry(
        key: customResult.dataKey,
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

  int _compareBindingKeys(String left, String right) {
    final leftVPin = _normalizeVPinKey(left);
    final rightVPin = _normalizeVPinKey(right);
    if (leftVPin != null && rightVPin != null) {
      final leftIndex = int.tryParse(leftVPin.replaceFirst('V', '')) ?? 0;
      final rightIndex = int.tryParse(rightVPin.replaceFirst('V', '')) ?? 0;
      return leftIndex.compareTo(rightIndex);
    }
    if (leftVPin != null) {
      return -1;
    }
    if (rightVPin != null) {
      return 1;
    }
    return left.toLowerCase().compareTo(right.toLowerCase());
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

  void _setSettingsResultState(VoidCallback fn) {
    setState(fn);
  }

  void _setAppearanceState(VoidCallback fn) {
    setState(fn);
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
                    label: 'บันทึก',
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
                    label: 'ลบ',
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
                    label: 'ลบ',
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
                    label: 'บันทึก',
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
            label: 'ข้อมูล',
            icon: Icons.settings_outlined,
          ),
          const SizedBox(width: 6),
          buildTab(
            page: _WidgetSettingsPage.design,
            label: 'ออกแบบ',
            icon: Icons.palette_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLockWidgetControl() {
    return _buildFieldShell(
      child: SwitchListTile(
        value: _locked,
        onChanged: (value) {
          setState(() {
            _locked = value;
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        dense: true,
        secondary: Icon(
          _locked ? Icons.lock_rounded : Icons.lock_open_rounded,
          color: _locked
              ? DashboardRuntimeTheme.surfaceBorderFocusColor
              : DashboardRuntimeTheme.labelTextColor,
          size: 18,
        ),
        title: const Text(
          'ล็อกวิดเจ็ต',
          style: TextStyle(
            color: DashboardRuntimeTheme.headlineColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'ล็อกตำแหน่งและขนาดในโหมดแก้ไข',
          style: TextStyle(
            color: DashboardRuntimeTheme.mutedTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        activeThumbColor: DashboardRuntimeTheme.surfaceBorderFocusColor,
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
                  // แยกโทนสีให้สวิตช์และกดค้างดูต่างกัน แต่ยังคงอยู่ในโทนแอปเดียวกัน
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
                                  tooltip: 'ปิด',
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
                                'ตั้งค่าวิดเจ็ต',
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
                          const _SettingsLabel('ข้อมูลที่เชื่อมต่อ'),
                          const SizedBox(height: 8),
                          _buildBindingField(),
                          const SizedBox(height: 14),
                          if (_isButtonWidget) ...[
                            const _SettingsLabel('โหมดปุ่ม'),
                            const SizedBox(height: 8),
                            _buildButtonModeSelector(),
                            const SizedBox(height: 14),
                          ],
                          if (_isSliderLikeNumericControl) ...[
                            const _SettingsLabel('ช่วงค่า'),
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
                                        hint: 'ต่ำสุด',
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
                                        hint: 'สูงสุด',
                                        prefixIcon: Icons.north_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const _SettingsLabel('ขั้น'),
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
                                  hint: 'ค่าขั้น',
                                  prefixIcon: Icons.straighten_rounded,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const _SettingsLabel('หน่วย'),
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
                          const _SettingsLabel('ล็อกเลย์เอาต์'),
                          const SizedBox(height: 8),
                          _buildLockWidgetControl(),
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
