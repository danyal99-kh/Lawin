import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/token_storage.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._tokens) {
    // همه‌ی درخواست‌ها توکن نشست را از حافظه می‌گیرند (fallback: رسانه‌ی امن).
    _api.authToken = () => _token;
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final TokenStorage _tokens;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  String? _token;
  String? get token => _token;

  bool _busy = false;
  bool get busy => _busy;

  /// جلوگیری از حلقه‌ی بازگشتی: وقتی خودِ logout جواب 401 می‌گیرد (توکنی که
  /// می‌خواهد باطل کند از قبل مرده) نباید دوباره logout صدا زده شود.
  bool _ignoringUnauthorized = false;

  /// بازگردانی نشست. **هیچ ورود خودکار وجود ندارد:** اگر توکنی از اجرای قبلی
  /// روی دستگاه باقی مانده باشد، بهترین‌تلاش آن را سمت سرور باطل می‌کنیم و
  /// پاکش می‌کنیم؛ همیشه با صفحه‌ی ورود شروع می‌شود.
  Future<void> restore() async {
    final saved = await _tokens.read();
    if (saved != null) {
      await _bestEffortRevoke();
      await _tokens.clear();
    }
    _token = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<AppFailure?> login(String username, String password) async {
    _busy = true;
    notifyListeners();
    final result = await _api.post<String>(
      ApiEndpoints.login,
      (j) => (j as Map<String, dynamic>)['token'] as String,
      body: {'username': username.trim(), 'password': password},
    );
    _busy = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      notifyListeners();
      return failure;
    }
    _token = result.dataOrNull!;
    await _tokens.write(_token!);
    _status = AuthStatus.signedIn;
    notifyListeners();
    return null;
  }

  /// خروج کامل: ابتدا توکن سمت سرور باطل می‌شود، سپس حافظه‌ی امن پاک می‌شود.
  /// نتیجه‌ی باطل‌سازی «بهترین‌تلاش» است؛ حتی اگر سرور در دسترس نباشد،
  /// نشست محلی بسته می‌شود. وقتی از قبل خارج شده‌ایم چیزی به سرور نمی‌فرستیم.
  Future<void> logout() async {
    if (_status == AuthStatus.signedOut) {
      await _tokens.clear();
      _token = null;
      notifyListeners();
      return;
    }
    _ignoringUnauthorized = true;
    try {
      await _bestEffortRevoke();
    } finally {
      _ignoringUnauthorized = false;
    }
    await _tokens.clear();
    _token = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  /// باطل‌کردن توکنِ فعلی سمت سرور؛ نتیجه مهم نیست (آفلاین/خطا نباید مانع
  /// بستن نشست محلی شود).
  Future<void> _bestEffortRevoke() async {
    try {
      await _api.post<void>(ApiEndpoints.logout, (_) {});
    } catch (_) {
      // هیچ؛ بهترین‌تلاش.
    }
  }

  void _handleUnauthorized() {
    if (_status == AuthStatus.signedIn && !_ignoringUnauthorized) {
      logout();
    }
  }
}