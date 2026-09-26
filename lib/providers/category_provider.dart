import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/errors/result.dart';
import '../core/utils/view_state.dart';
import '../models/product_category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._repository);

  final CategoryRepository _repository;

  ViewState<List<ProductCategory>> _state = const ViewState.initial();
  ViewState<List<ProductCategory>> get state => _state;

  List<ProductCategory> get categories => _state.data ?? const [];

  bool _disposed = false;

  /// لیست خالی هم «موفق» است تا صفحه دکمه‌ی افزودن را نگه دارد.
  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<List<ProductCategory>>.loading(previous: previous);
    _notify();
    final result = await _repository.getCategories();
    _state = result.when<ViewState<List<ProductCategory>>>(
      success: (list) => ViewState<List<ProductCategory>>.success(list),
      failure: (f) =>
          ViewState<List<ProductCategory>>.error(f, previous: previous),
    );
    _notify();
  }

  /// null یعنی موفق؛ در غیر این صورت خطای قابل‌نمایش.
  Future<AppFailure?> save(String name, {int? id}) async {
    final result = id == null
        ? await _repository.create(name)
        : await _repository.update(id, name);
    return _apply(result);
  }

  Future<AppFailure?> delete(int id) async {
    final result = await _repository.delete(id);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _state = ViewState<List<ProductCategory>>.success(
        categories.where((c) => c.id != id).toList());
    _notify();
    return null;
  }

  AppFailure? _apply(Result<ProductCategory> result) {
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    final saved = result.dataOrNull!;
    final exists = categories.any((c) => c.id == saved.id);
    _state = ViewState<List<ProductCategory>>.success(exists
        ? [for (final c in categories) c.id == saved.id ? saved : c]
        : [...categories, saved]);
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