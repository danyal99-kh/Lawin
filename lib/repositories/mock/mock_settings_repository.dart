import 'package:cafe_book_admin/repositories/settings_repository.dart.dart';

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
}
