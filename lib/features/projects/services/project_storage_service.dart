import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_model.dart';
import 'project_state.dart';

class ProjectStorageService {
  ProjectStorageService({SharedPreferences? preferences})
    : _preferences = preferences;

  static const String _projectsKey = 'projects_v1';
  static const String _selectedProjectIdKey = 'selected_project_id_v1';

  final SharedPreferences? _preferences;

  Future<List<ProjectModel>> loadProjects() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(_projectsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <ProjectModel>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <ProjectModel>[];
      }

      final projects = <ProjectModel>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }

        final project = ProjectModel.fromJson(
          entry.map((key, value) => MapEntry(key.toString(), value)),
        );
        if (project.id.isEmpty || project.name.isEmpty) {
          continue;
        }
        projects.add(project);
      }

      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    } catch (_) {
      return const <ProjectModel>[];
    }
  }

  Future<ProjectModel> createProject(String name, {String? iconKey}) async {
    final normalizedName = _normalizeProjectName(name);
    final now = DateTime.now();
    final project = ProjectModel(
      id: _createProjectId(now),
      name: normalizedName,
      iconKey: _normalizeIconKey(iconKey),
      createdAt: now,
      updatedAt: now,
    );

    final projects = await loadProjects();
    await _saveProjects(<ProjectModel>[project, ...projects]);
    await selectProject(project.id);
    return project;
  }

  Future<ProjectModel?> renameProject({
    required String projectId,
    required String name,
    String? iconKey,
  }) async {
    final normalizedName = _normalizeProjectName(name);
    final projects = await loadProjects();
    ProjectModel? renamedProject;

    final updatedProjects = projects.map((project) {
      if (project.id != projectId) {
        return project;
      }

      renamedProject = project.copyWith(
        name: normalizedName,
        iconKey: iconKey == null ? project.iconKey : _normalizeIconKey(iconKey),
        updatedAt: DateTime.now(),
      );
      return renamedProject!;
    }).toList();

    if (renamedProject == null) {
      return null;
    }

    await _saveProjects(updatedProjects);
    if (ProjectState.current?.id == projectId) {
      ProjectState.current = renamedProject;
    }
    return renamedProject;
  }

  Future<void> deleteProject(String projectId) async {
    final projects = await loadProjects();
    final updatedProjects = projects
        .where((project) => project.id != projectId)
        .toList();

    await _saveProjects(updatedProjects);

    final selectedProjectId = await loadSelectedProjectId();
    if (selectedProjectId == projectId) {
      final nextProject = updatedProjects.isEmpty ? null : updatedProjects.first;
      await selectProject(nextProject?.id);
    }
  }

  Future<ProjectModel?> loadSelectedProject() async {
    final selectedProjectId = await loadSelectedProjectId();
    if (selectedProjectId == null) {
      ProjectState.current = null;
      return null;
    }

    final projects = await loadProjects();
    for (final project in projects) {
      if (project.id == selectedProjectId) {
        ProjectState.current = project;
        return project;
      }
    }

    await selectProject(null);
    return null;
  }

  Future<String?> loadSelectedProjectId() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final projectId = preferences.getString(_selectedProjectIdKey)?.trim();
    if (projectId == null || projectId.isEmpty) {
      return null;
    }
    return projectId;
  }

  Future<void> selectProject(String? projectId) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    if (projectId == null || projectId.trim().isEmpty) {
      await preferences.remove(_selectedProjectIdKey);
      ProjectState.current = null;
      return;
    }

    await preferences.setString(_selectedProjectIdKey, projectId);
    final projects = await loadProjects();
    for (final project in projects) {
      if (project.id == projectId) {
        ProjectState.current = project;
        return;
      }
    }
    ProjectState.current = null;
  }

  Future<void> clear() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.remove(_projectsKey);
    await preferences.remove(_selectedProjectIdKey);
    ProjectState.current = null;
  }

  Future<void> _saveProjects(List<ProjectModel> projects) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final payload = projects.map((project) => project.toJson()).toList();
    await preferences.setString(_projectsKey, jsonEncode(payload));
  }

  String _normalizeProjectName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Untitled Project';
    }
    return trimmed;
  }

  String _normalizeIconKey(String? iconKey) {
    final trimmed = iconKey?.trim() ?? '';
    if (trimmed.isEmpty) {
      return ProjectModel.defaultIconKey;
    }
    return trimmed;
  }

  String _createProjectId(DateTime now) {
    return 'project_${now.microsecondsSinceEpoch.toRadixString(36)}';
  }
}
