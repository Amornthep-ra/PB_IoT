import 'dart:ui';

import 'package:flutter/material.dart';

import '../features/dashboard/services/dashboard_runtime_controller.dart';
import '../features/dashboard_builder/widgets/dashboard_home_view.dart';
import '../features/devices/screens/devices_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRuntimeController _runtimeController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _runtimeController = DashboardRuntimeController();
  }

  @override
  void dispose() {
    _runtimeController.dispose();
    super.dispose();
  }

  Widget _buildCurrentScreen() {
    return switch (_selectedIndex) {
      0 => DashboardHomeView(runtimeController: _runtimeController),
      1 => DevicesScreen(runtimeController: _runtimeController),
      2 => NotificationsScreen(runtimeController: _runtimeController),
      _ => DashboardHomeView(runtimeController: _runtimeController),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      body: _buildCurrentScreen(),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset > 0 ? bottomInset + 8 : 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: AppGlassTheme.surfaceDecoration(
                radius: 24,
                borderAlpha: 0.55,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.72),
                  const Color(0xFFF6FBFF).withValues(alpha: 0.46),
                ],
                shadows: AppGlassTheme.shadowLg,
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  _BottomNavItem(
                    icon: Icons.speed_outlined,
                    label: 'Dashboard',
                    isActive: _selectedIndex == 0,
                    activeColors: const [Color(0xFFB6D2F5), Color(0xFF82AEE8)],
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _BottomNavItem(
                    icon: Icons.devices_other_outlined,
                    label: 'Devices',
                    isActive: _selectedIndex == 1,
                    activeColors: const [Color(0xFFF6C7D7), Color(0xFFE59AB6)],
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  _BottomNavItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Alerts',
                    isActive: _selectedIndex == 2,
                    activeColors: const [Color(0xFFD5C8F7), Color(0xFFAA93E8)],
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  _BottomNavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: false,
                    activeColors: const [Color(0xFFC5E4D2), Color(0xFF8BC3A5)],
                    onTap: () {
                      Navigator.pushNamed(context, '/account-session');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColors,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final List<Color> activeColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : const Color(0xFF5F6B78);

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: isActive
              ? Border.all(color: const Color(0xFFFFFFFF).withValues(alpha: 0.75))
              : null,
          gradient: isActive
              ? AppGlassTheme.surfaceGradient(activeColors)
              : null,
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
