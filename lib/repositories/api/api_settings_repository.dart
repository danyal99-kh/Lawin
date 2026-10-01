import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/app_settings.dart';
import '../settings_repository.dart';

/// تنظیمات پنل روی Django. دو منبع جدا هستند و جداگانه خوانده/ذخیره می‌شوند:
/// `/settings/` برای اطلاعات کافه و `/settings/welcome/` برای پیام خوشامدگویی.
/// نوشتن هر دو با PATCH جزئی است تا فیلدهای نیامده روی سرور دست‌نخورده بمانند.
class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository(this._api);
  final ApiClient _api;

  static AppSettings _settings(dynamic j) =>
      AppSettings.fromJson(j as Map<String, dynamic>);

  static WelcomeSettings _welcome(dynamic j) =>
      WelcomeSettings.fromJson(j as Map<String, dynamic>);

  static Map<String, dynamic> _body(AppSettingsDraft d) => {
        'name': d.cafeName,
        'address': d.address ?? '',
        'phone': d.phone ?? '',
        'receipt_note': d.receiptFooterNote ?? '',
        'auto_print': d.autoPrintBarOrders,
        'low_stock_alert': d.lowStockAlertEnabled,
      };

  static Map<String, dynamic> _welcomeBody(WelcomeSettingsDraft d) => {
        'title': d.title,
        'message': d.message,
        'enabled': d.enabled,
      };

  @override
  Future<Result<AppSettings>> getSettings() =>
      _api.get(ApiEndpoints.settings, _settings);

  @override
  Future<Result<AppSettings>> update(AppSettingsDraft draft) => _api.patch(
        ApiEndpoints.settings,
        _settings,
        body: _body(draft.normalized()),
      );

  @override
  Future<Result<WelcomeSettings>> getWelcomeSettings() =>
      _api.get(ApiEndpoints.welcomeSettings, _welcome);

  @override
  Future<Result<WelcomeSettings>> updateWelcomeSettings(
    WelcomeSettingsDraft draft,
  ) =>
      _api.patch(
        ApiEndpoints.welcomeSettings,
        _welcome,
        body: _welcomeBody(draft.normalized()),
      );
}
