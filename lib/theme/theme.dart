import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  // Светлая McDonald's-тема
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    primaryColor: AppColors.red,
    colorScheme: ColorScheme.light(
      primary:   AppColors.red,
      secondary: AppColors.yellow,
      surface:   AppColors.lightCard,
      onSurface: AppColors.lightText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.red,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCard,
      selectedItemColor: AppColors.red,
      unselectedItemColor: AppColors.lightGreyText,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(AppColors.red),
      trackColor: MaterialStateProperty.resolveWith((s) =>
      s.contains(MaterialState.selected) ? AppColors.yellow : AppColors.lightCard),
    ),
  );

  // Классический тёмный режим
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    primaryColor: AppColors.red,
    colorScheme: ColorScheme.dark(
      primary:   AppColors.red,
      secondary: AppColors.yellow,
      surface:   AppColors.darkCard,
      onSurface: AppColors.darkText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      selectedItemColor: AppColors.red,
      unselectedItemColor: AppColors.darkGreyText,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(AppColors.red),
      trackColor: MaterialStateProperty.resolveWith((s) =>
      s.contains(MaterialState.selected) ? AppColors.yellow : AppColors.darkCard),
    ),
  );
}
