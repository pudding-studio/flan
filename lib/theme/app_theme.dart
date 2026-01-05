import 'package:flutter/material.dart';
import 'custom_indicator_shape.dart';

class AppTheme {
  static const Color seedColor = Color.fromARGB(255, 255, 191, 63);

  // Navigation Bar 설정값
  static const double navBarHeight = 44;
  static const double navBarIconOffset = 6;
  static const double navBarBottomPadding = 5;
  static const double navBarIndicatorWidth = 54;
  static const double navBarIndicatorHeight = 27;
  static const double navBarIndicatorRadius = 15;
  static const double navBarIconSizeSelected = 24;
  static const double navBarIconSizeUnselected = 22;

  // AppBar 설정값
  static const double appBarHeight = 46;
  static const double appBarTitleSpacing = 20;
  static const double appBarTitleFontSize = 20;
  static const FontWeight appBarTitleFontWeight = FontWeight.w500;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      toolbarHeight: appBarHeight,
      titleSpacing: appBarTitleSpacing,
      titleTextStyle: TextStyle(
        fontSize: appBarTitleFontSize,
        fontWeight: appBarTitleFontWeight,
        color: Colors.black87,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: navBarHeight,
      elevation: 0,
      indicatorShape: CustomIndicatorShape(
        width: navBarIndicatorWidth,
        height: navBarIndicatorHeight,
        borderRadius: BorderRadius.all(Radius.circular(navBarIndicatorRadius)),
        offsetY: navBarIconOffset,
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(size: navBarIconSizeSelected);
        }
        return const IconThemeData(size: navBarIconSizeUnselected);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
        }
        return TextStyle(fontSize: 9);
      }),
      
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      toolbarHeight: appBarHeight,
      titleSpacing: appBarTitleSpacing,
      titleTextStyle: TextStyle(
        fontSize: appBarTitleFontSize,
        fontWeight: appBarTitleFontWeight,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: navBarHeight,
      elevation: 0,
      indicatorShape: CustomIndicatorShape(
        width: navBarIndicatorWidth,
        height: navBarIndicatorHeight,
        borderRadius: BorderRadius.all(Radius.circular(navBarIndicatorRadius)),
        offsetY: navBarIconOffset,
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(size: navBarIconSizeSelected);
        }
        return const IconThemeData(size: navBarIconSizeUnselected);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
        }
        return TextStyle(fontSize: 9);
      }),

    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
  );
}
