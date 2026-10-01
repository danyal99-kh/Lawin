// تست ویجت صفحه‌ی تنظیمات: نمایش، ویرایش، ذخیره و نمایش خطا برای هر دو بخش
// (اطلاعات کافه و پیام خوشامدگویی).
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/models/app_settings.dart';
import 'package:cafe_book_admin/pages/settings/settings_page.dart';
import 'package:cafe_book_admin/pages/settings/widgets/settings_form.dart';
import 'package:cafe_book_admin/pages/settings/widgets/welcome_settings_card.dart';
import 'package:cafe_book_admin/providers/settings_provider.dart';
import 'package:cafe_book_admin/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _settings = AppSettings(
  cafeName: 'کافه‌کتاب',
  address: 'نشانی کافه',
  phone: '0211234',
  receiptFooterNote: 'با تشکر',
);

const _welcome = WelcomeSettings(title: 'خوش آمدید', message: 'بنشینید.');

/// Repository ساختگی که هر پاسخ را از تست کنترل می‌کند.
class _FakeRepository implements SettingsRepository {
  AppSettings settings = _settings;
  WelcomeSettings welcome = _welcome;
  AppFailure? saveError;
  AppFailure? saveWelcomeError;

  final List<AppSettingsDraft> saved = [];
  final List<WelcomeSettingsDraft> savedWelcome = [];

  @override
  Future<Result<AppSettings>> getSettings() async => Success(settings);

  @override
  Future<Result<AppSettings>> update(AppSettingsDraft draft) async {
    saved.add(draft);
    if (saveError != null) return Failure(saveError!);
    settings = AppSettings(
      cafeName: draft.cafeName,
      address: draft.address,
      phone: draft.phone,
      receiptFooterNote: draft.receiptFooterNote,
      autoPrintBarOrders: draft.autoPrintBarOrders,
      lowStockAlertEnabled: draft.lowStockAlertEnabled,
    );
    return Success(settings);
  }

  @override
  Future<Result<WelcomeSettings>> getWelcomeSettings() async => Success(welcome);

  @override
  Future<Result<WelcomeSettings>> updateWelcomeSettings(
    WelcomeSettingsDraft draft,
  ) async {
    savedWelcome.add(draft);
    if (saveWelcomeError != null) return Failure(saveWelcomeError!);
    welcome = WelcomeSettings(
      title: draft.title,
      message: draft.message,
      enabled: draft.enabled,
    );
    return Success(welcome);
  }
}

class _AlwaysFailingRepository implements SettingsRepository {
  @override
  Future<Result<AppSettings>> getSettings() async =>
      Failure(AppFailure.network());
  @override
  Future<Result<AppSettings>> update(AppSettingsDraft draft) async =>
      Failure(AppFailure.network());
  @override
  Future<Result<WelcomeSettings>> getWelcomeSettings() async =>
      Failure(AppFailure.network());
  @override
  Future<Result<WelcomeSettings>> updateWelcomeSettings(
    WelcomeSettingsDraft draft,
  ) async =>
      Failure(AppFailure.network());
}

Future<SettingsProvider> pumpSettings(
  WidgetTester tester,
  SettingsRepository repository,
) async {
  // صفحه‌ی تنظیمات بلند است؛ پنجره‌ی تست را بزرگ می‌کنیم تا دکمه‌ها داخل
  // کادر باشند و tap بدون اسکرول به آن‌ها بخورد.
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final provider = SettingsProvider(repository);
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: provider,
      child: const MaterialApp(
        // در برنامه واقعی Scaffold را AppShell می‌دهد؛ اینجا هم لازم است تا
        // SnackBar بعد از ذخیره جایی برای نمایش داشته باشد.
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SettingsPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

/// قبل از tap اسکرول می‌کند تا دکمه حتماً hit-test شود.
Future<void> tapButton(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads both resources on open', (tester) async {
    final repo = _FakeRepository();
    await pumpSettings(tester, repo);

    expect(find.byType(SettingsForm), findsOneWidget);
    expect(find.byType(WelcomeSettingsCard), findsOneWidget);
    expect(find.text('کافه‌کتاب'), findsOneWidget);
    expect(find.text('خوش آمدید'), findsOneWidget);
    expect(find.text('بنشینید.'), findsOneWidget);
  });

  testWidgets('saves the cafe details through the provider', (tester) async {
    final repo = _FakeRepository();
    final provider = await pumpSettings(tester, repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'نام کافه'), 'کافه دانش');
    await tapButton(tester, 'ذخیره تنظیمات');

    expect(repo.saved, hasLength(1));
    expect(repo.saved.single.cafeName, 'کافه دانش');
    expect(provider.state.data?.cafeName, 'کافه دانش');
    expect(find.text('تنظیمات ذخیره شد.'), findsOneWidget);
  });

  testWidgets('blocks an empty cafe name and does not call the repository',
      (tester) async {
    final repo = _FakeRepository();
    await pumpSettings(tester, repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'نام کافه'), '   ');
    await tapButton(tester, 'ذخیره تنظیمات');

    expect(repo.saved, isEmpty);
    expect(find.text('نام کافه را وارد کنید.'), findsOneWidget);
  });

  testWidgets('saves the welcome message and can disable it', (tester) async {
    final repo = _FakeRepository();
    final provider = await pumpSettings(tester, repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'عنوان'), '  عنوان تازه  ');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'متن خوشامدگویی'), ' متن تازه ');
    await tester.ensureVisible(find.text('نمایش صفحه‌ی خوشامدگویی'));
    await tester.tap(find.text('نمایش صفحه‌ی خوشامدگویی'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'ذخیره پیام خوشامدگویی');

    expect(repo.savedWelcome, hasLength(1));
    // Draft خام است؛ بریدن فاصله‌ها کار Repository است.
    expect(repo.savedWelcome.single.title, '  عنوان تازه  ');
    expect(repo.savedWelcome.single.enabled, isFalse);
    expect(provider.welcomeState.data?.title, '  عنوان تازه  ');
    expect(find.text('پیام خوشامدگویی ذخیره شد.'), findsOneWidget);
  });

  testWidgets('blocks an empty welcome title', (tester) async {
    final repo = _FakeRepository();
    await pumpSettings(tester, repo);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'عنوان'), '');
    await tapButton(tester, 'ذخیره پیام خوشامدگویی');

    expect(repo.savedWelcome, isEmpty);
    expect(find.text('عنوان خوشامدگویی را وارد کنید.'), findsOneWidget);
  });

  testWidgets('shows the server message when saving settings fails',
      (tester) async {
    final repo = _FakeRepository()
      ..saveError = AppFailure.validation('نام کافه را وارد کنید.');
    await pumpSettings(tester, repo);

    await tapButton(tester, 'ذخیره تنظیمات');

    expect(find.text('نام کافه را وارد کنید.'), findsOneWidget);
  });

  testWidgets('shows the server message when saving the welcome fails',
      (tester) async {
    final repo = _FakeRepository()
      ..saveWelcomeError =
          AppFailure.validation('عنوان خوشامدگویی را وارد کنید.');
    await pumpSettings(tester, repo);

    await tapButton(tester, 'ذخیره پیام خوشامدگویی');

    expect(find.text('عنوان خوشامدگویی را وارد کنید.'), findsOneWidget);
  });

  testWidgets('a failing welcome load does not hide the cafe form',
      (tester) async {
    final provider = SettingsProvider(_FakeRepository());
    final broken = _WelcomeFailsRepository();
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: provider,
        child: MaterialApp(
          home: ChangeNotifierProvider<SettingsProvider>.value(
            value: broken.provider,
            child: const Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: SettingsPage(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsForm), findsOneWidget);
    expect(find.text('اتصال به سرور برقرار نشد. اینترنت یا شبکه را بررسی کنید.'),
        findsOneWidget);
  });

  testWidgets('shows an error view when the whole page fails to load',
      (tester) async {
    await pumpSettings(tester, _AlwaysFailingRepository());
    expect(find.byType(SettingsForm), findsNothing);
    expect(find.byType(WelcomeSettingsCard), findsNothing);
  });
}

/// فقط بخش خوشامدگویی شکست می‌خورد؛ تنظیمات کافه سالم است.
class _WelcomeFailsRepository implements SettingsRepository {
  _WelcomeFailsRepository() {
    provider = SettingsProvider(this);
  }

  late final SettingsProvider provider;

  @override
  Future<Result<AppSettings>> getSettings() async => Success(_settings);

  @override
  Future<Result<AppSettings>> update(AppSettingsDraft draft) async =>
      Success(_settings);

  @override
  Future<Result<WelcomeSettings>> getWelcomeSettings() async =>
      Failure(AppFailure.network());

  @override
  Future<Result<WelcomeSettings>> updateWelcomeSettings(
    WelcomeSettingsDraft draft,
  ) async =>
      Failure(AppFailure.network());
}
