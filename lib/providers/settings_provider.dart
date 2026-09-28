import 'package:cafe_book_admin/repositories/settings_repository.dart.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repository);

  final SettingsRepository _repository;

  ViewState<AppSettings> _state = const ViewState.initial();
  ViewState<AppSettings> get state => _state;

  bool _saving = false;
  bool get saving => _saving;

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
