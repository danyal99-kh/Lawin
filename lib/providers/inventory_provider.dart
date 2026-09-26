// lib/providers/inventory_provider.dart
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/network/utils/text_utils.dart';
import '../core/utils/view_state.dart';
import '../models/enums.dart';
import '../models/inventory_draft.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

enum InventoryStockFilter {
  all('همه'),
  ok('موجود'),
  low('کم'),
  out('تمام‌شده');

  const InventoryStockFilter(this.label);
  final String label;

  bool matches(StockStatus s) => switch (this) {
        InventoryStockFilter.all => true,
        InventoryStockFilter.ok => s == StockStatus.ok,
        InventoryStockFilter.low => s == StockStatus.low,
        InventoryStockFilter.out => s == StockStatus.out,
      };
}

/// وضعیت صفحه‌ی انبار: تعریف/ویرایش/حذف کالا + جستجو و فیلتر بر اساس وضعیت موجودی.
/// افزایش/کاهش موجودی از طریق Providerهای خرید (قسمت دوم) و ضایعات (قسمت سوم) انجام می‌شود.
class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._repository);

  final InventoryRepository _repository;

  ViewState<List<InventoryItem>> _state = const ViewState.initial();
  ViewState<List<InventoryItem>> get state => _state;

  String _query = '';
  InventoryStockFilter _filter = InventoryStockFilter.all;

  String get query => _query;
  InventoryStockFilter get filter => _filter;

  bool _disposed = false;

  List<InventoryItem> get all => _state.data ?? const [];

  bool get hasFilters =>
      _query.isNotEmpty || _filter != InventoryStockFilter.all;

  List<InventoryItem> get visible {
    final q = TextUtils.normalizeFa(_query);
    return all.where((i) {
      if (!_filter.matches(i.stockStatus)) return false;
      return q.isEmpty || TextUtils.normalizeFa(i.name).contains(q);
    }).toList();
  }

  int countFor(InventoryStockFilter f) =>
      all.where((i) => f.matches(i.stockStatus)).length;

  void setQuery(String q) {
    _query = q;
    _notify();
  }

  void setFilter(InventoryStockFilter f) {
    _filter = f;
    _notify();
  }

  void clearFilters() {
    _query = '';
    _filter = InventoryStockFilter.all;
    _notify();
  }

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<InventoryItem>>.loading(previous: previous);
    _notify();
    final result = await _repository.getItems();
    _state = result.when<ViewState<List<InventoryItem>>>(
      success: (list) => ViewState<List<InventoryItem>>.success(list),
      failure: (f) =>
          ViewState<List<InventoryItem>>.error(f, previous: previous),
    );
    _notify();
  }

  /// ایجاد (id == null) یا ویرایش. null یعنی موفق.
  Future<AppFailure?> save(InventoryItemDraft draft, {int? id}) async {
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
    _state = ViewState<List<InventoryItem>>.success(
        all.where((i) => i.id != id).toList());
    _notify();
    return null;
  }

  void _upsert(InventoryItem saved) {
    final exists = all.any((i) => i.id == saved.id);
    _state = ViewState<List<InventoryItem>>.success(exists
        ? [for (final i in all) i.id == saved.id ? saved : i]
        : [...all, saved]);
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
