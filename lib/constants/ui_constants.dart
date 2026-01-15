import 'package:flutter/material.dart';

/// UI 전역 상수 정의
class UIConstants {
  // 간격
  static const double spacing4 = 4.0;
  static const double spacing5 = 5.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;

  // 탭
  static const double tabWidth = 65.0;
  static const double tabBarHeight = 40.0;

  // 아이콘 크기
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 18.0;
  static const double iconSizeLarge = 20.0;
  static const double iconSizeXLarge = 24.0;
  static const double helpIconSize = 16.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 10.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusXXLarge = 20.0;

  // Opacity
  static const double opacityLow = 0.2;
  static const double opacityMedium = 0.3;
  static const double opacityHigh = 0.5;
  static const double opacitySemiTransparent = 0.7;

  // Padding
  static const EdgeInsets paddingSmall = EdgeInsets.all(4.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(8.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(16.0);

  static const EdgeInsets textFieldPaddingSmall =
      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
  static const EdgeInsets textFieldPaddingLarge =
      EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0);

  static const EdgeInsets containerPadding =
      EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0);

  // Private constructor to prevent instantiation
  UIConstants._();
}
