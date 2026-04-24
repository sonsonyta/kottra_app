import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';

const BorderRadius _inputBorderRadius = BorderRadius.all(Radius.circular(18));

ThemeData buildLightTheme() => _buildTheme(Brightness.light, AppColors.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark, AppColors.dark);

ThemeData _buildTheme(Brightness brightness, AppColors c) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kBrandPrimary,
    brightness: brightness,
    primary: c.primary,
    surface: c.surface,
    error: c.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: colorScheme.primary),
      floatingLabelStyle: TextStyle(color: colorScheme.primary),
      enabledBorder: OutlineInputBorder(
        borderRadius: _inputBorderRadius,
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _inputBorderRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: _inputBorderRadius,
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.45),
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionHandleColor: colorScheme.primary,
    ),
  );
}
