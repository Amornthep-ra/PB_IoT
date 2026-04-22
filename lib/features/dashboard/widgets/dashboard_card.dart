import 'package:flutter/material.dart';

import 'dashboard_runtime_theme.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.emphasize = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: DashboardRuntimeTheme.cardDecoration(
        radius: 22,
        emphasize: emphasize,
      ),
      child: child,
    );
  }
}
