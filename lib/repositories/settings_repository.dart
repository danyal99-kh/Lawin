import '../core/errors/result.dart';
import '../models/app_settings.dart';

abstract interface class SettingsRepository {
  Future<Result<AppSettings>> getSettings();
  Future<Result<AppSettings>> update(AppSettingsDraft draft);

  /// پیام خوشامدگویی منبع جداگانه‌ای است (endpoint و مدل مستقل در Django).
  Future<Result<WelcomeSettings>> getWelcomeSettings();
  Future<Result<WelcomeSettings>> updateWelcomeSettings(
    WelcomeSettingsDraft draft,
  );
}
