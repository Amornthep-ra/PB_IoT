import 'package:flutter/material.dart';

import '../services/token_request_service.dart';
import '../theme/app_responsive.dart';

class RequestTokenScreen extends StatefulWidget {
  const RequestTokenScreen({super.key});

  @override
  State<RequestTokenScreen> createState() => _RequestTokenScreenState();
}

class _RequestTokenScreenState extends State<RequestTokenScreen> {
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();
  final TokenRequestService _tokenRequestService = TokenRequestService();

  bool _isLoading = false;
  String? _errorText;

  static const _backgroundColor = Color(0xFFF2F5FA);
  static const _cardColor = Color(0xFFEFF3F8);
  static const _cardHighlightColor = Color(0xFFFFFFFF);
  static const _surfaceColor = Color(0xFFF8FAFD);
  static const _surfaceBorderColor = Color(0xFFD7E0EA);
  static const _surfaceBorderFocusColor = Color(0xFF6EAB90);
  static const _fieldTextColor = Color(0xFF20303A);
  static const _mutedTextColor = Color(0xFF667587);
  static const _labelTextColor = Color(0xFF4B5A69);
  static const _headlineColor = Color(0xFF15212B);
  static const _buttonStartColor = Color(0xFF7FC39C);
  static const _buttonEndColor = Color(0xFF4E9070);
  static const _buttonGlowColor = Color(0xFF9CCCB0);
  static const _shadowDarkColor = Color(0x1D9CA9B5);
  static const _shadowLightColor = Color(0xF9FFFFFF);
  static const _fieldRadius = 16.0;
  static const _buttonRadius = 18.0;

  @override
  void dispose() {
    _gmailController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _onCreateTokenPressed() async {
    FocusScope.of(context).unfocus();

    final gmail = _gmailController.text.trim();
    final deviceId = _deviceIdController.text.trim();

    if (gmail.isEmpty || deviceId.isEmpty) {
      setState(() {
        _errorText = 'Please enter your Gmail address and device ID.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _tokenRequestService.requestToken(gmail: gmail, deviceId: deviceId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token request submitted. Please check your Gmail.'),
        ),
      );
      Navigator.maybePop(context);
    } on TokenRequestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Unable to create token right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isFocused,
    bool hasError = false,
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
        fontSize: 15,
        color: _mutedTextColor,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _surfaceColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _RequestTokenBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = AppResponsiveMetrics.resolve(
                  width: width,
                  height: constraints.maxHeight,
                  bottomSafeInset: mediaQuery.padding.bottom,
                );
                final isShortHeight = constraints.maxHeight < 780;
                final cardPadding = EdgeInsets.fromLTRB(
                  20,
                  isShortHeight ? 18 : 20,
                  20,
                  isShortHeight ? 20 : 26,
                );
                final introGap = isShortHeight ? 6.0 : 8.0;
                final helperGap = isShortHeight ? 10.0 : 14.0;
                final submitGap = isShortHeight ? 16.0 : 18.0;
                final emptyErrorGap = isShortHeight ? 14.0 : 18.0;
                Widget buildRequestCard({
                  required double availableHeight,
                  required double availableWidth,
                }) {
                  final compactContent = availableHeight < 575;
                  final contentScale = (availableHeight / 620).clamp(0.82, 1.0);
                  final heroSize = (metrics.authHeroSize * contentScale).clamp(
                    104.0,
                    metrics.authHeroSize,
                  );
                  final heroGap =
                      (metrics.authResolvedHeroCardGap(
                        keyboardVisible: false,
                      ) *
                              contentScale)
                          .clamp(8.0, 18.0);
                  final resolvedCardPadding = EdgeInsets.fromLTRB(
                    cardPadding.left,
                    (cardPadding.top * (compactContent ? contentScale : 1.0)).clamp(
                      14.0,
                      cardPadding.top,
                    ),
                    cardPadding.right,
                    (cardPadding.bottom *
                            (compactContent
                                ? (contentScale - 0.04).clamp(0.82, 1.0)
                                : 1.0))
                        .clamp(14.0, cardPadding.bottom),
                  );
                  final resolvedIntroGap =
                      (introGap * contentScale).clamp(4.0, introGap);
                  final resolvedFieldGap = (metrics.authFieldGap * contentScale)
                      .clamp(10.0, metrics.authFieldGap);
                  final resolvedHelperGap =
                      (helperGap * contentScale).clamp(8.0, helperGap);
                  final resolvedEmptyErrorGap =
                      (emptyErrorGap * contentScale).clamp(10.0, emptyErrorGap);
                  final resolvedSubmitGap =
                      (submitGap * contentScale).clamp(12.0, submitGap);
                  final resolvedNoteTopGap =
                      (8 * contentScale).clamp(4.0, 8.0);
                  final buttonHeight = ((metrics.primaryButtonHeight + 4) *
                          contentScale)
                      .clamp(44.0, metrics.primaryButtonHeight + 4);
                  final titleFontSize =
                      (24 * contentScale).clamp(20.0, 24.0);
                  final bodyFontSize =
                      (14 * contentScale).clamp(12.0, 14.0);
                  final noteFontSize =
                      (12 * contentScale).clamp(11.0, 12.0);

                  return Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: availableWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LogoHero(
                              width: heroSize,
                              height: heroSize,
                            ),
                            SizedBox(height: heroGap),
                            Container(
                              padding: resolvedCardPadding,
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
                                  Text(
                                    'Request New Token',
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                      color: _headlineColor,
                                    ),
                                  ),
                                  SizedBox(height: resolvedIntroGap),
                                  Text(
                                    'กรอก Gmail และชื่ออุปกรณ์ (Device ID) ของคุณ เพื่อรับรหัสเข้าใช้งาน (Access Token) ใหม่ทางอีเมลครับ',
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      height: compactContent ? 1.38 : 1.45,
                                      color: const Color(0xFF5D6E80),
                                    ),
                                  ),
                                  SizedBox(height: resolvedFieldGap),
                                  _FieldBlock(
                                    label: 'Gmail Address',
                                    child: _RequestTextField(
                                      controller: _gmailController,
                                      hintText: 'ตัวอย่าง: example@gmail.com',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      keyboardAppearance: Brightness.light,
                                      hasError: _errorText != null,
                                      decorationBuilder: _inputDecoration,
                                      onChanged: (_) {
                                        if (_errorText != null) {
                                          setState(() {
                                            _errorText = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(height: resolvedFieldGap),
                                  _FieldBlock(
                                    label: 'Device ID',
                                    child: _RequestTextField(
                                      controller: _deviceIdController,
                                      hintText: 'ตัวอย่าง: PrinceBot',
                                      textInputAction: TextInputAction.done,
                                      keyboardAppearance: Brightness.light,
                                      hasError: _errorText != null,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                        color: _fieldTextColor,
                                        fontFamily: 'monospace',
                                      ),
                                      decorationBuilder: _inputDecoration,
                                      onSubmitted: (_) => _onCreateTokenPressed(),
                                      onChanged: (_) {
                                        if (_errorText != null) {
                                          setState(() {
                                            _errorText = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(height: resolvedNoteTopGap),
                                  Text(
                                    'ตั้งชื่ออุปกรณ์ (Device ID) เพื่อช่วยให้จำได้ว่ากำลังใช้ Token ไหนอยู่ และชื่อนี้จะถูกใช้เป็นชื่อโปรไฟล์ของคุณด้วย',
                                    style: TextStyle(
                                      fontSize: noteFontSize,
                                      height: compactContent ? 1.32 : 1.4,
                                      color: const Color(0xFF748293),
                                    ),
                                  ),
                                  SizedBox(height: resolvedHelperGap),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: _errorText == null
                                        ? SizedBox(height: resolvedEmptyErrorGap)
                                        : Container(
                                            key: ValueKey<String>(_errorText!),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF2F2),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFF2C8C8),
                                              ),
                                            ),
                                            child: Text(
                                              _errorText!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.35,
                                                color: Color(0xFFB24A4A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                  ),
                                  SizedBox(height: resolvedSubmitGap),
                                  _PrimaryActionButton(
                                    height: buttonHeight,
                                    isLoading: _isLoading,
                                    label: 'Create Token & Send to Gmail',
                                    onPressed: _isLoading
                                        ? null
                                        : _onCreateTokenPressed,
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

                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: metrics.authResolvedTopSpacing(
                        keyboardVisible: false,
                      ),
                    ),
                    Row(
                      children: [
                        _TopBarButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    buildRequestCard(
                      availableHeight: constraints.maxHeight,
                      availableWidth: constraints.maxWidth,
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
                    22 + keyboardInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
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

class _RequestTokenBackground extends StatelessWidget {
  const _RequestTokenBackground();

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
            top: 90,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFFBCD7C7).withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            right: -76,
            top: 28,
            child: _GlowOrb(
              size: 236,
              color: const Color(0xFFD7E5EF).withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            right: -48,
            bottom: 110,
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
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
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
        color: _RequestTokenScreenState._cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: _RequestTokenScreenState._shadowLightColor,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: _RequestTokenScreenState._shadowDarkColor,
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

class _LogoHero extends StatelessWidget {
  const _LogoHero({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _RequestTokenScreenState._cardHighlightColor,
              _RequestTokenScreenState._cardColor,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: _RequestTokenScreenState._shadowLightColor,
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: _RequestTokenScreenState._shadowDarkColor,
              offset: Offset(8, 10),
              blurRadius: 18,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: width * 0.42,
                height: height * 0.42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE6F0EA),
                  boxShadow: const [
                    BoxShadow(
                      color: _RequestTokenScreenState._shadowLightColor,
                      offset: Offset(-3, -3),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: _RequestTokenScreenState._shadowDarkColor,
                      offset: Offset(4, 5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 32,
                  color: Color(0xFF5A9676),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'REQUEST TOKEN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Color(0xFF84A291),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _RequestTokenScreenState._labelTextColor,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _RequestTextField extends StatefulWidget {
  const _RequestTextField({
    required this.controller,
    required this.hintText,
    required this.decorationBuilder,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.style,
    this.hasError = false,
    this.keyboardAppearance,
  });

  final TextEditingController controller;
  final String hintText;
  final InputDecoration Function({
    required String hintText,
    required bool isFocused,
    bool hasError,
  }) decorationBuilder;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final bool hasError;
  final Brightness? keyboardAppearance;

  @override
  State<_RequestTextField> createState() => _RequestTextFieldState();
}

class _RequestTextFieldState extends State<_RequestTextField> {
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
        borderRadius: BorderRadius.circular(_RequestTokenScreenState._fieldRadius),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? _RequestTokenScreenState._buttonGlowColor.withValues(alpha: 0.18)
                : _RequestTokenScreenState._shadowLightColor,
            offset: const Offset(-4, -4),
            blurRadius: isFocused ? 12 : 8,
          ),
          BoxShadow(
            color: isFocused
                ? _RequestTokenScreenState._buttonGlowColor.withValues(alpha: 0.10)
                : _RequestTokenScreenState._shadowDarkColor,
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
        keyboardAppearance: widget.keyboardAppearance,
        autocorrect: false,
        maxLines: 1,
        style: widget.style ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.15,
              color: _RequestTokenScreenState._fieldTextColor,
            ),
        cursorColor: _RequestTokenScreenState._surfaceBorderFocusColor,
        decoration: widget.decorationBuilder(
          hintText: widget.hintText,
          isFocused: isFocused,
          hasError: widget.hasError,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
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
        borderRadius: BorderRadius.circular(_RequestTokenScreenState._buttonRadius),
        boxShadow: [
          BoxShadow(
            color: _RequestTokenScreenState._buttonGlowColor.withValues(
              alpha: disabled ? 0.05 : 0.16,
            ),
            blurRadius: disabled ? 12 : 22,
          ),
          const BoxShadow(
            color: _RequestTokenScreenState._shadowLightColor,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: _RequestTokenScreenState._shadowDarkColor,
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
                _RequestTokenScreenState._buttonRadius,
              ),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _RequestTokenScreenState._buttonRadius,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _RequestTokenScreenState._buttonStartColor.withValues(
                    alpha: disabled ? 0.76 : 1,
                  ),
                  _RequestTokenScreenState._buttonEndColor.withValues(
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        key: const ValueKey('label'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
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
