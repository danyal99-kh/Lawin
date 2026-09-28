/// تنظیمات اتصال به Backend.
///
/// هیچ Secret یا کلید حساسی در کد قرار نمی‌گیرد. مقادیر هنگام اجرا/ساخت با
/// `--dart-define` تزریق می‌شوند. مثال:
///
///   flutter run -d windows --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://127.0.0.1:8000
///
/// توکن احراز هویت (JWT) در مرحله اتصال به Django از طریق یک TokenStorage امن
/// (مثلاً flutter_secure_storage) مدیریت می‌شود، نه از طریق این فایل.
abstract final class AppConfig {
  /// آدرس پایه‌ی API جنگو. تا زمانی که Backend آماده نیست خالی است.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000');

  /// اگر true باشد Repositoryها از Mock Data استفاده می‌کنند.
  static const bool useMock =
      bool.fromEnvironment('USE_MOCK', defaultValue: true);

  /// فاصله‌ی زمانی دریافت سفارش‌های جدید مشتری از Backend (Polling).
  /// در آینده می‌توان با SSE/WebSocket جایگزین کرد بدون تغییر UI.
  static const int incomingOrdersPollSeconds =
      int.fromEnvironment('INCOMING_ORDERS_POLL_SECONDS', defaultValue: 5);

  static const Duration requestTimeout = Duration(seconds: 15);
}
