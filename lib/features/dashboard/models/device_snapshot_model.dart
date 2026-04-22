class DeviceSnapshotModel {
  const DeviceSnapshotModel({
    this.online = false,
    this.updatedAt,
    this.status = const <String, dynamic>{},
    this.units = const <String, dynamic>{},
    this.virtualPins = const <String, dynamic>{},
    this.error,
  });

  final bool online;
  final DateTime? updatedAt;
  final Map<String, dynamic> status;
  final Map<String, dynamic> units;
  final Map<String, dynamic> virtualPins;
  final String? error;

  factory DeviceSnapshotModel.fromJson(Map<String, dynamic> json) {
    return DeviceSnapshotModel(
      online: json['online'] == true,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      status: (json['status'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      units: (json['units'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      virtualPins:
          (json['virtualPins'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      error: json['error']?.toString(),
    );
  }

  DeviceSnapshotModel copyWith({
    bool? online,
    DateTime? updatedAt,
    Map<String, dynamic>? status,
    Map<String, dynamic>? units,
    Map<String, dynamic>? virtualPins,
    String? error,
    bool clearError = false,
  }) {
    return DeviceSnapshotModel(
      online: online ?? this.online,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      units: units ?? this.units,
      virtualPins: virtualPins ?? this.virtualPins,
      error: clearError ? null : (error ?? this.error),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'online': online,
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
      'units': units,
      'virtualPins': virtualPins,
      'error': error,
    };
  }
}
