/// نوع خطاهای قابل‌نمایش به کاربر.
enum FailureType {
  network,
  timeout,
  server,
  unauthorized,
  validation,
  insufficientStock,
  inactiveProduct,
  paymentFailed,
  printer,
  notFound,
  conflict,
  unknown,
}

/// خطای دامنه‌ای برنامه. هرگز Exception خام یا Stack Trace به کاربر نشان داده نمی‌شود.
class AppFailure implements Exception {
  const AppFailure(this.type, {String? message, this.details})
      : _message = message;

  final FailureType type;
  final String? _message;

  /// اطلاعات فنی (فقط برای لاگ، نه نمایش به کاربر).
  final Object? details;

  factory AppFailure.network() => const AppFailure(FailureType.network);
  factory AppFailure.timeout() => const AppFailure(FailureType.timeout);
  factory AppFailure.server([Object? details]) =>
      AppFailure(FailureType.server, details: details);
  factory AppFailure.unauthorized() =>
      const AppFailure(FailureType.unauthorized);
  factory AppFailure.validation([String? message]) =>
      AppFailure(FailureType.validation, message: message);
  factory AppFailure.insufficientStock([String? itemName]) => AppFailure(
        FailureType.insufficientStock,
        message: itemName == null ? null : 'موجودی «$itemName» کافی نیست.',
      );
  factory AppFailure.inactiveProduct([String? name]) => AppFailure(
        FailureType.inactiveProduct,
        message: name == null ? null : 'محصول «$name» غیرفعال است.',
      );
  factory AppFailure.paymentFailed() =>
      const AppFailure(FailureType.paymentFailed);
  factory AppFailure.printer([String? message]) =>
      AppFailure(FailureType.printer, message: message);
  factory AppFailure.notFound() => const AppFailure(FailureType.notFound);
  factory AppFailure.conflict([String? message]) =>
      AppFailure(FailureType.conflict, message: message);
  factory AppFailure.unknown([Object? details]) =>
      AppFailure(FailureType.unknown, details: details);

  /// پیام فارسی و قابل‌فهم برای کاربر.
  String get userMessage {
    final custom = _message;
    if (custom != null && custom.isNotEmpty) return custom;
    switch (type) {
      case FailureType.network:
        return 'اتصال به سرور برقرار نشد. اینترنت یا شبکه را بررسی کنید.';
      case FailureType.timeout:
        return 'پاسخی از سرور دریافت نشد. لطفاً دوباره تلاش کنید.';
      case FailureType.server:
        return 'مشکلی در سرور رخ داد. کمی بعد دوباره تلاش کنید.';
      case FailureType.unauthorized:
        return 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.';
      case FailureType.validation:
        return 'اطلاعات واردشده ناقص یا نامعتبر است.';
      case FailureType.insufficientStock:
        return 'موجودی انبار برای این عملیات کافی نیست.';
      case FailureType.inactiveProduct:
        return 'این محصول غیرفعال است و قابل سفارش نیست.';
      case FailureType.paymentFailed:
        return 'ثبت پرداخت ناموفق بود. دوباره تلاش کنید.';
      case FailureType.printer:
        return 'چاپ انجام نشد. اتصال چاپگر را بررسی کنید.';
      case FailureType.notFound:
        return 'مورد درخواستی پیدا نشد.';
      case FailureType.conflict:
        return 'این مورد قبلاً تغییر کرده است. صفحه را تازه‌سازی کنید.';
      case FailureType.unknown:
        return 'خطای غیرمنتظره‌ای رخ داد.';
    }
  }

  /// آیا «تلاش مجدد» برای این خطا معنا دارد؟
  bool get isRetryable =>
      type == FailureType.network ||
      type == FailureType.timeout ||
      type == FailureType.server ||
      type == FailureType.printer ||
      type == FailureType.unknown;

  @override
  String toString() => 'AppFailure($type)';
}
