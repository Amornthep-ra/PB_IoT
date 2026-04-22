import 'package:flutter/material.dart';

import '../../models/dashboard_widget_model.dart';
import '../../models/device_snapshot_model.dart';
import '../dashboard_card.dart';
import '../dashboard_runtime_theme.dart';

class StatusCardWidget extends StatelessWidget {
  const StatusCardWidget({
    super.key,
    required this.widget,
    required this.snapshot,
  });

  final DashboardWidgetModel widget;
  final DeviceSnapshotModel snapshot;

  @override
  Widget build(BuildContext context) {
    final statusText = snapshot.online
        ? (widget.options['onlineText']?.toString() ?? 'Online')
        : (widget.options['offlineText']?.toString() ?? 'Offline');
    final statusColor = snapshot.online
        ? DashboardRuntimeTheme.buttonEndColor
        : DashboardRuntimeTheme.errorTextColor;
    final updatedAt = snapshot.updatedAt;
    final updatedText = updatedAt == null
        ? null
        : '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';

    return DashboardCard(
      padding: const EdgeInsets.all(14),
      emphasize: snapshot.online,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? 'Status',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DashboardRuntimeTheme.labelTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          if (updatedText != null) ...[
            const Spacer(),
            Text(
              'Updated $updatedText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: DashboardRuntimeTheme.mutedTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
