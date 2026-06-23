part of '../dashboard_builder_screen.dart';

class _BuilderInfoRow extends StatelessWidget {
  const _BuilderInfoRow({
    required this.label,
    required this.value,
    required this.themePreset,
  });

  final String label;
  final String value;
  final DashboardThemePreset themePreset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themePreset.bodyColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: themePreset.mutedTextColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
