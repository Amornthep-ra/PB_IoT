import 'package:flutter/material.dart';

import '../models/alert_event_model.dart';
import '../models/alert_rule_model.dart';

class AlertEventDetailScreen extends StatelessWidget {
  const AlertEventDetailScreen({super.key, required this.event});

  final AlertEventModel event;

  @override
  Widget build(BuildContext context) {
    final palette = _severityPalette(event.severity);
    final dataKey = _eventDataKey(event);
    final displayTitle = _alertTitleWithDataKey(
      title: event.ruleTitle,
      dataKey: dataKey,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF20303A),
        title: const Text('Alert Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: palette.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            palette.icon,
                            color: palette.color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF20303A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTimestamp(event.createdAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A8794),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DetailChip(
                          label: event.widgetTitle,
                          color: const Color(0xFF4E9070),
                        ),
                        if (dataKey != null)
                          _DetailChip(
                            label: dataKey,
                            color: const Color(0xFF4C8BC8),
                          ),
                        _DetailChip(
                          label: _severityLabel(event.severity),
                          color: palette.color,
                        ),
                        _DetailChip(
                          label: event.isRead ? 'Read' : 'Unread',
                          color: event.isRead
                              ? const Color(0xFF97A3AF)
                              : const Color(0xFFE28A3B),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4E9070),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      event.message,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.55,
                        color: Color(0xFF20303A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4E9070),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Rule ID', value: event.ruleId),
                    _InfoRow(label: 'Widget ID', value: event.widgetId),
                    _InfoRow(
                      label: 'Triggered At',
                      value: _formatFullTimestamp(event.createdAt),
                    ),
                    if (event.payload.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Payload',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF20303A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...event.payload.entries.map(
                        (entry) => _InfoRow(
                          label: entry.key,
                          value: entry.value?.toString() ?? '-',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xF9FFFFFF),
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0x1D9CA9B5),
            offset: Offset(10, 12),
            blurRadius: 24,
          ),
          BoxShadow(
            color: Color(0x14677E92),
            offset: Offset(0, 18),
            blurRadius: 28,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6E7A86),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF20303A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityPalette {
  const _SeverityPalette({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

_SeverityPalette _severityPalette(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return const _SeverityPalette(
        icon: Icons.info_outline_rounded,
        color: Color(0xFF4C8BC8),
      );
    case AlertRuleSeverity.warning:
      return const _SeverityPalette(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFE28A3B),
      );
    case AlertRuleSeverity.critical:
      return const _SeverityPalette(
        icon: Icons.error_outline_rounded,
        color: Color(0xFFCC5A4E),
      );
  }
}

String _severityLabel(AlertRuleSeverity severity) {
  switch (severity) {
    case AlertRuleSeverity.info:
      return 'Info';
    case AlertRuleSeverity.warning:
      return 'Warning';
    case AlertRuleSeverity.critical:
      return 'Critical';
  }
}

String _alertTitleWithDataKey({
  required String title,
  required String? dataKey,
}) {
  final normalizedTitle = title.trim();
  final normalizedDataKey = dataKey?.trim() ?? '';
  if (normalizedDataKey.isEmpty) {
    return normalizedTitle;
  }
  if (normalizedTitle.toLowerCase().contains(
    '(${normalizedDataKey.toLowerCase()})',
  )) {
    return normalizedTitle;
  }
  return '$normalizedTitle ($normalizedDataKey)';
}

String? _eventDataKey(AlertEventModel event) {
  final dataKey = event.payload['dataKey']?.toString().trim() ?? '';
  return dataKey.isEmpty ? null : dataKey;
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(local.year, local.month, local.day);
  final difference = today.difference(eventDay).inDays;

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  if (difference <= 0) {
    return 'Today $hour:$minute';
  }
  if (difference == 1) {
    return 'Yesterday $hour:$minute';
  }

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/$hour:$minute';
}

String _formatFullTimestamp(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}
