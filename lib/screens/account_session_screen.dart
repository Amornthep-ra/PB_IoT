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

part 'account_session_parts/avatar_widgets.dart';
part 'account_session_parts/background_widgets.dart';
part 'account_session_parts/session_detail_widgets.dart';

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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
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
                    tooltip: 'กลับ',
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
                      'ตั้งค่า',
                      style: TextStyle(
                        fontSize: 21,
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
    ).showSnackBar(const SnackBar(content: Text('คัดลอกโทเค็นแล้ว')));
  }

  String _maskedToken(String token) {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return 'ไม่พร้อมใช้งาน';
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

  String _authTypeLabel(String authType) {
    return switch (authType.trim().toLowerCase()) {
      'token' => 'โทเค็น',
      'cookie' => 'คุกกี้',
      'session' => 'เซสชัน',
      _ => authType,
    };
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
        const SnackBar(content: Text('ไม่สามารถเปิดนโยบายความเป็นส่วนตัวได้')),
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
        ? 'ผู้ใช้งาน'
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
        : 'ไม่พร้อมใช้งาน';
    final authType = session?.authType?.trim();
    final authTypeText = authType == null || authType.isEmpty
        ? 'ไม่ทราบ'
        : _authTypeLabel(authType);
    final isOfflineMode = session?.isOfflineMode == true;
    final isAuthenticated = session?.authenticated == true;
    final sessionStatusText = isOfflineMode
        ? 'ออฟไลน์'
        : (isAuthenticated ? 'ใช้งานอยู่' : 'ไม่ได้ใช้งาน');
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
                final isTablet = AppResponsiveLayout.isTabletWidth(
                  constraints.maxWidth,
                );
                final contentWidth = isTablet
                    ? AppResponsiveLayout.dashboardShellWidth(
                        constraints.maxWidth,
                      )
                    : double.infinity;
                final content = SizedBox(
                  key: const ValueKey<String>('account_session_content_shell'),
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: _headlineColor,
                        ),
                      ),
                      SizedBox(height: metrics.sectionGap),
                      _SectionCard(
                        metrics: metrics,
                        title: 'รายละเอียดเซสชัน',
                        children: [
                          _InfoRow(
                            metrics: metrics,
                            icon: Icons.key_outlined,
                            label: 'ประเภทการเข้าสู่ระบบ',
                            value: authTypeText,
                          ),
                          const _DividerRow(),
                          _InfoRow(
                            metrics: metrics,
                            icon: Icons.memory_rounded,
                            label: 'โทเค็น',
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
                            label: 'สถานะเซสชัน',
                            value: sessionStatusText,
                            valueColor: sessionStatusColor,
                          ),
                        ],
                      ),
                      SizedBox(height: metrics.sectionGap),
                      _SectionCard(
                        metrics: metrics,
                        title: 'การตั้งค่า',
                        children: [
                          _MenuRow(
                            metrics: metrics,
                            icon: Icons.settings_outlined,
                            label: 'การตั้งค่าทั่วไป',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'การตั้งค่าทั่วไปจะพร้อมใช้งานเร็วๆ นี้',
                                  ),
                                ),
                              );
                            },
                          ),
                          const _DividerRow(),
                          _MenuRow(
                            metrics: metrics,
                            icon: Icons.folder_open_rounded,
                            label: 'เปลี่ยนโปรเจกต์',
                            onTap: _onSwitchProjectPressed,
                          ),
                          const _DividerRow(),
                          _MenuRow(
                            metrics: metrics,
                            icon: Icons.privacy_tip_outlined,
                            label: 'นโยบายความเป็นส่วนตัว',
                            onTap: _onOpenPrivacyPolicy,
                          ),
                          const _DividerRow(),
                          _MenuRow(
                            metrics: metrics,
                            icon: Icons.help_outline_rounded,
                            label: 'ช่วยเหลือและสนับสนุน',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'ศูนย์ช่วยเหลือยังไม่พร้อมใช้งาน',
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
                        label: 'ออกจากระบบ',
                        onPressed: _isLoggingOut ? null : _onLogoutPressed,
                      ),
                    ],
                  ),
                );

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 0 : metrics.screenPadding,
                    isTablet ? 36 : metrics.topSpacing,
                    isTablet ? 0 : metrics.screenPadding,
                    metrics.bottomSafeGap + 96,
                  ),
                  children: [
                    isTablet
                        ? Align(alignment: Alignment.topCenter, child: content)
                        : content,
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
