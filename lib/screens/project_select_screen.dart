import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../features/projects/models/project_model.dart';
import '../features/projects/services/project_storage_service.dart';
import '../theme/app_theme.dart';

const _backgroundColor = Color(0xFFF2F5FA);
const _headlineColor = Color(0xFF20303A);
const _mutedTextColor = Color(0xFF667587);
const _labelTextColor = Color(0xFF4B5A69);
const _buttonStartColor = Color(0xFF7FC39C);
const _buttonEndColor = Color(0xFF4E9070);
const _buttonGlowColor = Color(0xFF9CCCB0);
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
    _ => const <Color>[_buttonStartColor, _buttonEndColor],
  };
}

Color _projectIconGlowColor(String iconKey) => _projectIconColors(iconKey).last;

class _ProjectDialogResult {
  const _ProjectDialogResult({required this.name, required this.iconKey});

  final String name;
  final String iconKey;
}

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
      final selectedProject = await _projectStorageService.loadSelectedProject();
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
        _errorText = 'Unable to load projects.';
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
        _errorText = 'Unable to create project.';
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
      final selectedProject = await _projectStorageService.loadSelectedProject();
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
        _errorText = 'Unable to update project.';
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
        _errorText = 'Unable to open project.';
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
      final selectedProject = await _projectStorageService.loadSelectedProject();
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
        _errorText = 'Unable to delete project.';
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
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 22,
                  borderAlpha: 0.60,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                    const Color(0xFFFFF4F5).withValues(alpha: 0.54),
                  ],
                  shadows: AppGlassTheme.shadowMd,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFFFE2E5),
                            border: Border.all(color: const Color(0xFFF5B7BE)),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFC4525C),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Delete Project',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _headlineColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Delete "${project.name}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.32,
                        fontWeight: FontWeight.w700,
                        color: _headlineColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'เมื่อลบแล้วจะไม่สามารถเรียกคืนข้อมูลได้',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: _mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ProjectActionButton(
                            label: 'Cancel',
                            isSecondary: true,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProjectActionButton(
                            label: 'Delete',
                            isDanger: true,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _ProjectBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(mediaQuery),
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
      floatingActionButton: _projects.isEmpty || _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _isBusy ? null : _createProject,
              backgroundColor: _buttonEndColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Project'),
            ),
    );
  }

  Widget _buildHeader(MediaQueryData mediaQuery) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            mediaQuery.size.width < 390 ? 18 : 22,
            20,
            mediaQuery.size.width < 390 ? 18 : 22,
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
                width: 48,
                height: 48,
                decoration: AppGlassTheme.accentDecoration(
                  radius: 16,
                  colors: const <Color>[_buttonStartColor, _buttonEndColor],
                  borderColor: Colors.white,
                  glowColor: _buttonGlowColor,
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Project',
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

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState({
    required this.errorText,
    required this.isBusy,
    required this.onCreateProject,
  });

  final String? errorText;
  final bool isBusy;
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: 0.62,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.74),
              const Color(0xFFF4FBF7).withValues(alpha: 0.46),
            ],
            shadows: AppGlassTheme.shadowMd,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.add_business_rounded,
                color: _buttonEndColor,
                size: 54,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create your first project',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _headlineColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Projects keep each farm dashboard separate.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: _mutedTextColor,
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 16),
                _ProjectErrorBanner(message: errorText!),
              ],
              const SizedBox(height: 22),
              _ProjectActionButton(
                label: isBusy ? 'Creating...' : 'Create Project',
                onPressed: isBusy ? null : onCreateProject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectNameDialog extends StatefulWidget {
  const _ProjectNameDialog({this.project});

  final ProjectModel? project;

  @override
  State<_ProjectNameDialog> createState() => _ProjectNameDialogState();
}

class _ProjectNameDialogState extends State<_ProjectNameDialog> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _selectedIconKey;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _controller.text = project?.name ?? '';
    _selectedIconKey = project?.iconKey ?? ProjectModel.defaultIconKey;
    if (!_projectIconKeys.contains(_selectedIconKey)) {
      _selectedIconKey = ProjectModel.defaultIconKey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(
      _ProjectDialogResult(
        name: _controller.text.trim(),
        iconKey: _selectedIconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxDialogHeight =
        (mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48).clamp(
          220.0,
          mediaQuery.size.height * 0.82,
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: AppGlassTheme.surfaceDecoration(
                radius: 22,
                borderAlpha: 0.60,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                  const Color(0xFFF4FBF7).withValues(alpha: 0.52),
                ],
                shadows: AppGlassTheme.shadowMd,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isEditing ? 'Edit Project' : 'Create Project',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _headlineColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Project Icon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _labelTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final iconKey in _projectIconKeys)
                            _ProjectIconChoice(
                              icon: _projectIconData(iconKey),
                              colors: _projectIconColors(iconKey),
                              isSelected: iconKey == _selectedIconKey,
                              onTap: () {
                                setState(() {
                                  _selectedIconKey = iconKey;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Project Name',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _labelTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _headlineColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ตัวอย่าง: PB IoT',
                          hintStyle: const TextStyle(color: _mutedTextColor),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.72),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'กรุณาใส่ชื่อโปรเจกต์';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ProjectActionButton(
                              label: 'Cancel',
                              isSecondary: true,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProjectActionButton(
                              label: _isEditing ? 'Save' : 'Create',
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectIconChoice extends StatelessWidget {
  const _ProjectIconChoice({
    required this.icon,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> colors;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: isSelected
                ? AppGlassTheme.accentDecoration(
                    radius: 15,
                    colors: colors,
                    borderColor: Colors.white,
                    glowColor: colors.last,
                  )
                : AppGlassTheme.surfaceDecoration(
                    radius: 15,
                    borderAlpha: 0.72,
                    colors: <Color>[
                      const Color(0xFFFFFFFF).withValues(alpha: 0.70),
                      const Color(0xFFF6FBFF).withValues(alpha: 0.42),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : colors.last,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectModel project;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isBusy ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: AppGlassTheme.surfaceDecoration(
                radius: 20,
                borderAlpha: isSelected ? 0.92 : 0.58,
                colors: isSelected
                    ? <Color>[
                        const Color(0xFFEAF7F1).withValues(alpha: 0.84),
                        const Color(0xFFFFFFFF).withValues(alpha: 0.68),
                      ]
                    : <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.70),
                        const Color(0xFFF6FBFF).withValues(alpha: 0.42),
                      ],
                shadows: AppGlassTheme.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _projectIconColors(project.iconKey),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _projectIconGlowColor(
                            project.iconKey,
                          ).withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _projectIconData(project.iconKey),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _headlineColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Updated ${_formatProjectDate(project.updatedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: isSelected ? _buttonEndColor : _mutedTextColor,
                    size: isSelected ? 24 : 26,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 36,
                    height: 40,
                    child: IconButton(
                      tooltip: 'Edit project',
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      color: _mutedTextColor,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 40,
                    child: IconButton(
                      tooltip: 'Delete project',
                      onPressed: isBusy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: const Color(0xFFC4525C),
                      iconSize: 21,
                      padding: EdgeInsets.zero,
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

  static String _formatProjectDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _ProjectActionButton extends StatelessWidget {
  const _ProjectActionButton({
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final foreground = isSecondary ? _labelTextColor : Colors.white;
    final accentColors = isDanger
        ? const <Color>[Color(0xFFE9828C), Color(0xFFC4525C)]
        : const <Color>[_buttonStartColor, _buttonEndColor];
    final glowColor = isDanger ? const Color(0xFFECA1A8) : _buttonGlowColor;

    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: isSecondary
            ? AppGlassTheme.surfaceDecoration(
                radius: 16,
                borderAlpha: 0.76,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.64),
                  const Color(0xFFF6FBFF).withValues(alpha: 0.42),
                ],
                shadows: const <BoxShadow>[],
              )
            : AppGlassTheme.accentDecoration(
                radius: 16,
                colors: accentColors,
                borderColor: Colors.white,
                glowColor: glowColor,
              ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: onPressed == null
                      ? foreground.withValues(alpha: 0.54)
                      : foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectErrorBanner extends StatelessWidget {
  const _ProjectErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5B7BE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC4525C),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9E3F48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectBackground extends StatelessWidget {
  const _ProjectBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF2F5FA),
            Color(0xFFEAF7F1),
            Color(0xFFF7FBFF),
          ],
        ),
      ),
      child: CustomPaint(painter: _ProjectBackgroundPainter()),
    );
  }
}

class _ProjectBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.34)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
