import 'package:cafe_book_admin/repositories/settings_repository.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repository);

  final SettingsRepository _repository;

  ViewState<AppSettings> _state = const ViewState.initial();
  ViewState<AppSettings> get state => _state;

  /// پیام خوشامدگویی منبع جداگانه‌ای است، پس وضعیت جدا دارد تا خطای یکی
  /// روی دیگری اثر نگذارد.
  ViewState<WelcomeSettings> _welcomeState = const ViewState.initial();
  ViewState<WelcomeSettings> get welcomeState => _welcomeState;

  bool _saving = false;
  bool get saving => _saving;

  bool _savingWelcome = false;
  bool get savingWelcome => _savingWelcome;

  bool _disposed = false;

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<AppSettings>.loading(previous: previous);
    _notify();
    final result = await _repository.getSettings();
    _state = result.when<ViewState<AppSettings>>(
      success: (data) => ViewState<AppSettings>.success(data),
      failure: (f) => ViewState<AppSettings>.error(f, previous: previous),
    );
    _notify();
  }

  Future<void> loadWelcome() async {
    final previous = _welcomeState.data;
    _welcomeState = ViewState<WelcomeSettings>.loading(previous: previous);
    _notify();
    final result = await _repository.getWelcomeSettings();
    _welcomeState = result.when<ViewState<WelcomeSettings>>(
      success: (data) => ViewState<WelcomeSettings>.success(data),
      failure: (f) => ViewState<WelcomeSettings>.error(f, previous: previous),
    );
    _notify();
  }

  /// null یعنی موفق؛ در غیر این صورت خطای قابل‌نمایش.
  Future<AppFailure?> save(AppSettingsDraft draft) async {
    _saving = true;
    _notify();
    final result = await _repository.update(draft);
    AppFailure? failure;
    result.when<void>(
      success: (data) => _state = ViewState<AppSettings>.success(data),
      failure: (f) => failure = f,
    );
    _saving = false;
    _notify();
    return failure;
  }

  /// ذخیره‌ی پیام خوشامدگویی؛ مثل [save] پیام خطا را برمی‌گرداند.
  Future<AppFailure?> saveWelcome(WelcomeSettingsDraft draft) async {
    _savingWelcome = true;
    _notify();
    final result = await _repository.updateWelcomeSettings(draft);
    AppFailure? failure;
    result.when<void>(
      success: (data) => _welcomeState = ViewState<WelcomeSettings>.success(data),
      failure: (f) => failure = f,
    );
    _savingWelcome = false;
    _notify();
    return failure;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
