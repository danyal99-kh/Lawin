// تست SecurityGateProvider: باز شدن به‌ازای بخش، بلیت مشترک، بسته شدن در
// خروج از بخش/خروج کامل، و بی‌اعتبار شدن بلیت‌ها بعد از تغییر رمز.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/pages/shell/app_destination.dart';
import 'package:cafe_book_admin/providers/auth_provider.dart';
import 'package:cafe_book_admin/providers/security_gate_provider.dart';
import 'package:cafe_book_admin/repositories/security_repository.dart';
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

/// Repository امنیتی کنترل‌شونده: رمز درست «secret123»، بلیت‌ها شماره‌دار.
class _FakeSecurityRepository implements SecurityRepository {
  String? password = 'secret123';
  AppFailure? changeError;
  int serial = 0;
  int verifyCalls = 0;
  int changeCalls = 0;

  @override
  Future<Result<String>> verify(String password) async {
    verifyCalls++;
    final p = this.password;
    if (p == null) {
      return Failure(AppFailure.securityNotConfigured());
    }
    if (password != p) {
      return Failure(AppFailure.security('رمز امنیتی صحیح نیست.'));
    }
    return Success('ticket-${++serial}');
  }

  @override
  Future<Result<void>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    changeCalls++;
    if (newPassword.length < 6) {
      return Failure(
          AppFailure.validation('رمز امنیتی باید حداقل ۶ کاراکتر باشد.'));
    }
    final p = password;
    if (p != null && currentPassword != p) {
      return Failure(AppFailure.security('رمز امنیتی صحیح نیست.'));
    }
    if (changeError != null) return Failure(changeError!);
    password = newPassword;
    return const Success(null);
  }
}

class _Harness {
  _Harness() {
    tokens = _MemoryTokens();
    api = ApiClient(tokens,
        client: MockClient((req) async => http.Response('{}', 200)));
    auth = AuthProvider(api, tokens);
    repo = _FakeSecurityRepository();
    gate = SecurityGateProvider(auth: auth, repository: repo, api: api);
  }

  late final _MemoryTokens tokens;
  late final ApiClient api;
  late final AuthProvider auth;
  late final _FakeSecurityRepository repo;
  late final SecurityGateProvider gate;

  void dispose() {
    gate.dispose();
    auth.dispose();
  }
}

void main() {
  test('starts locked with no ticket', () {
    final h = _Harness();
    addTearDown(h.dispose);

    expect(h.gate.isLocked(SecuritySection.accounting), isTrue);
    expect(h.gate.isLocked(SecuritySection.reports), isTrue);
    expect(h.gate.ticket, isNull);
  });

  test('a correct password unlocks the section and stores a shared ticket',
      () async {
    final h = _Harness();
    addTearDown(h.dispose);

    final failure =
        await h.gate.unlock(SecuritySection.accounting, 'secret123');

    expect(failure, isNull);
    expect(h.gate.isLocked(SecuritySection.accounting), isFalse);
    expect(h.gate.ticket, 'ticket-1');
    // گزارش‌ها با همین رمز هنوز باز نشده‌اند.
    expect(h.gate.isLocked(SecuritySection.reports), isTrue);
  });

  test('a wrong password keeps the section locked and returns a failure',
      () async {
    final h = _Harness();
    addTearDown(h.dispose);

    final failure = await h.gate.unlock(SecuritySection.accounting, 'wrong');

    expect(failure, isNotNull);
    expect(failure?.type, FailureType.security);
    expect(h.gate.isLocked(SecuritySection.accounting), isTrue);
    expect(h.gate.ticket, isNull);
  });

  test('no configured password reports securityNotConfigured and stays locked',
      () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.repo.password = null;

    final failure = await h.gate.unlock(SecuritySection.accounting, 'x');

    expect(failure?.type, FailureType.securityNotConfigured);
    expect(h.gate.isLocked(SecuritySection.accounting), isTrue);
  });

  test('sections are independent: unlocking one does not unlock the other',
      () async {
    final h = _Harness();
    addTearDown(h.dispose);

    await h.gate.unlock(SecuritySection.accounting, 'secret123');

    expect(h.gate.isLocked(SecuritySection.reports), isTrue);
    await h.gate.unlock(SecuritySection.reports, 'secret123');
    expect(h.gate.isLocked(SecuritySection.reports), isFalse);
    // بلیت مشترک است.
    expect(h.gate.ticket, 'ticket-2');
  });

  test('leaving a financial section re-locks it but keeps the other open',
      () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.gate.unlock(SecuritySection.accounting, 'secret123');
    await h.gate.unlock(SecuritySection.reports, 'secret123');

    h.gate.invalidate(SecuritySection.accounting);

    expect(h.gate.isLocked(SecuritySection.accounting), isTrue);
    expect(h.gate.isLocked(SecuritySection.reports), isFalse);
    // چون گزارش‌ها هنوز بازند، بلیت مشترک نگه داشته می‌شود.
    expect(h.gate.ticket, 'ticket-2');
  });

  test('closing the last open section drops the ticket', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.gate.unlock(SecuritySection.accounting, 'secret123');

    h.gate.invalidate(SecuritySection.accounting);

    expect(h.gate.isLocked(SecuritySection.accounting), isTrue);
    expect(h.gate.ticket, isNull);
  });

  test('signing out clears every financial access', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.auth.login('admin', 'pass');
    await h.gate.unlock(SecuritySection.accounting, 'secret123');
    await h.gate.unlock(SecuritySection.reports, 'secret123');
    expect(h.gate.isLocked(SecuritySection.accounting), isFalse);

    await h.auth.logout();

    expect(h.gate.isLocked(SecuritySection.accounting), isTrue);
    expect(h.gate.isLocked(SecuritySection.reports), isTrue);
    expect(h.gate.ticket, isNull);
  });

  test('a successful password change invalidates all previous tickets',
      () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.gate.unlock(SecuritySection.accounting, 'secret123');
    expect(h.gate.ticket, isNotNull);

    final failure = await h.gate.changePassword(
      currentPassword: 'secret123',
      newPassword: 'safe-pass-2000',
    );

    expect(failure, isNull);
    expect(h.gate.isLocked(SecuritySection.accounting), isTrue);
    expect(h.gate.ticket, isNull);
    expect(h.repo.password, 'safe-pass-2000');
  });

  test('a failed password change keeps the open access', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.gate.unlock(SecuritySection.accounting, 'secret123');
    expect(h.gate.ticket, 'ticket-1');

    final failure = await h.gate.changePassword(
      currentPassword: 'wrong',
      newPassword: 'safe-pass-2000',
    );

    expect(failure, isNotNull);
    expect(failure?.type, FailureType.security);
    expect(h.gate.isLocked(SecuritySection.accounting), isFalse);
    expect(h.gate.ticket, 'ticket-1');
  });

  test('storeTicket keeps a fresh sliding ticket from the server', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.gate.unlock(SecuritySection.accounting, 'secret123');

    h.gate.storeTicket('ticket-refreshed');

    expect(h.gate.ticket, 'ticket-refreshed');
    // مقدار یکسان/خالی بی‌اثر است.
    h.gate.storeTicket('ticket-refreshed');
    h.gate.storeTicket('');
    expect(h.gate.ticket, 'ticket-refreshed');
  });

  test('sectionOf maps destinations to their financial section', () {
    expect(sectionOf(AppDestination.accounting), SecuritySection.accounting);
    expect(sectionOf(AppDestination.expenses), SecuritySection.accounting);
    expect(sectionOf(AppDestination.reports), SecuritySection.reports);
    expect(sectionOf(AppDestination.dashboard), isNull);
    expect(sectionOf(AppDestination.settings), isNull);
    expect(sectionOf(AppDestination.tables), isNull);
  });
}