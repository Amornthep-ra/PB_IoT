import 'dart:async';

import 'package:flutter/material.dart';

import '../../dashboard/models/device_snapshot_model.dart';
import '../../dashboard/services/dashboard_runtime_controller.dart';
import '../../dashboard/widgets/dashboard_runtime_theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
    required this.runtimeController,
  });

  final DashboardRuntimeController runtimeController;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  DashboardRuntimeController get _runtimeController => widget.runtimeController;

  @override
  void initState() {
    super.initState();
    _runtimeController.addListener(_handleRuntimeChanged);
    unawaited(_runtimeController.initialize());
  }

  @override
  void dispose() {
    _runtimeController.removeListener(_handleRuntimeChanged);
    super.dispose();
  }

  void _handleRuntimeChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _runtimeController.snapshot;
    final isLoading = _runtimeController.isLoading;

    return SafeArea(
      child: RefreshIndicator(
        color: DashboardRuntimeTheme.buttonEndColor,
        onRefresh: _runtimeController.refreshSnapshotFromServer,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const Text(
              'Devices',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: DashboardRuntimeTheme.fieldTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ตรวจสอบสถานะการเชื่อมต่อและวิเคราะห์ปัญหาอุปกรณ์ได้ครบในจุดเดียว',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: DashboardRuntimeTheme.mutedTextColor,
              ),
            ),
            const SizedBox(height: 18),
            _buildStatusCard(snapshot),
            const SizedBox(height: 18),
            if (isLoading && snapshot == null)
              const _LoadingCard()
            else ...[
              _buildVirtualPinSection(snapshot),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(DeviceSnapshotModel? snapshot) {
    final isOnline = snapshot?.online == true;
    final updatedLabel = _formatUpdatedAt(snapshot?.updatedAt);
    final errorMessage = _runtimeController.errorText;
    final hasError = errorMessage != null && errorMessage.trim().isNotEmpty;
    final accentColor = hasError
        ? DashboardRuntimeTheme.errorTextColor
        : isOnline
            ? DashboardRuntimeTheme.buttonEndColor
            : const Color(0xFFC95E68);
    final pillColor = hasError
        ? DashboardRuntimeTheme.errorBackgroundColor
        : isOnline
            ? const Color(0xFFE5F4EB)
            : const Color(0xFFFFECEF);
    final title = hasError ? 'Connection issue' : isOnline ? 'Online' : 'Offline';
    final subtitle = hasError
        ? errorMessage
        : isOnline
            ? 'อุปกรณ์กำลังรายงานสถานะอย่างปกติ'
            : 'อุปกรณ์ไม่ได้รายงานสถานะในขณะนี้';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DashboardRuntimeTheme.cardDecoration(emphasize: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isOnline
                            ? Icons.router_rounded
                            : Icons.portable_wifi_off_rounded,
                        color: accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: DashboardRuntimeTheme.headlineColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: DashboardRuntimeTheme.mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RefreshButton(
                isRefreshing: false,
                onPressed: () =>
                    unawaited(_runtimeController.refreshSnapshotFromServer()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill(
                label: 'Status',
                value: title,
                background: pillColor,
                foreground: accentColor,
              ),
              _StatusPill(
                label: 'Updated',
                value: updatedLabel,
                background: DashboardRuntimeTheme.surfaceColor,
                foreground: DashboardRuntimeTheme.labelTextColor,
              ),
              _StatusPill(
                label: 'Polling',
                value: 'Shared 2s',
                background: DashboardRuntimeTheme.surfaceColor,
                foreground: DashboardRuntimeTheme.labelTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualPinSection(DeviceSnapshotModel? snapshot) {
    final virtualPins = snapshot?.virtualPins.entries.toList() ??
        <MapEntry<String, dynamic>>[];
    virtualPins.sort((left, right) => left.key.compareTo(right.key));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DashboardRuntimeTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Virtual Pins',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DashboardRuntimeTheme.fieldTextColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ช่วยให้คุณตรวจสอบค่าพินที่ส่งมาแบบเรียลไทม์ และดูการเชื่อมต่อภายในตัวอุปกรณ์ได้ในที่เดียว',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: DashboardRuntimeTheme.mutedTextColor,
            ),
          ),
          const SizedBox(height: 14),
          if (virtualPins.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DashboardRuntimeTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardRuntimeTheme.surfaceBorderColor),
              ),
              child: const Text(
                'ยังไม่มีข้อมูลค่าพินเสมือนในขณะนี้',
                style: TextStyle(
                  fontSize: 13,
                  color: DashboardRuntimeTheme.mutedTextColor,
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: virtualPins
                  .map(
                    (entry) => _PinChip(
                      pin: entry.key,
                      value: entry.value?.toString() ?? '--',
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _formatUpdatedAt(DateTime? value) {
    if (value == null) {
      return '--';
    }
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.isRefreshing,
    required this.onPressed,
  });

  final bool isRefreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isRefreshing ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: DashboardRuntimeTheme.insetSurfaceDecoration(radius: 18),
          child: isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: DashboardRuntimeTheme.labelTextColor,
                ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinChip extends StatelessWidget {
  const _PinChip({
    required this.pin,
    required this.value,
  });

  final String pin;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardRuntimeTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardRuntimeTheme.surfaceBorderColor),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$pin  ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DashboardRuntimeTheme.fieldTextColor,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 13,
                color: DashboardRuntimeTheme.mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: DashboardRuntimeTheme.cardDecoration(),
      child: const Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            SizedBox(height: 14),
            Text(
              'Loading device status...',
              style: TextStyle(
                fontSize: 14,
                color: DashboardRuntimeTheme.mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
