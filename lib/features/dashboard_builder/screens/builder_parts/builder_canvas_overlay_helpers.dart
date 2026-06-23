part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderCanvasOverlayHelpers
    on _DashboardBuilderScreenState {
  Widget _buildPreviewOverlay({
    required DashboardItem activeItem,
    required GridRect rect,
    required double cellWidth,
    required double rowHeight,
    required double stepX,
    required double stepY,
  }) {
    var left = rect.x * stepX;
    var top = rect.y * stepY;
    var width = DashboardGridMetrics.itemWidthFor(
      rect: rect,
      cellWidth: cellWidth,
    );
    var height = DashboardGridMetrics.itemHeightFor(
      rect: rect,
      rowHeight: rowHeight,
    );
    final editorGeometry = _resolveEditorGeometry(
      item: activeItem,
      width: width,
      height: height,
    );
    final previewRect = editorGeometry.previewOverlayRect;
    left += previewRect.left;
    top += previewRect.top;
    width = previewRect.width;
    height = previewRect.height;
    final previewRadius = editorGeometry.previewCornerRadius;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                key: ValueKey<String>(
                  'dashboard_builder_preview_overlay_${activeItem.id}',
                ),
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                decoration: _dashboardPreviewOverlayDecoration(
                  isInvalid: _previewInvalid,
                  radius: previewRadius,
                ),
              ),
            ),
            if (_previewInvalid)
              Positioned(
                left: 6,
                right: 6,
                top: height >= 48 ? 8 : -32,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD16A6A).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD16A6A,
                          ).withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        'พื้นที่ทับกัน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedItemTitleOverlay({
    required DashboardItem item,
    required double cellWidth,
    required double rowHeight,
    required double stepX,
    required double stepY,
  }) {
    if (!_shouldRenderCanvasTitle(item)) {
      return const SizedBox.shrink();
    }

    final left = item.rect.x * stepX;
    final top = item.rect.y * stepY;
    final width = DashboardGridMetrics.itemWidthFor(
      rect: item.rect,
      cellWidth: cellWidth,
    );
    final height = DashboardGridMetrics.itemHeightFor(
      rect: item.rect,
      rowHeight: rowHeight,
    );
    final style = _canvasWidgetTitleStyle(item);
    final titleHeight = _canvasWidgetTitleHeight(style);
    final isBottomTitle =
        item.titlePosition.trim().toLowerCase() ==
        DashboardItemTitlePosition.bottomOutside;

    return Positioned(
      left: left,
      top: isBottomTitle ? top + height - titleHeight : top,
      width: width,
      height: titleHeight,
      child: IgnorePointer(
        child: _CanvasWidgetTitleOverlay(
          text: item.title.toUpperCase(),
          style: style,
        ),
      ),
    );
  }

  bool _shouldRenderCanvasTitle(DashboardItem item) {
    final title = item.title.trim();
    return title.isNotEmpty &&
        item.titlePosition.trim().toLowerCase() !=
            DashboardItemTitlePosition.hidden &&
        !_isFactoryDefaultInspectorTitle(item, title);
  }

  TextStyle _canvasWidgetTitleStyle(DashboardItem item) {
    final isFactoryDefault = _isFactoryDefaultInspectorTitle(item, item.title);
    final defaultAdjustment = item.titleFontSize == null && isFactoryDefault
        ? -1.0
        : 0.0;
    final fontSize = ((item.titleFontSize ?? 10.0) + defaultAdjustment).clamp(
      7.0,
      12.0,
    );
    final titleColor = item.titleColor ?? _themePreset.headlineColor;

    return TextStyle(
      fontSize: fontSize,
      fontWeight: isFactoryDefault ? FontWeight.w600 : FontWeight.w700,
      letterSpacing: isFactoryDefault ? 0.3 : 0.4,
      color: _themePreset.isDark
          ? DashboardTextContrast.readableTextColor(
              preferred: titleColor,
              background: _themePreset.canvasColors.isNotEmpty
                  ? _themePreset.canvasColors.first
                  : _themePreset.pageEnd,
              fallback: _themePreset.headlineColor,
              minRatio: 3.6,
            )
          : titleColor,
      shadows: _themePreset.isDark
          ? <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : <Shadow>[
              Shadow(
                color: Colors.white.withValues(alpha: 0.88),
                blurRadius: 5,
              ),
            ],
    );
  }

  double _canvasWidgetTitleHeight(TextStyle style) {
    return ((style.fontSize ?? 10.0) * 1.4).clamp(12.0, 24.0);
  }

  Widget _buildResizePlaceholder({
    required DashboardItem item,
    required double borderRadius,
  }) {
    final title = item.title.trim().isEmpty ? 'Widget' : item.title.trim();
    final accent = (item.titleColor ?? DashboardRuntimeTheme.buttonEndColor)
        .withValues(alpha: 0.72);

    if (item.type == DashboardItemType.button) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final placeholderGeometry = _resolvePaddedPlaceholderGeometry(
            item: item,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
          final shellGeometry = resolveButtonShellGeometry(
            width: math.max(0.0, constraints.maxWidth),
            height: math.max(0.0, constraints.maxHeight),
          );
          final visualStyle = resolveButtonVisualStyle(
            item: item,
            themePreset: _themePreset,
            isActive: item.enabled,
            shellBorderWidthFallback: shellGeometry.metrics.borderWidth,
            sizeClass: shellGeometry.metrics.sizeClass,
            glowColor: item.glowColor,
            glowStrength: resolveItemGlowStrength(
              item: item,
              themePreset: _themePreset,
              defaultStrength: 0.12,
            ),
            glowBlur: resolveItemGlowBlur(
              item: item,
              themePreset: _themePreset,
            ),
          );
          final bodyRect = placeholderGeometry.bodyRect;
          final previewWidth = bodyRect.width;
          final previewHeight = bodyRect.height;

          return SizedBox.expand(
            key: const ValueKey<String>(
              'dashboard_builder_button_resize_placeholder',
            ),
            child: Stack(
              children: [
                Positioned(
                  left: bodyRect.left,
                  top: bodyRect.top,
                  width: previewWidth,
                  height: previewHeight,
                  child: DecoratedBox(
                    key: const ValueKey<String>(
                      'dashboard_builder_button_resize_placeholder_shell',
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          visualStyle.surfaceColor,
                          visualStyle.shellGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        shellGeometry.shellCornerRadius,
                      ),
                      border: Border.all(
                        color: visualStyle.resolvedShellBorderColor,
                        width: visualStyle.resolvedShellBorderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: visualStyle.highlightShadowColor.withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: math.min(
                            10.0,
                            shellGeometry.metrics.baseShadowBlur * 0.24,
                          ),
                          offset: Offset.zero,
                        ),
                        BoxShadow(
                          color: visualStyle.ambientShadowColor.withValues(
                            alpha: 0.10,
                          ),
                          blurRadius: math.min(
                            14.0,
                            shellGeometry.metrics.baseShadowBlur * 0.34,
                          ),
                          offset: Offset(0, previewWidth * 0.012),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                shellGeometry.shellCornerRadius,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.18),
                                  Colors.transparent,
                                  visualStyle.currentAccent.withValues(
                                    alpha: item.enabled ? 0.022 : 0.010,
                                  ),
                                ],
                                stops: const [0.0, 0.35, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: shellGeometry.controlRect.left,
                          top: shellGeometry.controlRect.top,
                          width: shellGeometry.controlRect.width,
                          height: shellGeometry.controlRect.height,
                          child: DecoratedBox(
                            key: const ValueKey<String>(
                              'dashboard_builder_button_resize_placeholder_control',
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  visualStyle.controlSurfaceColor,
                                  visualStyle.controlGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                shellGeometry.controlCornerRadius,
                              ),
                              border: Border.all(
                                color: visualStyle.currentAccent.withValues(
                                  alpha: item.enabled ? 0.58 : 0.38,
                                ),
                                width: shellGeometry.metrics.controlBorderWidth,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: visualStyle.controlHighlightShadowColor
                                      .withValues(alpha: 0.22),
                                  blurRadius: 4,
                                  offset: Offset.zero,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          visualStyle.currentAccent.withValues(
                                            alpha: item.enabled ? 0.045 : 0.018,
                                          ),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.72],
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: SizedBox(
                                    key: const ValueKey<String>(
                                      'dashboard_builder_button_resize_placeholder_center',
                                    ),
                                    width: shellGeometry.iconSize,
                                    height: shellGeometry.iconSize,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        -(shellGeometry.iconSize * 0.08),
                                      ),
                                      child: Icon(
                                        Icons.power_settings_new_rounded,
                                        size: shellGeometry.iconSize,
                                        color: visualStyle.currentAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (item.type == DashboardItemType.slider) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final placeholderGeometry = _resolvePaddedPlaceholderGeometry(
            item: item,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
          final bodyRect = placeholderGeometry.bodyRect;
          final bodyRadius = placeholderGeometry.cornerRadius;
          final sliderGeometry = resolveSliderVisualGeometry(
            width: math.max(0.0, bodyRect.width),
            height: math.max(0.0, bodyRect.height),
            estimatedValueHeight: SmartSliderVisualSpec.estimatedValueHeight,
            labelTrackGap: SmartSliderVisualSpec.labelTrackGap,
            compactLabelTrackGap: SmartSliderVisualSpec.compactLabelTrackGap,
            trackTouchHeight: SmartSliderVisualSpec.trackTouchHeight,
            compactTrackTouchHeight:
                SmartSliderVisualSpec.compactTrackTouchHeight,
          );
          final valueRect = sliderGeometry.valueRect;
          final trackRect = sliderGeometry.trackRect;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: bodyRect,
                child: DecoratedBox(
                  key: const ValueKey<String>(
                    'dashboard_builder_slider_resize_placeholder_body',
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(bodyRadius),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.42),
                      width: 1.1,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (!valueRect.isEmpty)
                        Positioned.fromRect(
                          rect: valueRect,
                          child: Center(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fromRect(
                        rect: trackRect,
                        child: Center(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (item.type == DashboardItemType.gauge ||
        item.type == DashboardItemType.led) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final placeholderGeometry = _resolvePaddedPlaceholderGeometry(
            item: item,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
          final bodyRect = placeholderGeometry.bodyRect;
          final bodyRadius = placeholderGeometry.cornerRadius;
          final isLed = item.type == DashboardItemType.led;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: bodyRect.left,
                top: bodyRect.top,
                width: bodyRect.width,
                height: bodyRect.height,
                child: DecoratedBox(
                  key: ValueKey<String>(
                    isLed
                        ? 'dashboard_builder_led_resize_placeholder_body'
                        : 'dashboard_builder_gauge_resize_placeholder_body',
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: isLed ? 0.46 : 0.34),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.08),
                        blurRadius: 14,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: isLed
                          ? bodyRect.width * 0.46
                          : math.min(42.0, bodyRect.width * 0.42),
                      height: isLed
                          ? bodyRect.height * 0.46
                          : math.min(12.0, bodyRect.height * 0.22),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isLed ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(bodyRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    final hasEnoughHeightForTitle = item.rect.h >= 3;
    final indicatorHeight = item.type == DashboardItemType.toggle ? 18.0 : 10.0;
    final canShowBottomIndicator = item.rect.h >= 2;
    final placeholderBar = Container(
      height: indicatorHeight,
      width: item.type == DashboardItemType.slider
          ? double.infinity
          : item.type == DashboardItemType.gauge
          ? 42
          : double.infinity,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final placeholderGeometry = _resolvePaddedPlaceholderGeometry(
          item: item,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        final bodyRect = placeholderGeometry.bodyRect;
        final shapeRadius = BorderRadius.circular(
          placeholderGeometry.cornerRadius,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              rect: bodyRect,
              child: DecoratedBox(
                key: ValueKey<String>(
                  'dashboard_builder_resize_placeholder_body_${item.id}',
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: shapeRadius,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.42),
                    width: 1.1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showTitle =
                          hasEnoughHeightForTitle &&
                          constraints.maxHeight >= 34;
                      final showBottomIndicator =
                          canShowBottomIndicator &&
                          constraints.maxHeight >= indicatorHeight + 4;

                      if (!showTitle) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: item.type == DashboardItemType.gauge
                                ? null
                                : 1,
                            child: item.type == DashboardItemType.gauge
                                ? SizedBox(width: 42, child: placeholderBar)
                                : placeholderBar,
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent.withValues(alpha: 0.84),
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (showBottomIndicator) ...[
                            const Spacer(),
                            placeholderBar,
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
