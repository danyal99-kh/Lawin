import 'package:cafe_book_admin/repositories/settings_repository.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/app_settings.dart';

/// تنظیمات فقط در حافظه نگه‌داری می‌شود (بدون وابستگی به MockDatabase،
/// چون با هیچ Repository دیگری داده مشترک ندارد).
class MockSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings(
    cafeName: 'کافه‌کتاب',
    receiptFooterNote: 'با تشکر از خرید شما 🌿',
  );

  WelcomeSettings _welcome = const WelcomeSettings(
    title: 'به کافه‌کتاب خوش آمدید ☕📚',
    message: 'لحظه‌ای برای خودتان، یک فنجان برای حالتان.',
  );

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  AppFailure? _validate(AppSettingsDraft d) {
    if (d.cafeName.isEmpty) {
      return AppFailure.validation('نام کافه را وارد کنید.');
    }
    if (d.cafeName.length > 60) {
      return AppFailure.validation('نام کافه حداکثر ۶۰ حرف باشد.');
    }
    return null;
  }

  AppFailure? _validateWelcome(WelcomeSettingsDraft d) {
    if (d.title.isEmpty) {
      return AppFailure.validation('عنوان خوشامدگویی را وارد کنید.');
    }
    if (d.title.length > 120) {
      return AppFailure.validation('عنوان خوشامدگویی حداکثر ۱۲۰ حرف باشد.');
    }
    if (d.message.length > 400) {
      return AppFailure.validation('متن خوشامدگویی حداکثر ۴۰۰ حرف باشد.');
    }
    return null;
  }

  @override
  Future<Result<AppSettings>> getSettings() async {
    try {
      await _latency();
      return Success(_settings);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<AppSettings>> update(AppSettingsDraft draft) async {
    try {
      await _latency();
      final d = draft.normalized();
      final invalid = _validate(d);
      if (invalid != null) return Failure(invalid);
      _settings = AppSettings(
        cafeName: d.cafeName,
        address: d.address,
        phone: d.phone,
        receiptFooterNote: d.receiptFooterNote,
        autoPrintBarOrders: d.autoPrintBarOrders,
        lowStockAlertEnabled: d.lowStockAlertEnabled,
      );
      return Success(_settings);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<WelcomeSettings>> getWelcomeSettings() async {
    try {
      await _latency();
      return Success(_welcome);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<WelcomeSettings>> updateWelcomeSettings(
    WelcomeSettingsDraft draft,
  ) async {
    try {
      await _latency();
      final d = draft.normalized();
      final invalid = _validateWelcome(d);
      if (invalid != null) return Failure(invalid);
      _welcome = WelcomeSettings(title: d.title, message: d.message, enabled: d.enabled);
      return Success(_welcome);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
