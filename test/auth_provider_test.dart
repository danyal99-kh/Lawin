// تست AuthProvider: ورود، بازگردانی نشست بدون ورود خودکار، خروج کامل
// (باطل‌کردن سمت سرور + پاک‌سازی محلی) و قطع نشست در 401.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryTokens implements TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

/// پاسخ‌هایی که آزمون‌گر دقیقاً کنترل می‌کند؛ درخواست‌ها هم ثبت می‌شوند.
class _Http {
  _Http(this.handler);
  final Future<http.Response> Function(http.Request) handler;
  final List<http.Request> requests = [];

  MockClient get client => MockClient((req) async {
        requests.add(req);
        return handler(req);
      });
}

/// behت‌روتیپ‌های کمکی برای همه‌ی تست‌ها.
class _Harness {
  _Harness({required this.http}) {
    tokens = _MemoryTokens();
    api = ApiClient(tokens, client: http.client);
    auth = AuthProvider(api, tokens);
  }

  final _Http http;
  late final _MemoryTokens tokens;
  late final ApiClient api;
  late final AuthProvider auth;

  void dispose() => auth.dispose();
}

http.Response _loginResponse() => http.Response(
    '{"token": "new-token-1"}', 200,
    headers: {'content-type': 'application/json'});

http.Response _unauthorized() => http.Response(
    '{"error": {"code": "unauthorized", "message": "اعتبار شما نامعتبر است."}}',
    401,
    headers: {'content-type': 'application/json'});

bool _isLogin(http.Request req) => req.url.path.endsWith('/auth/login/');
bool _isLogout(http.Request req) => req.url.path.endsWith('/auth/logout/');

/// منتظر می‌ماند تا شرط برقرار شود (با سقف زمانی، برای رویدادهای ناهمگام).
Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('login', () {
    test('success stores the token and signs in', () async {
      final h = _Http((req) async => _loginResponse());
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);

      final failure = await harness.auth.login('admin', 'pass');

      expect(failure, isNull);
      expect(harness.auth.status, AuthStatus.signedIn);
      expect(harness.auth.token, 'new-token-1');
      expect(harness.tokens.value, 'new-token-1');
      expect(h.requests, hasLength(1));
    });

    test('a login failure stays signed out and stores nothing', () async {
      final h = _Http((req) async =>
          http.Response('{"error": {"code": "validation", "message": "ورود ناموفق بود."}}', 400,
              headers: {'content-type': 'application/json'}));
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);
      await harness.auth.restore();

      final failure = await harness.auth.login('admin', 'wrong');

      expect(failure, isNotNull);
      expect(failure?.type, FailureType.validation);
      expect(harness.auth.status, AuthStatus.signedOut);
      expect(harness.tokens.value, isNull);
    });
  });

  group('restore', () {
    test('no saved token: signed out immediately, no network', () async {
      final h = _Http((req) async => _loginResponse());
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);

      await harness.auth.restore();

      expect(harness.auth.status, AuthStatus.signedOut);
      expect(harness.auth.token, isNull);
      expect(h.requests, isEmpty);
    });

    test('a leftover token is revoked best-effort and cleared: NO auto-login',
        () async {
      final h = _Http((req) async {
        if (_isLogin(req)) return _loginResponse();
        return http.Response('{}', 200);
      });
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);
      await harness.tokens.write('leftover-token');

      await harness.auth.restore();

      // هرگز وارد نمی‌شود؛ توکن قبلی باطل و پاک می‌شود.
      expect(harness.auth.status, AuthStatus.signedOut);
      expect(harness.auth.token, isNull);
      expect(harness.tokens.value, isNull);
      final logout = h.requests.where(_isLogout);
      expect(logout, hasLength(1));
      expect(logout.single.headers['Authorization'], 'Token leftover-token');
    });

    test('a stale (already-revoked) token still leads to signed out',
        () async {
      // سرور برای باطل‌کردن 401 برمی‌گرداند؛ باید بی‌صدا نادیده گرفته شود.
      final h = _Http((req) async => _unauthorized());
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);
      await harness.tokens.write('stale-token');

      await harness.auth.restore();

      expect(harness.auth.status, AuthStatus.signedOut);
      expect(harness.tokens.value, isNull);
    });
  });

  group('logout', () {
    test('revokes the token on the server then clears locally', () async {
      final h = _Http((req) async {
        if (_isLogin(req)) return _loginResponse();
        return http.Response('{}', 200);
      });
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);
      await harness.auth.login('admin', 'pass');
      expect(harness.auth.status, AuthStatus.signedIn);

      await harness.auth.logout();

      expect(harness.auth.status, AuthStatus.signedOut);
      expect(harness.auth.token, isNull);
      expect(harness.tokens.value, isNull);
      final logout = h.requests.where(_isLogout);
      expect(logout, hasLength(1));
      expect(logout.single.headers['Authorization'], 'Token new-token-1');
    });

    test('is idempotent when already signed out', () async {
      final h = _Http((req) async => http.Response('{}', 200));
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);
      await harness.auth.restore();

      await harness.auth.logout();
      await harness.auth.logout();

      expect(harness.auth.status, AuthStatus.signedOut);
      expect(h.requests.where(_isLogout), isEmpty,
          reason: 'وقتی هیچ نشستی نیست چیزی به سرور نمی‌فرستیم');
    });
  });

  group('unauthorized', () {
    test('a 401 during a request signs the session out', () async {
      final h = _Http((req) async {
        if (_isLogin(req)) return _loginResponse();
        return _unauthorized();
      });
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);
      await harness.auth.restore();
      await harness.auth.login('admin', 'pass');

      await harness.api.post<void>('/x', (_) {});

      // خروج در پاسخ به 401 ناهمگام است؛ منتظر می‌مانیم.
      await _waitFor(() => harness.auth.status == AuthStatus.signedOut);
      expect(harness.auth.status, AuthStatus.signedOut);
    });

    test('a 401 during logout does not loop', () async {
      final h = _Http((req) async {
        if (_isLogin(req)) return _loginResponse();
        return _unauthorized(); // logout هم 401 می‌دهد (توکن از قبل مرده)
      });
      final harness = _Harness(http: h);
      addTearDown(harness.dispose);
      await harness.auth.login('admin', 'pass');

      await harness.auth.logout();

      // فقط یک بار logout صدا زده شد (بازگشت 401 باعث logout دوم نمی‌شود).
      expect(harness.auth.status, AuthStatus.signedOut);
      expect(h.requests.where(_isLogout), hasLength(1));
      expect(harness.tokens.value, isNull);
    });
  });
}