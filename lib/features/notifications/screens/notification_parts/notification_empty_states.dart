part of '../notifications_screen.dart';

class _EmptyRulesCard extends StatelessWidget {
  const _EmptyRulesCard({required this.onCreateRule});

  final VoidCallback onCreateRule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = AppResponsiveLayout.isTabletWidth(
          MediaQuery.sizeOf(context).width,
        );
        final useStackedLayout = !isTablet || constraints.maxWidth < 340;
        final icon = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4E9070).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.rule_folder_outlined,
            color: Color(0xFF4E9070),
            size: 20,
          ),
        );
        final copy = Column(
          crossAxisAlignment: useStackedLayout
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              'ยังไม่มีกฎแจ้งเตือน',
              textAlign: useStackedLayout ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20303A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'สร้างกฎแจ้งเตือนจากวิดเจ็ต เช่น เตือนเมื่อดินแห้ง',
              textAlign: useStackedLayout ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                fontSize: 12,
                height: 1.38,
                color: Color(0xFF667587),
              ),
            ),
          ],
        );
        final createButton = Container(
          key: const ValueKey<String>('notification_empty_rules_card'),
          decoration: AppGlassTheme.accentDecoration(
            radius: 14,
            colors: const <Color>[Color(0xFFB6D2F5), Color(0xFF82AEE8)],
            borderColor: const Color(0xFF9EC3F0),
            glowColor: const Color(0xFF82AEE8),
          ),
          child: TextButton.icon(
            onPressed: onCreateRule,
            icon: const Icon(Icons.add_alert_rounded, size: 16),
            label: const Text(
              'สร้าง',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );

        final content = useStackedLayout
            ? Column(
                key: const ValueKey<String>('notification_empty_rules_content'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(height: 10),
                  copy,
                  const SizedBox(height: 14),
                  createButton,
                ],
              )
            : Row(
                key: const ValueKey<String>('notification_empty_rules_content'),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: copy),
                  const SizedBox(width: 12),
                  createButton,
                ],
              );

        if (!isTablet) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: content,
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: const ValueKey<String>('notification_empty_events_card'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4E9070).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF4E9070),
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20303A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF667587),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!AppResponsiveLayout.isTabletWidth(
          MediaQuery.sizeOf(context).width,
        )) {
          return content;
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: content,
          ),
        );
      },
    );
  }
}
