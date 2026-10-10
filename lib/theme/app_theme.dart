import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFDCE8FC);
  static const Color primary = Color(0xFF20A5A5);
  static const Color secondary = Color(0xFFFFC857);
  static const Color orange = Color(0xFFFFA34D);

  static const Color darkText = Color(0xFF293747);
  static const Color lightText = Color(0xFF778597);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
    ),

    fontFamily: 'Roboto',

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkText,
      elevation: 0,
    ),

    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFDCE8FC),
    ),
  );
}
