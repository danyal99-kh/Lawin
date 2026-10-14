import 'dart:io';

import 'package:cafe_book_admin/core/network/utils/text_utils.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/product.dart';
import '../product_repository.dart';
import 'mock_database.dart';
import 'mock_pricing.dart';

/// اعتبارسنجی‌ها همان قوانینی است که بعداً Backend اعمال می‌کند.
class MockProductRepository implements ProductRepository {
  MockProductRepository(this._db);

  final MockDatabase _db;

  static const int maxPrice = 100000000;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  AppFailure? _validate(ProductDraft d, {int? excludeId}) {
    if (d.name.isEmpty) return AppFailure.validation('نام محصول را وارد کنید.');
    if (d.name.length > 80) {
      return AppFailure.validation('نام محصول حداکثر ۸۰ حرف باشد.');
    }
    if (d.price <= 0) {
      return AppFailure.validation('قیمت فروش باید بیشتر از صفر باشد.');
    }
    if (d.price > maxPrice) {
      return AppFailure.validation('قیمت واردشده معتبر نیست.');
    }
    if (!_db.categories.any((c) => c.id == d.categoryId)) {
      return AppFailure.validation('دسته‌بندی انتخاب‌شده وجود ندارد.');
    }
    final key = TextUtils.normalizeFa(d.name);
    final duplicate = _db.products.any((p) =>
        p.id != excludeId &&
        p.categoryId == d.categoryId &&
        TextUtils.normalizeFa(p.name) == key);
    if (duplicate) {
      return AppFailure.validation(
          'محصولی با این نام در همین دسته‌بندی وجود دارد.');
    }
    return null;
  }

  @override
  Future<Result<List<Product>>> getProducts() async {
    try {
      await _latency();
      return Success(_db.products.map(_withOffer).toList());
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  /// قیمت مؤثر را از آفرهای فعال Mock محاسبه و به محصول ضمیمه می‌کند؛
  /// قیمت پایه (`price`) دست‌نخورده می‌ماند.
  Product _withOffer(Product p) {
    final quote = quoteProduct(_db.offers, p);
    return p.copyWith(
      effectivePrice: quote.finalPrice,
      discountPercent: quote.totalPercent,
      offerActive: quote.totalPercent > 0,
    );
  }

  @override
  Future<Result<Product>> create(ProductDraft draft, {File? image}) async {
    try {
      await _latency();
      final d = draft.normalized();
      final invalid = _validate(d);
      if (invalid != null) return Failure(invalid);
      final product = Product(
        id: _db.nextProductId(),
        name: d.name,
        categoryId: d.categoryId,
        price: d.price,
        description: d.description,
        imageUrl: d.imageUrl,
        isActive: d.isActive,
      );
      _db.products.add(product);
      return Success(product);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Product>> update(int id, ProductDraft draft, {File? image}) async {
    try {
      await _latency();
      final index = _db.products.indexWhere((p) => p.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final d = draft.normalized();
      final invalid = _validate(d, excludeId: id);
      if (invalid != null) return Failure(invalid);
      final updated = _db.products[index].applyDraft(d);
      _db.products[index] = updated;
      return Success(_withOffer(updated));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Product>> setActive(int id, {required bool active}) async {
    try {
      await _latency();
      final index = _db.products.indexWhere((p) => p.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final updated = _db.products[index].copyWith(isActive: active);
      _db.products[index] = updated;
      return Success(_withOffer(updated));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _latency();
      final index = _db.products.indexWhere((p) => p.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final usedInOpenOrder = _db.orders
          .any((o) => o.status.isOpen && o.items.any((i) => i.productId == id));
      if (usedInOpenOrder) {
        return Failure(AppFailure.conflict(
          'این محصول در یک سفارش باز استفاده شده و فعلاً قابل حذف نیست. '
          'می‌توانید آن را غیرفعال کنید.',
        ));
      }
      _db.products.removeAt(index);
      return const Success<void>(null);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
