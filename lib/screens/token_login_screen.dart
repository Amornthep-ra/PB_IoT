import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_image_cache_storage.dart';
import '../services/session_cookie_storage.dart';
import '../services/session_snapshot_storage.dart';
import '../services/session_state.dart';
import '../theme/app_responsive.dart';

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

  static const _backgroundColor = Color(0xFFF2F5FA);
  static const _cardColor = Color(0xFFEFF3F8);
  static const _surfaceColor = Color(0xFFF8FAFD);
  static const _surfaceBorderColor = Color(0xFFD7E0EA);
  static const _surfaceBorderFocusColor = Color(0xFF6EAB90);
  static const _fieldTextColor = Color(0xFF20303A);
  static const _mutedTextColor = Color(0xFF667587);
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

      var synchronizedSession =
          await ProfileImageCacheStorage.synchronizeSession(session);
      synchronizedSession = await ProfileImageCacheStorage.refreshFromNetwork(
        synchronizedSession,
      );
      synchronizedSession = synchronizedSession.copyWith(isOfflineMode: false);
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

  void _onRequestToken() {
    Navigator.pushNamed(context, '/request-token');
  }

  void _onForgotToken() {
    Navigator.pushNamed(context, '/forgot-token');
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
                final footerTopGap = isShortHeight ? 24.0 : 36.0;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: metrics.authResolvedTopSpacing(
                        keyboardVisible: false,
                      ),
                    ),
                    _LogoPlaceholder(
                      width: metrics.authHeroSize,
                      height: metrics.authHeroSize,
                    ),
                    SizedBox(
                      height: metrics.authResolvedHeroCardGap(
                        keyboardVisible: false,
                      ),
                    ),
                    Container(
                      padding: cardPadding,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(
                          metrics.authCardRadius,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: _shadowLightColor,
                            offset: Offset(-8, -8),
                            blurRadius: 16,
                          ),
                          BoxShadow(
                            color: _shadowDarkColor,
                            offset: Offset(10, 12),
                            blurRadius: 24,
                          ),
                          BoxShadow(
                            color: Color(0x14677E92),
                            offset: Offset(0, 18),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldBlock(
                            label: 'Token Access',
                            child: _LoginTextField(
                              controller: _tokenController,
                              hintText: 'กรุณากรอกโทเค็นแอปของคุณ',
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.text,
                              onChanged: (_) {
                                if (_loginError != null) {
                                  setState(() {
                                    _loginError = null;
                                  });
                                }
                              },
                              decorationBuilder: _inputDecoration,
                              hasError: _loginError != null,
                              isObscured: _obscureToken,
                              keyboardAppearance: Brightness.light,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                                color: _fieldTextColor,
                                fontFamily: 'monospace',
                              ),
                              suffixIconBuilder:
                                  ({
                                    required bool isFocused,
                                    required bool hasError,
                                  }) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _FieldIconButton(
                                          icon: _obscureToken
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          tooltip: _obscureToken
                                              ? 'Show token'
                                              : 'Hide token',
                                          onTap: () {
                                            setState(() {
                                              _obscureToken = !_obscureToken;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    );
                                  },
                            ),
                          ),
                          SizedBox(height: metrics.authFieldGap),
                          _FieldBlock(
                            label: 'Profile Name',
                            trailingLabel: '(ชื่อโปรไฟล์)',
                            child: _LoginTextField(
                              controller: _displayNameController,
                              hintText: 'กรอกชื่อที่ต้องการให้เป็นชื่อโปรไฟล์',
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _onLoginPressed(),
                              decorationBuilder: _inputDecoration,
                              keyboardAppearance: Brightness.light,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: loginError == null
                                ? SizedBox(height: errorGapHeight)
                                : _LoginErrorBox(
                                    key: ValueKey<String>(loginError.title),
                                    error: loginError,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          _RememberMeRow(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value;
                              });
                            },
                          ),
                          SizedBox(height: buttonTopGap),
                          _GlowLoginButton(
                            height: metrics.primaryButtonHeight + 4,
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _onLoginPressed,
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      minimum: EdgeInsets.only(top: footerTopGap, bottom: 20),
                      child: _BottomActionBar(
                        onRequestToken: _onRequestToken,
                        onForgotToken: _onForgotToken,
                      ),
                    ),
                  ],
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: content,
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

class _LoginErrorBox extends StatelessWidget {
  const _LoginErrorBox({super.key, required this.error});

  final _LoginError error;

  @override
  Widget build(BuildContext context) {
    const errorColor = Color(0xFFB24A4A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2C8C8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(error.icon, size: 18, color: errorColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.25,
                    color: errorColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  error.message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF8F4A4A),
                    fontWeight: FontWeight.w500,
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

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

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
            left: -60,
            top: 110,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFFBCD7C7).withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            right: -70,
            top: 20,
            child: _GlowOrb(
              size: 230,
              color: const Color(0xFFD7E5EF).withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            right: -48,
            bottom: 90,
            child: _GlowOrb(
              size: 180,
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

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.child,
    this.trailingLabel,
  });

  final String label;
  final String? trailingLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _TokenLoginScreenState._labelTextColor,
                ),
              ),
              if (trailingLabel != null)
                TextSpan(
                  text: ' $trailingLabel',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF718093),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          'assets/icons/logo/Princebot_IoT.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.decorationBuilder,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.style,
    this.hasError = false,
    this.isObscured = false,
    this.keyboardAppearance,
    this.suffixIconBuilder,
  });

  final TextEditingController controller;
  final String hintText;
  final InputDecoration Function({
    required String hintText,
    required bool isFocused,
    bool hasError,
    Widget? suffixIcon,
  })
  decorationBuilder;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final bool hasError;
  final bool isObscured;
  final Brightness? keyboardAppearance;
  final Widget Function({required bool isFocused, required bool hasError})?
  suffixIconBuilder;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          _TokenLoginScreenState._fieldRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? _TokenLoginScreenState._buttonGlowColor.withValues(
                    alpha: 0.18,
                  )
                : _TokenLoginScreenState._shadowLightColor,
            offset: const Offset(-4, -4),
            blurRadius: isFocused ? 12 : 8,
          ),
          BoxShadow(
            color: isFocused
                ? _TokenLoginScreenState._buttonGlowColor.withValues(
                    alpha: 0.10,
                  )
                : _TokenLoginScreenState._shadowDarkColor,
            offset: const Offset(6, 8),
            blurRadius: isFocused ? 18 : 12,
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        obscureText: widget.isObscured,
        autocorrect: false,
        enableSuggestions: !widget.isObscured,
        keyboardAppearance: widget.keyboardAppearance,
        maxLines: 1,
        style:
            widget.style ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.15,
              color: _TokenLoginScreenState._fieldTextColor,
            ),
        cursorColor: _TokenLoginScreenState._surfaceBorderFocusColor,
        decoration: widget.decorationBuilder(
          hintText: widget.hintText,
          isFocused: isFocused,
          hasError: widget.hasError,
          suffixIcon: widget.suffixIconBuilder?.call(
            isFocused: isFocused,
            hasError: widget.hasError,
          ),
        ),
      ),
    );
  }
}

class _RememberMeRow extends StatelessWidget {
  const _RememberMeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFF7FC39C)
                    : const Color(0xFFDDE5EE),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: value
                      ? const Color(0xFF8FCDAA)
                      : const Color(0xFFCFD9E3),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.76),
                    offset: const Offset(-1, -1),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: const Color(0x190E1E2B),
                    offset: const Offset(2, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value
                        ? const Color(0xFFF9FFFB)
                        : const Color(0xFFF8FAFD),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Remember me',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5E6C79),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowLoginButton extends StatelessWidget {
  const _GlowLoginButton({
    required this.height,
    required this.isLoading,
    required this.onPressed,
  });

  final double height;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          _TokenLoginScreenState._buttonRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: _TokenLoginScreenState._buttonGlowColor.withValues(
              alpha: disabled ? 0.05 : 0.16,
            ),
            blurRadius: disabled ? 12 : 22,
          ),
          const BoxShadow(
            color: _TokenLoginScreenState._shadowLightColor,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: _TokenLoginScreenState._shadowDarkColor,
            offset: Offset(8, 10),
            blurRadius: 14,
          ),
          const BoxShadow(
            color: Color(0x1F4F9070),
            offset: Offset(0, 14),
            blurRadius: 26,
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
              borderRadius: BorderRadius.circular(
                _TokenLoginScreenState._buttonRadius,
              ),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _TokenLoginScreenState._buttonRadius,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _TokenLoginScreenState._buttonStartColor.withValues(
                    alpha: disabled ? 0.76 : 1,
                  ),
                  _TokenLoginScreenState._buttonEndColor.withValues(
                    alpha: disabled ? 0.76 : 1,
                  ),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.34),
                width: 0.9,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x36FFFFFF),
                  offset: Offset(0, 1),
                  blurRadius: 0,
                ),
              ],
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
                    : const Text(
                        'Sign In',
                        key: ValueKey('label'),
                        style: TextStyle(
                          fontSize: 17,
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onRequestToken,
    required this.onForgotToken,
  });

  final VoidCallback onRequestToken;
  final VoidCallback onForgotToken;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _FooterLink(label: 'Request Token', onTap: onRequestToken),
        const Text(
          '|',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF5D6A63),
            fontWeight: FontWeight.w400,
          ),
        ),
        _FooterLink(label: 'Forgot Token', onTap: onForgotToken),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF66788A),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

class _FieldIconButton extends StatelessWidget {
  const _FieldIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 18,
      iconSize: 19,
      color: const Color(0xFF718092),
      icon: Icon(icon),
    );
  }
}
