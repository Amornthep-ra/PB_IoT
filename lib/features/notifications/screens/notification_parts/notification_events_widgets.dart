part of '../notifications_screen.dart';

class _EventsSection extends StatelessWidget {
  const _EventsSection({
    required this.title,
    required this.subtitle,
    required this.events,
    required this.ruleDataKeysById,
    required this.unreadCount,
    required this.isUpdating,
    required this.allowClear,
    required this.onClear,
    required this.onMarkAllRead,
    required this.onOpenEvent,
    required this.selectedPage,
    required this.onPageChanged,
    this.onDeleteEvent,
  });

  final String title;
  final String subtitle;
  final List<AlertEventModel> events;
  final Map<String, String> ruleDataKeysById;
  final int unreadCount;
  final bool isUpdating;
  final bool allowClear;
  final VoidCallback? onClear;
  final VoidCallback? onMarkAllRead;
  final ValueChanged<AlertEventModel> onOpenEvent;
  final _AlertsPage selectedPage;
  final ValueChanged<_AlertsPage> onPageChanged;
  final ValueChanged<AlertEventModel>? onDeleteEvent;

  @override
  Widget build(BuildContext context) {
    final isHistorySection = onDeleteEvent != null;
    final shouldShowSubtitle = isHistorySection && subtitle.trim().isNotEmpty;
    return _GlassCard(
      key: const ValueKey<String>('notification_events_section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stackHeader = constraints.maxWidth < 360;
              final actions = Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (allowClear && (events.isNotEmpty || unreadCount > 0))
                    if (events.isNotEmpty)
                      TextButton(
                        onPressed: isUpdating ? null : onClear,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          onDeleteEvent == null ? 'ล้าง' : 'ล้างทั้งหมด',
                        ),
                      ),
                  if (allowClear && unreadCount > 0)
                    TextButton(
                      onPressed: isUpdating ? null : onMarkAllRead,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('อ่านทั้งหมด'),
                    ),
                ],
              );

              final titleText = Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20303A),
                ),
              );

              if (stackHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText,
                    const SizedBox(height: 10),
                    _AlertsPageSwitcher(
                      key: const ValueKey<String>(
                        'notification_events_header_switcher',
                      ),
                      selectedPage: selectedPage,
                      onChanged: onPageChanged,
                    ),
                    if (allowClear &&
                        (events.isNotEmpty || unreadCount > 0)) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleText),
                      const SizedBox(width: 10),
                      Flexible(
                        child: _AlertsPageSwitcher(
                          key: const ValueKey<String>(
                            'notification_events_header_switcher',
                          ),
                          selectedPage: selectedPage,
                          onChanged: onPageChanged,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  if (allowClear && (events.isNotEmpty || unreadCount > 0)) ...[
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                ],
              );
            },
          ),
          if (shouldShowSubtitle) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF667587),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (events.isEmpty)
            _EmptyEventsCard(
              title: isHistorySection
                  ? 'ยังไม่มีประวัติ'
                  : 'ยังไม่มีเหตุการณ์ใหม่',
              message: isHistorySection
                  ? 'ระบบจะบันทึกเหตุการณ์ทั้งหมดไว้ที่นี่โดยอัตโนมัติ'
                  : allowClear
                  ? 'เหตุการณ์ใหม่จะแสดงที่นี่จนกว่าคุณจะล้างรายการนี้'
                  : 'บันทึกทุกเหตุการณ์ลงคลังข้อมูลอัตโนมัติ',
            )
          else
            Column(
              children: [
                for (var index = 0; index < events.length; index++) ...[
                  _AlertEventCard(
                    event: events[index],
                    ruleDataKey: ruleDataKeysById[events[index].ruleId],
                    onTap: () => onOpenEvent(events[index]),
                    onDelete: onDeleteEvent == null
                        ? null
                        : () => onDeleteEvent!(events[index]),
                  ),
                  if (index != events.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
