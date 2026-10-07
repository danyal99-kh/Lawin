// تست کارت «وضعیت کافه»: نمایش باز/بسته، دکمه‌ی معکوس، وضعیت خطا، پیام
// SnackBar و (برای بستن) دیالوگ تأیید + خروج کامل از حساب. همه‌چیز با
// Repository ساختگی، بدون شبکه.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/core/utils/persian_format.dart';
import 'package:cafe_book_admin/models/cafe_status.dart';
import 'package:cafe_book_admin/pages/dashboard/widgets/cafe_status_card.dart';
import 'package:cafe_book_admin/providers/auth_provider.dart';
import 'package:cafe_book_admin/providers/cafe_status_provider.dart';
import 'package:cafe_book_admin/repositories/cafe_status_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// TokenStorage خالی درست‌وحسابی (بدون وابستگی به پلتفرم).
class _MemoryTokens implements TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

/// Repository ساختگی که واقعاً باز/بسته می‌کند، مثل Mock واقعی.
class _FakeRepository implements CafeStatusRepository {
  _FakeRepository(this.status);
  CafeStatus status;

  @override
  Future<Result<CafeStatus>> getStatus() async => Success(status);

  @override
  Future<Result<CafeStatus>> open() async {
    status = const CafeStatus(isOpen: true, openedAt: null, closedAt: null);
    return Success(status);
  }

  @override
  Future<Result<CafeStatus>> close() async {
    status = const CafeStatus(isOpen: false, openedAt: null, closedAt: null);
    return Success(status);
  }
}

/// Repository ساختگی که همیشه خطا می‌دهد.
class _FailingRepository implements CafeStatusRepository {
  @override
  Future<Result<CafeStatus>> getStatus() async =>
      Failure(AppFailure.network());

  @override
  Future<Result<CafeStatus>> open() async => Failure(AppFailure.network());

  @override
  Future<Result<CafeStatus>> close() async => Failure(AppFailure.network());
}

/// Repository ساختگی که load موفق است ولی بستن شکست می‌خورد (مثلاً سرور خطا داد).
class _CloseFailsRepository implements CafeStatusRepository {
  @override
  Future<Result<CafeStatus>> getStatus() async =>
      const Success(CafeStatus(isOpen: true));

  @override
  Future<Result<CafeStatus>> open() async =>
      const Success(CafeStatus(isOpen: true));

  @override
  Future<Result<CafeStatus>> close() async => Failure(AppFailure.network());
}

/// AuthProvider واقعی با سرویس‌گیرنده‌ی ساختگی که همیشه 200 برمی‌گرداند.
class AuthHarness {
  final tokens = _MemoryTokens();
  late final AuthProvider auth;
  late final ApiClient api;

  AuthHarness() {
    api = ApiClient(tokens,
        client: MockClient((req) async => http.Response('{}', 200)));
    auth = AuthProvider(api, tokens);
  }

  void dispose() => auth.dispose();
}

Future<CafeStatusProvider> pumpCard(
  WidgetTester tester,
  CafeStatusRepository repository, {
  AuthHarness? authHarness,
}) async {
  final provider = CafeStatusProvider(repository);
  addTearDown(provider.dispose);
  await provider.load();
  final harness = authHarness ?? AuthHarness();
  // وقتی خودمان ساختیم‌اش dispose می‌کنیم؛ وگرنه تستِ صاحب‌اش این کار را می‌کند.
  if (authHarness == null) addTearDown(harness.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: harness.tokens),
        Provider<ApiClient>.value(value: harness.api),
        ChangeNotifierProvider<AuthProvider>.value(value: harness.auth),
        ChangeNotifierProvider<CafeStatusProvider>.value(value: provider),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: CafeStatusCard()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  final openedAt = DateTime(2026, 10, 6, 9, 21);

  testWidgets('a closed cafe shows the close state and the open button',
      (tester) async {
    await pumpCard(tester, _FakeRepository(const CafeStatus(isOpen: false)));

    expect(find.text('وضعیت کافه'), findsOneWidget);
    expect(find.text('کافه بسته است'), findsOneWidget);
    expect(find.text('هنوز فعالیتی ثبت نشده'), findsOneWidget);
    expect(find.text('باز کردن کافه'), findsOneWidget);
    expect(find.text('بستن کافه'), findsNothing);
  });

  testWidgets('an open cafe shows the open time and the close button',
      (tester) async {
    await pumpCard(
      tester,
      _FakeRepository(CafeStatus(isOpen: true, openedAt: openedAt)),
    );

    expect(find.text('کافه فعال است'), findsOneWidget);
    expect(find.text('شروع فعالیت'), findsOneWidget);
    expect(find.text(PersianFormat.time(openedAt)), findsOneWidget);
    expect(find.text('بستن کافه'), findsOneWidget);
    expect(find.text('باز کردن کافه'), findsNothing);
  });

  testWidgets('a closed cafe keeps last activity instead of a placeholder',
      (tester) async {
    await pumpCard(
      tester,
      _FakeRepository(
        CafeStatus(isOpen: false, openedAt: openedAt, closedAt: openedAt),
      ),
    );

    expect(find.text('آخرین فعالیت'), findsOneWidget);
    expect(find.text(PersianFormat.time(openedAt)), findsOneWidget);
    expect(find.text('هنوز فعالیتی ثبت نشده'), findsNothing);
  });

  testWidgets('opening the cafe flips the card and confirms with a snack',
      (tester) async {
    await pumpCard(tester, _FakeRepository(const CafeStatus(isOpen: false)));

    await tester.tap(find.text('باز کردن کافه'));
    await tester.pumpAndSettle();

    expect(find.text('کافه فعال است'), findsOneWidget);
    expect(find.text('بستن کافه'), findsOneWidget);
    expect(find.text('کافه با موفقیت باز شد'), findsOneWidget);
  });

  testWidgets('closing asks for confirmation before doing anything',
      (tester) async {
    final harness = AuthHarness();
    addTearDown(harness.dispose);
    await pumpCard(
      tester,
      _FakeRepository(CafeStatus(isOpen: true, openedAt: openedAt)),
    );

    await tester.tap(find.text('بستن کافه'));
    await tester.pumpAndSettle();

    // دیالوگ تأیید باز شده؛ هنوز کافه باز است.
    expect(find.text('بستن کافه'), findsWidgets);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('کافه فعال است'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog keeps the cafe open and signed in',
      (tester) async {
    await pumpCard(
      tester,
      _FakeRepository(CafeStatus(isOpen: true, openedAt: openedAt)),
    );

    await tester.tap(find.text('بستن کافه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('کافه فعال است'), findsOneWidget);
  });

  testWidgets('confirming close flips the card and signs out completely',
      (tester) async {
    final harness = AuthHarness();
    addTearDown(harness.dispose);
    // یک توکن از «قبل» در حافظه هست تا تسک خروج واقعاً فراخوانی شود.
    await harness.tokens.write('old-token');
    await pumpCard(
      tester,
      _FakeRepository(CafeStatus(isOpen: true, openedAt: openedAt)),
      authHarness: harness,
    );

    await tester.tap(find.text('بستن کافه'));
    await tester.pumpAndSettle();
    // دکمه‌ی «بستن کافه» داخل دیالوگ (FilledButton) را انتخاب می‌کنیم.
    await tester.tap(find.widgetWithText(FilledButton, 'بستن کافه'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('کافه بسته است'), findsOneWidget);
    expect(harness.auth.status, AuthStatus.signedOut);
    expect(harness.tokens.value, isNull, reason: 'توکن باید از حافظه‌ی امن پاک شود');
  });

  testWidgets('a failed close keeps the session and reports a snack',
      (tester) async {
    final harness = AuthHarness();
    addTearDown(harness.dispose);
    await harness.tokens.write('old-token');
    await pumpCard(tester, _CloseFailsRepository(), authHarness: harness);

    await tester.tap(find.text('بستن کافه'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'بستن کافه'));
    await tester.pumpAndSettle();

    expect(find.text('تغییر وضعیت کافه انجام نشد'), findsOneWidget);
    expect(find.text('کافه فعال است'), findsOneWidget);
    expect(harness.auth.status, isNot(AuthStatus.signedOut));
    expect(harness.tokens.value, 'old-token');
  });

  testWidgets('a load failure shows the retry action, not a fake state',
      (tester) async {
    await pumpCard(tester, _FailingRepository());

    expect(find.text('تلاش مجدد'), findsOneWidget);
    expect(find.text('کافه فعال است'), findsNothing);
    expect(find.text('کافه بسته است'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed toggle keeps the state and reports a snack',
      (tester) async {
    final provider = CafeStatusProvider(_FailingRepository());
    addTearDown(provider.dispose);
    await provider.load();
    // بعد از خطای load هم کارت باید دکمه‌ی تلاش را نشان دهد؛ این تست
    // مطمئن می‌شود خطای توگل پیام رد نمی‌شود.
    final harness = AuthHarness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TokenStorage>.value(value: harness.tokens),
          Provider<ApiClient>.value(value: harness.api),
          ChangeNotifierProvider<AuthProvider>.value(value: harness.auth),
          ChangeNotifierProvider<CafeStatusProvider>.value(value: provider),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: CafeStatusCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}