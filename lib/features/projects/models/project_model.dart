class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    String? iconKey,
    required this.createdAt,
    required this.updatedAt,
  }) : iconKey = iconKey ?? defaultIconKey;

  static const String defaultIconKey = 'sprout';

  final String id;
  final String name;
  final String iconKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel copyWith({
    String? id,
    String? name,
    String? iconKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id']?.toString() ?? '').trim();
    final name = (json['name']?.toString() ?? '').trim();
    final iconKey = (json['iconKey']?.toString() ?? defaultIconKey).trim();

    return ProjectModel(
      id: id,
      name: name,
      iconKey: iconKey.isEmpty ? defaultIconKey : iconKey,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
