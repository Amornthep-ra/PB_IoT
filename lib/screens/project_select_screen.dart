import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../features/projects/models/project_model.dart';
import '../features/projects/services/project_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_responsive.dart';

part 'project_select_parts/empty_project_state.dart';
part 'project_select_parts/project_dialogs.dart';
part 'project_select_parts/project_tile_widgets.dart';
part 'project_select_parts/project_action_widgets.dart';
part 'project_select_parts/project_background.dart';

const _backgroundColor = Color(0xFFF2F5FA);
const _headlineColor = Color(0xFF20303A);
const _mutedTextColor = Color(0xFF667587);
const _labelTextColor = Color(0xFF4B5A69);
const _buttonStartColor = Color(0xFF7FC39C);
const _buttonEndColor = Color(0xFF4E9070);
const _buttonGlowColor = Color(0xFF9CCCB0);
const _dangerColor = Color(0xFFC4525C);
const _projectIconKeys = <String>[
  'sprout',
  'greenhouse',
  'water',
  'sun',
  'sensor',
  'farm',
  'tree',
  'flower',
  'thermostat',
  'automation',
  'home',
  'building',
  'factory',
  'warehouse',
  'energy',
  'power',
  'lighting',
  'climate',
  'cooling',
  'fire',
  'network',
  'router',
  'security',
  'camera',
  'lab',
  'biotech',
  'storage',
  'battery',
  'robot',
  'tools',
  'garden',
  'compost',
  'aquarium',
  'weather',
  'analytics',
  'map',
];

IconData _projectIconData(String iconKey) {
  return switch (iconKey) {
    'greenhouse' => Icons.yard_rounded,
    'water' => Icons.water_drop_rounded,
    'sun' => Icons.wb_sunny_rounded,
    'sensor' => Icons.sensors_rounded,
    'farm' => Icons.agriculture_rounded,
    'tree' => Icons.forest_rounded,
    'flower' => Icons.local_florist_rounded,
    'thermostat' => Icons.thermostat_rounded,
    'automation' => Icons.memory_rounded,
    'home' => Icons.home_rounded,
    'building' => Icons.apartment_rounded,
    'factory' => Icons.factory_rounded,
    'warehouse' => Icons.warehouse_rounded,
    'energy' => Icons.bolt_rounded,
    'power' => Icons.power_rounded,
    'lighting' => Icons.lightbulb_rounded,
    'climate' => Icons.air_rounded,
    'cooling' => Icons.ac_unit_rounded,
    'fire' => Icons.local_fire_department_rounded,
    'network' => Icons.hub_rounded,
    'router' => Icons.router_rounded,
    'security' => Icons.security_rounded,
    'camera' => Icons.videocam_rounded,
    'lab' => Icons.science_rounded,
    'biotech' => Icons.biotech_rounded,
    'storage' => Icons.inventory_2_rounded,
    'battery' => Icons.battery_charging_full_rounded,
    'robot' => Icons.smart_toy_rounded,
    'tools' => Icons.construction_rounded,
    'garden' => Icons.grass_rounded,
    'compost' => Icons.compost_rounded,
    'aquarium' => Icons.water_rounded,
    'weather' => Icons.cloud_rounded,
    'analytics' => Icons.analytics_rounded,
    'map' => Icons.map_rounded,
    _ => Icons.eco_rounded,
  };
}

List<Color> _projectIconColors(String iconKey) {
  return switch (iconKey) {
    'greenhouse' => const <Color>[Color(0xFF8BC3A5), Color(0xFF4E9070)],
    'water' => const <Color>[Color(0xFF8ECDF2), Color(0xFF4A91C4)],
    'sun' => const <Color>[Color(0xFFF7C86C), Color(0xFFE89A3C)],
    'sensor' => const <Color>[Color(0xFFB9A7F2), Color(0xFF846BD6)],
    'farm' => const <Color>[Color(0xFFD8B37E), Color(0xFFA7743D)],
    'tree' => const <Color>[Color(0xFF74C69D), Color(0xFF2D8C62)],
    'flower' => const <Color>[Color(0xFFF1A8C8), Color(0xFFD95F99)],
    'thermostat' => const <Color>[Color(0xFFF29B8F), Color(0xFFD95D4F)],
    'automation' => const <Color>[Color(0xFF9CB7E8), Color(0xFF5278C6)],
    'home' => const <Color>[Color(0xFF9DD8C1), Color(0xFF4B9C7A)],
    'building' => const <Color>[Color(0xFFAEBBCA), Color(0xFF667487)],
    'factory' => const <Color>[Color(0xFFB8C0CC), Color(0xFF5F6B7A)],
    'warehouse' => const <Color>[Color(0xFFD1B38D), Color(0xFF9A6B3E)],
    'energy' => const <Color>[Color(0xFFFFD96D), Color(0xFFE0A01C)],
    'power' => const <Color>[Color(0xFFF6A8A8), Color(0xFFD75353)],
    'lighting' => const <Color>[Color(0xFFFFE08A), Color(0xFFE6B647)],
    'climate' => const <Color>[Color(0xFFA7D8F0), Color(0xFF4D9AC2)],
    'cooling' => const <Color>[Color(0xFFA9E4F5), Color(0xFF48A7C2)],
    'fire' => const <Color>[Color(0xFFFFA37D), Color(0xFFE05F35)],
    'network' => const <Color>[Color(0xFF93C7F2), Color(0xFF427FC1)],
    'router' => const <Color>[Color(0xFF9DD3E8), Color(0xFF4A91A8)],
    'security' => const <Color>[Color(0xFFB1B9F0), Color(0xFF6671C7)],
    'camera' => const <Color>[Color(0xFFB5A8DE), Color(0xFF7A62BF)],
    'lab' => const <Color>[Color(0xFFA5D8D0), Color(0xFF4A9A91)],
    'biotech' => const <Color>[Color(0xFFB2D99B), Color(0xFF68A84A)],
    'storage' => const <Color>[Color(0xFFD2C5B4), Color(0xFF8F7861)],
    'battery' => const <Color>[Color(0xFFA9DCA6), Color(0xFF4F9B4B)],
    'robot' => const <Color>[Color(0xFFC0B2E8), Color(0xFF7B63C7)],
    'tools' => const <Color>[Color(0xFFC9CED6), Color(0xFF6E7784)],
    'garden' => const <Color>[Color(0xFF9CD796), Color(0xFF57A54F)],
    'compost' => const <Color>[Color(0xFFC2B47C), Color(0xFF85763B)],
    'aquarium' => const <Color>[Color(0xFF79D1D4), Color(0xFF299CA0)],
    'weather' => const <Color>[Color(0xFFB4C7E7), Color(0xFF5F80B4)],
    'analytics' => const <Color>[Color(0xFF98C5F0), Color(0xFF4E7FC0)],
    'map' => const <Color>[Color(0xFFA5D4B0), Color(0xFF589263)],
    _ => const <Color>[_buttonStartColor, _buttonEndColor],
  };
}

Color _projectIconGlowColor(String iconKey) => _projectIconColors(iconKey).last;

class ProjectSelectScreen extends StatefulWidget {
  const ProjectSelectScreen({super.key});

  @override
  State<ProjectSelectScreen> createState() => _ProjectSelectScreenState();
}

class _ProjectSelectScreenState extends State<ProjectSelectScreen> {
  final ProjectStorageService _projectStorageService = ProjectStorageService();

  bool _isLoading = true;
  bool _isBusy = false;
  List<ProjectModel> _projects = const <ProjectModel>[];
  String? _selectedProjectId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProjects());
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final projects = await _projectStorageService.loadProjects();
      final selectedProject = await _projectStorageService
          .loadSelectedProject();
      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
        _selectedProjectId = selectedProject?.id;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorText = 'ไม่สามารถโหลดโปรเจกต์ได้';
      });
    }
  }

  Future<void> _createProject() async {
    final result = await _showProjectNameDialog();
    if (result == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    ProjectModel project;
    try {
      project = await _projectStorageService.createProject(
        result.name,
        iconKey: result.iconKey,
      );
      if (!mounted) {
        return;
      }

      final projects = await _projectStorageService.loadProjects();
      setState(() {
        _projects = projects;
        _selectedProjectId = project.id;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to create project: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'ไม่สามารถสร้างโปรเจกต์ได้';
      });
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _editProject(ProjectModel project) async {
    final result = await _showProjectNameDialog(project: project);
    if (result == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    try {
      await _projectStorageService.renameProject(
        projectId: project.id,
        name: result.name,
        iconKey: result.iconKey,
      );
      final projects = await _projectStorageService.loadProjects();
      final selectedProject = await _projectStorageService
          .loadSelectedProject();
      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
        _selectedProjectId = selectedProject?.id;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to update project: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'ไม่สามารถแก้ไขโปรเจกต์ได้';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _selectProject(ProjectModel project) async {
    setState(() {
      _isBusy = true;
      _selectedProjectId = project.id;
      _errorText = null;
    });

    try {
      await _projectStorageService.selectProject(project.id);
      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'ไม่สามารถเปิดโปรเจกต์ได้';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _deleteProject(ProjectModel project) async {
    final confirmed = await _showDeleteProjectDialog(project);
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    try {
      await _projectStorageService.deleteProject(project.id);
      final projects = await _projectStorageService.loadProjects();
      final selectedProject = await _projectStorageService
          .loadSelectedProject();
      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
        _selectedProjectId = selectedProject?.id;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to delete project: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'ไม่สามารถลบโปรเจกต์ได้';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<bool?> _showDeleteProjectDialog(ProjectModel project) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteProjectDialog(project: project),
    );
  }

  Future<_ProjectDialogResult?> _showProjectNameDialog({
    ProjectModel? project,
  }) async {
    return showDialog<_ProjectDialogResult>(
      context: context,
      builder: (context) => _ProjectNameDialog(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = AppResponsiveLayout.isTabletWidth(mediaQuery.size.width);
    final topPadding = isTablet
        ? (mediaQuery.size.height * 0.06).clamp(56.0, 80.0)
        : 18.0;
    final showCreateAction = _projects.isNotEmpty && !_isLoading;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _ProjectBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppResponsiveLayout.tabletContentMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, topPadding, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(
                        mediaQuery,
                        showCreateAction: isTablet && showCreateAction,
                      ),
                      const SizedBox(height: 18),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isTablet || !showCreateAction
          ? null
          : FloatingActionButton.extended(
              onPressed: _isBusy ? null : _createProject,
              backgroundColor: _buttonEndColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('สร้างโปรเจกต์'),
            ),
    );
  }

  Widget _buildHeader(
    MediaQueryData mediaQuery, {
    required bool showCreateAction,
  }) {
    final isCompactWidth = mediaQuery.size.width < 390;
    final headerVerticalPadding = isCompactWidth ? 16.0 : 18.0;
    final headerIconSize = isCompactWidth ? 44.0 : 46.0;
    final headerIconRadius = isCompactWidth ? 15.0 : 16.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            headerVerticalPadding,
            20,
            headerVerticalPadding,
          ),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: 0.62,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.74),
              const Color(0xFFF6FBFF).withValues(alpha: 0.46),
            ],
            shadows: AppGlassTheme.shadowLg,
          ),
          child: Row(
            children: [
              Container(
                width: headerIconSize,
                height: headerIconSize,
                decoration: AppGlassTheme.accentDecoration(
                  radius: headerIconRadius,
                  colors: const <Color>[_buttonStartColor, _buttonEndColor],
                  borderColor: Colors.white,
                  glowColor: _buttonGlowColor,
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลือกโปรเจกต์',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _headlineColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'เลือกพื้นที่ทำงานเพื่อเปิดแดชบอร์ด',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (showCreateAction) ...[
                const SizedBox(width: 14),
                _ProjectHeaderCreateButton(
                  onPressed: _isBusy ? null : _createProject,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _buttonEndColor),
      );
    }

    final errorText = _errorText;
    if (_projects.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _EmptyProjectState(
                errorText: errorText,
                isBusy: _isBusy,
                onCreateProject: _createProject,
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          _ProjectErrorBanner(message: errorText),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 92),
            itemCount: _projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = _projects[index];
              return _ProjectTile(
                project: project,
                isSelected: project.id == _selectedProjectId,
                isBusy: _isBusy,
                onTap: () => _selectProject(project),
                onEdit: () => _editProject(project),
                onDelete: () => _deleteProject(project),
              );
            },
          ),
        ),
      ],
    );
  }
}
