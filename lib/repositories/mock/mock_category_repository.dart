import 'package:cafe_book_admin/core/network/utils/text_utils.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../core/utils/persian_format.dart';
import '../../models/product_category.dart';
import '../category_repository.dart';
import 'mock_database.dart';

/// اعتبارسنجی‌ها همان قوانینی است که بعداً Backend اعمال می‌کند.
class MockCategoryRepository implements CategoryRepository {
  MockCategoryRepository(this._db);

  final MockDatabase _db;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  List<ProductCategory> buildCategories() => [
        for (final c in _db.categories)
          c.copyWith(
            productCount:
                _db.products.where((p) => p.categoryId == c.id).length,
          ),
      ];

  AppFailure? _validate(String rawName, {int? excludeId}) {
    final name = rawName.trim();
    if (name.isEmpty)
      return AppFailure.validation('نام دسته‌بندی را وارد کنید.');
    if (name.length > 40) {
      return AppFailure.validation('نام دسته‌بندی حداکثر ۴۰ حرف باشد.');
    }
    final key = TextUtils.normalizeFa(name);
    final duplicate = _db.categories
        .any((c) => c.id != excludeId && TextUtils.normalizeFa(c.name) == key);
    if (duplicate) {
      return AppFailure.validation('دسته‌بندی‌ای با این نام وجود دارد.');
    }
    return null;
  }

  @override
  Future<Result<List<ProductCategory>>> getCategories() async {
    try {
      await _latency();
      return Success(buildCategories());
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<ProductCategory>> create(String name) async {
    try {
      await _latency();
      final invalid = _validate(name);
      if (invalid != null) return Failure(invalid);
      final c = ProductCategory(id: _db.nextCategoryId(), name: name.trim());
      _db.categories.add(c);
      return Success(c);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<ProductCategory>> update(int id, String name) async {
    try {
      await _latency();
      final index = _db.categories.indexWhere((c) => c.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final invalid = _validate(name, excludeId: id);
      if (invalid != null) return Failure(invalid);
      final updated = _db.categories[index].copyWith(name: name.trim());
      _db.categories[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _latency();
      final index = _db.categories.indexWhere((c) => c.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final count = _db.products.where((p) => p.categoryId == id).length;
      if (count > 0) {
        return Failure(AppFailure.conflict(
          'این دسته‌بندی ${PersianFormat.digits(count)} محصول دارد؛ '
          'ابتدا محصولات آن را به دسته‌ی دیگری ببرید یا حذف کنید.',
        ));
      }
      _db.categories.removeAt(index);
      return const Success<void>(null);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
