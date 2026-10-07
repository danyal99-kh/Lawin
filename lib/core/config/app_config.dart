/// تنظیمات اتصال به Backend.
///
/// هیچ Secret یا کلید حساسی در کد قرار نمی‌گیرد. مقادیر هنگام اجرا/ساخت با
/// `--dart-define` تزریق می‌شوند.
///
/// - اجرای عادی (بدون هیچ پارامتر اضافه) یعنی اتصال به بک‌اند واقعی Django.
/// - برای استفاده از داده‌ی فیک باید صراحتاً `--dart-define=USE_MOCK=true` داده شود.
///
/// مثال (بک‌اند واقعی):
///
///   flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
///
/// مثال (حالت Mock):
///
///   flutter run -d windows --dart-define=USE_MOCK=true
///
/// توکن احراز هویت (JWT) در مرحله اتصال به Django از طریق یک TokenStorage امن
/// (مثلاً flutter_secure_storage) مدیریت می‌شود، نه از طریق این فایل.
abstract final class AppConfig {
  /// آدرس پایه‌ی API جنگو (پیش‌فرض: سرور محلی روی همین سیستم).
  ///
  /// بسته به محل اجرای برنامه، با `--dart-define=API_BASE_URL=...` مقدار مناسب را بدهید:
  /// - دسکتاپ (Windows) و شبیه‌ساز iOS: `http://127.0.0.1:8000`
  /// - امولاتور اندروید: `http://10.0.2.2:8000` (آدرس سیستم میزبان از دید امولاتور)
  /// - گوشی واقعی: IP سیستم در شبکه‌ی محلی، مثلاً `http://192.168.1.20:8000`
  ///   (گوشی و سیستم باید در یک شبکه باشند و `runserver` با `0.0.0.0:8000`
  ///   اجرا شود و آن IP در `DJANGO_ALLOWED_HOSTS` بک‌اند باشد).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000');

  /// اگر true باشد Repositoryها از Mock Data استفاده می‌کنند. پیش‌فرض false است
  /// (بک‌اند واقعی)؛ فقط با `--dart-define=USE_MOCK=true` فعال می‌شود.
  static const bool useMock =
      bool.fromEnvironment('USE_MOCK', defaultValue: false);

  /// فاصله‌ی زمانی دریافت سفارش‌های جدید مشتری از Backend (Polling).
  /// در آینده می‌توان با SSE/WebSocket جایگزین کرد بدون تغییر UI.
  static const int incomingOrdersPollSeconds =
      int.fromEnvironment('INCOMING_ORDERS_POLL_SECONDS', defaultValue: 5);

  static const Duration requestTimeout = Duration(seconds: 15);
}
