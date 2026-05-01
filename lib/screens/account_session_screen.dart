import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/profile_avatar_preset_storage.dart';
import '../services/profile_image_cache_storage.dart';
import '../services/session_cookie_storage.dart';
import '../services/session_snapshot_storage.dart';
import '../services/session_state.dart';
import '../theme/app_responsive.dart';
import '../theme/app_theme.dart';
import '../features/dashboard/services/dashboard_runtime_value_storage.dart';

class AccountSessionScreen extends StatefulWidget {
  const AccountSessionScreen({super.key});

  @override
  State<AccountSessionScreen> createState() => _AccountSessionScreenState();
}

class _AccountSessionScreenState extends State<AccountSessionScreen> {
  final AuthService _authService = AuthService();

  bool _isLoggingOut = false;
  bool _isUpdatingProfileAvatar = false;
  bool _isTokenVisible = false;
  Timer? _tokenVisibilityTimer;

  static const _backgroundColor = Color(0xFFF2F5FA);
  static const _headlineColor = Color(0xFF15212B);
  static const _labelTextColor = Color(0xFF4B5A69);
  static const _mutedTextColor = Color(0xFF667587);
  static const _dangerStartColor = Color(0xFFF06A62);
  static const _dangerEndColor = Color(0xFFD84840);
  static const _dangerGlowColor = Color(0xFFF0A09B);
  static const _privacyPolicyUrl =
      'https://sites.google.com/view/pb-iot-privacy-policy';

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 28,
            borderAlpha: 0.58,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.82),
              const Color(0xFFF7FBFF).withValues(alpha: 0.46),
            ],
            shadows: AppGlassTheme.shadowMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 10,
                  borderAlpha: 0.38,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.64),
                    const Color(0xFFDCEBFF).withValues(alpha: 0.24),
                  ],
                  shadows: AppGlassTheme.shadowSm,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    splashRadius: 14,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 12,
                      color: Color(0xFF4F5F6E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: _headlineColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ดูรายละเอียดบัญชี สถานะเซสชันได้ที่นี่',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
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

  @override
  void initState() {
    super.initState();
    _initializeSessionState();
  }

  @override
  void dispose() {
    _tokenVisibilityTimer?.cancel();
    super.dispose();
  }

  void _toggleTokenVisibility() {
    _tokenVisibilityTimer?.cancel();
    setState(() {
      _isTokenVisible = !_isTokenVisible;
    });

    if (!_isTokenVisible) {
      return;
    }

    _tokenVisibilityTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTokenVisible = false;
      });
    });
  }

  Future<void> _copyToken(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: trimmedToken));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('คัดลอก Token แล้ว')));
  }

  String _maskedToken(String token) {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return 'Not available';
    }
    if (trimmedToken.length <= 2) {
      return '••••';
    }
    if (trimmedToken.length <= 8) {
      return '••••${trimmedToken.substring(trimmedToken.length - 2)}';
    }
    return '${trimmedToken.substring(0, 4)}••••••••'
        '${trimmedToken.substring(trimmedToken.length - 4)}';
  }

  Future<void> _initializeSessionState() async {
    await _restoreMissingSessionTokenFromRememberedLogin();
    if (!mounted) {
      return;
    }
    await ProfileImageCacheStorage.clear();
    await _refreshSessionFromServer();
  }

  Future<void> _restoreMissingSessionTokenFromRememberedLogin() async {
    final currentSession = SessionState.current;
    if (currentSession == null || currentSession.token.trim().isNotEmpty) {
      return;
    }

    final remembered = await SessionCookieStorage.loadRememberedLogin();
    final rememberedToken = remembered?.token.trim();
    if (rememberedToken == null || rememberedToken.isEmpty) {
      return;
    }

    final updatedSession = currentSession.copyWith(token: rememberedToken);
    SessionState.current = updatedSession;
    await SessionSnapshotStorage.save(updatedSession);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onEditProfileAvatarPressed() async {
    final selectedAction = await showModalBottomSheet<_ProfileAvatarAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ProfileAvatarSourceSheet(
          hasProfileAvatar: _resolvedProfileAvatarId != null,
          onActionSelected: (action) => Navigator.of(context).pop(action),
        );
      },
    );

    if (selectedAction == null) {
      return;
    }

    if (selectedAction == _ProfileAvatarAction.remove) {
      await _removeProfileAvatar();
      return;
    }

    if (selectedAction == _ProfileAvatarAction.avatar) {
      await _chooseProfileAvatarPreset();
      return;
    }
  }

  Future<void> _removeProfileAvatar() async {
    if (_resolvedProfileAvatarId == null) {
      return;
    }

    setState(() {
      _isUpdatingProfileAvatar = true;
    });

    try {
      await _clearProfileAvatarState();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfileAvatar = false;
        });
      }
    }
  }

  Future<void> _clearProfileAvatarState() async {
    final currentSession = SessionState.current;
    if (currentSession == null) {
      return;
    }

    await ProfileImageCacheStorage.clear();
    await ProfileAvatarPresetStorage.removeForSession(currentSession);
    await SessionSnapshotStorage.save(
      currentSession.copyWith(
        profileImageUrl: '',
        cachedProfileImagePath: '',
        profileAvatarId: '',
        isOfflineMode: false,
      ),
    );
    SessionState.current = currentSession.copyWith(
      profileImageUrl: '',
      cachedProfileImagePath: '',
      profileAvatarId: '',
      isOfflineMode: false,
    );
  }

  Future<void> _chooseProfileAvatarPreset() async {
    final currentAvatarId = _resolvedProfileAvatarId;
    final selectedAvatarId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ProfileAvatarPickerSheet(currentAvatarId: currentAvatarId);
      },
    );

    if (selectedAvatarId == null || !mounted) {
      return;
    }

    await _selectProfileAvatarPreset(selectedAvatarId);
  }

  Future<void> _selectProfileAvatarPreset(String avatarId) async {
    final currentSession = SessionState.current;
    if (currentSession == null) {
      return;
    }

    setState(() {
      _isUpdatingProfileAvatar = true;
    });

    try {
      await ProfileAvatarPresetStorage.saveForSession(
        session: currentSession,
        avatarId: avatarId,
      );
      await ProfileImageCacheStorage.clear();

      final updatedSession = currentSession.copyWith(
        profileImageUrl: '',
        cachedProfileImagePath: '',
        profileAvatarId: avatarId,
        isOfflineMode: false,
      );

      SessionState.current = updatedSession;
      await SessionSnapshotStorage.save(updatedSession);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfileAvatar = false;
        });
      }
    }
  }

  Future<void> _refreshSessionFromServer() async {
    try {
      final currentSession = SessionState.current;
      final refreshedSession = await _authService.fetchCurrentSession();
      if (refreshedSession == null) {
        return;
      }

      final preservedToken = refreshedSession.token.trim().isNotEmpty
          ? refreshedSession.token
          : currentSession?.token;
      final preservedDisplayName =
          refreshedSession.displayName.trim().isNotEmpty
          ? refreshedSession.displayName
          : currentSession?.displayName;
      var mergedSession = refreshedSession.copyWith(
        token: preservedToken,
        displayName: preservedDisplayName,
      );
      mergedSession = await ProfileAvatarPresetStorage.applyStoredAvatar(
        mergedSession,
      );

      final synchronizedSession = mergedSession.copyWith(
        cachedProfileImagePath: '',
        isOfflineMode: false,
      );
      SessionState.current = synchronizedSession;
      await SessionSnapshotStorage.save(synchronizedSession);

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Keep the existing local state when session refresh is unavailable.
    }
  }

  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();
    } catch (_) {
      // Ignore logout API failures and still clear the local session.
    }

    await SessionCookieStorage.clear();
    await ProfileImageCacheStorage.clear();
    await SessionSnapshotStorage.clear();
    await DashboardRuntimeValueStorage().clear();
    SessionState.current = null;

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _onSwitchProjectPressed() {
    Navigator.pushNamedAndRemoveUntil(context, '/projects', (route) => false);
  }

  Future<void> _onOpenPrivacyPolicy() async {
    final uri = Uri.parse(_privacyPolicyUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Privacy Policy.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionState.current;
    final mediaQuery = MediaQuery.of(context);
    final profileAvatarId = _resolvedProfileAvatarId;
    final displayName = session?.displayName.trim();
    final userName = displayName == null || displayName.isEmpty
        ? 'Farmer John'
        : displayName;
    final sessionToken = session?.token.trim();
    final fallbackToken = session?.mqttDeviceId?.trim();
    final rawToken = sessionToken != null && sessionToken.isNotEmpty
        ? sessionToken
        : (fallbackToken != null && fallbackToken.isNotEmpty
              ? fallbackToken
              : '');
    final hasToken = rawToken.isNotEmpty;
    final tokenText = hasToken
        ? (_isTokenVisible ? rawToken : _maskedToken(rawToken))
        : 'Not available';
    final authType = session?.authType?.trim();
    final authTypeText = authType == null || authType.isEmpty
        ? 'Unknown'
        : authType;
    final isOfflineMode = session?.isOfflineMode == true;
    final isAuthenticated = session?.authenticated == true;
    final sessionStatusText = isOfflineMode
        ? 'Offline'
        : (isAuthenticated ? 'Active' : 'Inactive');
    final sessionStatusColor = isOfflineMode
        ? const Color(0xFFE0A11B)
        : (isAuthenticated ? const Color(0xFF59BE6E) : const Color(0xFF8A9099));
    final width = mediaQuery.size.width;
    final bottomSafeInset = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _AccountBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = AppResponsiveMetrics.resolve(
                  width: width,
                  height: constraints.maxHeight,
                  bottomSafeInset: bottomSafeInset,
                );

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    metrics.screenPadding,
                    metrics.topSpacing,
                    metrics.screenPadding,
                    metrics.bottomSafeGap,
                  ),
                  children: [
                    _buildGlassHeader(),
                    SizedBox(height: metrics.headerGap),
                    Center(
                      child: _HeroProfileCard(
                        metrics: metrics,
                        profileAvatarId: profileAvatarId,
                        isUpdating: _isUpdatingProfileAvatar,
                        onEditTap: _onEditProfileAvatarPressed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: _headlineColor,
                      ),
                    ),
                    SizedBox(height: metrics.sectionGap),
                    _SectionCard(
                      metrics: metrics,
                      title: 'Session Details',
                      children: [
                        _InfoRow(
                          metrics: metrics,
                          icon: Icons.key_outlined,
                          label: 'Auth Type',
                          value: authTypeText,
                        ),
                        const _DividerRow(),
                        _InfoRow(
                          metrics: metrics,
                          icon: Icons.memory_rounded,
                          label: 'Token',
                          value: tokenText,
                          valueMonospace: hasToken,
                          trailing: hasToken
                              ? _TokenActions(
                                  isVisible: _isTokenVisible,
                                  onToggleVisibility: _toggleTokenVisibility,
                                  onCopy: () => _copyToken(rawToken),
                                )
                              : null,
                        ),
                        const _DividerRow(),
                        _InfoRow(
                          metrics: metrics,
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Session Status',
                          value: sessionStatusText,
                          valueColor: sessionStatusColor,
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.sectionGap),
                    _SectionCard(
                      metrics: metrics,
                      title: 'Preferences',
                      children: [
                        _MenuRow(
                          metrics: metrics,
                          icon: Icons.settings_outlined,
                          label: 'General Settings',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'General settings will be available here soon.',
                                ),
                              ),
                            );
                          },
                        ),
                        const _DividerRow(),
                        _MenuRow(
                          metrics: metrics,
                          icon: Icons.folder_open_rounded,
                          label: 'Switch Project',
                          onTap: _onSwitchProjectPressed,
                        ),
                        const _DividerRow(),
                        _MenuRow(
                          metrics: metrics,
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: _onOpenPrivacyPolicy,
                        ),
                        const _DividerRow(),
                        _MenuRow(
                          metrics: metrics,
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Help & support is not available yet.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.logoutTopGap),
                    _DangerActionButton(
                      height: metrics.primaryButtonHeight,
                      isLoading: _isLoggingOut,
                      label: 'Logout',
                      onPressed: _isLoggingOut ? null : _onLogoutPressed,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? get _resolvedProfileAvatarId {
    final value = SessionState.current?.profileAvatarId?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

enum _ProfileAvatarAction { avatar, remove }

const List<_ProfileAvatarPreset> _profileAvatarPresets = <_ProfileAvatarPreset>[
  _ProfileAvatarPreset(
    id: 'avatar1',
    assetPath: 'assets/icons/profile/avatar1.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar2',
    assetPath: 'assets/icons/profile/avatar2.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar3',
    assetPath: 'assets/icons/profile/avatar3.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar4',
    assetPath: 'assets/icons/profile/avatar4.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar5',
    assetPath: 'assets/icons/profile/avatar5.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar6',
    assetPath: 'assets/icons/profile/avatar6.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar7',
    assetPath: 'assets/icons/profile/avatar7.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar8',
    assetPath: 'assets/icons/profile/avatar8.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar9',
    assetPath: 'assets/icons/profile/avatar9.png',
  ),
  _ProfileAvatarPreset(
    id: 'avatar10',
    assetPath: 'assets/icons/profile/avatar10.png',
  ),
];

_ProfileAvatarPreset _profileAvatarPresetById(String avatarId) {
  return _profileAvatarPresets.firstWhere(
    (preset) => preset.id == avatarId,
    orElse: () => _profileAvatarPresets.first,
  );
}

class _ProfileAvatarPreset {
  const _ProfileAvatarPreset({required this.id, required this.assetPath});

  final String id;
  final String assetPath;
}

class _ProfileAvatarPresetImage extends StatelessWidget {
  const _ProfileAvatarPresetImage({required this.avatarId});

  final String avatarId;

  @override
  Widget build(BuildContext context) {
    final preset = _profileAvatarPresetById(avatarId);

    return Image.asset(
      preset.assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.person_outline_rounded,
          color: Color(0xFF5A9676),
        );
      },
    );
  }
}

class _AccountBackground extends StatelessWidget {
  const _AccountBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF7FBFF),
            Color(0xFFF1F5FA),
            Color(0xFFEEF3F8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFFFF).withValues(alpha: 0.54),
                    Colors.transparent,
                    const Color(0xFFDCE7F0).withValues(alpha: 0.18),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: -68,
            top: 88,
            child: _GlowOrb(
              size: 228,
              color: const Color(0xFFBCD7C7).withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            right: -78,
            top: 26,
            child: _GlowOrb(
              size: 236,
              color: const Color(0xFFD7E5EF).withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            right: -46,
            bottom: 104,
            child: _GlowOrb(
              size: 184,
              color: const Color(0xFFB8DCC3).withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _HeroProfileCard extends StatelessWidget {
  const _HeroProfileCard({
    required this.metrics,
    required this.profileAvatarId,
    required this.isUpdating,
    required this.onEditTap,
  });

  final AppResponsiveMetrics metrics;
  final String? profileAvatarId;
  final bool isUpdating;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.heroAvatarSize,
      height: metrics.heroAvatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: metrics.heroAvatarSize,
                height: metrics.heroAvatarSize,
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: metrics.heroAvatarSize / 2,
                  borderAlpha: 0.54,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.76),
                    const Color(0xFFE8F5FF).withValues(alpha: 0.28),
                  ],
                  shadows: AppGlassTheme.shadowMd,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (profileAvatarId != null)
                      _ProfileAvatarPresetImage(avatarId: profileAvatarId!)
                    else
                      _ProfileAvatarFallback(metrics: metrics),
                    if (isUpdating)
                      Container(
                        color: Colors.black.withValues(alpha: 0.20),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      width: 36,
                      height: 36,
                      decoration: AppGlassTheme.accentDecoration(
                        radius: 18,
                        colors: const <Color>[
                          Color(0xFF6BB38A),
                          Color(0xFF4E8D6B),
                        ],
                        borderColor: Colors.white.withValues(alpha: 0.92),
                        glowColor: const Color(0xFF6BB38A),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback({required this.metrics});

  final AppResponsiveMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_outline_rounded,
      size: metrics.heroAvatarIconSize,
      color: const Color(0xFF5A9676),
    );
  }
}

class _ProfileAvatarSourceSheet extends StatelessWidget {
  const _ProfileAvatarSourceSheet({
    required this.hasProfileAvatar,
    required this.onActionSelected,
  });

  final bool hasProfileAvatar;
  final ValueChanged<_ProfileAvatarAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight =
        (mediaQuery.size.height - mediaQuery.padding.vertical - 24)
            .clamp(0.0, double.infinity)
            .toDouble();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 24,
                  borderAlpha: 0.5,
                  colors: <Color>[
                    const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                    const Color(0xFFF5FBFF).withValues(alpha: 0.38),
                  ],
                  shadows: AppGlassTheme.shadowMd,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile avatar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _AccountSessionScreenState._headlineColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose a built-in avatar for this account.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _AccountSessionScreenState._mutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SourceActionTile(
                          icon: Icons.grid_view_rounded,
                          label: 'Choose avatar',
                          onTap: () =>
                              onActionSelected(_ProfileAvatarAction.avatar),
                        ),
                        if (hasProfileAvatar) ...[
                          const SizedBox(height: 8),
                          _SourceActionTile(
                            icon: Icons.delete_outline_rounded,
                            label: 'Remove avatar',
                            iconColor: const Color(0xFFB24A46),
                            onTap: () =>
                                onActionSelected(_ProfileAvatarAction.remove),
                          ),
                        ],
                        const SizedBox(height: 6),
                      ],
                    ),
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

class _SourceActionTile extends StatelessWidget {
  const _SourceActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = const Color(0xFF557B67),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: AppGlassTheme.surfaceDecoration(
          radius: 18,
          borderAlpha: 0.34,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.46),
            iconColor.withValues(alpha: 0.08),
          ],
          shadows: const <BoxShadow>[],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: 14,
                    borderAlpha: 0.32,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.56),
                      iconColor.withValues(alpha: 0.1),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
                  child: Icon(icon, color: iconColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AccountSessionScreenState._labelTextColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF718093),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarPickerSheet extends StatelessWidget {
  const _ProfileAvatarPickerSheet({required this.currentAvatarId});

  final String? currentAvatarId;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gridHeight = (mediaQuery.size.height * 0.22)
        .clamp(150.0, 210.0)
        .toDouble();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: AppGlassTheme.surfaceDecoration(
                radius: 24,
                borderAlpha: 0.5,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                  const Color(0xFFF5FBFF).withValues(alpha: 0.42),
                ],
                shadows: AppGlassTheme.shadowMd,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose avatar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _AccountSessionScreenState._headlineColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pick a built-in avatar for this account.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _AccountSessionScreenState._mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: gridHeight,
                      child: GridView.builder(
                        itemCount: _profileAvatarPresets.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final preset = _profileAvatarPresets[index];
                          final isSelected = preset.id == currentAvatarId;
                          return _ProfileAvatarChoice(
                            preset: preset,
                            isSelected: isSelected,
                            onTap: () => Navigator.of(context).pop(preset.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarChoice extends StatelessWidget {
  const _ProfileAvatarChoice({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final _ProfileAvatarPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(6),
        decoration: AppGlassTheme.surfaceDecoration(
          radius: 14,
          borderAlpha: isSelected ? 0.86 : 0.34,
          colors: <Color>[
            Colors.white.withValues(alpha: isSelected ? 0.72 : 0.48),
            const Color(0xFF6BB38A).withValues(alpha: isSelected ? 0.14 : 0.06),
          ],
          shadows: const <BoxShadow>[],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: ClipOval(
                child: _ProfileAvatarPresetImage(avatarId: preset.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.metrics,
    required this.title,
    required this.children,
  });

  final AppResponsiveMetrics metrics;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(metrics.sectionCardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: metrics.sectionCardPadding,
          decoration: AppGlassTheme.surfaceDecoration(
            radius: metrics.sectionCardRadius,
            borderAlpha: 0.5,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.76),
              const Color(0xFFF5FBFF).withValues(alpha: 0.38),
            ],
            shadows: AppGlassTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: 999,
                  borderAlpha: 0.3,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.46),
                    const Color(0xFFEAF3FF).withValues(alpha: 0.2),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _AccountSessionScreenState._labelTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF6B7280),
    this.valueMonospace = false,
    this.trailing,
  });

  final AppResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool valueMonospace;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: metrics.infoRowVerticalPadding + 2,
      ),
      decoration: AppGlassTheme.surfaceDecoration(
        radius: 18,
        borderAlpha: 0.28,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.42),
          const Color(0xFFF3F9FF).withValues(alpha: 0.22),
        ],
        shadows: const <BoxShadow>[],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(metrics.iconTileRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: metrics.iconTileSize,
                height: metrics.iconTileSize,
                decoration: AppGlassTheme.surfaceDecoration(
                  radius: metrics.iconTileRadius,
                  borderAlpha: 0.32,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.54),
                    const Color(0xFFEAF3FF).withValues(alpha: 0.18),
                  ],
                  shadows: const <BoxShadow>[],
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AccountSessionScreenState._mutedTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: valueColor,
                    fontFeatures: valueMonospace
                        ? const <FontFeature>[FontFeature.tabularFigures()]
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _TokenActions extends StatelessWidget {
  const _TokenActions({
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onCopy,
  });

  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TokenIconButton(
          icon: isVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          tooltip: isVisible ? 'Hide token' : 'Show token',
          onPressed: onToggleVisibility,
        ),
        const SizedBox(width: 2),
        _TokenIconButton(
          icon: Icons.copy_rounded,
          tooltip: 'Copy token',
          onPressed: onCopy,
        ),
      ],
    );
  }
}

class _TokenIconButton extends StatelessWidget {
  const _TokenIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      icon: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AppResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: metrics.menuRowVerticalPadding + 2,
        ),
        decoration: AppGlassTheme.surfaceDecoration(
          radius: 18,
          borderAlpha: 0.28,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.42),
            const Color(0xFFF3F9FF).withValues(alpha: 0.22),
          ],
          shadows: const <BoxShadow>[],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(metrics.iconTileRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: metrics.iconTileSize,
                  height: metrics.iconTileSize,
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: metrics.iconTileRadius,
                    borderAlpha: 0.32,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.54),
                      const Color(0xFFEAF3FF).withValues(alpha: 0.18),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AccountSessionScreenState._labelTextColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF718093),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.42),
      ),
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({
    required this.height,
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final double height;
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: AppGlassTheme.accentDecoration(
            radius: 16,
            colors: <Color>[
              _AccountSessionScreenState._dangerStartColor.withValues(
                alpha: disabled ? 0.76 : 0.96,
              ),
              _AccountSessionScreenState._dangerEndColor.withValues(
                alpha: disabled ? 0.76 : 0.92,
              ),
            ],
            borderColor: Colors.white.withValues(alpha: 0.34),
            glowColor: _AccountSessionScreenState._dangerGlowColor.withValues(
              alpha: disabled ? 0.08 : 0.2,
            ),
          ),
          child: SizedBox(
            height: height,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          label,
                          key: const ValueKey('label'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
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
