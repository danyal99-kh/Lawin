import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/network/api_client.dart';
import '../pages/shell/app_destination.dart';
import '../repositories/security_repository.dart';
import 'auth_provider.dart';

/// بخش‌های مالی که «رمز امنیتی» لازم دارند. هزینه‌ها زیرمجموعه‌ی حسابداری‌اند
/// و یک بار ورود، هر دو را باز می‌کند.
enum SecuritySection { accounting, reports }

/// هر مقصد ناوبری متعلق به کدام بخش امنیتی است؟ null یعنی بخش خارج از گیت.
SecuritySection? sectionOf(AppDestination destination) => switch (destination) {
      AppDestination.accounting || AppDestination.expenses =>
        SecuritySection.accounting,
      AppDestination.reports => SecuritySection.reports,
      _ => null,
    };

/// دروازه‌ی رمز امنیتی مالی.
///
/// - یک بلیت مشترک کوتاه‌مدت (از Backend پس از «ورود امنیتی») در هدر امنیتی
///   همه‌ی درخواست‌های مالی فرستاده می‌شود.
/// - به‌ازای «بخش» (حسابداری/گزارش‌ها) پرچم باز بودن نگه می‌دارد؛ با خروج از
///   بخش، بلیت همان بخش بی‌اعتبار می‌شود و ورود بعدی دوباره رمز می‌خواهد.
/// - با خروج کامل از حساب، همه‌چیز پاک می‌شود.
class SecurityGateProvider extends ChangeNotifier {
  SecurityGateProvider({required this.auth, required this.repository, ApiClient? api}) {
    // وصل کردن هدر بلیت به کلاینت HTTP: این‌جا گیت قطعاً ساخته شده، پس
    // درخواست‌های قبل از آن (مثل باطل‌کردن توکن هنگام شروع برنامه) بدون
    // بلیت می‌مانند و کرش نمی‌کنند.
    if (api != null) {
      api.securityTicket = () => ticket;
      api.onSecurityTicket = storeTicket;
    }
    auth.addListener(_onAuthChanged);
  }

  final AuthProvider auth;
  final SecurityRepository repository;

  final Set<SecuritySection> _unlocked = {};
  String? _ticket;
  bool _busy = false;

  bool get busy => _busy;

  /// بلیت مالیِ فعلی برای هدر `X-Security-Ticket`.
  String? get ticket => _ticket;

  bool isLocked(SecuritySection section) =>
      !_unlocked.contains(section) || _ticket == null;

  /// نگه‌داشتن بلیت تازه‌ای که Backend در پاسخ (نشست لغزان) برگرداند.
  void storeTicket(String value) {
    if (value.isEmpty || value == _ticket) return;
    _ticket = value;
    notifyListeners();
  }

  /// «ورود امنیتی» برای یک بخش. خطا به‌صورت `AppFailure` برمی‌گردد تا
  /// صفحه‌ی رمز آن را نمایش دهد؛ موفقیت یعنی همان پمپ‌شده و گیت باز است.
  Future<AppFailure?> unlock(SecuritySection section, String password) async {
    if (_busy) return AppFailure.validation('ورود امنیتی در حال انجام است.');
    _busy = true;
    notifyListeners();
    final result = await repository.verify(password);
    _busy = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      notifyListeners();
      return failure;
    }
    _ticket = result.dataOrNull;
    _unlocked.add(section);
    notifyListeners();
    return null;
  }

  /// خروج از یک بخش: برای ورود بعدی دوباره رمز لازم می‌شود. اگر بخش دیگری
  /// هنوز باز باشد، بلیت مشترک نگه داشته می‌شود.
  void invalidate(SecuritySection section) {
    if (!_unlocked.remove(section)) return;
    if (_unlocked.isEmpty) _ticket = null;
    notifyListeners();
  }

  /// تغییر رمز از تنظیمات: موفقیت یعنی همه‌ی بلیت‌های قبلی سمت سرور مرده‌اند،
  /// پس کل گیت هم بسته می‌شود.
  Future<AppFailure?> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    final result = await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    final failure = result.failureOrNull;
    if (failure == null) invalidateAll();
    return failure;
  }

  void invalidateAll() {
    if (_unlocked.isEmpty && _ticket == null) return;
    _unlocked.clear();
    _ticket = null;
    notifyListeners();
  }

  /// هر مسیر خروج (دکمه، بستن کافه، بی‌اعتبار شدن نشست) این‌جا بلیت‌ها را می‌بندد.
  void _onAuthChanged() {
    if (auth.status != AuthStatus.signedIn) invalidateAll();
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}