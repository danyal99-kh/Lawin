import 'package:cafe_book_admin/core/network/utils/text_utils.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/view_state.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

enum ProductStatusFilter {
  all('همه'),
  active('فعال'),
  inactive('غیرفعال');

  const ProductStatusFilter(this.label);
  final String label;
}

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._repository);

  final ProductRepository _repository;

  ViewState<List<Product>> _state = const ViewState.initial();
  ViewState<List<Product>> get state => _state;

  String _query = '';
  int? _categoryId;
  ProductStatusFilter _status = ProductStatusFilter.all;

  String get query => _query;
  int? get categoryId => _categoryId;
  ProductStatusFilter get status => _status;

  bool _disposed = false;

  List<Product> get all => _state.data ?? const [];

  bool get hasFilters =>
      _query.isNotEmpty ||
      _categoryId != null ||
      _status != ProductStatusFilter.all;

  /// نتیجه‌ی جستجو + فیلتر دسته + فیلتر وضعیت.
  List<Product> get visible {
    final q = TextUtils.normalizeFa(_query);
    return all.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      switch (_status) {
        case ProductStatusFilter.active:
          if (!p.isActive) return false;
        case ProductStatusFilter.inactive:
          if (p.isActive) return false;
        case ProductStatusFilter.all:
          break;
      }
      return q.isEmpty || TextUtils.normalizeFa(p.name).contains(q);
    }).toList();
  }

  void setQuery(String q) {
    _query = q;
    _notify();
  }

  void setCategory(int? id) {
    _categoryId = id;
    _notify();
  }

  void setStatus(ProductStatusFilter s) {
    _status = s;
    _notify();
  }

  void clearFilters() {
    _query = '';
    _categoryId = null;
    _status = ProductStatusFilter.all;
    _notify();
  }

  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<Product>>.loading(previous: previous);
    _notify();
    final result = await _repository.getProducts();
    _state = result.when<ViewState<List<Product>>>(
      success: (list) => ViewState<List<Product>>.success(list),
      failure: (f) => ViewState<List<Product>>.error(f, previous: previous),
    );
    _notify();
  }

  /// ایجاد (id == null) یا ویرایش. null یعنی موفق.
  Future<AppFailure?> save(ProductDraft draft, {int? id}) async {
    final result = id == null
        ? await _repository.create(draft)
        : await _repository.update(id, draft);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _upsert(result.dataOrNull!);
    return null;
  }

  Future<AppFailure?> toggleActive(Product product) async {
    final result =
        await _repository.setActive(product.id, active: !product.isActive);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _upsert(result.dataOrNull!);
    return null;
  }

  Future<AppFailure?> delete(int id) async {
    final result = await _repository.delete(id);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _state = ViewState<List<Product>>.success(
        all.where((p) => p.id != id).toList());
    _notify();
    return null;
  }

  void _upsert(Product saved) {
    final exists = all.any((p) => p.id == saved.id);
    _state = ViewState<List<Product>>.success(exists
        ? [for (final p in all) p.id == saved.id ? saved : p]
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