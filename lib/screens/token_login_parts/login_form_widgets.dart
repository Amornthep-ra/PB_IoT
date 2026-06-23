part of '../token_login_screen.dart';

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.cardPadding,
    required this.cardRadius,
    required this.fieldGap,
    required this.errorGapHeight,
    required this.buttonTopGap,
    required this.buttonHeight,
    required this.tokenController,
    required this.displayNameController,
    required this.loginError,
    required this.hasFieldError,
    required this.rememberMe,
    required this.obscureToken,
    required this.isLoading,
    required this.decorationBuilder,
    required this.onTokenChanged,
    required this.onToggleTokenVisibility,
    required this.onDisplayNameSubmitted,
    required this.onRememberChanged,
    required this.onLoginPressed,
  });

  final EdgeInsetsGeometry cardPadding;
  final double cardRadius;
  final double fieldGap;
  final double errorGapHeight;
  final double buttonTopGap;
  final double buttonHeight;
  final TextEditingController tokenController;
  final TextEditingController displayNameController;
  final _LoginError? loginError;
  final bool hasFieldError;
  final bool rememberMe;
  final bool obscureToken;
  final bool isLoading;
  final InputDecoration Function({
    required String hintText,
    required bool isFocused,
    bool hasError,
    Widget? suffixIcon,
  })
  decorationBuilder;
  final ValueChanged<String> onTokenChanged;
  final VoidCallback onToggleTokenVisibility;
  final ValueChanged<String> onDisplayNameSubmitted;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback? onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: _TokenLoginScreenState._cardColor,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: const Color(0xFFE4EBF3), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: _TokenLoginScreenState._shadowLightColor,
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: _TokenLoginScreenState._shadowDarkColor,
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
            label: 'โทเค็นเข้าใช้งาน',
            child: _LoginTextField(
              controller: tokenController,
              hintText: 'กรุณากรอกโทเค็นแอปของคุณ',
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              onChanged: onTokenChanged,
              decorationBuilder: decorationBuilder,
              hasError: hasFieldError,
              isObscured: obscureToken,
              isSensitive: true,
              keyboardAppearance: Brightness.light,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: _TokenLoginScreenState._fieldTextColor,
                fontFamily: 'monospace',
              ),
              suffixIconBuilder:
                  ({required bool isFocused, required bool hasError}) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FieldIconButton(
                          icon: obscureToken
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          tooltip: obscureToken ? 'แสดงโทเค็น' : 'ซ่อนโทเค็น',
                          onTap: onToggleTokenVisibility,
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  },
            ),
          ),
          SizedBox(height: fieldGap),
          _FieldBlock(
            label: 'ชื่อโปรไฟล์',
            child: _LoginTextField(
              controller: displayNameController,
              hintText: 'กรอกชื่อที่ต้องการให้เป็นชื่อโปรไฟล์',
              textInputAction: TextInputAction.done,
              onSubmitted: onDisplayNameSubmitted,
              decorationBuilder: decorationBuilder,
              keyboardAppearance: Brightness.light,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loginError == null
                ? SizedBox(height: errorGapHeight)
                : _LoginErrorBox(
                    key: ValueKey<String>(loginError!.title),
                    error: loginError!,
                  ),
          ),
          const SizedBox(height: 8),
          _RememberMeRow(value: rememberMe, onChanged: onRememberChanged),
          SizedBox(height: buttonTopGap),
          _GlowLoginButton(
            height: buttonHeight,
            isLoading: isLoading,
            onPressed: onLoginPressed,
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF83C8D4).withValues(alpha: 0.20),
              blurRadius: 26,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF7FC39C).withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: 1,
            ),
            const BoxShadow(color: Color(0x180F172A), blurRadius: 18),
            const BoxShadow(color: Color(0xEFFFFFFF), blurRadius: 10),
          ],
        ),
        child: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              'assets/icons/logo/Princebot_IoT_V2C.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
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
    this.isSensitive = false,
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
  final bool isSensitive;
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
        autocorrect: !widget.isSensitive,
        enableSuggestions: !widget.isSensitive,
        enableIMEPersonalizedLearning: !widget.isSensitive,
        smartDashesType: widget.isSensitive
            ? SmartDashesType.disabled
            : SmartDashesType.enabled,
        smartQuotesType: widget.isSensitive
            ? SmartQuotesType.disabled
            : SmartQuotesType.enabled,
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
    return Semantics(
      label: 'จดจำโทเค็นบนอุปกรณ์นี้',
      toggled: value,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      alignment: value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
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
                      'จดจำโทเค็นบนอุปกรณ์นี้',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF536170),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 60, top: 3),
                child: Text(
                  'เก็บโทเค็นอย่างปลอดภัยบนอุปกรณ์นี้',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6E7C8B),
                  ),
                ),
              ),
            ],
          ),
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
                        'เข้าสู่ระบบ',
                        key: ValueKey('label'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
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

class _LoginFooterLinks extends StatelessWidget {
  const _LoginFooterLinks({
    required this.onTokenRequestTap,
    required this.onPrivacyPolicyTap,
    required this.onDeleteAccountTap,
  });

  final VoidCallback onTokenRequestTap;
  final VoidCallback onPrivacyPolicyTap;
  final VoidCallback onDeleteAccountTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: onTokenRequestTap,
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('ขอโทเค็น / ลืมโทเค็น? คลิกที่นี่'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4E9070),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 2,
          children: [
            TextButton(
              onPressed: onPrivacyPolicyTap,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF667587),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('นโยบายความเป็นส่วนตัว'),
            ),
            TextButton(
              onPressed: onDeleteAccountTap,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA94E4A),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('ลบบัญชี'),
            ),
          ],
        ),
      ],
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
