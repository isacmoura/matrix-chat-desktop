import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand700 = Color(0xFF4F378B);
  static const brand600 = Color(0xFF6750A4);
  static const brand300 = Color(0xFF8F72CE);
  static const brand100 = Color(0xFFE9DDFF);
  static const canvas = Color(0xFFFFFBFF);
  static const panel = Color(0xFFFFFFFF);
  static const sidebar = Color(0xFFF8F2FB);
  static const subtle = Color(0xFFF3EDF7);
  static const selected = Color(0xFFEADCFF);
  static const text = Color(0xFF1D1B20);
  static const muted = Color(0xFF625B71);
  static const border = Color(0xFFCAC4D0);
  static const borderSoft = Color(0xFFE7E0EC);
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFF9DEDC);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand600,
    primary: AppColors.brand600,
    error: AppColors.error,
    surface: AppColors.panel,
    onSurface: AppColors.text,
  );

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.brand600, 2),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 2),
      disabledBorder: border(AppColors.borderSoft),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.brand600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.brand600.withOpacity(0.8),
        disabledForegroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
