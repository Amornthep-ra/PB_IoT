class SessionModel {
  const SessionModel({
    required this.token,
    required this.displayName,
    this.userId,
    this.email,
    this.transport,
    this.authType,
    this.authenticated = false,
    this.mqttDeviceId,
    this.profileImageUrl,
    this.cachedProfileImagePath,
    this.isOfflineMode = false,
    this.raw = const <String, dynamic>{},
  });

  final String token;
  final String displayName;
  final String? userId;
  final String? email;
  final String? transport;
  final String? authType;
  final bool authenticated;
  final String? mqttDeviceId;
  final String? profileImageUrl;
  final String? cachedProfileImagePath;
  final bool isOfflineMode;
  final Map<String, dynamic> raw;

  factory SessionModel.fromLoginResponse({
    required String token,
    required String displayName,
    required Map<String, dynamic> json,
  }) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return SessionModel(
      token: token,
      displayName: (user['name'] ?? displayName).toString(),
      userId: user['id']?.toString(),
      email: user['email']?.toString(),
      transport: json['transport']?.toString(),
      authType: json['authType']?.toString(),
      authenticated: json['success'] == true,
      mqttDeviceId: json['mqttDeviceId']?.toString(),
      profileImageUrl: user['profileImageUrl']?.toString(),
      cachedProfileImagePath: null,
      isOfflineMode: false,
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }

  factory SessionModel.fromSessionResponse(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return SessionModel(
      token: '',
      displayName: (user['name'] ?? '').toString(),
      userId: user['id']?.toString(),
      email: user['email']?.toString(),
      transport: json['transport']?.toString(),
      authType: json['authType']?.toString(),
      authenticated: json['authenticated'] == true,
      mqttDeviceId: json['mqttDeviceId']?.toString(),
      profileImageUrl: user['profileImageUrl']?.toString(),
      cachedProfileImagePath: null,
      isOfflineMode: false,
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }

  SessionModel copyWith({
    String? token,
    String? displayName,
    String? userId,
    String? email,
    String? transport,
    String? authType,
    bool? authenticated,
    String? mqttDeviceId,
    String? profileImageUrl,
    String? cachedProfileImagePath,
    bool? isOfflineMode,
    Map<String, dynamic>? raw,
  }) {
    return SessionModel(
      token: token ?? this.token,
      displayName: displayName ?? this.displayName,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      transport: transport ?? this.transport,
      authType: authType ?? this.authType,
      authenticated: authenticated ?? this.authenticated,
      mqttDeviceId: mqttDeviceId ?? this.mqttDeviceId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      cachedProfileImagePath:
          cachedProfileImagePath ?? this.cachedProfileImagePath,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      raw: raw ?? this.raw,
    );
  }
}
