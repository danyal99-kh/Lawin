import '../core/errors/result.dart';
import '../models/product.dart';

abstract interface class ProductRepository {
  Future<Result<List<Product>>> getProducts();
  Future<Result<Product>> create(ProductDraft draft);
  Future<Result<Product>> update(int id, ProductDraft draft);
  Future<Result<Product>> setActive(int id, {required bool active});

  /// محصولی که در سفارش باز استفاده شده حذف نمی‌شود (conflict).
  Future<Result<void>> delete(int id);
}