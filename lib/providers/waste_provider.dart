// lib/providers/waste_provider.dart
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/waste.dart';
import '../repositories/waste_repository.dart';

/// تاریخچه‌ی ضایعات و ثبت ضایعات جدید.
class WasteProvider extends ChangeNotifier {
  WasteProvider(this._repository);

  final WasteRepository _repository;

  ViewState<List<Waste>> _state = const ViewState.initial();
  ViewState<List<Waste>> get state => _state;

  List<Waste> get all => _state.data ?? const [];

  bool _disposed = false;

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<Waste>>.loading(previous: previous);
    _notify();
    final result = await _repository.getWastes();
    _state = result.when<ViewState<List<Waste>>>(
      success: (list) => ViewState<List<Waste>>.success(list),
      failure: (f) => ViewState<List<Waste>>.error(f, previous: previous),
    );
    _notify();
  }

  /// null یعنی موفق؛ در غیر این صورت خطای قابل‌نمایش (مثلاً کمبود موجودی).
  Future<AppFailure?> record(WasteDraft draft) async {
    final result = await _repository.create(draft);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    final saved = result.dataOrNull!;
    _state = ViewState<List<Waste>>.success([saved, ...all]);
    _notify();
    return null;
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
