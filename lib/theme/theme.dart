// lib/theme/theme.dart
import 'package:flutter/material.dart';

class WarthogColors {
  // PRIMARY PALETTE - ZYRTARE
  static const Color primaryYellow = Color(0xFFFDB913);
  static const Color primaryOrange = Color(0xFFF25C05);
  static const Color primaryDarkOrange = Color(0xFFE79300);
  static const Color primaryPink = Color(0xFFF20544);
  
  // SECONDARY COLORS
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color blue = Color(0xFF0000FF);
  static const Color green = Color(0xFF009900);
  static const Color yellow = Color(0xFFFFFF00);
  static const Color red = Color(0xFFFF0000);
  static const Color purple = Color(0xFF800080);
  static const Color orange = Color(0xFFFFA500);
  static const Color pink = Color(0xFFFFB6C1);
  static const Color brown = Color(0xFFA52A2A);
  static const Color grey = Color(0xFF808080);
  
  // GRADIENTS
  static const List<Color> primaryGradient = [
    primaryOrange,
    primaryYellow,
    primaryDarkOrange,
    primaryPink,
    primaryYellow,
  ];
  
  static const List<Color> orangeGradient = [
    Color(0xFFF25C05),
    Color(0xFFFDB913),
  ];
}

class WarthogTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: WarthogColors.primaryYellow,
      secondary: WarthogColors.primaryOrange,
      tertiary: WarthogColors.primaryPink,
      background: Color(0xFFF5F5F5),
      surface: Colors.white,
      error: WarthogColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: WarthogColors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: WarthogColors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: WarthogColors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WarthogColors.primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WarthogColors.primaryYellow, width: 2),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: WarthogColors.primaryYellow,
      secondary: WarthogColors.primaryOrange,
      tertiary: WarthogColors.primaryPink,
      background: Color(0xFF000000), // E zezë e plotë!
      surface: Color(0xFF1A1A1A),     // Gri shumë e errët për kartela
      error: WarthogColors.red,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000), // Background i zi
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WarthogColors.primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WarthogColors.primaryYellow, width: 2),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A1A1A),
    ),
  );
}