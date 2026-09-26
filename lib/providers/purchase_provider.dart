// lib/providers/purchase_provider.dart
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/purchase.dart';
import '../repositories/purchase_repository.dart';

/// تاریخچه‌ی خریدها و ثبت خرید جدید.
class PurchaseProvider extends ChangeNotifier {
  PurchaseProvider(this._repository);

  final PurchaseRepository _repository;

  ViewState<List<Purchase>> _state = const ViewState.initial();
  ViewState<List<Purchase>> get state => _state;

  List<Purchase> get all => _state.data ?? const [];

  bool _disposed = false;

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<Purchase>>.loading(previous: previous);
    _notify();
    final result = await _repository.getPurchases();
    _state = result.when<ViewState<List<Purchase>>>(
      success: (list) => ViewState<List<Purchase>>.success(list),
      failure: (f) => ViewState<List<Purchase>>.error(f, previous: previous),
    );
    _notify();
  }

  /// null یعنی موفق؛ در غیر این صورت خطای قابل‌نمایش.
  Future<AppFailure?> record(PurchaseDraft draft) async {
    final result = await _repository.create(draft);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    final saved = result.dataOrNull!;
    _state = ViewState<List<Purchase>>.success([saved, ...all]);
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
