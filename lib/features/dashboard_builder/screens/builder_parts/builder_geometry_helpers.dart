part of '../dashboard_builder_screen.dart';

class _DashboardEditorGeometry {
  const _DashboardEditorGeometry({
    required this.selectionRect,
    required this.previewOverlayRect,
    required this.placeholderBodyRect,
    required this.selectionCornerRadius,
    required this.previewCornerRadius,
    required this.placeholderCornerRadius,
  });

  final Rect selectionRect;
  final Rect previewOverlayRect;
  final Rect placeholderBodyRect;
  final double selectionCornerRadius;
  final double previewCornerRadius;
  final double placeholderCornerRadius;
}

class _DashboardPlaceholderGeometry {
  const _DashboardPlaceholderGeometry({
    required this.bodyRect,
    required this.cornerRadius,
  });

  final Rect bodyRect;
  final double cornerRadius;
}

class _DashboardEditorChromePalette {
  const _DashboardEditorChromePalette({
    required this.selectionBorder,
    required this.activeSelectionBorder,
    required this.fillStart,
    required this.fillEnd,
    required this.halo,
    required this.ambient,
    required this.whiteHighlight,
  });

  final Color selectionBorder;
  final Color activeSelectionBorder;
  final Color fillStart;
  final Color fillEnd;
  final Color halo;
  final Color ambient;
  final Color whiteHighlight;
}

const _dashboardEditorChromePalette = _DashboardEditorChromePalette(
  selectionBorder: Color(0xFF2FAE7A),
  activeSelectionBorder: Color(0xFF159A66),
  fillStart: Color(0xFFDDF8E9),
  fillEnd: Color(0xFFAEEBCB),
  halo: Color(0xFF8BDBB5),
  ambient: Color(0xFF31B77E),
  whiteHighlight: Colors.white,
);

BoxDecoration _dashboardSelectionChromeDecoration({
  required bool isActivelyManipulating,
  required double radius,
}) {
  final palette = _dashboardEditorChromePalette;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        palette.fillStart.withValues(
          alpha: isActivelyManipulating ? 0.15 : 0.055,
        ),
        palette.fillEnd.withValues(
          alpha: isActivelyManipulating ? 0.07 : 0.018,
        ),
      ],
    ),
    border: Border.all(
      color:
          (isActivelyManipulating
                  ? palette.activeSelectionBorder
                  : palette.selectionBorder)
              .withValues(alpha: isActivelyManipulating ? 0.88 : 0.68),
      width: isActivelyManipulating ? 1.7 : 1.15,
    ),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: palette.whiteHighlight.withValues(
          alpha: isActivelyManipulating ? 0.16 : 0.075,
        ),
        blurRadius: 7,
        offset: const Offset(0, -1),
      ),
      BoxShadow(
        color: palette.halo.withValues(
          alpha: isActivelyManipulating ? 0.12 : 0.055,
        ),
        blurRadius: isActivelyManipulating ? 14 : 8,
        spreadRadius: isActivelyManipulating ? 0.4 : 0.02,
      ),
      BoxShadow(
        color: palette.ambient.withValues(
          alpha: isActivelyManipulating ? 0.09 : 0.035,
        ),
        blurRadius: isActivelyManipulating ? 16 : 9,
        spreadRadius: 0.02,
      ),
    ],
  );
}

BoxDecoration _dashboardPreviewOverlayDecoration({
  required bool isInvalid,
  required double radius,
}) {
  if (isInvalid) {
    const borderColor = Color(0xFFD16A6A);
    const fillStartColor = Color(0xFFF5BCB7);
    const fillEndColor = Color(0xFFE78982);
    const glowColor = Color(0xFFF3B6B6);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          fillStartColor.withValues(alpha: 0.18),
          fillEndColor.withValues(alpha: 0.10),
        ],
      ),
      border: Border.all(
        color: borderColor.withValues(alpha: 0.82),
        width: 1.45,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.10),
          blurRadius: 10,
          offset: const Offset(0, -1),
        ),
        BoxShadow(
          color: glowColor.withValues(alpha: 0.13),
          blurRadius: 16,
          spreadRadius: 0.35,
        ),
      ],
    );
  }

  final palette = _dashboardEditorChromePalette;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        palette.fillStart.withValues(alpha: 0.10),
        palette.fillEnd.withValues(alpha: 0.04),
      ],
    ),
    border: Border.all(
      color: palette.activeSelectionBorder.withValues(alpha: 0.78),
      width: 1.25,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.07),
        blurRadius: 7,
        offset: const Offset(0, -1),
      ),
      BoxShadow(
        color: palette.halo.withValues(alpha: 0.075),
        blurRadius: 12,
        spreadRadius: 0.1,
      ),
    ],
  );
}

extension _DashboardBuilderGeometryHelpers on _DashboardBuilderScreenState {
  int _columnsForWidth(double width) {
    return DashboardGridMetrics.columnsForWidth(width);
  }

  _DashboardEditorGeometry _resolveEditorGeometry({
    required DashboardItem item,
    required double width,
    required double height,
  }) {
    const itemVisualInset = 2.0;
    final contentWidth = math.max(0.0, width - (itemVisualInset * 2));
    final contentHeight = math.max(0.0, height - (itemVisualInset * 2));

    if (item.type == DashboardItemType.button) {
      final shellGeometry = resolveButtonShellGeometry(
        width: contentWidth,
        height: contentHeight,
      );
      final shellRect = Rect.fromLTWH(
        itemVisualInset + shellGeometry.shellRect.left,
        itemVisualInset + shellGeometry.shellRect.top,
        shellGeometry.shellRect.width,
        shellGeometry.shellRect.height,
      );
      final shellRadius = math.max(0.0, shellGeometry.shellCornerRadius);
      return _DashboardEditorGeometry(
        selectionRect: shellRect,
        previewOverlayRect: shellRect,
        placeholderBodyRect: shellRect,
        selectionCornerRadius: shellRadius,
        previewCornerRadius: shellRadius,
        placeholderCornerRadius: shellRadius,
      );
    }

    if (item.type == DashboardItemType.slider) {
      final shellRect = Rect.fromLTWH(
        itemVisualInset,
        itemVisualInset,
        contentWidth,
        contentHeight,
      );
      const shellRadius = 24.0;
      return _DashboardEditorGeometry(
        selectionRect: shellRect,
        previewOverlayRect: shellRect,
        placeholderBodyRect: shellRect,
        selectionCornerRadius: shellRadius,
        previewCornerRadius: shellRadius,
        placeholderCornerRadius: shellRadius,
      );
    }

    if (item.type == DashboardItemType.gauge) {
      final selectionRect = Rect.fromLTWH(
        itemVisualInset,
        itemVisualInset,
        contentWidth,
        contentHeight,
      );
      final previewRect = _gaugePreviewBodyRect(
        left: itemVisualInset,
        top: itemVisualInset,
        width: contentWidth,
        height: contentHeight,
      );
      return _DashboardEditorGeometry(
        selectionRect: selectionRect,
        previewOverlayRect: previewRect,
        placeholderBodyRect: previewRect,
        selectionCornerRadius: 24.0,
        previewCornerRadius: previewRect.shortestSide / 2,
        placeholderCornerRadius: previewRect.shortestSide / 2,
      );
    }

    if (item.type == DashboardItemType.led) {
      final selectionRect = Rect.fromLTWH(
        itemVisualInset,
        itemVisualInset,
        contentWidth,
        contentHeight,
      );
      final previewRect = _ledPreviewBodyRect(
        left: itemVisualInset,
        top: itemVisualInset,
        width: contentWidth,
        height: contentHeight,
      );
      final selectionRadius = selectionRect.shortestSide / 2;
      return _DashboardEditorGeometry(
        selectionRect: selectionRect,
        previewOverlayRect: previewRect,
        placeholderBodyRect: previewRect,
        selectionCornerRadius: selectionRadius,
        previewCornerRadius: previewRect.shortestSide / 2,
        placeholderCornerRadius: previewRect.shortestSide / 2,
      );
    }

    if (item.type == DashboardItemType.valueLabel ||
        item.type == DashboardItemType.toggle) {
      final selectionRect = Rect.fromLTWH(
        itemVisualInset,
        itemVisualInset,
        contentWidth,
        contentHeight,
      );
      final selectionRadius = item.type == DashboardItemType.toggle
          ? math.max(0.0, (height / 2) - itemVisualInset)
          : 24.0;
      return _DashboardEditorGeometry(
        selectionRect: selectionRect,
        previewOverlayRect: selectionRect,
        placeholderBodyRect: selectionRect,
        selectionCornerRadius: selectionRadius,
        previewCornerRadius: selectionRadius,
        placeholderCornerRadius: selectionRadius,
      );
    }

    final defaultRect = Rect.fromLTWH(0, 0, width, height);
    return _DashboardEditorGeometry(
      selectionRect: defaultRect,
      previewOverlayRect: defaultRect,
      placeholderBodyRect: defaultRect,
      selectionCornerRadius: 24.0,
      previewCornerRadius: 24.0,
      placeholderCornerRadius: 24.0,
    );
  }

  _DashboardPlaceholderGeometry _resolvePaddedPlaceholderGeometry({
    required DashboardItem item,
    required double width,
    required double height,
  }) {
    final editorGeometry = _resolveEditorGeometry(
      item: item,
      width: math.max(0.0, width + 4),
      height: math.max(0.0, height + 4),
    );
    return _DashboardPlaceholderGeometry(
      bodyRect: editorGeometry.placeholderBodyRect.shift(const Offset(-2, -2)),
      cornerRadius: editorGeometry.placeholderCornerRadius,
    );
  }

  Rect _centeredSquareRect({
    required double left,
    required double top,
    required double width,
    required double height,
    required double side,
  }) {
    final resolvedSide = side.clamp(0.0, math.min(width, height)).toDouble();
    return Rect.fromLTWH(
      left + ((width - resolvedSide) / 2),
      top + ((height - resolvedSide) / 2),
      resolvedSide,
      resolvedSide,
    );
  }

  Rect _gaugePreviewBodyRect({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final shortestSide = math.min(width, height);
    final controlInset = shortestSide >= 56
        ? 11.0
        : (shortestSide * 0.18).clamp(4.0, 11.0).toDouble();
    final side = math.max(
      0.0,
      math.min(width - (controlInset * 2), height - (controlInset * 2)),
    );
    return _centeredSquareRect(
      left: left,
      top: top,
      width: width,
      height: height,
      side: side,
    );
  }

  Rect _ledPreviewBodyRect({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final shellPadding = math.min(width, height) < 54 ? 5.0 : 7.0;
    final innerWidth = math.max(0.0, width - (shellPadding * 2));
    final innerHeight = math.max(0.0, height - (shellPadding * 2));
    final compact = height < 70;
    final side = (math.min(innerWidth, innerHeight) * (compact ? 0.70 : 0.76))
        .clamp(0.0, 64.0)
        .toDouble();
    return _centeredSquareRect(
      left: left + shellPadding,
      top: top + shellPadding,
      width: innerWidth,
      height: innerHeight,
      side: side,
    );
  }

  GridRect _effectiveCollisionRect({
    required DashboardItem item,
    required GridRect rect,
    required double rowHeight,
  }) {
    if (item.type != DashboardItemType.slider ||
        rowHeight <
            _DashboardBuilderScreenState._sliderCompactCollisionCellThreshold ||
        rect.h <= 1) {
      return rect;
    }

    const itemVisualInset = 2.0;
    final pixelWidth = DashboardGridMetrics.itemWidthFor(
      rect: rect,
      cellWidth: rowHeight,
    );
    final pixelHeight = DashboardGridMetrics.itemHeightFor(
      rect: rect,
      rowHeight: rowHeight,
    );
    final contentWidth = math.max(0.0, pixelWidth - (itemVisualInset * 2));
    final contentHeight = math.max(0.0, pixelHeight - (itemVisualInset * 2));
    final layout = buildSliderShellLayout(
      width: contentWidth,
      height: contentHeight,
      desiredShellHeight: SmartSliderVisualSpec.desiredShellHeight,
      shellBottomInsetFor: SmartSliderVisualSpec.shellBottomInsetFor,
    );
    final topInset = itemVisualInset + layout.shellTopInset;
    final compactTopRows = (topInset / rowHeight)
        .floor()
        .clamp(0, rect.h - 1)
        .toInt();
    if (compactTopRows <= 0) {
      return rect;
    }

    return rect.copyWith(
      y: rect.y + compactTopRows,
      h: rect.h - compactTopRows,
    );
  }

  bool _visualCollisionOverlaps({
    required DashboardItem leftItem,
    required GridRect leftRect,
    required DashboardItem rightItem,
    required GridRect rightRect,
    required double rowHeight,
  }) {
    return DashboardLayoutEngine.overlaps(
      _effectiveCollisionRect(
        item: leftItem,
        rect: leftRect,
        rowHeight: rowHeight,
      ),
      _effectiveCollisionRect(
        item: rightItem,
        rect: rightRect,
        rowHeight: rowHeight,
      ),
    );
  }

  bool _canResizeHorizontally(DashboardItem item) => item.minW != item.maxW;

  bool _canResizeVertically(DashboardItem item) => item.minH != item.maxH;

  GridRect _defaultButtonRect({
    required String title,
    required double canvasWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final normalizedTitle = title.trim().isEmpty ? 'Button' : title.trim();
    final minimumRect = _minimumButtonRect(
      title: normalizedTitle,
      canvasWidth: canvasWidth,
      textScaler: textScaler,
      textDirection: textDirection,
    );
    final columns = _columnsForWidth(canvasWidth);
    final cellWidth = DashboardGridMetrics.cellWidthFor(
      width: canvasWidth,
      columns: columns,
    );
    final rowHeight = DashboardGridMetrics.rowHeightFor(cellWidth);

    for (
      var gridW = minimumRect.w > 4 ? minimumRect.w : 4;
      gridW <= 20;
      gridW += 1
    ) {
      for (
        var gridH = minimumRect.h > 4 ? minimumRect.h : 4;
        gridH <= 10;
        gridH += 1
      ) {
        if (_buttonContentFits(
          title: normalizedTitle,
          gridW: gridW,
          gridH: gridH,
          cellWidth: cellWidth,
          rowHeight: rowHeight,
          textScaler: textScaler,
          textDirection: textDirection,
        )) {
          return GridRect(x: 0, y: 0, w: gridW, h: gridH);
        }
      }
    }

    return minimumRect;
  }

  double _fallbackCanvasWidth() {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return 360;
    }

    final availableWidth = (mediaQuery.size.width - 32).clamp(
      240.0,
      double.infinity,
    );
    return AppResponsiveLayout.dashboardCanvasWidth(availableWidth);
  }

  GridRect _minimumButtonRect({
    required String title,
    double? canvasWidth,
    TextScaler? textScaler,
    TextDirection? textDirection,
  }) {
    final effectiveCanvasWidth = canvasWidth ?? _fallbackCanvasWidth();
    final effectiveTextScaler =
        textScaler ??
        MediaQuery.maybeTextScalerOf(context) ??
        TextScaler.noScaling;
    final effectiveTextDirection =
        textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;
    final normalizedTitle = title.trim().isEmpty ? 'Button' : title.trim();
    final columns = _columnsForWidth(effectiveCanvasWidth);
    final cellWidth = DashboardGridMetrics.cellWidthFor(
      width: effectiveCanvasWidth,
      columns: columns,
    );
    final rowHeight = DashboardGridMetrics.rowHeightFor(cellWidth);
    GridRect? bestRect;

    for (
      var gridW = _DashboardBuilderScreenState._buttonMinW;
      gridW <= _DashboardBuilderScreenState._buttonMaxW;
      gridW += 1
    ) {
      for (
        var gridH = _DashboardBuilderScreenState._buttonMinH;
        gridH <= _DashboardBuilderScreenState._buttonMaxH;
        gridH += 1
      ) {
        if (!_buttonContentFits(
          title: normalizedTitle,
          gridW: gridW,
          gridH: gridH,
          cellWidth: cellWidth,
          rowHeight: rowHeight,
          textScaler: effectiveTextScaler,
          textDirection: effectiveTextDirection,
        )) {
          continue;
        }

        final candidate = GridRect(x: 0, y: 0, w: gridW, h: gridH);
        if (bestRect == null) {
          bestRect = candidate;
          continue;
        }

        final candidateArea = candidate.w * candidate.h;
        final bestArea = bestRect.w * bestRect.h;
        final isBetter =
            candidateArea < bestArea ||
            (candidateArea == bestArea && candidate.h < bestRect.h) ||
            (candidateArea == bestArea &&
                candidate.h == bestRect.h &&
                candidate.w < bestRect.w);
        if (isBetter) {
          bestRect = candidate;
        }
      }
    }

    return bestRect ?? const GridRect(x: 0, y: 0, w: 6, h: 6);
  }

  bool _buttonRectFitsItem({
    required DashboardItem item,
    required GridRect rect,
    double? canvasWidth,
    TextScaler? textScaler,
    TextDirection? textDirection,
  }) {
    final effectiveCanvasWidth = canvasWidth ?? _fallbackCanvasWidth();
    final effectiveTextScaler =
        textScaler ??
        MediaQuery.maybeTextScalerOf(context) ??
        TextScaler.noScaling;
    final effectiveTextDirection =
        textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;
    final columns = _columnsForWidth(effectiveCanvasWidth);
    final cellWidth = DashboardGridMetrics.cellWidthFor(
      width: effectiveCanvasWidth,
      columns: columns,
    );
    final rowHeight = DashboardGridMetrics.rowHeightFor(cellWidth);

    return _buttonContentFits(
      title: item.title,
      gridW: rect.w,
      gridH: rect.h,
      cellWidth: cellWidth,
      rowHeight: rowHeight,
      textScaler: effectiveTextScaler,
      textDirection: effectiveTextDirection,
    );
  }

  GridRect _clampGaugeRectToAspect({
    required DashboardItem item,
    required GridRect rect,
  }) {
    if (item.type != DashboardItemType.gauge) {
      return rect;
    }

    var w = rect.w.clamp(item.minW, item.maxW);
    var h = rect.h.clamp(item.minH, item.maxH);
    if (w <= 0 || h <= 0) {
      return rect;
    }

    for (var i = 0; i < 3; i += 1) {
      final ratio = w / h;
      if (ratio > _DashboardBuilderScreenState._gaugeMaxAspectRatio) {
        w = (h * _DashboardBuilderScreenState._gaugeMaxAspectRatio)
            .round()
            .clamp(item.minW, item.maxW);
        continue;
      }
      if (ratio < _DashboardBuilderScreenState._gaugeMinAspectRatio) {
        h = (w / _DashboardBuilderScreenState._gaugeMinAspectRatio)
            .round()
            .clamp(item.minH, item.maxH);
        continue;
      }
      break;
    }

    return rect.copyWith(w: w, h: h);
  }

  GridRect _clampToggleRectToAspect({
    required DashboardItem item,
    required GridRect rect,
  }) {
    if (item.type != DashboardItemType.toggle) {
      return rect;
    }

    var w = rect.w.clamp(item.minW, item.maxW);
    var h = rect.h.clamp(item.minH, item.maxH);
    if (w <= 0 || h <= 0) {
      return rect;
    }

    for (var i = 0; i < 3; i += 1) {
      final ratio = w / h;
      if (ratio < _DashboardBuilderScreenState._toggleMinAspectRatio) {
        w = (h * _DashboardBuilderScreenState._toggleMinAspectRatio)
            .round()
            .clamp(item.minW, item.maxW);
        continue;
      }
      if (ratio > _DashboardBuilderScreenState._toggleMaxAspectRatio) {
        h = (w / _DashboardBuilderScreenState._toggleMaxAspectRatio)
            .round()
            .clamp(item.minH, item.maxH);
        continue;
      }
      break;
    }

    return rect.copyWith(w: w, h: h);
  }

  bool _buttonContentFits({
    required String title,
    required int gridW,
    required int gridH,
    required double cellWidth,
    required double rowHeight,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final pixelWidth =
        (gridW * cellWidth) +
        ((gridW - 1) * _DashboardBuilderScreenState._gridGap);
    final pixelHeight =
        (gridH * rowHeight) +
        ((gridH - 1) * _DashboardBuilderScreenState._gridGap);

    const titleFontSize = 8.0;
    const itemVisualInset = 2.0;
    final visualWidth = math.max(0.0, pixelWidth - (itemVisualInset * 2));
    final visualHeight = math.max(0.0, pixelHeight - (itemVisualInset * 2));
    final shellGeometry = resolveButtonShellGeometry(
      width: visualWidth,
      height: visualHeight,
    );
    final controlWidth = shellGeometry.controlRect.width;
    final controlHeight = shellGeometry.controlRect.height;
    final iconSize = shellGeometry.iconSize;

    if (controlWidth <= 0 || controlHeight <= 0 || iconSize <= 0) {
      return false;
    }

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: const TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: 1,
    )..layout(maxWidth: visualWidth);

    final requiredControlHeight = iconSize + 12;
    final requiredControlWidth = iconSize + 16;

    final titleFitsHeader =
        titlePainter.width <= pixelWidth && pixelWidth >= 36;

    final controlFits =
        requiredControlHeight <= controlHeight &&
        requiredControlWidth <= controlWidth;

    return titleFitsHeader && controlFits;
  }

  DashboardItem _normalizeItem(DashboardItem item) {
    if (item.type == DashboardItemType.button) {
      final minimumRect = _minimumButtonRect(title: item.title);
      return item.copyWith(
        minW: minimumRect.w,
        minH: minimumRect.h,
        maxH: _DashboardBuilderScreenState._buttonMaxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(
            minimumRect.w,
            _DashboardBuilderScreenState._buttonMaxW,
          ),
          h: item.rect.h.clamp(
            minimumRect.h,
            _DashboardBuilderScreenState._buttonMaxH,
          ),
        ),
      );
    }

    if (item.type == DashboardItemType.gauge) {
      return item.copyWith(
        rect: _clampGaugeRectToAspect(item: item, rect: item.rect),
      );
    }

    if (item.type == DashboardItemType.toggle) {
      const minW = 5;
      const maxW = 18;
      const minH = 3;
      const maxH = 8;
      final clampedRect = _clampToggleRectToAspect(item: item, rect: item.rect);
      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: clampedRect.x,
          y: clampedRect.y,
          w: clampedRect.w.clamp(minW, maxW),
          h: clampedRect.h.clamp(minH, maxH),
        ),
      );
    }

    if (item.type == DashboardItemType.slider) {
      const minW = 10;
      const maxW = 28;
      const minH = 4;
      const maxH = 8;
      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minW, maxW),
          h: item.rect.h.clamp(minH, maxH),
        ),
      );
    }

    if (item.type == DashboardItemType.stepH) {
      const minW = 8;
      const maxW = 18;
      const minH = 3;
      const maxH = 5;

      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minW, maxW),
          h: item.rect.h.clamp(minH, maxH),
        ),
      );
    }

    if (item.type == DashboardItemType.stepV) {
      const minW = 3;
      const maxW = 5;
      const minH = 8;
      const maxH = 18;

      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minW, maxW),
          h: item.rect.h.clamp(minH, maxH),
        ),
      );
    }

    if (item.type == DashboardItemType.valueLabel) {
      const minW = 8;
      const maxW = 24;
      const minH = 3;
      const maxH = 14;

      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minW, maxW),
          h: item.rect.h.clamp(minH, maxH),
        ),
      );
    }

    if (item.type == DashboardItemType.trend) {
      const minW = 10;
      const maxW = 26;
      const minH = 5;
      const maxH = 10;

      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minW, maxW),
          h: item.rect.h.clamp(minH, maxH),
        ),
      );
    }

    if (item.type == DashboardItemType.led) {
      const minW = 4;
      const maxW = 8;
      const minH = 4;
      const maxH = 8;

      return item.copyWith(
        minW: minW,
        maxW: maxW,
        minH: minH,
        maxH: maxH,
        rect: GridRect(
          x: item.rect.x,
          y: item.rect.y,
          w: item.rect.w.clamp(minW, maxW),
          h: item.rect.h.clamp(minH, maxH),
        ),
      );
    }

    return item;
  }

  List<DashboardItem> _normalizeItems(List<DashboardItem> items) {
    return items.map(_normalizeItem).toList();
  }
}
