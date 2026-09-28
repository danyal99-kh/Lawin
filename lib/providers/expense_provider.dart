// lib/providers/expense_provider.dart
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/network/utils/text_utils.dart';
import '../core/utils/view_state.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

/// وضعیت صفحه‌ی هزینه‌ها: جستجو + فیلتر دسته‌بندی + ایجاد/ویرایش/حذف.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._repository);

  final ExpenseRepository _repository;

  ViewState<List<Expense>> _state = const ViewState.initial();
  ViewState<List<Expense>> get state => _state;

  String _query = '';
  ExpenseCategory? _category;

  String get query => _query;
  ExpenseCategory? get category => _category;

  bool _disposed = false;

  List<Expense> get all => _state.data ?? const [];

  bool get hasFilters => _query.isNotEmpty || _category != null;

  List<Expense> get visible {
    final q = TextUtils.normalizeFa(_query);
    return all.where((e) {
      if (_category != null && e.category != _category) return false;
      return q.isEmpty || TextUtils.normalizeFa(e.title).contains(q);
    }).toList();
  }

  int get totalAmount => visible.fold(0, (sum, e) => sum + e.amount);

  void setQuery(String q) {
    _query = q;
    _notify();
  }

  void setCategory(ExpenseCategory? c) {
    _category = c;
    _notify();
  }

  void clearFilters() {
    _query = '';
    _category = null;
    _notify();
  }

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<Expense>>.loading(previous: previous);
    _notify();
    final result = await _repository.getExpenses();
    _state = result.when<ViewState<List<Expense>>>(
      success: (list) => ViewState<List<Expense>>.success(list),
      failure: (f) => ViewState<List<Expense>>.error(f, previous: previous),
    );
    _notify();
  }

  /// ایجاد (id == null) یا ویرایش. null یعنی موفق.
  Future<AppFailure?> save(ExpenseDraft draft, {int? id}) async {
    final result = id == null
        ? await _repository.create(draft)
        : await _repository.update(id, draft);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _upsert(result.dataOrNull!);
    return null;
  }

  Future<AppFailure?> delete(int id) async {
    final result = await _repository.delete(id);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _state =
        ViewState<List<Expense>>.success(all.where((e) => e.id != id).toList());
    _notify();
    return null;
  }

  void _upsert(Expense saved) {
    final exists = all.any((e) => e.id == saved.id);
    final list = exists
        ? [for (final e in all) e.id == saved.id ? saved : e]
        : [saved, ...all];
    list.sort((a, b) => b.date.compareTo(a.date));
    _state = ViewState<List<Expense>>.success(list);
    _notify();
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
