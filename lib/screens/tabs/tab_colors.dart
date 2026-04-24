import 'package:flutter/material.dart';

/// Brand seed used by both themes.
const Color kBrandPrimary = Color(0xFF2E86DE);

/// Semantic color palette resolved per-brightness via [Theme.of].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.infoLight,
    required this.divider,
    required this.holiday,
    required this.holidayLight,
    required this.shadowSubtle,
    required this.shadow,
    required this.shadowStrong,
    required this.fieldFill,
    required this.fieldBorder,
  });

  final Color primary;
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color infoLight;
  final Color divider;
  final Color holiday;
  final Color holidayLight;
  final Color shadowSubtle;
  final Color shadow;
  final Color shadowStrong;
  final Color fieldFill;
  final Color fieldBorder;

  static const AppColors light = AppColors(
    primary: Color(0xFF2E86DE),
    primaryDark: Color(0xFF1B5FA8),
    background: Color(0xFFF0F6FF),
    surface: Colors.white,
    surfaceMuted: Color(0xFFF5F8FD),
    textPrimary: Color(0xFF1A2E4A),
    textSecondary: Color(0xFF7E92B4),
    success: Color(0xFF27AE60),
    successLight: Color(0xFFE8F8EF),
    warning: Color(0xFFE67E22),
    warningLight: Color(0xFFFEF3E8),
    error: Color(0xFFE74C3C),
    errorLight: Color(0xFFFDECEA),
    infoLight: Color(0xFFEAF2FF),
    divider: Color(0xFFE8EFF8),
    holiday: Color(0xFF8E44AD),
    holidayLight: Color(0xFFF5EEF8),
    shadowSubtle: Color(0x0A2E86DE),
    shadow: Color(0x1A2E86DE),
    shadowStrong: Color(0x332E86DE),
    fieldFill: Color(0xFFFDFEFF),
    fieldBorder: Color(0xFFDCE7F7),
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFF4A9DFF),
    primaryDark: Color(0xFF2E86DE),
    background: Color(0xFF0F1620),
    surface: Color(0xFF1A2333),
    surfaceMuted: Color(0xFF202B40),
    textPrimary: Color(0xFFEDF2FA),
    textSecondary: Color(0xFF8FA0BC),
    success: Color(0xFF2ECC71),
    successLight: Color(0xFF1F3328),
    warning: Color(0xFFF39C12),
    warningLight: Color(0xFF332720),
    error: Color(0xFFE74C3C),
    errorLight: Color(0xFF3A211E),
    infoLight: Color(0xFF1B2940),
    divider: Color(0xFF243049),
    holiday: Color(0xFFB07CD8),
    holidayLight: Color(0xFF2A1E33),
    shadowSubtle: Color(0x33000000),
    shadow: Color(0x66000000),
    shadowStrong: Color(0x80000000),
    fieldFill: Color(0xFF1F2A3D),
    fieldBorder: Color(0xFF2D3A55),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? infoLight,
    Color? divider,
    Color? holiday,
    Color? holidayLight,
    Color? shadowSubtle,
    Color? shadow,
    Color? shadowStrong,
    Color? fieldFill,
    Color? fieldBorder,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      infoLight: infoLight ?? this.infoLight,
      divider: divider ?? this.divider,
      holiday: holiday ?? this.holiday,
      holidayLight: holidayLight ?? this.holidayLight,
      shadowSubtle: shadowSubtle ?? this.shadowSubtle,
      shadow: shadow ?? this.shadow,
      shadowStrong: shadowStrong ?? this.shadowStrong,
      fieldFill: fieldFill ?? this.fieldFill,
      fieldBorder: fieldBorder ?? this.fieldBorder,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      holiday: Color.lerp(holiday, other.holiday, t)!,
      holidayLight: Color.lerp(holidayLight, other.holidayLight, t)!,
      shadowSubtle: Color.lerp(shadowSubtle, other.shadowSubtle, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowStrong: Color.lerp(shadowStrong, other.shadowStrong, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
    );
  }
}

/// Convenience accessor for the active [AppColors].
AppColors appColors(BuildContext context) =>
    Theme.of(context).extension<AppColors>()!;
