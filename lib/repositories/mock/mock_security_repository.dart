import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';

import '../security_repository.dart';

/// نسخه‌ی درون‌حافظه‌ایِ رمز امنیتی فقط برای حالت Mock (توسعه).
///
/// هیچ رمزی روی دیسک نمی‌نشیند و هیچ الگوریتم هش‌کردنی هم بازنویسی نشده؛
/// نمونه‌ی واقعی (Django/PBKDF2) همیشه مرجع تصمیم‌گیری است.
class MockSecurityRepository implements SecurityRepository {
  String? _password;
  int _serial = 0;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  @override
  Future<Result<String>> verify(String password) async {
    await _latency();
    final p = _password;
    if (p == null) {
      return Failure(AppFailure.securityNotConfigured());
    }
    if (password != p) {
      return Failure(AppFailure.security('رمز امنیتی صحیح نیست.'));
    }
    return Success('mock-financial-ticket-${++_serial}');
  }

  @override
  Future<Result<void>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    await _latency();
    if (newPassword.length < 6) {
      return Failure(AppFailure.validation('رمز امنیتی باید حداقل ۶ کاراکتر باشد.'));
    }
    final current = _password;
    if (current != null && current != currentPassword) {
      return Failure(AppFailure.security('رمز امنیتی صحیح نیست.'));
    }
    _password = newPassword;
    return const Success(null);
  }
}