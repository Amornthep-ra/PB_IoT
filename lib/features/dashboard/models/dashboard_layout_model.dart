import 'dashboard_widget_model.dart';

class DashboardLayoutModel {
  const DashboardLayoutModel({
    required this.id,
    required this.name,
    this.widgets = const <DashboardWidgetModel>[],
    this.version = 1,
  });

  final String id;
  final String name;
  final List<DashboardWidgetModel> widgets;
  final int version;

  bool get isEmpty => widgets.isEmpty;

  DashboardLayoutModel copyWith({
    String? id,
    String? name,
    List<DashboardWidgetModel>? widgets,
    int? version,
  }) {
    return DashboardLayoutModel(
      id: id ?? this.id,
      name: name ?? this.name,
      widgets: widgets ?? this.widgets,
      version: version ?? this.version,
    );
  }

  factory DashboardLayoutModel.fromJson(Map<String, dynamic> json) {
    final widgetsJson = json['widgets'] as List<dynamic>? ?? const <dynamic>[];

    return DashboardLayoutModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Dashboard',
      version: (json['version'] as num?)?.toInt() ?? 1,
      widgets: widgetsJson
          .whereType<Map<String, dynamic>>()
          .map(DashboardWidgetModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'version': version,
      'widgets': widgets.map((widget) => widget.toJson()).toList(),
    };
  }
}
