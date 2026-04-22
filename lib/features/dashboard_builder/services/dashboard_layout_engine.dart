import '../models/dashboard_item.dart';

class LayoutResolution {
  const LayoutResolution({
    required this.items,
    required this.activeRect,
  });

  final List<DashboardItem> items;
  final GridRect activeRect;
}

class DashboardLayoutEngine {
  const DashboardLayoutEngine._();

  static GridRect clampRect({
    required DashboardItem item,
    required GridRect rect,
    required int columns,
    required int maxRows,
  }) {
    final width = rect.w.clamp(item.minW, item.maxW);
    final height = rect.h.clamp(item.minH, item.maxH);
    final x = rect.x.clamp(0, columns - width);
    final y = rect.y.clamp(0, maxRows - height);
    return GridRect(x: x, y: y, w: width, h: height);
  }

  static bool overlaps(GridRect left, GridRect right) {
    return left.x < right.right &&
        left.right > right.x &&
        left.y < right.bottom &&
        left.bottom > right.y;
  }

  static LayoutResolution? resolvePlacement({
    required List<DashboardItem> items,
    required String activeId,
    required GridRect candidateRect,
    required int columns,
    required int maxRows,
  }) {
    final activeItem = items.firstWhere((item) => item.id == activeId);
    final activeRect = clampRect(
      item: activeItem,
      rect: candidateRect,
      columns: columns,
      maxRows: maxRows,
    );

    final remaining = items.where((item) => item.id != activeId).toList()
      ..sort((left, right) {
        final byRow = left.rect.y.compareTo(right.rect.y);
        return byRow != 0 ? byRow : left.rect.x.compareTo(right.rect.x);
      });

    final resolved = <DashboardItem>[
      activeItem.copyWith(rect: activeRect),
    ];

    for (final item in remaining) {
      var nextRect = clampRect(
        item: item,
        rect: item.rect,
        columns: columns,
        maxRows: maxRows,
      );

      while (resolved.any((other) => overlaps(nextRect, other.rect))) {
        nextRect = nextRect.copyWith(y: nextRect.y + 1);
        if (nextRect.bottom > maxRows) {
          return null;
        }
      }

      resolved.add(item.copyWith(rect: nextRect));
    }

    final finalActive = resolved.firstWhere((item) => item.id == activeId);
    return LayoutResolution(items: resolved, activeRect: finalActive.rect);
  }

  static GridRect? findFirstAvailableRect({
    required List<DashboardItem> items,
    required DashboardItem item,
    required int columns,
    required int maxRows,
  }) {
    for (var y = 0; y < maxRows; y++) {
      for (var x = 0; x <= columns - item.minW; x++) {
        final candidate = GridRect(x: x, y: y, w: item.minW, h: item.minH);
        if (candidate.bottom > maxRows) {
          continue;
        }
        final collides = items.any((other) => overlaps(candidate, other.rect));
        if (!collides) {
          return candidate;
        }
      }
    }
    return null;
  }
}

