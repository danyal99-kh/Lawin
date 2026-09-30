import '../core/errors/result.dart';
import '../models/app_settings.dart';

abstract interface class SettingsRepository {
  Future<Result<AppSettings>> getSettings();
  Future<Result<AppSettings>> update(AppSettingsDraft draft);
}
