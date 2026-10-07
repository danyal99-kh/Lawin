// تست کارت «رمز امنیتی» در تنظیمات: تعیین برای اولین بار، تغییر با رمز فعلی،
// خطاهای سمت کلاینت (کوتاه/تکرار) و پیام خطای سرور — همه با Repository ساختگی.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/pages/settings/widgets/security_settings_card.dart';
import 'package:cafe_book_admin/providers/auth_provider.dart';
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

class _FakeSecurityRepository implements SecurityRepository {
  String? password = 'secret123';
  int changeCalls = 0;
  final List<({String? current, String newPassword})> calls = [];

  @override
  Future<Result<String>> verify(String password) async =>
      const Success('ticket-1');

  @override
  Future<Result<void>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    changeCalls++;
    calls.add((current: currentPassword, newPassword: newPassword));
    final p = password;
    if (p != null && currentPassword != p) {
      return Failure(AppFailure.security('رمز امنیتی صحیح نیست.'));
    }
    password = newPassword;
    return const Success(null);
  }
}

Future<void> _pumpCard(
  WidgetTester tester, {
  _FakeSecurityRepository? repository,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final tokens = _MemoryTokens();
  final api = ApiClient(tokens,
      client: MockClient((req) async => http.Response('{}', 200)));
  final auth = AuthProvider(api, tokens);
  final repo = repository ?? _FakeSecurityRepository();
  final gate = SecurityGateProvider(auth: auth, repository: repo, api: api);
  addTearDown(() {
    gate.dispose();
    auth.dispose();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SecurityGateProvider>.value(value: gate),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SecuritySettingsCard()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saves a first-time password without a current one',
      (tester) async {
    final repo = _FakeSecurityRepository();
    await _pumpCard(tester, repository: repo);
    repo.password = null; // اولین بار: هنوز رمزی نیست.

    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز فعلی'), '');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز جدید'), 'secret-1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'تکرار رمز جدید'), 'secret-1');
    await tester.tap(find.text('ذخیره رمز امنیتی'));
    await tester.pumpAndSettle();

    expect(repo.changeCalls, 1);
    expect(repo.calls.single.current, '');
    expect(repo.calls.single.newPassword, 'secret-1');
    expect(find.text('رمز امنیتی ذخیره شد.'), findsOneWidget);
  });

  testWidgets('changes an existing password with the current password',
      (tester) async {
    final repo = _FakeSecurityRepository();
    await _pumpCard(tester, repository: repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز فعلی'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز جدید'), 'new-pass-2026');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'تکرار رمز جدید'), 'new-pass-2026');
    await tester.tap(find.text('ذخیره رمز امنیتی'));
    await tester.pumpAndSettle();

    expect(repo.calls.single.current, 'secret123');
    expect(repo.calls.single.newPassword, 'new-pass-2026');
    expect(find.text('رمز امنیتی ذخیره شد.'), findsOneWidget);
  });

  testWidgets('rejects a short password without calling the repository',
      (tester) async {
    final repo = _FakeSecurityRepository();
    await _pumpCard(tester, repository: repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز فعلی'), 'secret123');
    await tester.enterText(find.widgetWithText(TextFormField, 'رمز جدید'), '123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'تکرار رمز جدید'), '123');
    await tester.tap(find.text('ذخیره رمز امنیتی'));
    await tester.pumpAndSettle();

    expect(repo.changeCalls, 0);
    expect(find.text('رمز امنیتی باید حداقل ۶ کاراکتر باشد.'), findsOneWidget);
  });

  testWidgets('rejects a mismatching confirmation', (tester) async {
    final repo = _FakeSecurityRepository();
    await _pumpCard(tester, repository: repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز فعلی'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز جدید'), 'new-pass-2026');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'تکرار رمز جدید'), 'other-pass');
    await tester.tap(find.text('ذخیره رمز امنیتی'));
    await tester.pumpAndSettle();

    expect(repo.changeCalls, 0);
    expect(find.text('تکرار رمز با رمز جدید یکسان نیست.'), findsOneWidget);
  });

  testWidgets('shows the server message when the current password is wrong',
      (tester) async {
    final repo = _FakeSecurityRepository();
    await _pumpCard(tester, repository: repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز فعلی'), 'wrong-one');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز جدید'), 'new-pass-2026');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'تکرار رمز جدید'), 'new-pass-2026');
    await tester.tap(find.text('ذخیره رمز امنیتی'));
    await tester.pumpAndSettle();

    expect(repo.changeCalls, 1);
    expect(find.text('رمز امنیتی صحیح نیست.'), findsOneWidget);
    expect(find.text('رمز امنیتی ذخیره شد.'), findsNothing);
  });
}