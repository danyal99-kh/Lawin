// تست ویجت دروازه‌ی امنیتی: گیت بسته → صفحه‌ی رمز؛ رمز غلط → خطا؛ رمز درست →
// محتوا آشکار می‌شود؛ و «هنوز تنظیم نشده» → راهنما + دکمه‌ی تنظیمات.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/pages/security/security_gate.dart';
import 'package:cafe_book_admin/pages/shell/app_destination.dart';
import 'package:cafe_book_admin/providers/auth_provider.dart';
import 'package:cafe_book_admin/providers/navigation_provider.dart';
import 'package:cafe_book_admin/providers/security_gate_provider.dart';
import 'package:cafe_book_admin/repositories/security_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

class _MemoryTokens implements TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

/// رمز درست: «secret123»؛ تا وقتی set نشده باشد کد securityNotConfigured.
class _FakeSecurityRepository implements SecurityRepository {
  String? password = 'secret123';

  @override
  Future<Result<String>> verify(String password) async {
    final p = this.password;
    if (p == null) return Failure(AppFailure.securityNotConfigured());
    return password == p
        ? Success('ticket-1')
        : Failure(AppFailure.security('رمز امنیتی صحیح نیست.'));
  }

  @override
  Future<Result<void>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async =>
      const Success(null);
}

Future<void> _pumpGate(
  WidgetTester tester, {
  SecuritySection section = SecuritySection.accounting,
  _FakeSecurityRepository? repository,
  NavigationProvider? navigation,
}) async {
  final tokens = _MemoryTokens();
  final api = ApiClient(tokens,
      client: MockClient((req) async => http.Response('{}', 200)));
  final auth = AuthProvider(api, tokens);
  final gate = SecurityGateProvider(
    auth: auth,
    repository: repository ?? _FakeSecurityRepository(),
    api: api,
  );
  final nav = navigation ?? NavigationProvider();
  addTearDown(() {
    gate.dispose();
    auth.dispose();
    nav.dispose();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SecurityGateProvider>.value(value: gate),
        ChangeNotifierProvider<NavigationProvider>.value(value: nav),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SecurityGate(
              section: section,
              child: const Text('محتوای مالی باز شد'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a locked section shows the password prompt, not the content',
      (tester) async {
    await _pumpGate(tester);

    expect(find.text('رمز امنیتی حسابداری و هزینه‌ها'), findsOneWidget);
    expect(find.text('محتوای مالی باز شد'), findsNothing);
    expect(find.text('ورود'), findsOneWidget);
  });

  testWidgets('a wrong password shows an error and stays locked',
      (tester) async {
    await _pumpGate(tester);

    await tester.enterText(find.byType(TextField), 'wrong-pass');
    await tester.tap(find.text('ورود'));
    await tester.pumpAndSettle();

    expect(find.text('رمز امنیتی صحیح نیست.'), findsOneWidget);
    expect(find.text('محتوای مالی باز شد'), findsNothing);
  });

  testWidgets('a correct password reveals the child widget', (tester) async {
    await _pumpGate(tester);

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('ورود'));
    await tester.pumpAndSettle();

    expect(find.text('محتوای مالی باز شد'), findsOneWidget);
    expect(find.text('رمز امنیتی حسابداری و هزینه‌ها'), findsNothing);
  });

  testWidgets('reports section shows its own title', (tester) async {
    await _pumpGate(tester, section: SecuritySection.reports);

    expect(find.text('رمز امنیتی گزارش‌ها'), findsOneWidget);
  });

  testWidgets('unlocking accounting does not unlock reports', (tester) async {
    final nav = NavigationProvider();
    await _pumpGate(tester, navigation: nav);

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('ورود'));
    await tester.pumpAndSettle();

    expect(find.text('محتوای مالی باز شد'), findsOneWidget);
    final gate = Provider.of<SecurityGateProvider>(
        tester.element(find.byType(SecurityGate)),
        listen: false);
    expect(gate.isLocked(SecuritySection.reports), isTrue);
  });

  testWidgets('not-configured password shows guidance and a settings shortcut',
      (tester) async {
    final repo = _FakeSecurityRepository()..password = null;
    final nav = NavigationProvider();
    await _pumpGate(tester, repository: repo, navigation: nav);

    await tester.enterText(find.byType(TextField), 'anything');
    await tester.tap(find.text('ورود'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('رمز امنیتی هنوز تنظیم نشده است'), findsOneWidget);
    expect(find.text('رفتن به تنظیمات'), findsOneWidget);

    await tester.tap(find.text('رفتن به تنظیمات'));
    await tester.pumpAndSettle();

    expect(nav.current, AppDestination.settings);
  });
}