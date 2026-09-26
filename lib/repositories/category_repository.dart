import '../core/errors/result.dart';
import '../models/product_category.dart';

abstract interface class CategoryRepository {
  Future<Result<List<ProductCategory>>> getCategories();
  Future<Result<ProductCategory>> create(String name);
  Future<Result<ProductCategory>> update(int id, String name);

  /// دسته‌ای که محصول دارد حذف نمی‌شود (conflict).
  Future<Result<void>> delete(int id);
}