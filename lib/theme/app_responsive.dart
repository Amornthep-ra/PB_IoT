import 'package:flutter/material.dart';

enum AppWidthClass { compact, regular, large }

class AppResponsiveMetrics {
  const AppResponsiveMetrics({
    required this.widthClass,
    required this.isCompactHeight,
    required this.screenPadding,
    required this.topSpacing,
    required this.headerGap,
    required this.sectionGap,
    required this.logoutTopGap,
    required this.bottomSafeGap,
    required this.primaryButtonHeight,
    required this.heroCardRadius,
    required this.sectionCardRadius,
    required this.heroCardPadding,
    required this.sectionCardPadding,
    required this.heroAvatarSize,
    required this.heroAvatarIconSize,
    required this.iconTileSize,
    required this.iconTileRadius,
    required this.infoRowVerticalPadding,
    required this.menuRowVerticalPadding,
    required this.authCardRadius,
    required this.authFieldGap,
    required this.authHeroSize,
    required this.authTopSpacing,
    required this.authKeyboardTopSpacing,
    required this.authHeroCardGap,
    required this.authKeyboardHeroCardGap,
  });

  final AppWidthClass widthClass;
  final bool isCompactHeight;
  final double screenPadding;
  final double topSpacing;
  final double headerGap;
  final double sectionGap;
  final double logoutTopGap;
  final double bottomSafeGap;
  final double primaryButtonHeight;
  final double heroCardRadius;
  final double sectionCardRadius;
  final EdgeInsets heroCardPadding;
  final EdgeInsets sectionCardPadding;
  final double heroAvatarSize;
  final double heroAvatarIconSize;
  final double iconTileSize;
  final double iconTileRadius;
  final double infoRowVerticalPadding;
  final double menuRowVerticalPadding;
  final double authCardRadius;
  final double authFieldGap;
  final double authHeroSize;
  final double authTopSpacing;
  final double authKeyboardTopSpacing;
  final double authHeroCardGap;
  final double authKeyboardHeroCardGap;

  bool get isCompactWidth => widthClass == AppWidthClass.compact;

  double authResolvedTopSpacing({required bool keyboardVisible}) {
    return keyboardVisible ? authKeyboardTopSpacing : authTopSpacing;
  }

  double authResolvedHeroCardGap({required bool keyboardVisible}) {
    return keyboardVisible ? authKeyboardHeroCardGap : authHeroCardGap;
  }

  static AppResponsiveMetrics resolve({
    required double width,
    required double height,
    required double bottomSafeInset,
  }) {
    final widthClass = width < 360
        ? AppWidthClass.compact
        : width < 430
        ? AppWidthClass.regular
        : AppWidthClass.large;
    final isCompactHeight = height < 840;

    final screenPadding = switch (widthClass) {
      AppWidthClass.compact => 18.0,
      AppWidthClass.regular => 24.0,
      AppWidthClass.large => 28.0,
    };

    final topSpacing = isCompactHeight
        ? (height * 0.018).clamp(8.0, 16.0)
        : (height * 0.035).clamp(14.0, 28.0);
    final headerGap = isCompactHeight ? 10.0 : 18.0;
    final sectionGap = isCompactHeight
        ? (widthClass == AppWidthClass.compact ? 8.0 : 10.0)
        : (widthClass == AppWidthClass.compact ? 14.0 : 16.0);
    final logoutTopGap = isCompactHeight
        ? (height * 0.016).clamp(8.0, 14.0)
        : (height * 0.045).clamp(18.0, 34.0);
    final bottomSafeGap = isCompactHeight
        ? (bottomSafeInset + 10).clamp(12.0, 20.0)
        : (bottomSafeInset + 18).clamp(22.0, 40.0);

    return AppResponsiveMetrics(
      widthClass: widthClass,
      isCompactHeight: isCompactHeight,
      screenPadding: screenPadding,
      topSpacing: topSpacing,
      headerGap: headerGap,
      sectionGap: sectionGap,
      logoutTopGap: logoutTopGap,
      bottomSafeGap: bottomSafeGap,
      primaryButtonHeight: isCompactHeight
          ? (widthClass == AppWidthClass.compact ? 48.0 : 50.0)
          : (widthClass == AppWidthClass.compact ? 50.0 : 52.0),
      heroCardRadius: isCompactHeight ? 24.0 : 26.0,
      sectionCardRadius: isCompactHeight ? 20.0 : 22.0,
      heroCardPadding: EdgeInsets.all(isCompactHeight ? 14.0 : 18.0),
      sectionCardPadding: EdgeInsets.fromLTRB(
        isCompactHeight ? 12.0 : 16.0,
        isCompactHeight ? 12.0 : 16.0,
        isCompactHeight ? 12.0 : 16.0,
        isCompactHeight ? 2.0 : 6.0,
      ),
      heroAvatarSize: isCompactHeight ? 128.0 : 144.0,
      heroAvatarIconSize: isCompactHeight ? 56.0 : 64.0,
      iconTileSize: isCompactHeight ? 30.0 : 34.0,
      iconTileRadius: isCompactHeight ? 8.0 : 10.0,
      infoRowVerticalPadding: isCompactHeight ? 6.0 : 10.0,
      menuRowVerticalPadding: isCompactHeight ? 6.0 : 10.0,
      authCardRadius: widthClass == AppWidthClass.compact ? 24.0 : 26.0,
      authFieldGap: isCompactHeight
          ? (widthClass == AppWidthClass.compact ? 16.0 : 18.0)
          : (widthClass == AppWidthClass.compact ? 18.0 : 20.0),
      authHeroSize: isCompactHeight
          ? (widthClass == AppWidthClass.compact ? 124.0 : 136.0)
          : (widthClass == AppWidthClass.compact ? 142.0 : 158.0),
      authTopSpacing: isCompactHeight
          ? (height * 0.05).clamp(18.0, 30.0)
          : (height * 0.095).clamp(28.0, 72.0),
      authKeyboardTopSpacing: (height * 0.02).clamp(10.0, 18.0),
      authHeroCardGap: isCompactHeight
          ? (height * 0.02).clamp(12.0, 18.0)
          : (height * 0.03).clamp(16.0, 24.0),
      authKeyboardHeroCardGap: 10.0,
    );
  }
}
