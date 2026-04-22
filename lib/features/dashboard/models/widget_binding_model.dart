enum WidgetBindingSource {
  api,
  mqtt,
  local,
}

enum WidgetBindingValueType {
  number,
  boolean,
  string,
  enumeration,
}

class WidgetBindingModel {
  const WidgetBindingModel({
    required this.source,
    this.readKey,
    this.writeKey,
    this.pin,
    this.valueType = WidgetBindingValueType.string,
  });

  final WidgetBindingSource source;
  final String? readKey;
  final String? writeKey;
  final String? pin;
  final WidgetBindingValueType valueType;

  WidgetBindingModel copyWith({
    WidgetBindingSource? source,
    String? readKey,
    String? writeKey,
    String? pin,
    WidgetBindingValueType? valueType,
    bool clearReadKey = false,
    bool clearWriteKey = false,
    bool clearPin = false,
  }) {
    return WidgetBindingModel(
      source: source ?? this.source,
      readKey: clearReadKey ? null : (readKey ?? this.readKey),
      writeKey: clearWriteKey ? null : (writeKey ?? this.writeKey),
      pin: clearPin ? null : (pin ?? this.pin),
      valueType: valueType ?? this.valueType,
    );
  }

  factory WidgetBindingModel.fromJson(Map<String, dynamic> json) {
    return WidgetBindingModel(
      source: WidgetBindingSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => WidgetBindingSource.local,
      ),
      readKey: json['readKey']?.toString(),
      writeKey: json['writeKey']?.toString(),
      pin: json['pin']?.toString(),
      valueType: WidgetBindingValueType.values.firstWhere(
        (value) => value.name == json['valueType'],
        orElse: () => WidgetBindingValueType.string,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source': source.name,
      'readKey': readKey,
      'writeKey': writeKey,
      'pin': pin,
      'valueType': valueType.name,
    };
  }
}
