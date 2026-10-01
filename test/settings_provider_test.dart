// تست Provider تنظیمات: load / save برای هر دو منبع و رفتار در خطا.
// Repository ساختگی، پس بدون شبکه و بدون MockDatabase.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/utils/view_state.dart';
import 'package:cafe_book_admin/models/app_settings.dart';
import 'package:cafe_book_admin/providers/settings_provider.dart';
import 'package:cafe_book_admin/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _settings = AppSettings(
  cafeName: 'کافه‌کتاب',
  address: 'نشانی',
  receiptFooterNote: 'با تشکر',
);

const _welcome = WelcomeSettings(
  title: 'خوش آمدید',
  message: 'بنشینید.',
);

/// Repository قابل‌کنترل: هر متد یک Result آماده برمی‌گرداند و تست‌ها
/// می‌توانند پاسخ را با [settings] / [welcome] عوض کنند.
class _FakeRepository implements SettingsRepository {
  Result<AppSettings> settings = const Success(_settings);
  Result<WelcomeSettings> welcome = const Success(_welcome);
  AppSettingsDraft? savedDraft;
  WelcomeSettingsDraft? savedWelcome;
  int loadCalls = 0;
  int welcomeLoadCalls = 0;

  @override
  Future<Result<AppSettings>> getSettings() async {
    loadCalls++;
    return settings;
  }

  @override
  Future<Result<AppSettings>> update(AppSettingsDraft draft) async {
    savedDraft = draft;
    return settings;
  }

  @override
  Future<Result<WelcomeSettings>> getWelcomeSettings() async {
    welcomeLoadCalls++;
    return welcome;
  }

  @override
  Future<Result<WelcomeSettings>> updateWelcomeSettings(
    WelcomeSettingsDraft draft,
  ) async {
    savedWelcome = draft;
    return welcome;
  }
}

void main() {
  late _FakeRepository repo;
  late SettingsProvider provider;

  setUp(() {
    repo = _FakeRepository();
    provider = SettingsProvider(repo);
  });
  test('starts as initial with nothing loaded', () {
    expect(provider.state.status, ViewStatus.initial);
    expect(provider.welcomeState.status, ViewStatus.initial);
    expect(provider.saving, isFalse);
    expect(provider.savingWelcome, isFalse);
  });

  group('load', () {
    test('load() fills state and returns the server entity', () async {
      await provider.load();
      expect(provider.state.status, ViewStatus.success);
      expect(provider.state.data?.cafeName, 'کافه‌کتاب');
      expect(repo.loadCalls, 1);
    });

    test('load() keeps previous data and exposes the failure', () async {
      await provider.load();
      repo.settings = Failure(AppFailure.network());
      await provider.load();
      expect(provider.state.status, ViewStatus.error);
      expect(provider.state.failure?.type, FailureType.network);
      expect(provider.state.data?.cafeName, 'کافه‌کتاب'); // داده قبلی حفظ شد
    });

    test('loadWelcome() is independent from load()', () async {
      repo.welcome = Failure(AppFailure.network());
      await provider.load();
      await provider.loadWelcome();
      expect(provider.state.status, ViewStatus.success);
      expect(provider.welcomeState.status, ViewStatus.error);
    });

    test('notifyListeners fires so the page swaps in a spinner', () async {
      var notified = 0;
      provider.addListener(() => notified++);
      await provider.load();
      expect(notified, greaterThanOrEqualTo(2)); // loading + success
    });
  });

  group('save', () {
    test('passes the draft to the repository and stores the response',
        () async {
      const draft = AppSettingsDraft(cafeName: 'کافه دانش', phone: '0211234');
      final failure = await provider.save(draft);
      expect(failure, isNull);
      expect(repo.savedDraft?.cafeName, 'کافه دانش');
      expect(repo.savedDraft?.phone, '0211234');
      expect(provider.saving, isFalse);
      expect(provider.state.data?.cafeName, 'کافه‌کتاب');
    });

    test('returns the failure and leaves state untouched', () async {
      await provider.load();
      final before = provider.state.data;
      repo.settings = Failure(AppFailure.validation('نام کافه را وارد کنید.'));
      final failure = await provider.save(const AppSettingsDraft(cafeName: ''));
      expect(failure?.type, FailureType.validation);
      expect(failure?.userMessage, 'نام کافه را وارد کنید.');
      expect(provider.state.data, same(before));
      expect(provider.state.status, ViewStatus.success);
      expect(provider.saving, isFalse);
    });
  });

  group('saveWelcome', () {
    test('passes the draft and updates the welcome state', () async {
      const draft = WelcomeSettingsDraft(title: '  عنوان تازه  ', message: ' متن ');
      final failure = await provider.saveWelcome(draft);
      expect(failure, isNull);
      expect(repo.savedWelcome?.title, '  عنوان تازه  '); // Draft خام
      expect(provider.welcomeState.status, ViewStatus.success);
      expect(provider.savingWelcome, isFalse);
      // ذخیره‌ی پیام نباید تنظیمات کافه را تغییر دهد
      expect(provider.state.status, ViewStatus.initial);
    });

    test('returns the failure from the server', () async {
      repo.welcome = Failure(
          AppFailure.validation('عنوان خوشامدگویی را وارد کنید.'));
      final failure = await provider.saveWelcome(
          const WelcomeSettingsDraft(title: '', message: 'x'));
      expect(failure?.type, FailureType.validation);
      expect(failure?.userMessage, 'عنوان خوشامدگویی را وارد کنید.');
      expect(provider.welcomeState.status, ViewStatus.initial);
      expect(provider.savingWelcome, isFalse);
    });
  });

  test('does not notify after dispose', () async {
    provider.dispose();
    await provider.load(); // نباید استثنا بدهد
    expect(provider.state.status, ViewStatus.success);
  });
}
