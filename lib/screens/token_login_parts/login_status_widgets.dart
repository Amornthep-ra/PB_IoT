part of '../token_login_screen.dart';

class _LoginErrorBox extends StatelessWidget {
  const _LoginErrorBox({super.key, required this.error});

  static const infoAccentColor = Color(0xFF2F80A8);
  static const infoBackgroundColor = Color(0xFFEFF7FC);
  static const infoIconBackgroundColor = Color(0xFFDDF0FA);
  static const infoBorderColor = Color(0xFFBFDDEB);
  static const infoMessageColor = Color(0xFF42697B);

  final _LoginError error;

  @override
  Widget build(BuildContext context) {
    final isNotice = error == _LoginError.sessionExpired;
    final accentColor = isNotice ? infoAccentColor : const Color(0xFFB24A4A);
    final backgroundColor = isNotice
        ? infoBackgroundColor
        : const Color(0xFFFFF2F2);
    final iconBackgroundColor = isNotice
        ? infoIconBackgroundColor
        : const Color(0xFFFFE2E2);
    final borderColor = isNotice ? infoBorderColor : const Color(0xFFF2C8C8);
    final messageColor = isNotice ? infoMessageColor : const Color(0xFF8F4A4A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(error.icon, size: 18, color: accentColor),
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
                    fontWeight: FontWeight.w700,
                  ).copyWith(color: accentColor),
                ),
                const SizedBox(height: 2),
                Text(
                  error.message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ).copyWith(color: messageColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
