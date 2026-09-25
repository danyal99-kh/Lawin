/// enumهایی که با مقدار رشته‌ای در JSON جنگو نگاشت می‌شوند.
abstract interface class ApiEnum {
  /// مقدار ارسالی/دریافتی در API (snake_case)
  String get apiValue;

  /// برچسب فارسی برای نمایش
  String get label;
}

/// تبدیل مقدار خام JSON به enum؛ در صورت ناشناخته بودن، مقدار پیش‌فرض برمی‌گردد
/// تا افزودن وضعیت جدید در Backend باعث Crash نشود.
T parseApiEnum<T extends ApiEnum>(
  List<T> values,
  Object? raw, {
  required T fallback,
}) {
  for (final v in values) {
    if (v.apiValue == raw) return v;
  }
  return fallback;
}
