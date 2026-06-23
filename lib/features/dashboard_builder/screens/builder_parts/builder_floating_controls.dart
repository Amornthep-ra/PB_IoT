part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderFloatingControls on _DashboardBuilderScreenState {
  Widget _buildFloatingControls() {
    const accentLineColor = DashboardRuntimeTheme.surfaceBorderFocusColor;
    final outerRingColor = _themePreset.cardColor;
    final undoTone = _resolveActionTone(_undoActionTone);
    final redoTone = _resolveActionTone(_redoActionTone);
    final duplicateTone = _resolveActionTone(_duplicateActionTone);
    final selectionTone = _resolveActionTone(_selectionActionTone);
    final settingsTone = _resolveActionTone(_settingsActionTone);
    final deleteTone = _resolveActionTone(_deleteActionTone);
    final hasSelection = _hasSelection;
    const baseAddButtonSize = 68.0;
    const baseIdleSecondaryButtonSize = 40.0;
    const baseSelectedSecondaryButtonSize = 40.0;
    const baseSecondaryGap = 8.0;
    const baseSelectedSecondaryGap = 6.0;
    const baseGroupGap = 14.0;
    const baseSelectedGroupGap = 8.0;
    const baseIdleToolbarPadding = 15.0;
    const baseSelectedToolbarPadding = 13.0;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final shortestSide = mediaQuery.size.shortestSide;
    final horizontalScreenMargin = hasSelection ? 8.0 : 24.0;
    final availableWidth =
        screenWidth - mediaQuery.padding.horizontal - horizontalScreenMargin;

    final isTabletLayout = shortestSide >= 600;
    final isLargeTabletLayout = shortestSide >= 900 || screenWidth >= 1000;

    final useSelectedToolbarMetrics = hasSelection || !isTabletLayout;

    final baseSecondaryButtonSize = useSelectedToolbarMetrics
        ? baseSelectedSecondaryButtonSize
        : baseIdleSecondaryButtonSize;
    final baseEffectiveSecondaryGap = useSelectedToolbarMetrics
        ? baseSelectedSecondaryGap
        : baseSecondaryGap;
    final baseEffectiveGroupGap = useSelectedToolbarMetrics
        ? baseSelectedGroupGap
        : baseGroupGap;
    final baseToolbarPadding = useSelectedToolbarMetrics
        ? baseSelectedToolbarPadding
        : baseIdleToolbarPadding;

    final baseIdleWingWidth = baseSecondaryButtonSize;
    final baseLeftSelectionReserve =
        (baseSecondaryButtonSize * 2) + baseEffectiveSecondaryGap;
    final baseRightSelectionReserve =
        (baseSecondaryButtonSize * 2) + baseEffectiveSecondaryGap;
    final baseLeftSelectionWingWidth =
        baseLeftSelectionReserve +
        baseEffectiveGroupGap +
        baseSecondaryButtonSize;
    final baseRightSelectionWingWidth =
        baseSecondaryButtonSize +
        baseEffectiveGroupGap +
        baseRightSelectionReserve;

    final baseShellWingWidth = hasSelection
        ? math.max(baseLeftSelectionWingWidth, baseRightSelectionWingWidth)
        : baseIdleWingWidth;

    final baseRequiredWidth =
        (baseShellWingWidth * 2) +
        baseAddButtonSize +
        (baseEffectiveGroupGap * 2) +
        (baseToolbarPadding * 2);

    final controlsScale = (!isTabletLayout || hasSelection)
        ? (availableWidth / baseRequiredWidth).clamp(0.58, 1.0).toDouble()
        : 1.0;

    final addButtonSize = (baseAddButtonSize * controlsScale)
        .clamp(hasSelection ? 50.0 : 54.0, baseAddButtonSize)
        .toDouble();
    final secondaryButtonSize = (baseSecondaryButtonSize * controlsScale)
        .clamp(hasSelection ? 30.0 : 34.0, baseSecondaryButtonSize)
        .toDouble();
    final secondaryGap = (baseEffectiveSecondaryGap * controlsScale)
        .clamp(hasSelection ? 3.0 : 4.0, baseSecondaryGap)
        .toDouble();
    final groupGap = (baseEffectiveGroupGap * controlsScale)
        .clamp(hasSelection ? 3.0 : 6.0, baseGroupGap)
        .toDouble();
    final toolbarPadding = (baseToolbarPadding * controlsScale)
        .clamp(8.0, baseToolbarPadding)
        .toDouble();
    final actionIconSize = (18.0 * controlsScale).clamp(15.0, 18.0).toDouble();

    final sideWingWidth = (baseShellWingWidth * controlsScale)
        .clamp(34.0, baseShellWingWidth)
        .toDouble();

    final leftSelectionReserve = (secondaryButtonSize * 2) + secondaryGap;
    final rightSelectionReserve = (secondaryButtonSize * 2) + secondaryGap;

    final contextActionOpacity = hasSelection ? 1.0 : 0.0;
    final contextActionScale = hasSelection ? 1.0 : 0.88;
    final isToolbarTranslucent = _activeGestureItemId != null;

    final toolbarContentWidth =
        (toolbarPadding * 2) +
        (sideWingWidth * 2) +
        addButtonSize +
        (groupGap * 2) +
        4;
    final toolbarComfortWidth = (hasSelection ? 12.0 : 18.0) * controlsScale;

    final toolbarPreferredWidth = toolbarContentWidth + toolbarComfortWidth;
    final tabletToolbarMaxWidth = isLargeTabletLayout
        ? 700.0
        : isTabletLayout
        ? 580.0
        : availableWidth;
    final toolbarMaxWidth = math.min(availableWidth, tabletToolbarMaxWidth);
    final toolbarWidth = math.min(toolbarPreferredWidth, toolbarMaxWidth);

    final toolbarHeight = math.max(addButtonSize + 8, 66.0);

    Widget buildAddButton() {
      return Transform.translate(
        offset: const Offset(0, -2),
        child: Semantics(
          button: true,
          label: 'เพิ่มวิดเจ็ต',
          child: Tooltip(
            message: 'เพิ่มวิดเจ็ต',
            preferBelow: false,
            child: Material(
              key: const ValueKey<String>('dashboard_builder_add_action'),
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openAddWidgetSheet,
                child: SizedBox(
                  width: addButtonSize,
                  height: addButtonSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: addButtonSize,
                        height: addButtonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _themePreset.isDark
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: hasSelection ? 0.28 : 0.22,
                                    ),
                                    blurRadius: hasSelection ? 8 : 7,
                                    offset: Offset(0, hasSelection ? 7 : 5),
                                  ),
                                  BoxShadow(
                                    color: DashboardRuntimeTheme.buttonEndColor
                                        .withValues(
                                          alpha: hasSelection ? 0.09 : 0.06,
                                        ),
                                    blurRadius: hasSelection ? 11 : 8,
                                  ),
                                ]
                              : <BoxShadow>[
                                  BoxShadow(
                                    color:
                                        DashboardRuntimeTheme.shadowLightColor,
                                    blurRadius: hasSelection ? 8 : 6,
                                  ),
                                  BoxShadow(
                                    color: accentLineColor.withValues(
                                      alpha: hasSelection ? 0.08 : 0.06,
                                    ),
                                    blurRadius: hasSelection ? 8 : 6,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color:
                                        DashboardRuntimeTheme.shadowDarkColor,
                                    blurRadius: hasSelection ? 9 : 7,
                                    offset: Offset(2, hasSelection ? 5 : 4),
                                  ),
                                ],
                        ),
                      ),
                      Container(
                        width: addButtonSize * 0.84,
                        height: addButtonSize * 0.84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _themePreset.isDark
                                ? <Color>[
                                    outerRingColor.withValues(alpha: 0.96),
                                    _themePreset.surfaceColor.withValues(
                                      alpha: 0.82,
                                    ),
                                  ]
                                : <Color>[
                                    Colors.white.withValues(alpha: 0.92),
                                    DashboardRuntimeTheme.buttonStartColor
                                        .withValues(alpha: 0.12),
                                  ],
                          ),
                          border: Border.all(
                            color: DashboardRuntimeTheme.buttonEndColor
                                .withValues(
                                  alpha: _themePreset.isDark
                                      ? (hasSelection ? 0.32 : 0.24)
                                      : (hasSelection ? 0.22 : 0.16),
                                ),
                            width: 1.4,
                          ),
                          boxShadow: _themePreset.isDark
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: hasSelection ? 0.18 : 0.14,
                                    ),
                                    blurRadius: hasSelection ? 8 : 6,
                                    offset: Offset(0, hasSelection ? 4 : 3),
                                  ),
                                ]
                              : <BoxShadow>[
                                  BoxShadow(
                                    color:
                                        DashboardRuntimeTheme.shadowLightColor,
                                    blurRadius: hasSelection ? 8 : 6,
                                    offset: Offset(
                                      hasSelection ? -3 : -2,
                                      hasSelection ? -3 : -2,
                                    ),
                                  ),
                                ],
                        ),
                      ),
                      Container(
                        width: addButtonSize * 0.66,
                        height: addButtonSize * 0.66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                DashboardRuntimeTheme.buttonStartColor,
                                Colors.white,
                                0.08,
                              )!,
                              DashboardRuntimeTheme.buttonEndColor,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.52),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DashboardRuntimeTheme.buttonEndColor
                                  .withValues(
                                    alpha: hasSelection ? 0.11 : 0.08,
                                  ),
                              blurRadius: hasSelection ? 9 : 7,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: (addButtonSize * 0.40).clamp(24.0, 32.0),
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
        ),
      );
    }

    Widget buildLeftWing() {
      if (!hasSelection) {
        return SizedBox(
          width: sideWingWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _BuilderActionButton(
                icon: Icons.undo_rounded,
                onPressed: _canUndo ? _undo : null,
                tooltip: 'Undo',
                backgroundColor: _canUndo
                    ? undoTone.background
                    : _themePreset.surfaceColor,
                foregroundColor: _canUndo
                    ? undoTone.foreground
                    : _themePreset.mutedTextColor,
                size: secondaryButtonSize,
                iconSize: actionIconSize,
                glowColor: _canUndo ? undoTone.glow : _themePreset.borderColor,
                glowScale: _canUndo ? 1.1 : 0.55,
                isDarkTheme: _themePreset.isDark,
              ),
            ],
          ),
        );
      }

      return SizedBox(
        width: sideWingWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: leftSelectionReserve,
              child: IgnorePointer(
                ignoring: !hasSelection,
                child: AnimatedOpacity(
                  key: const ValueKey<String>(
                    'dashboard_builder_left_context_actions',
                  ),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  opacity: contextActionOpacity,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    scale: contextActionScale,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _BuilderActionButton(
                          icon: Icons.copy_all_rounded,
                          onPressed: _hasSelection
                              ? _duplicateSelectedItems
                              : null,
                          tooltip: 'Duplicate',
                          backgroundColor: duplicateTone.background,
                          foregroundColor: duplicateTone.foreground,
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: duplicateTone.glow,
                          isDarkTheme: _themePreset.isDark,
                        ),
                        SizedBox(width: secondaryGap),
                        _BuilderActionButton(
                          icon: _isMultiSelectMode
                              ? Icons.library_add_check_rounded
                              : Icons.select_all_rounded,
                          onPressed: _hasSelection
                              ? _toggleMultiSelectMode
                              : null,
                          tooltip: _isMultiSelectMode ? 'Selecting' : 'Select',
                          backgroundColor: _isMultiSelectMode
                              ? selectionTone.background
                              : _themePreset.surfaceColor,
                          foregroundColor: _isMultiSelectMode
                              ? selectionTone.foreground
                              : _themePreset.mutedTextColor,
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: _isMultiSelectMode
                              ? selectionTone.glow
                              : _themePreset.borderColor,
                          glowScale: _isMultiSelectMode ? 1.0 : 0.55,
                          isDarkTheme: _themePreset.isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: groupGap),
            _BuilderActionButton(
              icon: Icons.undo_rounded,
              onPressed: _canUndo ? _undo : null,
              tooltip: 'Undo',
              backgroundColor: _canUndo
                  ? undoTone.background
                  : _themePreset.surfaceColor,
              foregroundColor: _canUndo
                  ? undoTone.foreground
                  : _themePreset.mutedTextColor,
              size: secondaryButtonSize,
              iconSize: actionIconSize,
              glowColor: _canUndo ? undoTone.glow : _themePreset.borderColor,
              glowScale: _canUndo ? 1.1 : 0.55,
              isDarkTheme: _themePreset.isDark,
            ),
          ],
        ),
      );
    }

    Widget buildRightWing() {
      if (!hasSelection) {
        return SizedBox(
          width: sideWingWidth,
          child: Row(
            children: [
              _BuilderActionButton(
                icon: Icons.redo_rounded,
                onPressed: _canRedo ? _redo : null,
                tooltip: 'Redo',
                backgroundColor: _canRedo
                    ? redoTone.background
                    : _themePreset.surfaceColor,
                foregroundColor: _canRedo
                    ? redoTone.foreground
                    : _themePreset.mutedTextColor,
                size: secondaryButtonSize,
                iconSize: actionIconSize,
                glowColor: _canRedo ? redoTone.glow : _themePreset.borderColor,
                glowScale: _canRedo ? 1.1 : 0.55,
                isDarkTheme: _themePreset.isDark,
              ),
            ],
          ),
        );
      }

      return SizedBox(
        width: sideWingWidth,
        child: Row(
          children: [
            _BuilderActionButton(
              icon: Icons.redo_rounded,
              onPressed: _canRedo ? _redo : null,
              tooltip: 'Redo',
              backgroundColor: _canRedo
                  ? redoTone.background
                  : _themePreset.surfaceColor,
              foregroundColor: _canRedo
                  ? redoTone.foreground
                  : _themePreset.mutedTextColor,
              size: secondaryButtonSize,
              iconSize: actionIconSize,
              glowColor: _canRedo ? redoTone.glow : _themePreset.borderColor,
              glowScale: _canRedo ? 1.1 : 0.55,
              isDarkTheme: _themePreset.isDark,
            ),
            SizedBox(width: groupGap),
            SizedBox(
              width: rightSelectionReserve,
              child: IgnorePointer(
                ignoring: !hasSelection,
                child: AnimatedOpacity(
                  key: const ValueKey<String>(
                    'dashboard_builder_right_context_actions',
                  ),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  opacity: contextActionOpacity,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    scale: contextActionScale,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        _BuilderActionButton(
                          icon: Icons.settings_rounded,
                          onPressed: _hasSingleSelection
                              ? _openSelectedItemSettings
                              : null,
                          tooltip: 'Settings',
                          backgroundColor: _themePreset.surfaceColor,
                          foregroundColor: _hasSingleSelection
                              ? settingsTone.foreground
                              : _themePreset.mutedTextColor,
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: _hasSingleSelection
                              ? settingsTone.glow.withValues(alpha: 0.42)
                              : _themePreset.borderColor,
                          glowScale: _hasSingleSelection ? 0.72 : 0.55,
                          isDarkTheme: _themePreset.isDark,
                        ),
                        SizedBox(width: secondaryGap),
                        _BuilderActionButton(
                          icon: Icons.delete_outline_rounded,
                          onPressed: _hasSelection ? _removeSelectedItem : null,
                          tooltip: 'Delete',
                          backgroundColor: deleteTone.background,
                          foregroundColor: deleteTone.foreground,
                          size: secondaryButtonSize,
                          iconSize: actionIconSize,
                          glowColor: deleteTone.glow,
                          isDarkTheme: _themePreset.isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Transform.translate(
      offset: const Offset(0, 2),
      child: SizedBox(
        key: const ValueKey<String>('dashboard_builder_floating_toolbar'),
        width: toolbarWidth,
        height: toolbarHeight,
        child: CustomPaint(
          key: ValueKey<String>(
            isToolbarTranslucent
                ? 'dashboard_builder_floating_toolbar_shell_translucent'
                : 'dashboard_builder_floating_toolbar_shell',
          ),
          painter: _ThinGlassToolbarShellPainter(
            isDarkTheme: _themePreset.isDark,
            isTranslucent: isToolbarTranslucent,
            showDividers: hasSelection,
            addButtonSize: addButtonSize,
            groupGap: groupGap,
            sideWingWidth: sideWingWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: toolbarPadding),
            child: Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildLeftWing(),
                    SizedBox(width: groupGap),
                    buildAddButton(),
                    SizedBox(width: groupGap),
                    buildRightWing(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinGlassToolbarShellPainter extends CustomPainter {
  const _ThinGlassToolbarShellPainter({
    required this.isDarkTheme,
    required this.isTranslucent,
    required this.showDividers,
    required this.addButtonSize,
    required this.groupGap,
    required this.sideWingWidth,
  });

  final bool isDarkTheme;
  final bool isTranslucent;
  final bool showDividers;
  final double addButtonSize;
  final double groupGap;
  final double sideWingWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _thinGlassToolbarShellPath(size, addButtonSize: addButtonSize);
    final rect = Offset.zero & size;
    final shellOpacity = isTranslucent ? 0.42 : 1.0;
    final shadowColor = isDarkTheme
        ? Colors.black.withValues(alpha: isTranslucent ? 0.12 : 0.20)
        : const Color(
            0xFF7F92A5,
          ).withValues(alpha: isTranslucent ? 0.030 : 0.060);
    final glowColor = DashboardRuntimeTheme.buttonEndColor.withValues(
      alpha: (isDarkTheme ? 0.050 : 0.038) * shellOpacity,
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = shadowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isTranslucent ? 7 : 9),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = glowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isTranslucent ? 4 : 6),
    );

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkTheme
            ? <Color>[
                const Color(
                  0xFF27323B,
                ).withValues(alpha: isTranslucent ? 0.34 : 0.70),
                const Color(
                  0xFF18252F,
                ).withValues(alpha: isTranslucent ? 0.20 : 0.42),
              ]
            : <Color>[
                Colors.white.withValues(alpha: isTranslucent ? 0.42 : 0.82),
                const Color(
                  0xFFF6FBFF,
                ).withValues(alpha: isTranslucent ? 0.20 : 0.48),
              ],
      ).createShader(rect);

    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTranslucent ? 0.85 : 1.0
      ..color = Colors.white.withValues(
        alpha: isDarkTheme
            ? (isTranslucent ? 0.10 : 0.18)
            : (isTranslucent ? 0.44 : 0.74),
      );
    canvas.drawPath(path, borderPaint);

    final innerHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = (isDarkTheme ? Colors.white : const Color(0xFFFFFFFF))
          .withValues(alpha: isTranslucent ? 0.14 : 0.30);
    canvas.drawPath(path.shift(const Offset(0, -0.45)), innerHighlightPaint);

    if (!showDividers) {
      return;
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dividerOffset = (addButtonSize / 2) + groupGap + (sideWingWidth / 2);
    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = (isDarkTheme ? Colors.white : const Color(0xFF9AAABA))
          .withValues(
            alpha: isTranslucent
                ? (isDarkTheme ? 0.05 : 0.07)
                : (isDarkTheme ? 0.10 : 0.13),
          );

    for (final x in <double>[
      centerX - dividerOffset,
      centerX + dividerOffset,
    ]) {
      canvas.drawLine(
        Offset(x, centerY - 12),
        Offset(x, centerY + 12),
        dividerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ThinGlassToolbarShellPainter oldDelegate) {
    return oldDelegate.isDarkTheme != isDarkTheme ||
        oldDelegate.isTranslucent != isTranslucent ||
        oldDelegate.showDividers != showDividers ||
        oldDelegate.addButtonSize != addButtonSize ||
        oldDelegate.groupGap != groupGap ||
        oldDelegate.sideWingWidth != sideWingWidth;
  }
}

Path _thinGlassToolbarShellPath(Size size, {required double addButtonSize}) {
  final width = size.width;
  final height = size.height;
  final centerX = width / 2;
  final centerY = height / 2;
  final barHeight = math.min(height * 0.70, 48.0);
  final top = centerY - (barHeight / 2);
  final bottom = centerY + (barHeight / 2);
  final radius = barHeight / 2;
  final bulgeHalfWidth = math.max(addButtonSize * 0.58, 35.0);
  final bulgeTop = centerY - math.min(addButtonSize * 0.52, height * 0.48);
  final bulgeBottom = centerY + math.min(addButtonSize * 0.44, height * 0.42);

  return Path()
    ..moveTo(radius, top)
    ..lineTo(centerX - bulgeHalfWidth, top)
    ..cubicTo(
      centerX - (bulgeHalfWidth * 0.58),
      top,
      centerX - (bulgeHalfWidth * 0.58),
      bulgeTop,
      centerX,
      bulgeTop,
    )
    ..cubicTo(
      centerX + (bulgeHalfWidth * 0.58),
      bulgeTop,
      centerX + (bulgeHalfWidth * 0.58),
      top,
      centerX + bulgeHalfWidth,
      top,
    )
    ..lineTo(width - radius, top)
    ..arcToPoint(Offset(width, centerY), radius: Radius.circular(radius))
    ..arcToPoint(
      Offset(width - radius, bottom),
      radius: Radius.circular(radius),
    )
    ..lineTo(centerX + bulgeHalfWidth, bottom)
    ..cubicTo(
      centerX + (bulgeHalfWidth * 0.58),
      bottom,
      centerX + (bulgeHalfWidth * 0.58),
      bulgeBottom,
      centerX,
      bulgeBottom,
    )
    ..cubicTo(
      centerX - (bulgeHalfWidth * 0.58),
      bulgeBottom,
      centerX - (bulgeHalfWidth * 0.58),
      bottom,
      centerX - bulgeHalfWidth,
      bottom,
    )
    ..lineTo(radius, bottom)
    ..arcToPoint(Offset(0, centerY), radius: Radius.circular(radius))
    ..arcToPoint(Offset(radius, top), radius: Radius.circular(radius))
    ..close();
}
