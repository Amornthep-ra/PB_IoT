import 'package:flutter/material.dart';

import '../models/dashboard_widget_model.dart';
import '../models/device_snapshot_model.dart';
import 'widgets/progress_card_widget.dart';
import 'widgets/slider_widget.dart';
import 'widgets/status_card_widget.dart';
import 'widgets/switch_widget.dart';
import 'widgets/value_card_widget.dart';

class DashboardWidgetRenderer extends StatelessWidget {
  const DashboardWidgetRenderer({
    super.key,
    required this.widget,
    required this.snapshot,
    this.onControlValueChanged,
    this.enableControlInteraction = true,
  });

  final DashboardWidgetModel widget;
  final DeviceSnapshotModel snapshot;
  final void Function(DashboardWidgetModel widget, Object? value)?
      onControlValueChanged;
  final bool enableControlInteraction;

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case DashboardWidgetType.valueCard:
      case DashboardWidgetType.label:
        return ValueCardWidget(widget: widget, snapshot: snapshot);
      case DashboardWidgetType.switchControl:
        return SwitchWidget(
          widget: widget,
          snapshot: snapshot,
          onChanged: enableControlInteraction
              ? (value) => onControlValueChanged?.call(widget, value)
              : null,
        );
      case DashboardWidgetType.sliderControl:
        return SliderWidget(
          widget: widget,
          snapshot: snapshot,
          onChanged: enableControlInteraction
              ? (value) => onControlValueChanged?.call(widget, value)
              : null,
        );
      case DashboardWidgetType.statusCard:
        return StatusCardWidget(widget: widget, snapshot: snapshot);
      case DashboardWidgetType.progressCard:
        return ProgressCardWidget(widget: widget, snapshot: snapshot);
      case DashboardWidgetType.button:
        return StatusCardWidget(widget: widget, snapshot: snapshot);
    }
  }
}
