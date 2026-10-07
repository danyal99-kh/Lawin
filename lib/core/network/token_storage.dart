import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ذخیره‌ی امن توکن احراز هویت.
///
/// پیاده‌سازی واقعی از `flutter_secure_storage` (Keystore / Keychain /
/// DPAPI) استفاده می‌کند تا توکن در حافظه‌ی امن دستگاه بماند، نه در فایل‌های
/// معمولی برنامه.
abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// TokenStorage امن با تضمین «هیچ‌وقت کرش نمی‌کند».
///
/// اگر پلتفرم از حافظه‌ی امن پشتیبانی نکند (مثلاً در تست‌های ویجت که هیچ
/// Plugin در دسترس نیست) به‌جای پرتاب Exception مثل «هیچ توکنی ذخیره نشده»
/// رفتار می‌کند. به این ترتیب تست‌هایی که فقط AppProviders را بالا می‌آورند
/// بدون وابستگی به پلتفرم سبز می‌مانند.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> write(String token) {
    return _silently(() => _storage.write(key: _key, value: token));
  }

  @override
  Future<void> clear() {
    return _silently(() => _storage.delete(key: _key));
  }

  /// خطاهای «پلاگین در دسترس نیست» را بی‌اثر می‌کند.
  Future<void> _silently(Future<void> Function() op) async {
    try {
      await op();
    } on MissingPluginException {
      // بی‌اثر: مثل چیزی که چیزی ذخیره نشده.
    } on PlatformException {
      // بی‌اثر.
    }
  }
}