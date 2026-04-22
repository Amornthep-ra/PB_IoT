import 'package:flutter/material.dart';

import '../models/dashboard_layout_model.dart';
import '../models/dashboard_widget_model.dart';
import '../models/device_snapshot_model.dart';
import 'dashboard_runtime_theme.dart';
import 'dashboard_widget_renderer.dart';

class DashboardCanvas extends StatefulWidget {
  const DashboardCanvas({
    super.key,
    required this.layout,
    required this.snapshot,
    this.isEditMode = false,
    this.selectedWidgetId,
    this.onWidgetTap,
    this.onWidgetLongPress,
    this.onWidgetLayoutChanged,
    this.onWidgetControlChanged,
    this.isWidgetControlBusy,
  });

  final DashboardLayoutModel layout;
  final DeviceSnapshotModel snapshot;
  final bool isEditMode;
  final String? selectedWidgetId;
  final ValueChanged<DashboardWidgetModel>? onWidgetTap;
  final ValueChanged<DashboardWidgetModel>? onWidgetLongPress;
  final void Function(DashboardWidgetModel widget, DashboardWidgetLayout layout)?
      onWidgetLayoutChanged;
  final void Function(DashboardWidgetModel widget, Object? value)?
      onWidgetControlChanged;
  final bool Function(DashboardWidgetModel widget)? isWidgetControlBusy;

  @override
  State<DashboardCanvas> createState() => _DashboardCanvasState();
}

class _DashboardCanvasState extends State<DashboardCanvas> {
  final GlobalKey _dropZoneKey = GlobalKey();
  final Map<String, double> _resizeWidthCarry = <String, double>{};
  final Map<String, double> _resizeHeightCarry = <String, double>{};

  void _handleResizeUpdate({
    required DashboardWidgetModel widget,
    required DragUpdateDetails details,
    required int columns,
    required double columnStep,
    required double rowStep,
  }) {
    if (this.widget.onWidgetLayoutChanged == null) {
      return;
    }

    final widgetId = widget.id;
    final widthCarry = (_resizeWidthCarry[widgetId] ?? 0) + details.delta.dx;
    final heightCarry = (_resizeHeightCarry[widgetId] ?? 0) + details.delta.dy;

    var nextWidth = widget.layout.w;
    var nextHeight = widget.layout.h;
    var remainingWidthCarry = widthCarry;
    var remainingHeightCarry = heightCarry;

    while (remainingWidthCarry >= columnStep / 2) {
      nextWidth += 1;
      remainingWidthCarry -= columnStep;
    }
    while (remainingWidthCarry <= -(columnStep / 2)) {
      nextWidth -= 1;
      remainingWidthCarry += columnStep;
    }

    while (remainingHeightCarry >= rowStep / 2) {
      nextHeight += 1;
      remainingHeightCarry -= rowStep;
    }
    while (remainingHeightCarry <= -(rowStep / 2)) {
      nextHeight -= 1;
      remainingHeightCarry += rowStep;
    }

    final maxWidth = (columns - widget.layout.x).clamp(1, columns);
    nextWidth = nextWidth.clamp(1, maxWidth);
    nextHeight = nextHeight.clamp(1, 6);

    _resizeWidthCarry[widgetId] = remainingWidthCarry;
    _resizeHeightCarry[widgetId] = remainingHeightCarry;

    if (nextWidth == widget.layout.w && nextHeight == widget.layout.h) {
      return;
    }

    this.widget.onWidgetLayoutChanged!(
      widget,
      widget.layout.copyWith(w: nextWidth, h: nextHeight),
    );
  }

  void _clearResizeCarry(String widgetId) {
    _resizeWidthCarry.remove(widgetId);
    _resizeHeightCarry.remove(widgetId);
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    if (layout.widgets.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text('No widgets added yet.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 12.0;
        final columns = width >= 720 ? 4 : 2;
        final columnWidth = (width - (spacing * (columns - 1))) / columns;
        const rowHeight = 124.0;
        final columnStep = columnWidth + spacing;
        final rowStep = rowHeight + spacing;

        final maxRows = layout.widgets.fold<int>(0, (current, widget) {
          final bottom = widget.layout.y + widget.layout.h;
          return bottom > current ? bottom : current;
        });

        final canvasHeight = (maxRows * rowHeight) +
            ((maxRows - 1).clamp(0, 9999) * spacing);

        DashboardWidgetLayout buildDraggedLayout(
          Offset globalOffset,
          DashboardWidgetModel draggedWidget,
        ) {
          final renderBox =
              _dropZoneKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) {
            return draggedWidget.layout;
          }

          final localOffset = renderBox.globalToLocal(globalOffset);
          final maxX = (columns - draggedWidget.layout.w).clamp(0, columns - 1);

          final nextX = (localOffset.dx / columnStep).round().clamp(0, maxX);
          final nextY = (localOffset.dy / rowStep).round().clamp(0, 999);

          return draggedWidget.layout.copyWith(x: nextX, y: nextY);
        }

        return DragTarget<DashboardWidgetModel>(
          key: _dropZoneKey,
          onWillAcceptWithDetails: (_) => widget.isEditMode,
          onAcceptWithDetails: (details) {
            if (!widget.isEditMode || widget.onWidgetLayoutChanged == null) {
              return;
            }
            final nextLayout = buildDraggedLayout(details.offset, details.data);
            widget.onWidgetLayoutChanged!(details.data, nextLayout);
          },
          builder: (context, candidateData, rejectedData) {
            return SizedBox(
              height: canvasHeight <= 0 ? rowHeight : canvasHeight,
              child: Stack(
                children: layout.widgets.map((currentWidget) {
                  final x = currentWidget.layout.x.clamp(0, columns - 1);
                  final y = currentWidget.layout.y.clamp(0, 9999);
                  final w = currentWidget.layout.w.clamp(1, columns);
                  final h = currentWidget.layout.h.clamp(1, 6);
                  final span = (x + w) > columns ? (columns - x) : w;

                  final left = (columnWidth + spacing) * x;
                  final top = (rowHeight + spacing) * y;
                  final itemWidth =
                      (columnWidth * span) + (spacing * (span - 1));
                  final itemHeight = (rowHeight * h) + (spacing * (h - 1));
                  final isSelected = widget.selectedWidgetId == currentWidget.id;
                  final controlBusy =
                      widget.isWidgetControlBusy?.call(currentWidget) ?? false;
                  final canKeepInteractionWhileBusy =
                      currentWidget.type == DashboardWidgetType.button ||
                      currentWidget.type == DashboardWidgetType.switchControl;

                  Widget tile = GestureDetector(
                    onTap: widget.onWidgetTap != null
                        ? () => widget.onWidgetTap!(currentWidget)
                        : null,
                    onLongPress: !widget.isEditMode && widget.onWidgetLongPress != null
                        ? () => widget.onWidgetLongPress!(currentWidget)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: widget.isEditMode && isSelected
                            ? Border.all(
                                color: DashboardRuntimeTheme.surfaceBorderFocusColor,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: controlBusy ? 0.72 : 1,
                              child: DashboardWidgetRenderer(
                                widget: currentWidget,
                                snapshot: widget.snapshot,
                                onControlValueChanged: widget.onWidgetControlChanged,
                                enableControlInteraction:
                                    !controlBusy || canKeepInteractionWhileBusy,
                              ),
                            ),
                          ),
                          if (widget.isEditMode && isSelected)
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) => _handleResizeUpdate(
                                  widget: currentWidget,
                                  details: details,
                                  columns: columns,
                                  columnStep: columnStep,
                                  rowStep: rowStep,
                                ),
                                onPanEnd: (_) => _clearResizeCarry(currentWidget.id),
                                onPanCancel: () => _clearResizeCarry(currentWidget.id),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    gradient: DashboardRuntimeTheme.accentGradient(),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.34),
                                      width: 0.9,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DashboardRuntimeTheme.buttonGlowColor
                                            .withValues(alpha: 0.18),
                                        blurRadius: 14,
                                      ),
                                      const BoxShadow(
                                        color: DashboardRuntimeTheme.shadowDarkColor,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.open_in_full_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );

                  if (widget.isEditMode) {
                    tile = LongPressDraggable<DashboardWidgetModel>(
                      data: currentWidget,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      onDragStarted: () {
                        if (widget.onWidgetLongPress != null) {
                          widget.onWidgetLongPress!(currentWidget);
                        }
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: Opacity(
                            opacity: 0.9,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF1F9443),
                                  width: 2,
                                ),
                              ),
                                child: DashboardWidgetRenderer(
                                  widget: currentWidget,
                                  snapshot: widget.snapshot,
                                  onControlValueChanged: widget.onWidgetControlChanged,
                                  enableControlInteraction:
                                      !controlBusy || canKeepInteractionWhileBusy,
                                ),
                             ),
                           ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: tile,
                      ),
                      child: tile,
                    );
                  }

                  return Positioned(
                    left: left,
                    top: top,
                    width: itemWidth,
                    height: itemHeight,
                    child: tile,
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
