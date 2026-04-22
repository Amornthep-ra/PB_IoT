import 'widget_binding_model.dart';

enum DashboardWidgetType {
  valueCard,
  switchControl,
  sliderControl,
  statusCard,
  progressCard,
  button,
  label,
}

class DashboardWidgetLayout {
  const DashboardWidgetLayout({
    required this.x,
    required this.y,
    this.w = 2,
    this.h = 1,
  });

  final int x;
  final int y;
  final int w;
  final int h;

  DashboardWidgetLayout copyWith({
    int? x,
    int? y,
    int? w,
    int? h,
  }) {
    return DashboardWidgetLayout(
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }

  factory DashboardWidgetLayout.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetLayout(
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      w: (json['w'] as num?)?.toInt() ?? 2,
      h: (json['h'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'w': w,
      'h': h,
    };
  }
}

class DashboardWidgetModel {
  const DashboardWidgetModel({
    required this.id,
    required this.type,
    required this.layout,
    this.title,
    this.binding,
    this.options = const <String, dynamic>{},
  });

  final String id;
  final DashboardWidgetType type;
  final DashboardWidgetLayout layout;
  final String? title;
  final WidgetBindingModel? binding;
  final Map<String, dynamic> options;

  DashboardWidgetModel copyWith({
    String? id,
    DashboardWidgetType? type,
    DashboardWidgetLayout? layout,
    String? title,
    WidgetBindingModel? binding,
    Map<String, dynamic>? options,
  }) {
    return DashboardWidgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      layout: layout ?? this.layout,
      title: title ?? this.title,
      binding: binding ?? this.binding,
      options: options ?? this.options,
    );
  }

  factory DashboardWidgetModel.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetModel(
      id: json['id']?.toString() ?? '',
      type: DashboardWidgetType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => DashboardWidgetType.label,
      ),
      layout: DashboardWidgetLayout.fromJson(
        (json['layout'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      title: json['title']?.toString(),
      binding: json['binding'] is Map<String, dynamic>
          ? WidgetBindingModel.fromJson(json['binding'] as Map<String, dynamic>)
          : null,
      options: (json['options'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'layout': layout.toJson(),
      'title': title,
      'binding': binding?.toJson(),
      'options': options,
    };
  }
}
