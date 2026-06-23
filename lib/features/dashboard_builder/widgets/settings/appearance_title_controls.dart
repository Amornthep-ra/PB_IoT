part of '../widget_settings_sheet.dart';

extension _WidgetSettingsAppearanceTitleControls on _WidgetSettingsSheetState {
  Widget _buildTitleSection({
    required bool includeStyle,
    required bool includeTitleField,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeTitleField) ...[
          const _SettingsLabel('ชื่อวิดเจ็ต'),
          const SizedBox(height: 8),
          _buildFieldShell(
            focused: _titleFocusNode.hasFocus,
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              maxLines: 1,
              style: const TextStyle(
                color: DashboardRuntimeTheme.fieldTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration:
                  _fieldDecoration(
                    hint: 'ตั้งชื่อวิดเจ็ตของคุณ',
                    prefixIcon: Icons.title_rounded,
                  ).copyWith(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 18,
                    ),
                  ),
            ),
          ),
        ],
        if (includeStyle) ...[
          const SizedBox(height: 12),
          _buildColorStyleSection(),
          const SizedBox(height: 12),
          _buildBorderWidthSection(),
          const SizedBox(height: 12),
          _buildGlowSection(),
        ],
      ],
    );

    if (!includeStyle) {
      return content;
    }

    return DecoratedBox(
      decoration: _glassSheetDecoration(
        radius: 18,
        opacity: 0.74,
        elevated: false,
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: content),
    );
  }
}
