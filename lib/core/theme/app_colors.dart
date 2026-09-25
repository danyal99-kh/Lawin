import 'package:flutter/material.dart';

/// پالت رنگی کافه‌کتاب: فیروزه‌ای تیره به‌عنوان Accent اصلی، پس‌زمینه‌های گرم و خنثی،
/// و رنگ چوبی/قهوه‌ای به‌صورت محدود برای حس کتاب و کافه.
abstract final class AppColors {
  // Primary (فیروزه‌ای تیره)
  static const Color primary = Color(0xFF0B6B6F);
  static const Color primaryDark = Color(0xFF084E52);
  static const Color primarySoft = Color(0xFFDCEEEE);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Wood accent (محدود استفاده شود)
  static const Color wood = Color(0xFF8A6A4B);
  static const Color woodSoft = Color(0xFFF1E8DC);

  // Neutrals
  static const Color background = Color(0xFFF7F5F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1EEE8);
  static const Color border = Color(0xFFE4DFD6);
  static const Color textPrimary = Color(0xFF23201C);
  static const Color textSecondary = Color(0xFF6B655C);
  static const Color textDisabled = Color(0xFFA8A29A);

  // Status
  static const Color success = Color(0xFF2E7D4F);
  static const Color successSoft = Color(0xFFE3F2E9);
  static const Color warning = Color(0xFFC96F12);
  static const Color warningSoft = Color(0xFFFCEBD6);
  static const Color danger = Color(0xFFC0392B);
  static const Color dangerSoft = Color(0xFFFAE3E0);
  static const Color neutral = Color(0xFF7B766D);
  static const Color neutralSoft = Color(0xFFECE9E3);
  static const Color info = Color(0xFF0B6B6F);
  static const Color infoSoft = Color(0xFFDCEEEE);
}
