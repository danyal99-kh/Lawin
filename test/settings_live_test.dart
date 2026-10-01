// تست سرتاسری واقعی: ApiSettingsRepository → ApiClient → Django → دیتابیس.
// نیازمند اجرای Django روی 127.0.0.1:8000 و توکن معتبر در LAWIN_TEST_TOKEN.
//
//   cd Lawin && DJANGO_DEBUG=1 DJANGO_SECRET_KEY=... python manage.py runserver 127.0.0.1:8000 --noreload
//   flutter test test/settings_live_test.dart --dart-define=LAWIN_TEST_TOKEN=<token>
//
// اگر توکن داده نشود، تست‌ها skip می‌شوند تا در CI شکست نخورند.
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/api_endpoints.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/app_settings.dart';
import 'package:cafe_book_admin/repositories/api/api_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _token = String.fromEnvironment('LAWIN_TEST_TOKEN');

class _StaticTokenStorage implements TokenStorage {
  _StaticTokenStorage(this._token);
  final String _token;
  @override
  Future<String?> read() async => _token;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  if (_token.isEmpty) {
    test('skipped: set LAWIN_TEST_TOKEN', () {});
    return;
  }

  late ApiSettingsRepository repo;

  setUp(() {
    repo = ApiSettingsRepository(ApiClient(_StaticTokenStorage(_token)));
  });

  test('GET /settings/ returns a parsable singleton', () async {
    final result = await repo.getSettings();
    expect(result.failureOrNull, isNull);
    final s = result.dataOrNull!;
    expect(s.cafeName, isNotEmpty);
    expect(s.autoPrintBarOrders, isA<bool>());
    expect(s.lowStockAlertEnabled, isA<bool>());
  });

  test('PATCH /settings/ is partial and trims', () async {
    final before = (await repo.getSettings()).dataOrNull!;

    // فقط phone می‌رود؛ بقیه‌ی فیلدها نباید تغییر کنند.
    const phone = '02100000001';
    final patched = await repo.update(AppSettingsDraft(
      cafeName: before.cafeName,
      address: before.address,
      phone: '  $phone  ',
      receiptFooterNote: before.receiptFooterNote,
      autoPrintBarOrders: before.autoPrintBarOrders,
      lowStockAlertEnabled: before.lowStockAlertEnabled,
    ));
    expect(patched.failureOrNull, isNull);
    expect(patched.dataOrNull!.phone, phone);
    expect(patched.dataOrNull!.cafeName, before.cafeName);
    expect(patched.dataOrNull!.address, before.address);

    // برگرداندن به حالت اول
    await repo.update(AppSettingsDraft(
      cafeName: before.cafeName,
      address: before.address,
      phone: before.phone,
      receiptFooterNote: before.receiptFooterNote,
      autoPrintBarOrders: before.autoPrintBarOrders,
      lowStockAlertEnabled: before.lowStockAlertEnabled,
    ));
  });

  test('PATCH /settings/ rejects a blank name with a Persian message',
      () async {
    final before = (await repo.getSettings()).dataOrNull!;
    final bad = await repo.update(AppSettingsDraft(cafeName: '   '));
    expect(bad.failureOrNull?.type.name, 'validation');
    expect(bad.failureOrNull?.userMessage, 'نام کافه را وارد کنید.');
    expect((await repo.getSettings()).dataOrNull!.cafeName, before.cafeName);
  });

  test('PATCH /settings/ rejects a non-boolean toggle', () async {
    final api = ApiClient(_StaticTokenStorage(_token));
    final bad = await api.patch(
      ApiEndpoints.settings,
      (j) => AppSettings.fromJson(j as Map<String, dynamic>),
      body: {'auto_print': 'بله'},
    );
    expect(bad.failureOrNull?.type.name, 'validation');
  });

  test('GET /settings/welcome/ keeps the existing contract', () async {
    final result = await repo.getWelcomeSettings();
    expect(result.failureOrNull, isNull);
    final w = result.dataOrNull!;
    expect(w.title, isNotEmpty);
    expect(w.enabled, isA<bool>());
    expect(w.updatedAt, isNotNull);
  });

  test('PATCH /settings/welcome/ saves title and enabled', () async {
    final before = (await repo.getWelcomeSettings()).dataOrNull!;
    final patched = await repo.updateWelcomeSettings(WelcomeSettingsDraft(
      title: '  عنوان تست زنده  ',
      message: before.message,
      enabled: !before.enabled,
    ));
    expect(patched.failureOrNull, isNull);
    expect(patched.dataOrNull!.title, 'عنوان تست زنده');
    expect(patched.dataOrNull!.enabled, !before.enabled);

    await repo.updateWelcomeSettings(WelcomeSettingsDraft(
      title: before.title,
      message: before.message,
      enabled: before.enabled,
    ));
    final restored = (await repo.getWelcomeSettings()).dataOrNull!;
    expect(restored.title, before.title);
    expect(restored.enabled, before.enabled);
  });

  test('PATCH /settings/welcome/ rejects a blank title', () async {
    final bad = await repo
        .updateWelcomeSettings(const WelcomeSettingsDraft(title: ' ', message: 'x'));
    expect(bad.failureOrNull?.type.name, 'validation');
    expect(bad.failureOrNull?.userMessage, 'عنوان خوشامدگویی را وارد کنید.');
  });

  test('a bad token is rejected as unauthorized', () async {
    final bad = await ApiSettingsRepository(ApiClient(_StaticTokenStorage('nope')))
        .getSettings();
    expect(bad.failureOrNull?.type.name, 'unauthorized');
  });
}
