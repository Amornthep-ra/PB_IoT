part of '../devices_screen.dart';

class _PinSearchAndFilters extends StatelessWidget {
  const _PinSearchAndFilters({
    required this.controller,
    required this.query,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final String query;
  final _PinListFilter selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<_PinListFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontSize: 13,
            color: DashboardRuntimeTheme.fieldTextColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'ค้นหา Pin, Widget หรือประเภท',
            hintStyle: const TextStyle(
              color: DashboardRuntimeTheme.mutedTextColor,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: DashboardRuntimeTheme.mutedTextColor,
            ),
            suffixIcon: query.trim().isEmpty
                ? null
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: DashboardRuntimeTheme.mutedTextColor,
                    ),
                    onPressed: onClearSearch,
                  ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.56),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFD7E1E8).withValues(alpha: 0.7),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFD7E1E8).withValues(alpha: 0.7),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF82AEE8)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PinFilterChip(
              label: 'ทั้งหมด',
              selected: selectedFilter == _PinListFilter.all,
              onTap: () => onFilterChanged(_PinListFilter.all),
            ),
            _PinFilterChip(
              label: 'Live',
              selected: selectedFilter == _PinListFilter.live,
              onTap: () => onFilterChanged(_PinListFilter.live),
            ),
            _PinFilterChip(
              label: 'รอข้อมูล',
              selected: selectedFilter == _PinListFilter.waiting,
              onTap: () => onFilterChanged(_PinListFilter.waiting),
            ),
            _PinFilterChip(
              label: 'หลาย Widget',
              selected: selectedFilter == _PinListFilter.multiple,
              onTap: () => onFilterChanged(_PinListFilter.multiple),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoVirtualPinsState extends StatelessWidget {
  const _NoVirtualPinsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 16,
        borderAlpha: 0.38,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.58),
          const Color(0xFFF7FBFF).withValues(alpha: 0.32),
        ],
        shadows: AppGlassTheme.shadowSm,
      ),
      child: const Text(
        'ยังไม่มีข้อมูล Virtual Pin และยังไม่มี Widget ใดผูกกับพิน — สร้าง Widget จากหน้า Dashboard แล้ว Bind Pin เพื่อเริ่มติดตามค่า',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: DashboardRuntimeTheme.mutedTextColor,
        ),
      ),
    );
  }
}

class _NoPinMatchesState extends StatelessWidget {
  const _NoPinMatchesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 16,
        borderAlpha: 0.38,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.58),
          const Color(0xFFF7FBFF).withValues(alpha: 0.32),
        ],
        shadows: AppGlassTheme.shadowSm,
      ),
      child: const Text(
        'ไม่พบ Pin ที่ตรงกับการค้นหาหรือตัวกรอง',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: DashboardRuntimeTheme.mutedTextColor,
        ),
      ),
    );
  }
}

class _PinFilterChip extends StatelessWidget {
  const _PinFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? const Color(0xFF4E9070)
        : DashboardRuntimeTheme.mutedTextColor;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? const Color(0xFFE5F4EB)
                : Colors.white.withValues(alpha: 0.46),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB7DCC8)
                  : const Color(0xFFD7E1E8).withValues(alpha: 0.72),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
