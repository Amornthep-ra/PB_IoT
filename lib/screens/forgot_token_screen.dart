import 'package:flutter/material.dart';

import '../services/token_request_service.dart';
import '../theme/app_responsive.dart';

class ForgotTokenScreen extends StatefulWidget {
  const ForgotTokenScreen({super.key});

  @override
  State<ForgotTokenScreen> createState() => _ForgotTokenScreenState();
}

class _ForgotTokenScreenState extends State<ForgotTokenScreen> {
  final TextEditingController _gmailController = TextEditingController();
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
    super.dispose();
  }

  Future<void> _onSendTokenPressed() async {
    FocusScope.of(context).unfocus();

    final gmail = _gmailController.text.trim();

    if (gmail.isEmpty) {
      setState(() {
        _errorText = 'กรุณากรอกที่อยู่ Gmail ของคุณ';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _tokenRequestService.forgotToken(gmail: gmail);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งคำขอโทเค็นใหม่เรียบร้อยแล้ว โปรดตรวจสอบที่ Gmail ของคุณ'),
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
        _errorText = 'ส่งโทเค็นใหม่ไม่สำเร็จ โปรดลองใหม่อีกครั้ง';
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

  Widget _buildForgotCardContent({
    required double titleFontSize,
    required double bodyFontSize,
    required bool compactContent,
    required double resolvedIntroGap,
    required double resolvedFieldGap,
    required double resolvedHelperGap,
    required double resolvedEmptyErrorGap,
    required double resolvedSubmitGap,
    required double buttonHeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Forgot Token',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: _headlineColor,
          ),
        ),
        SizedBox(height: resolvedIntroGap),
        Text(
          'กรอกที่อยู่อีเมลล์ของคุณ แล้วเราจะส่ง Token ใหม่ไปยังกล่องจดหมายของคุณ',
          style: TextStyle(
            fontSize: bodyFontSize,
            height: compactContent ? 1.38 : 1.45,
            color: const Color(0xFF5D6E80),
          ),
        ),
        SizedBox(height: resolvedFieldGap),
        _FieldBlock(
          label: 'Gmail Address',
          child: _ForgotTextField(
            controller: _gmailController,
            hintText: 'กรอกที่อยู่อีเมลล์ของคุณ',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            keyboardAppearance: Brightness.light,
            hasError: _errorText != null,
            decorationBuilder: _inputDecoration,
            onSubmitted: (_) => _onSendTokenPressed(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
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
          label: 'Send New Token',
          onPressed: _isLoading ? null : _onSendTokenPressed,
        ),
      ],
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
          const Positioned.fill(child: _ForgotTokenBackground()),
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
                final fieldTopGap = isShortHeight ? 18.0 : 22.0;
                final helperGap = isShortHeight ? 10.0 : 14.0;
                final errorGap = isShortHeight ? 14.0 : 18.0;
                final submitGap = isShortHeight ? 16.0 : 18.0;
                final emptyErrorGap = isShortHeight ? 14.0 : 18.0;
                Widget buildForgotCard({
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
                    (cardPadding.top * (compactContent ? contentScale : 1.0))
                        .clamp(14.0, cardPadding.top),
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
                      (helperGap * contentScale).clamp(2.0, 8.0);
                  final resolvedEmptyErrorGap =
                      (emptyErrorGap * contentScale).clamp(2.0, 8.0);
                  final resolvedSubmitGap =
                      (submitGap * contentScale).clamp(6.0, 12.0);
                  final buttonHeight = ((metrics.primaryButtonHeight + 4) *
                          contentScale)
                      .clamp(44.0, metrics.primaryButtonHeight + 4);
                  final titleFontSize =
                      (24 * contentScale).clamp(20.0, 24.0);
                  final bodyFontSize =
                      (15 * contentScale).clamp(13.0, 15.0);

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
                              child: _buildForgotCardContent(
                                titleFontSize: titleFontSize,
                                bodyFontSize: bodyFontSize,
                                compactContent: compactContent,
                                resolvedIntroGap: resolvedIntroGap,
                                resolvedFieldGap: resolvedFieldGap,
                                resolvedHelperGap: resolvedHelperGap,
                                resolvedEmptyErrorGap: resolvedEmptyErrorGap,
                                resolvedSubmitGap: resolvedSubmitGap,
                                buttonHeight: buttonHeight,
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
                    if (constraints.maxHeight > 0) ...[
                      buildForgotCard(
                        availableHeight: constraints.maxHeight,
                        availableWidth: constraints.maxWidth,
                      ),
                    ] else ...[
                      _LogoHero(
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
                          const Text(
                            'Forgot Token',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: _headlineColor,
                            ),
                          ),
                          SizedBox(height: introGap),
                          const Text(
                            'กรอกที่อยู่อีเมลล์ของคุณ แล้วเราจะส่ง Token ใหม่ไปยังกล่องจดหมายของคุณ',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: Color(0xFF5D6E80),
                            ),
                          ),
                          SizedBox(height: fieldTopGap),
                          _FieldBlock(
                            label: 'Gmail Address',
                            child: _ForgotTextField(
                              controller: _gmailController,
                              hintText: 'กรอกที่อยู่อีเมลล์ของคุณ',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              keyboardAppearance: Brightness.light,
                              hasError: _errorText != null,
                              decorationBuilder: _inputDecoration,
                              onSubmitted: (_) => _onSendTokenPressed(),
                              onChanged: (_) {
                                if (_errorText != null) {
                                  setState(() {
                                    _errorText = null;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(height: errorGap),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _errorText == null
                                ? SizedBox(height: errorGap)
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
                          SizedBox(height: submitGap),
                          _PrimaryActionButton(
                            height: metrics.primaryButtonHeight + 4,
                            isLoading: _isLoading,
                            label: 'Send New Token',
                            onPressed: _isLoading ? null : _onSendTokenPressed,
                          ),
                        ],
                      ),
                    ),
                    ],
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

class _ForgotTokenBackground extends StatelessWidget {
  const _ForgotTokenBackground();

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
            left: -64,
            top: 92,
            child: _GlowOrb(
              size: 216,
              color: const Color(0xFFBCD7C7).withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            right: -74,
            top: 24,
            child: _GlowOrb(
              size: 232,
              color: const Color(0xFFD7E5EF).withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            right: -42,
            bottom: 108,
            child: _GlowOrb(
              size: 176,
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
        color: _ForgotTokenScreenState._cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: _ForgotTokenScreenState._shadowLightColor,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: _ForgotTokenScreenState._shadowDarkColor,
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
              _ForgotTokenScreenState._cardHighlightColor,
              _ForgotTokenScreenState._cardColor,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: _ForgotTokenScreenState._shadowLightColor,
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: _ForgotTokenScreenState._shadowDarkColor,
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
                      color: _ForgotTokenScreenState._shadowLightColor,
                      offset: Offset(-3, -3),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: _ForgotTokenScreenState._shadowDarkColor,
                      offset: Offset(4, 5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_reset_outlined,
                  size: 32,
                  color: Color(0xFF5A9676),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'FORGOT TOKEN',
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _ForgotTokenScreenState._labelTextColor,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ForgotTextField extends StatefulWidget {
  const _ForgotTextField({
    required this.controller,
    required this.hintText,
    required this.decorationBuilder,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
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
  final bool hasError;
  final Brightness? keyboardAppearance;

  @override
  State<_ForgotTextField> createState() => _ForgotTextFieldState();
}

class _ForgotTextFieldState extends State<_ForgotTextField> {
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
        borderRadius: BorderRadius.circular(_ForgotTokenScreenState._fieldRadius),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? _ForgotTokenScreenState._buttonGlowColor.withValues(alpha: 0.18)
                : _ForgotTokenScreenState._shadowLightColor,
            offset: const Offset(-4, -4),
            blurRadius: isFocused ? 12 : 8,
          ),
          BoxShadow(
            color: isFocused
                ? _ForgotTokenScreenState._buttonGlowColor.withValues(alpha: 0.10)
                : _ForgotTokenScreenState._shadowDarkColor,
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.15,
          color: _ForgotTokenScreenState._fieldTextColor,
        ),
        cursorColor: _ForgotTokenScreenState._surfaceBorderFocusColor,
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
        borderRadius: BorderRadius.circular(_ForgotTokenScreenState._buttonRadius),
        boxShadow: [
          BoxShadow(
            color: _ForgotTokenScreenState._buttonGlowColor.withValues(
              alpha: disabled ? 0.05 : 0.16,
            ),
            blurRadius: disabled ? 12 : 22,
          ),
          const BoxShadow(
            color: _ForgotTokenScreenState._shadowLightColor,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: _ForgotTokenScreenState._shadowDarkColor,
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
                _ForgotTokenScreenState._buttonRadius,
              ),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _ForgotTokenScreenState._buttonRadius,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _ForgotTokenScreenState._buttonStartColor.withValues(
                    alpha: disabled ? 0.76 : 1,
                  ),
                  _ForgotTokenScreenState._buttonEndColor.withValues(
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
