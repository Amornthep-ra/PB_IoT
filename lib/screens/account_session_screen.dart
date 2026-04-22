import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/profile_image_cache_storage.dart';
import '../services/session_cookie_storage.dart';
import '../services/session_snapshot_storage.dart';
import '../services/session_state.dart';
import '../theme/app_responsive.dart';
import '../features/dashboard/services/dashboard_runtime_value_storage.dart';

class AccountSessionScreen extends StatefulWidget {
  const AccountSessionScreen({super.key});

  @override
  State<AccountSessionScreen> createState() => _AccountSessionScreenState();
}

class _AccountSessionScreenState extends State<AccountSessionScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoggingOut = false;
  bool _isUpdatingProfilePhoto = false;
  XFile? _localProfilePhoto;
  String? _profileImageSyncUrl;

  static const _backgroundColor = Color(0xFFF2F5FA);
  static const _cardColor = Color(0xFFEFF3F8);
  static const _surfaceColor = Color(0xFFF8FAFD);
  static const _headlineColor = Color(0xFF15212B);
  static const _labelTextColor = Color(0xFF4B5A69);
  static const _mutedTextColor = Color(0xFF667587);
  static const _shadowDarkColor = Color(0x1D9CA9B5);
  static const _shadowLightColor = Color(0xF9FFFFFF);
  static const _dangerStartColor = Color(0xFFF06A62);
  static const _dangerEndColor = Color(0xFFD84840);
  static const _dangerGlowColor = Color(0xFFF0A09B);

  @override
  void initState() {
    super.initState();
    _syncProfileImageState();
    _refreshSessionFromServer();
  }

  Future<void> _onEditProfilePhotoPressed() async {
    final selectedAction = await showModalBottomSheet<_ProfilePhotoAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ProfilePhotoSourceSheet(
          hasProfilePhoto: _resolvedProfileImageUrl != null,
          onActionSelected: (action) => Navigator.of(context).pop(action),
        );
      },
    );

    if (selectedAction == null) {
      return;
    }

    if (selectedAction == _ProfilePhotoAction.remove) {
      await _removeProfilePhoto();
      return;
    }

    final selectedSource = selectedAction == _ProfilePhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: selectedSource,
        imageQuality: 88,
        maxWidth: 1600,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      setState(() {
        _localProfilePhoto = pickedFile;
        _isUpdatingProfilePhoto = true;
      });

      final uploadedUrl = await _authService.uploadProfilePhoto(
        filePath: pickedFile.path,
      );

      await _updateSessionProfileImage(
        profileImageUrl: uploadedUrl,
        localFilePath: pickedFile.path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _localProfilePhoto = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _localProfilePhoto = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update profile photo right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfilePhoto = false;
        });
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    final currentPhotoUrl = _resolvedProfileImageUrl;
    if (currentPhotoUrl == null || currentPhotoUrl.isEmpty) {
      return;
    }

    setState(() {
      _isUpdatingProfilePhoto = true;
    });

    try {
      await _authService.deleteProfilePhoto(photoUrl: currentPhotoUrl);
      await _clearCachedProfileImage();

      if (!mounted) {
        return;
      }

      setState(() {
        _localProfilePhoto = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to remove profile photo right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfilePhoto = false;
        });
      }
    }
  }

  Future<void> _updateSessionProfileImage({
    required String profileImageUrl,
    String? localFilePath,
  }) async {
    final currentSession = SessionState.current;
    if (currentSession == null) {
      return;
    }

    var updatedSession = currentSession.copyWith(
      profileImageUrl: profileImageUrl,
      cachedProfileImagePath: '',
    );

    updatedSession = await ProfileImageCacheStorage.synchronizeSession(
      updatedSession,
    );

    if (localFilePath != null && localFilePath.isNotEmpty) {
      updatedSession = await ProfileImageCacheStorage.cacheFromFile(
        session: updatedSession,
        sourcePath: localFilePath,
      );
    }

    SessionState.current = updatedSession;
    await SessionSnapshotStorage.save(
      updatedSession.copyWith(isOfflineMode: false),
    );
    _profileImageSyncUrl = _resolvedProfileImageUrl;
  }

  Future<void> _clearCachedProfileImage() async {
    final currentSession = SessionState.current;
    if (currentSession == null) {
      return;
    }

    await ProfileImageCacheStorage.clear();
    await SessionSnapshotStorage.save(
      currentSession.copyWith(
        profileImageUrl: '',
        cachedProfileImagePath: '',
        isOfflineMode: false,
      ),
    );
    SessionState.current = currentSession.copyWith(
      profileImageUrl: '',
      cachedProfileImagePath: '',
      isOfflineMode: false,
    );
    _profileImageSyncUrl = null;
  }

  Future<void> _syncProfileImageState() async {
    final currentSession = SessionState.current;
    if (currentSession == null) {
      return;
    }

    final normalizedUrl = _resolvedProfileImageUrl;
    if (_profileImageSyncUrl == normalizedUrl) {
      return;
    }

    _profileImageSyncUrl = normalizedUrl;

    var synchronizedSession = await ProfileImageCacheStorage.synchronizeSession(
      currentSession,
    );
    SessionState.current = synchronizedSession;

    if (normalizedUrl == null) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    synchronizedSession = await ProfileImageCacheStorage.refreshFromNetwork(
      synchronizedSession,
    );

    if (!mounted) {
      SessionState.current = synchronizedSession;
      return;
    }

    final latestUrl = SessionState.current?.profileImageUrl?.trim();
    if (latestUrl == normalizedUrl) {
      SessionState.current = synchronizedSession;
      setState(() {});
    }
  }

  Future<void> _refreshSessionFromServer() async {
    try {
      final refreshedSession = await _authService.fetchCurrentSession();
      if (refreshedSession == null) {
        return;
      }

      var synchronizedSession =
          await ProfileImageCacheStorage.synchronizeSession(refreshedSession);
      synchronizedSession = await ProfileImageCacheStorage.refreshFromNetwork(
        synchronizedSession,
      );
      synchronizedSession = synchronizedSession.copyWith(isOfflineMode: false);
      SessionState.current = synchronizedSession;
      await SessionSnapshotStorage.save(synchronizedSession);
      _profileImageSyncUrl = null;

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

  @override
  Widget build(BuildContext context) {
    final session = SessionState.current;
    final mediaQuery = MediaQuery.of(context);
    final cachedProfileImagePath = _resolvedCachedProfileImagePath;
    final profileImageUrl = _resolvedProfileImageUrl;
    final displayName = session?.displayName.trim();
    final userName = displayName == null || displayName.isEmpty
        ? 'Farmer John'
        : displayName;
    final sessionToken = session?.token.trim();
    final fallbackToken = session?.mqttDeviceId?.trim();
    final tokenText = sessionToken != null && sessionToken.isNotEmpty
        ? sessionToken
        : (fallbackToken != null && fallbackToken.isNotEmpty
              ? fallbackToken
              : 'Not available');
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

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.screenPadding,
                    metrics.topSpacing,
                    metrics.screenPadding,
                    metrics.bottomSafeGap,
                  ),
                  child: SizedBox(
                    height:
                        constraints.maxHeight -
                        metrics.topSpacing -
                        metrics.bottomSafeGap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _TopBarButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.maybePop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'Account & Session',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: _headlineColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 42),
                          ],
                        ),
                        SizedBox(height: metrics.headerGap),
                        Center(
                          child: _HeroProfileCard(
                            metrics: metrics,
                            localProfilePhoto: _localProfilePhoto,
                            cachedProfileImagePath: cachedProfileImagePath,
                            profileImageUrl: profileImageUrl,
                            isUpdating: _isUpdatingProfilePhoto,
                            onEditTap: _onEditProfilePhotoPressed,
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
                              label: 'App Settings',
                              onTap: () {
                                // TODO: Navigate to app settings.
                              },
                            ),
                            const _DividerRow(),
                            _MenuRow(
                              metrics: metrics,
                              icon: Icons.help_outline_rounded,
                              label: 'Help & Support',
                              onTap: () {
                                // TODO: Navigate to help and support.
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
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? get _resolvedProfileImageUrl {
    final session = SessionState.current;
    final value = session?.profileImageUrl?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _resolvedCachedProfileImagePath {
    return ProfileImageCacheStorage.resolveCachedPath(SessionState.current);
  }
}

enum _ProfilePhotoAction { camera, gallery, remove }

class _AccountBackground extends StatelessWidget {
  const _AccountBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFD), Color(0xFFE8EEF5)],
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

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _AccountSessionScreenState._cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: _AccountSessionScreenState._shadowLightColor,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: _AccountSessionScreenState._shadowDarkColor,
            offset: Offset(6, 8),
            blurRadius: 12,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        splashRadius: 18,
        iconSize: 18,
        color: const Color(0xFF4F5F6E),
        icon: Icon(icon),
      ),
    );
  }
}

class _HeroProfileCard extends StatelessWidget {
  const _HeroProfileCard({
    required this.metrics,
    required this.localProfilePhoto,
    required this.cachedProfileImagePath,
    required this.profileImageUrl,
    required this.isUpdating,
    required this.onEditTap,
  });

  final AppResponsiveMetrics metrics;
  final XFile? localProfilePhoto;
  final String? cachedProfileImagePath;
  final String? profileImageUrl;
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
          Container(
            width: metrics.heroAvatarSize,
            height: metrics.heroAvatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _AccountSessionScreenState._surfaceColor,
              boxShadow: const [
                BoxShadow(
                  color: _AccountSessionScreenState._shadowLightColor,
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: _AccountSessionScreenState._shadowDarkColor,
                  offset: Offset(5, 6),
                  blurRadius: 10,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (localProfilePhoto != null)
                  Image.file(
                    File(localProfilePhoto!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _ProfileAvatarFallback(metrics: metrics);
                    },
                  )
                else if (cachedProfileImagePath != null)
                  Image.file(
                    File(cachedProfileImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return profileImageUrl != null
                          ? Image.network(
                              profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _ProfileAvatarFallback(metrics: metrics);
                              },
                            )
                          : _ProfileAvatarFallback(metrics: metrics);
                    },
                  )
                else if (profileImageUrl != null)
                  Image.network(
                    profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _ProfileAvatarFallback(metrics: metrics);
                    },
                  )
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEditTap,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6BB38A), Color(0xFF4E8D6B)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
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

class _ProfilePhotoSourceSheet extends StatelessWidget {
  const _ProfilePhotoSourceSheet({
    required this.hasProfilePhoto,
    required this.onActionSelected,
  });

  final bool hasProfilePhoto;
  final ValueChanged<_ProfilePhotoAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: _AccountSessionScreenState._cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: _AccountSessionScreenState._shadowLightColor,
                offset: Offset(-6, -6),
                blurRadius: 10,
              ),
              BoxShadow(
                color: _AccountSessionScreenState._shadowDarkColor,
                offset: Offset(6, 8),
                blurRadius: 14,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change profile photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _AccountSessionScreenState._headlineColor,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose where to get your new profile image.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _AccountSessionScreenState._mutedTextColor,
                  ),
                ),
                const SizedBox(height: 14),
                _SourceActionTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take photo',
                  onTap: () => onActionSelected(_ProfilePhotoAction.camera),
                ),
                const SizedBox(height: 8),
                _SourceActionTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from gallery',
                  onTap: () => onActionSelected(_ProfilePhotoAction.gallery),
                ),
                if (hasProfilePhoto) ...[
                  const SizedBox(height: 8),
                  _SourceActionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove photo',
                    iconColor: const Color(0xFFB24A46),
                    onTap: () => onActionSelected(_ProfilePhotoAction.remove),
                  ),
                ],
                const SizedBox(height: 6),
              ],
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
        decoration: BoxDecoration(
          color: _AccountSessionScreenState._surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
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
    return Container(
      padding: metrics.sectionCardPadding,
      decoration: BoxDecoration(
        color: _AccountSessionScreenState._cardColor,
        borderRadius: BorderRadius.circular(metrics.sectionCardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: const [
          BoxShadow(
            color: _AccountSessionScreenState._shadowLightColor,
            offset: Offset(-6, -6),
            blurRadius: 10,
          ),
          BoxShadow(
            color: _AccountSessionScreenState._shadowDarkColor,
            offset: Offset(6, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _AccountSessionScreenState._labelTextColor,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
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
  });

  final AppResponsiveMetrics metrics;
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: metrics.infoRowVerticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: metrics.iconTileSize,
            height: metrics.iconTileSize,
            decoration: BoxDecoration(
              color: _AccountSessionScreenState._surfaceColor,
              borderRadius: BorderRadius.circular(metrics.iconTileRadius),
              boxShadow: const [
                BoxShadow(
                  color: _AccountSessionScreenState._shadowLightColor,
                  offset: Offset(-2, -2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: _AccountSessionScreenState._shadowDarkColor,
                  offset: Offset(3, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: metrics.menuRowVerticalPadding),
        child: Row(
          children: [
            Container(
              width: metrics.iconTileSize,
              height: metrics.iconTileSize,
              decoration: BoxDecoration(
                color: _AccountSessionScreenState._surfaceColor,
                borderRadius: BorderRadius.circular(metrics.iconTileRadius),
                boxShadow: const [
                  BoxShadow(
                    color: _AccountSessionScreenState._shadowLightColor,
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: _AccountSessionScreenState._shadowDarkColor,
                    offset: Offset(3, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF667A8C)),
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
        color: Colors.white.withValues(alpha: 0.72),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _AccountSessionScreenState._dangerGlowColor.withValues(
              alpha: disabled ? 0.05 : 0.16,
            ),
            blurRadius: disabled ? 12 : 22,
          ),
          const BoxShadow(
            color: _AccountSessionScreenState._shadowLightColor,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Color(0x28B54A44),
            offset: Offset(8, 10),
            blurRadius: 16,
          ),
        ],
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
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _AccountSessionScreenState._dangerStartColor.withValues(
                    alpha: disabled ? 0.76 : 1,
                  ),
                  _AccountSessionScreenState._dangerEndColor.withValues(
                    alpha: disabled ? 0.76 : 1,
                  ),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 0.9,
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
    );
  }
}
