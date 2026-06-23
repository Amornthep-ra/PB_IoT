import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../../theme/app_theme.dart';
import '../../../theme/app_responsive.dart';
import '../../dashboard/models/widget_binding_model.dart';
import '../../dashboard/services/dashboard_item_runtime_binding.dart';
import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';
import '../models/dashboard_item.dart';
import '../services/dashboard_grid_metrics.dart';
import 'dashboard_item_renderer.dart';
import 'dashboard_text_contrast.dart';
import 'smart_slider_widget.dart';
import 'widget_shell_layout.dart';

part 'home_parts/dashboard_home_chrome.dart';
part 'home_parts/dashboard_home_runtime_controls.dart';

class DashboardHomeView extends StatefulWidget {
  const DashboardHomeView({
    super.key,
    required this.runtimeController,
    this.dashboardService,
    this.bottomContentPadding = 0,
    this.onScrollActivityChanged,
  });

  final DashboardRuntimeController runtimeController;
  final DashboardService? dashboardService;
  final double bottomContentPadding;
  final ValueChanged<bool>? onScrollActivityChanged;

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView>
    with SingleTickerProviderStateMixin {
  static const double _gridGap = DashboardGridMetrics.gridGap;
  static const double _canvasHorizontalPadding = 0;
  static const double _canvasTopPadding = 0;
  static const double _canvasBottomScrollPadding = 24;
  static const double _emptyCanvasMinHeight = 420;
  static const double _emptyCanvasMaxHeight = 520;
  static const Duration _controlTapCooldown = Duration(milliseconds: 1500);
  static const Duration _highlightDuration = Duration(milliseconds: 1800);

  late final DashboardService _dashboardService =
      widget.dashboardService ?? DashboardService();
  final Map<String, Timer> _controlWriteDebounceTimers = <String, Timer>{};
  final Set<String> _controlWriteInFlight = <String>{};
  final Map<String, _QueuedControlWrite> _controlWriteInFlightPayloads =
      <String, _QueuedControlWrite>{};
  final Map<String, _QueuedControlWrite> _queuedControlWrites =
      <String, _QueuedControlWrite>{};
  final Map<String, DateTime> _recentControlInteractions = <String, DateTime>{};
  final Map<String, GlobalKey> _itemHighlightKeys = <String, GlobalKey>{};
  late final AnimationController _highlightController;
  late final Animation<double> _highlightAlpha;
  String? _highlightedItemId;
  int _controlWriteRevision = 0;
  bool _runtimeRefreshFrameScheduled = false;

  DashboardRuntimeController get _runtimeController => widget.runtimeController;
  List<DashboardItem> get _items => _runtimeController.items;
  bool get _isLoading => _runtimeController.isLoading;
  String? get _errorText => _runtimeController.errorText;
  String get _dashboardTitle => _runtimeController.dashboardTitle;
  BoxDecoration get _pageDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[DashboardRuntimeTheme.backgroundColor, Color(0xFFF8FBF8)],
    ),
  );
  BoxDecoration get _canvasDecoration => AppGlassTheme.surfaceDecoration(
    radius: 28,
    borderAlpha: 0.58,
    colors: _runtimeController.themePreset.canvasColors,
    shadows: AppGlassTheme.shadowSm,
  );

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: _highlightDuration,
    );
    _highlightAlpha = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_highlightController);
    _runtimeController.addListener(_handleRuntimeChanged);
    _runtimeController.highlightItemIdNotifier.addListener(
      _handleHighlightRequest,
    );
    unawaited(_runtimeController.initialize());

    // If a highlight was requested before this view mounted (e.g. user tapped
    // from the Devices tab while the Dashboard tab was not yet built), react
    // to the pending request once the first layout settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_runtimeController.highlightItemIdNotifier.value != null) {
        _handleHighlightRequest();
      }
    });
  }

  @override
  void dispose() {
    _runtimeController.removeListener(_handleRuntimeChanged);
    _runtimeController.highlightItemIdNotifier.removeListener(
      _handleHighlightRequest,
    );
    _highlightController.dispose();
    for (final timer in _controlWriteDebounceTimers.values) {
      timer.cancel();
    }
    _controlWriteDebounceTimers.clear();
    _controlWriteInFlightPayloads.clear();
    _queuedControlWrites.clear();
    super.dispose();
  }

  void _handleHighlightRequest() {
    final targetId = _runtimeController.highlightItemIdNotifier.value;
    if (targetId == null || !mounted) {
      return;
    }

    // Wait until the target widget has been laid out so that
    // Scrollable.ensureVisible can compute its final offset.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final key = _itemHighlightKeys[targetId];
      final context = key?.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          alignment: 0.35,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
      if (!mounted) {
        return;
      }

      setState(() {
        _highlightedItemId = targetId;
      });
      _highlightController
        ..stop()
        ..reset();
      unawaited(_highlightController.forward());
      Future<void>.delayed(
        _highlightDuration + const Duration(milliseconds: 80),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            _highlightedItemId = null;
          });
        },
      );

      _runtimeController.consumeHighlightRequest();
    });
  }

  void _handleRuntimeChanged() {
    if (!mounted) {
      return;
    }
    _setStateSafely(() {});
  }

  void _setStateSafely(VoidCallback update) {
    if (!mounted) {
      return;
    }

    void applyUpdate() {
      if (!mounted) {
        return;
      }
      setState(update);
    }

    try {
      applyUpdate();
    } on FlutterError {
      if (_runtimeRefreshFrameScheduled) {
        return;
      }
      _runtimeRefreshFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runtimeRefreshFrameScheduled = false;
        applyUpdate();
      });
    }
  }

  Future<void> _reloadDashboardDataAfterBuilder() async {
    await _runtimeController.reloadFromStorageAndSnapshot();
  }

  Future<void> _openDashboardBuilder() async {
    await Navigator.pushNamed(context, '/dashboard-builder');
    if (!mounted) {
      return;
    }
    await _reloadDashboardDataAfterBuilder();
  }

  int _columnsForWidth(double width) {
    return DashboardGridMetrics.columnsForWidth(width);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DashboardRuntimeTheme.buttonEndColor,
        ),
      );
    }

    return DecoratedBox(
      decoration: _pageDecoration,
      child: SafeArea(
        bottom: false,
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomScrollPadding =
                _canvasBottomScrollPadding + widget.bottomContentPadding;
            final viewportCanvasWidth =
                constraints.maxWidth - (_canvasHorizontalPadding * 2);
            final canvasWidth = AppResponsiveLayout.dashboardCanvasWidth(
              viewportCanvasWidth,
            );
            final isTablet = AppResponsiveLayout.isTabletWidth(
              constraints.maxWidth,
            );
            final shellMaxWidth = isTablet
                ? AppResponsiveLayout.dashboardShellWidth(constraints.maxWidth)
                : double.infinity;
            final topScrollPadding = isTablet ? 24.0 : _canvasTopPadding + 8;
            final columns = _columnsForWidth(canvasWidth);
            final cellWidth = DashboardGridMetrics.cellWidthFor(
              width: canvasWidth,
              columns: columns,
            );
            final rowHeight = DashboardGridMetrics.rowHeightFor(cellWidth);
            final stepX = DashboardGridMetrics.stepFor(cellWidth);
            final stepY = DashboardGridMetrics.stepFor(rowHeight);
            final maxBottom = _items.fold<int>(
              0,
              (current, item) =>
                  item.rect.bottom > current ? item.rect.bottom : current,
            );
            final viewportCanvasHeight =
                (constraints.maxHeight -
                        _canvasTopPadding -
                        bottomScrollPadding)
                    .clamp(0.0, double.infinity);
            final isEmptyDashboard = _items.isEmpty;
            final minVisibleRows =
                ((viewportCanvasHeight + _gridGap) / (rowHeight + _gridGap))
                    .ceil();
            final rows = math.max(minVisibleRows, maxBottom).clamp(6, 72);
            final contentHeight = (rows * rowHeight) + ((rows - 1) * _gridGap);
            final emptyCanvasHeight = viewportCanvasHeight.clamp(
              _emptyCanvasMinHeight,
              _emptyCanvasMaxHeight,
            );
            final canvasHeight = isEmptyDashboard
                ? emptyCanvasHeight
                : (contentHeight < viewportCanvasHeight
                      ? viewportCanvasHeight
                      : contentHeight);

            return NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  _canvasHorizontalPadding,
                  topScrollPadding,
                  _canvasHorizontalPadding,
                  bottomScrollPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: shellMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                key: const ValueKey<String>(
                                  'dashboard_header_surface',
                                ),
                                decoration: AppGlassTheme.surfaceDecoration(
                                  radius: 22,
                                  borderAlpha: 0.60,
                                  colors: <Color>[
                                    const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.66),
                                    const Color(
                                      0xFFF4FBF7,
                                    ).withValues(alpha: 0.40),
                                  ],
                                  shadows: AppGlassTheme.shadowMd,
                                ),
                                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                                child: LayoutBuilder(
                                  builder: (context, headerConstraints) {
                                    final titleWidget = Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          _dashboardTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            height: 1.1,
                                            color: DashboardRuntimeTheme
                                                .fieldTextColor,
                                          ),
                                        ),
                                      ),
                                    );
                                    final builderButton =
                                        _DashboardBuilderButton(
                                          label: 'เพิ่มวิดเจ็ต',
                                          icon: Icons.add_rounded,
                                          isCompact: true,
                                          onTap: _openDashboardBuilder,
                                        );

                                    return Row(
                                      children: [
                                        Expanded(child: titleWidget),
                                        const SizedBox(width: 4),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: builderButton,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_errorText != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _buildErrorBanner(_errorText!),
                      ),
                    ],
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: canvasWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              key: const ValueKey<String>(
                                'dashboard_canvas_surface',
                              ),
                              decoration: _canvasDecoration,
                              child: SizedBox(
                                height: canvasHeight,
                                child: isEmptyDashboard
                                    ? _buildEmptyState()
                                    : Stack(
                                        clipBehavior: Clip.hardEdge,
                                        children: [
                                          for (final item in _items)
                                            Positioned(
                                              key: ValueKey(item.id),
                                              left: item.rect.x * stepX,
                                              top: item.rect.y * stepY,
                                              width:
                                                  DashboardGridMetrics.itemWidthFor(
                                                    rect: item.rect,
                                                    cellWidth: cellWidth,
                                                  ),
                                              height:
                                                  DashboardGridMetrics.itemHeightFor(
                                                    rect: item.rect,
                                                    rowHeight: rowHeight,
                                                  ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                child: KeyedSubtree(
                                                  key: _itemHighlightKeys
                                                      .putIfAbsent(
                                                        item.id,
                                                        () => GlobalKey(),
                                                      ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: Opacity(
                                                          opacity:
                                                              _isItemInteractionLocked(
                                                                item,
                                                              )
                                                              ? 0.72
                                                              : 1,
                                                          child: Builder(
                                                            builder: (context) {
                                                              return DashboardItemRenderer(
                                                                item: item,
                                                                themePreset:
                                                                    _runtimeController
                                                                        .themePreset,
                                                                isEditMode:
                                                                    false,
                                                                enableInteraction:
                                                                    !_isItemInteractionLocked(
                                                                      item,
                                                                    ),
                                                                onItemChanged:
                                                                    _updateItemFromRenderer,
                                                                paintTitle:
                                                                    false,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      if (_highlightedItemId ==
                                                          item.id)
                                                        Positioned.fill(
                                                          child: IgnorePointer(
                                                            child: AnimatedBuilder(
                                                              animation:
                                                                  _highlightAlpha,
                                                              builder: (context, child) {
                                                                final alpha =
                                                                    _highlightAlpha
                                                                        .value;
                                                                return _DashboardItemHighlightOverlay(
                                                                  item: item,
                                                                  alpha: alpha,
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      if (_isItemInteractionLocked(
                                                        item,
                                                      ))
                                                        const Positioned.fill(
                                                          child: AbsorbPointer(
                                                            child:
                                                                SizedBox.expand(),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          for (final item in _items)
                                            _buildPositionedItemTitleOverlay(
                                              item: item,
                                              cellWidth: cellWidth,
                                              rowHeight: rowHeight,
                                              stepX: stepX,
                                              stepY: stepY,
                                            ),
                                        ],
                                      ),
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
          },
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final callback = widget.onScrollActivityChanged;
    if (callback == null || notification.depth != 0) {
      return false;
    }

    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      callback(false);
    } else if (notification is ScrollStartNotification ||
        notification is UserScrollNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      callback(true);
    } else if (notification is ScrollEndNotification) {
      callback(false);
    }
    return false;
  }

  Widget _buildPositionedItemTitleOverlay({
    required DashboardItem item,
    required double cellWidth,
    required double rowHeight,
    required double stepX,
    required double stepY,
  }) {
    if (!_shouldRenderRuntimeTitle(item)) {
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
    final style = _runtimeWidgetTitleStyle(item);
    final titleHeight = _runtimeWidgetTitleHeight(style);
    final isBottomTitle =
        item.titlePosition.trim().toLowerCase() ==
        DashboardItemTitlePosition.bottomOutside;

    return Positioned(
      left: left,
      top: isBottomTitle ? top + height - titleHeight : top,
      width: width,
      height: titleHeight,
      child: IgnorePointer(
        child: _DashboardWidgetTitleOverlay(
          text: item.title.toUpperCase(),
          style: style,
        ),
      ),
    );
  }

  bool _shouldRenderRuntimeTitle(DashboardItem item) {
    final title = item.title.trim();
    return title.isNotEmpty &&
        item.titlePosition.trim().toLowerCase() !=
            DashboardItemTitlePosition.hidden &&
        !_isFactoryDefaultTitle(item);
  }

  bool _isFactoryDefaultTitle(DashboardItem item) {
    return dashboardIsDefaultTitleForType(item.type, item.title);
  }

  TextStyle _runtimeWidgetTitleStyle(DashboardItem item) {
    final themePreset = _runtimeController.themePreset;
    final fontSize = (item.titleFontSize ?? 10.0).clamp(7.0, 12.0);

    final canvasColor = themePreset.canvasColors.isNotEmpty
        ? themePreset.canvasColors.first
        : themePreset.pageEnd;

    final isCanvasDark =
        ThemeData.estimateBrightnessForColor(canvasColor) == Brightness.dark;

    final fallback = isCanvasDark ? Colors.white : themePreset.headlineColor;

    final titleColor = item.titleColor ?? fallback;

    final resolvedTitleColor = DashboardTextContrast.readableTextColor(
      preferred: titleColor,
      background: canvasColor,
      fallback: fallback,
      minRatio: 4.5,
    );

    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: resolvedTitleColor.withValues(alpha: isCanvasDark ? 0.96 : 1.0),
      shadows: isCanvasDark
          ? <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: 0.28),
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

  double _runtimeWidgetTitleHeight(TextStyle style) {
    return ((style.fontSize ?? 10.0) * 1.4).clamp(12.0, 24.0);
  }
}
