import '../core/errors/result.dart';

/// رمز امنیتیِ مالی (مشترک بین Accounting، Expenses و Reports).
///
/// کل‌وزن تصمیم‌گیری و ذخیره‌ی رمز سمت Backend است؛ این اینترفیس فقط
/// «ورود امنیتی» (گرفتن بلیت کوتاه‌مدت) و «تنظیم/تغییر رمز» را بازتاب می‌دهد.
abstract interface class SecurityRepository {
  /// رمز درست است؟ در جواب، بلیت کوتاه‌مدت برمی‌گردد که در هدر امنیتی
  /// درخواست‌های مالی فرستاده می‌شود.
  Future<Result<String>> verify(String password);

  /// تنظیم رمز برای اولین بار (بدون رمز فعلی) یا تغییر آن (با رمز فعلی).
  /// موفقیت یعنی همه‌ی بلیت‌های قبلی سمت سرور بی‌اعتبار شده‌اند.
  Future<Result<void>> changePassword({
    String? currentPassword,
    required String newPassword,
  });
}