part of '../project_select_screen.dart';

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState({
    required this.errorText,
    required this.isBusy,
    required this.onCreateProject,
  });

  final String? errorText;
  final bool isBusy;
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: AppGlassTheme.surfaceDecoration(
            radius: 24,
            borderAlpha: 0.62,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.74),
              const Color(0xFFF4FBF7).withValues(alpha: 0.46),
            ],
            shadows: AppGlassTheme.shadowMd,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.add_business_rounded,
                color: _buttonEndColor,
                size: 54,
              ),
              const SizedBox(height: 16),
              const Text(
                'สร้างโปรเจกต์แรกของคุณ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _headlineColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'แยกแดชบอร์ดของแต่ละพื้นที่ทำงานให้เป็นระเบียบ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: _mutedTextColor,
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 16),
                _ProjectErrorBanner(message: errorText!),
              ],
              const SizedBox(height: 22),
              _ProjectActionButton(
                label: isBusy ? 'กำลังสร้าง...' : 'สร้างโปรเจกต์',
                onPressed: isBusy ? null : onCreateProject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
