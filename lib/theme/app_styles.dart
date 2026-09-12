import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 18.0;
  static const double radiusExtraLarge = 24.0;

  static final BorderRadius cardBorderRadius = BorderRadius.circular(radiusMedium);
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(radiusMedium);
  static final BorderRadius pillBorderRadius = BorderRadius.circular(30.0);

  // Box Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevatedCardShadow = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> primaryButtonShadow = [
    BoxShadow(
      color: Color(0x3D1E5BF8),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  // Header Gradient Decoration
  static const BoxDecoration headerGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.headerGradientStart,
        AppColors.headerGradientEnd,
      ],
    ),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(24.0),
      bottomRight: Radius.circular(24.0),
    ),
  );

  // Standard Card Decoration
  static BoxDecoration cardDecoration({
    Color? color,
    Border? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardSurface,
      borderRadius: borderRadius ?? cardBorderRadius,
      border: border ?? Border.all(color: AppColors.borderLight, width: 1.0),
      boxShadow: boxShadow ?? cardShadow,
    );
  }
}
