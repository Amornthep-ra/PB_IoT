import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/profile_avatar_preset_storage.dart';
import '../services/session_cookie_storage.dart';
import '../services/session_snapshot_storage.dart';
import '../services/session_state.dart';
import '../theme/app_responsive.dart';

part 'token_login_parts/login_background_widgets.dart';
part 'token_login_parts/login_form_widgets.dart';
part 'token_login_parts/login_status_widgets.dart';

class TokenLoginScreen extends StatefulWidget {
  const TokenLoginScreen({super.key});

  static const sessionExpiredRouteArgument = 'sessionExpired';

  @override
  State<TokenLoginScreen> createState() => _TokenLoginScreenState();
}

class _TokenLoginScreenState extends State<TokenLoginScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscureToken = true;
  bool _handledRouteError = false;
  _LoginError? _loginError;

  static const _tokenRequestUrl =
      'https://console.princebot.co.th/token/request';
  static const _deleteAccountUrl =
      'https://console.princebot.co.th/delete-account';
  static const _privacyPolicyUrl =
      'https://sites.google.com/view/pb-iot-privacy-policy';

  static const _backgroundColor = Color(0xFFF2F5FA);
  static const _cardColor = Color(0xFFEFF3F8);
  static const _surfaceColor = Color(0xFFF8FAFD);
  static const _surfaceBorderColor = Color(0xFFC9D5E1);
  static const _surfaceBorderFocusColor = Color(0xFF6EAB90);
  static const _fieldTextColor = Color(0xFF20303A);
  static const _mutedTextColor = Color(0xFF5C6A7A);
  static const _labelTextColor = Color(0xFF4B5A69);
  static const _buttonStartColor = Color(0xFF7FC39C);
  static const _buttonEndColor = Color(0xFF4E9070);
  static const _buttonGlowColor = Color(0xFF9CCCB0);
  static const _shadowDarkColor = Color(0x1D9CA9B5);
  static const _shadowLightColor = Color(0xF9FFFFFF);
  static const _fieldRadius = 16.0;
  static const _buttonRadius = 18.0;

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_handledRouteError) {
      return;
    }

    _handledRouteError = true;
    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument == TokenLoginScreen.sessionExpiredRouteArgument) {
      _loginError = _LoginError.sessionExpired;
    }
  }

  Future<void> _loadRememberedLogin() async {
    final remembered = await SessionCookieStorage.loadRememberedLogin();

    if (!mounted || remembered == null) {
      return;
    }

    setState(() {
      _rememberMe = remembered.rememberMe;
      _tokenController.text = remembered.token;
      _displayNameController.text = remembered.displayName;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();

    final token = _tokenController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (token.isEmpty) {
      setState(() {
        _loginError = _LoginError.missingToken;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      final session = await _authService.login(
        token: token,
        displayName: displayName,
        rememberMe: _rememberMe,
      );

      final sessionWithAvatar =
          await ProfileAvatarPresetStorage.applyStoredAvatar(session);
      final synchronizedSession = sessionWithAvatar.copyWith(
        cachedProfileImagePath: '',
        isOfflineMode: false,
      );
      await SessionSnapshotStorage.save(synchronizedSession);
      SessionState.current = synchronizedSession;

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/projects');
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loginError = _LoginError.fromAuthException(error);
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() {
        _loginError = _LoginError.timeout;
      });
    } on SocketException {
      if (!mounted) {
        return;
      }
      setState(() {
        _loginError = _LoginError.offline;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loginError = _LoginError.unknown;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onOpenTokenRequest() async {
    final uri = Uri.parse(_tokenRequestUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเปิดเบราว์เซอร์ได้ กรุณาลองอีกครั้ง'),
        ),
      );
    }
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

  Future<void> _onOpenDeleteAccount() async {
    final uri = Uri.parse(_deleteAccountUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดหน้าลบบัญชีได้')),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isFocused,
    bool hasError = false,
    Widget? suffixIcon,
  }) {
    final borderSide = BorderSide(
      color: hasError
          ? const Color(0xFFD86E6E)
          : isFocused
          ? _surfaceBorderFocusColor
          : _surfaceBorderColor,
      width: hasError ? 1.2 : (isFocused ? 1.4 : 1),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: _mutedTextColor,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _surfaceColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: borderSide,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFC46767), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFE18888), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final width = size.width;
    final loginError = _loginError;
    final keyboardVisible = keyboardInset > 0;
    final hasFieldError =
        loginError != null && loginError != _LoginError.sessionExpired;

    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = AppResponsiveMetrics.resolve(
                  width: width,
                  height: constraints.maxHeight,
                  bottomSafeInset: mediaQuery.padding.bottom,
                );
                final isShortHeight = constraints.maxHeight < 760;
                final cardPadding = EdgeInsets.fromLTRB(
                  20,
                  isShortHeight ? 18 : 20,
                  20,
                  isShortHeight ? 18 : 20,
                );
                final errorGapHeight = isShortHeight ? 14.0 : 18.0;
                final buttonTopGap = isShortHeight ? 18.0 : 22.0;
                final footerTopGap = isShortHeight ? 18.0 : 24.0;
                final effectiveFooterTopGap = keyboardVisible
                    ? 8.0
                    : footerTopGap;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: metrics.authResolvedTopSpacing(
                        keyboardVisible: keyboardVisible,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: keyboardVisible
                          ? const SizedBox.shrink()
                          : _LogoPlaceholder(
                              width: metrics.authHeroSize * 0.68,
                              height: metrics.authHeroSize * 0.68,
                            ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: metrics.authResolvedHeroCardGap(
                          keyboardVisible: keyboardVisible,
                        ),
                      ),
                    ),
                    _LoginFormCard(
                      cardPadding: cardPadding,
                      cardRadius: metrics.authCardRadius,
                      fieldGap: metrics.authFieldGap,
                      errorGapHeight: errorGapHeight,
                      buttonTopGap: buttonTopGap,
                      buttonHeight: metrics.primaryButtonHeight + 4,
                      tokenController: _tokenController,
                      displayNameController: _displayNameController,
                      loginError: loginError,
                      hasFieldError: hasFieldError,
                      rememberMe: _rememberMe,
                      obscureToken: _obscureToken,
                      isLoading: _isLoading,
                      decorationBuilder: _inputDecoration,
                      onTokenChanged: (_) {
                        if (_loginError != null) {
                          setState(() {
                            _loginError = null;
                          });
                        }
                      },
                      onToggleTokenVisibility: () {
                        setState(() {
                          _obscureToken = !_obscureToken;
                        });
                      },
                      onDisplayNameSubmitted: (_) => _onLoginPressed(),
                      onRememberChanged: (value) {
                        setState(() {
                          _rememberMe = value;
                        });
                      },
                      onLoginPressed: _isLoading ? null : _onLoginPressed,
                    ),
                    SafeArea(
                      top: false,
                      minimum: EdgeInsets.only(
                        top: effectiveFooterTopGap,
                        bottom: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LoginFooterLinks(
                            onTokenRequestTap: _onOpenTokenRequest,
                            onPrivacyPolicyTap: _onOpenPrivacyPolicy,
                            onDeleteAccountTap: _onOpenDeleteAccount,
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final contentWidth =
                    AppResponsiveLayout.constrainedContentWidth(
                      width - (metrics.screenPadding * 2),
                    );

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    metrics.screenPadding,
                    0,
                    metrics.screenPadding,
                    18 + keyboardInset,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: content,
                      ),
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
}

class _LoginError {
  const _LoginError({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  static const missingToken = _LoginError(
    title: 'กรุณากรอก Token',
    message: 'ใส่ app token ที่ได้รับก่อนเข้าสู่ระบบ',
    icon: Icons.vpn_key_rounded,
  );

  static const invalidToken = _LoginError(
    title: 'Token ไม่ถูกต้อง',
    message: 'ตรวจสอบ token อีกครั้ง หรือลองขอ token ใหม่หากยังเข้าไม่ได้',
    icon: Icons.vpn_key_rounded,
  );

  static const timeout = _LoginError(
    title: 'เซิร์ฟเวอร์ตอบสนองช้า',
    message: 'รอสักครู่แล้วลองใหม่อีกครั้ง',
    icon: Icons.schedule_rounded,
  );

  static const offline = _LoginError(
    title: 'ไม่มีอินเทอร์เน็ต',
    message: 'ตรวจสอบ Wi-Fi หรือสัญญาณมือถือ แล้วลองเข้าสู่ระบบอีกครั้ง',
    icon: Icons.wifi_off_rounded,
  );

  static const sessionExpired = _LoginError(
    title: 'Session หมดอายุ',
    message: 'กรุณาเข้าสู่ระบบใหม่เพื่อเชื่อมต่ออุปกรณ์อีกครั้ง',
    icon: Icons.lock_outline_rounded,
  );

  static const server = _LoginError(
    title: 'ระบบยังไม่พร้อมใช้งาน',
    message: 'เซิร์ฟเวอร์มีปัญหาชั่วคราว กรุณาลองใหม่ภายหลัง',
    icon: Icons.cloud_off_rounded,
  );

  static const unknown = _LoginError(
    title: 'เข้าสู่ระบบไม่สำเร็จ',
    message: 'ลองอีกครั้ง หรือเช็ก token และการเชื่อมต่ออินเทอร์เน็ต',
    icon: Icons.error_outline_rounded,
  );

  factory _LoginError.fromAuthException(AuthException error) {
    final message = error.message.toLowerCase();
    final statusCode = error.statusCode;

    if (message.contains('session') && message.contains('expired')) {
      return sessionExpired;
    }

    if (statusCode == 408 || statusCode == 504) {
      return timeout;
    }

    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        message.contains('token')) {
      return invalidToken;
    }

    if (statusCode != null && statusCode >= 500) {
      return server;
    }

    return unknown;
  }
}
