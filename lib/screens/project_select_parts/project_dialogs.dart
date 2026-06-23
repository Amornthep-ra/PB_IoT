part of '../project_select_screen.dart';

class _ProjectDialogResult {
  const _ProjectDialogResult({required this.name, required this.iconKey});

  final String name;
  final String iconKey;
}

class _DeleteProjectDialog extends StatelessWidget {
  const _DeleteProjectDialog({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: AppGlassTheme.surfaceDecoration(
              radius: 22,
              borderAlpha: 0.60,
              colors: <Color>[
                const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                const Color(0xFFFFF4F5).withValues(alpha: 0.54),
              ],
              shadows: AppGlassTheme.shadowMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFFFE2E5),
                        border: Border.all(color: const Color(0xFFF5B7BE)),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: _dangerColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'ลบโปรเจกต์',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _headlineColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'ลบ "${project.name}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.32,
                    fontWeight: FontWeight.w700,
                    color: _headlineColor,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'เมื่อลบแล้วจะไม่สามารถเรียกคืนข้อมูลได้',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: _mutedTextColor,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ProjectActionButton(
                        label: 'ยกเลิก',
                        isSecondary: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProjectActionButton(
                        label: 'ลบ',
                        isDanger: true,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectNameDialog extends StatefulWidget {
  const _ProjectNameDialog({this.project});

  final ProjectModel? project;

  @override
  State<_ProjectNameDialog> createState() => _ProjectNameDialogState();
}

class _ProjectNameDialogState extends State<_ProjectNameDialog> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _selectedIconKey;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _controller.text = project?.name ?? '';
    _selectedIconKey = project?.iconKey ?? ProjectModel.defaultIconKey;
    if (!_projectIconKeys.contains(_selectedIconKey)) {
      _selectedIconKey = ProjectModel.defaultIconKey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(
      _ProjectDialogResult(
        name: _controller.text.trim(),
        iconKey: _selectedIconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final isTablet = AppResponsiveLayout.isTabletWidth(mediaQuery.size.width);
    final maxDialogHeight = (mediaQuery.size.height - keyboardInset - 72).clamp(
      220.0,
      mediaQuery.size.height * (keyboardInset > 0 ? 0.64 : 0.82),
    );
    final maxDialogWidth = isTablet
        ? AppResponsiveLayout.tabletContentMaxWidth
        : double.infinity;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxDialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  key: const ValueKey('project_name_dialog_surface'),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: AppGlassTheme.surfaceDecoration(
                    radius: 22,
                    borderAlpha: 0.60,
                    colors: <Color>[
                      const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                      const Color(0xFFF4FBF7).withValues(alpha: 0.52),
                    ],
                    shadows: AppGlassTheme.shadowMd,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isEditing ? 'แก้ไขโปรเจกต์' : 'สร้างโปรเจกต์',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _headlineColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'ไอคอนโปรเจกต์',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _labelTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: isTablet
                                ? WrapAlignment.start
                                : WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final iconKey in _projectIconKeys)
                                _ProjectIconChoice(
                                  icon: _projectIconData(iconKey),
                                  colors: _projectIconColors(iconKey),
                                  isSelected: iconKey == _selectedIconKey,
                                  onTap: () {
                                    setState(() {
                                      _selectedIconKey = iconKey;
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'ชื่อโปรเจกต์',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _labelTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _controller,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _headlineColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ตัวอย่าง: PB IoT',
                              hintStyle: const TextStyle(
                                color: _mutedTextColor,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.72),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'กรุณาใส่ชื่อโปรเจกต์';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ProjectActionButton(
                                  label: 'ยกเลิก',
                                  isSecondary: true,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ProjectActionButton(
                                  label: _isEditing ? 'บันทึก' : 'สร้าง',
                                  onPressed: _submit,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _ProjectIconChoice extends StatelessWidget {
  const _ProjectIconChoice({
    required this.icon,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> colors;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: isSelected
                ? AppGlassTheme.accentDecoration(
                    radius: 15,
                    colors: colors,
                    borderColor: Colors.white,
                    glowColor: colors.last,
                  )
                : AppGlassTheme.surfaceDecoration(
                    radius: 15,
                    borderAlpha: 0.72,
                    colors: <Color>[
                      const Color(0xFFFFFFFF).withValues(alpha: 0.70),
                      const Color(0xFFF6FBFF).withValues(alpha: 0.42),
                    ],
                    shadows: const <BoxShadow>[],
                  ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : colors.last,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
