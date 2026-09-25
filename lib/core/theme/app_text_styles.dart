import 'package:flutter/material.dart';

import 'app_colors.dart';

/// تایپوگرافی فارسی. اگر فونت Vazirmatn در pubspec ثبت شده باشد از آن استفاده می‌شود،
/// در غیر این صورت به فونت‌های سیستم (Segoe UI/Tahoma در Windows و Noto/Roboto در Android) برمی‌گردد.
abstract final class AppTextStyles {
  static const String fontFamily = 'Vazirmatn';
  static const List<String> fontFallback = [
    'Segoe UI',
    'Tahoma',
    'Noto Sans Arabic',
    'Roboto',
  ];

  static TextStyle _base(double size, FontWeight weight, {Color? color}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontSize: size,
        fontWeight: weight,
        height: 1.5,
        color: color ?? AppColors.textPrimary,
      );

  static TextTheme textTheme() => TextTheme(
        displaySmall: _base(28, FontWeight.w700),
        headlineMedium: _base(24, FontWeight.w700),
        headlineSmall: _base(20, FontWeight.w700),
        titleLarge: _base(18, FontWeight.w700),
        titleMedium: _base(16, FontWeight.w600),
        titleSmall: _base(14, FontWeight.w600),
        bodyLarge: _base(16, FontWeight.w400),
        bodyMedium: _base(14, FontWeight.w400),
        bodySmall: _base(12, FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: _base(14, FontWeight.w600),
        labelMedium: _base(12, FontWeight.w600),
        labelSmall: _base(11, FontWeight.w500, color: AppColors.textSecondary),
      );
}
