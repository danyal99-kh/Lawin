// lib/repositories/purchase_repository.dart
import '../core/errors/result.dart';
import '../models/purchase.dart';

abstract interface class PurchaseRepository {
  /// تاریخچه‌ی خریدها، جدیدترین اول.
  Future<Result<List<Purchase>>> getPurchases();

  /// ثبت خرید؛ موجودی و قیمت خرید کالای مربوطه هم به‌روز می‌شود.
  Future<Result<Purchase>> create(PurchaseDraft draft);

  /// اصلاح خرید. موجودی و ورودی دفتر **جایگزین** می‌شوند، نه انباشته؛ اگر
  /// کم کردن مقدار، موجودی را منفی کند بک‌اند خطای outOfStock می‌دهد.
  Future<Result<Purchase>> update(int id, PurchaseDraft draft);

  /// حذف خرید؛ مقدار خریداری‌شده از موجودی کم و ورودی دفتر برگشت داده می‌شود.
  Future<Result<void>> delete(int id);
}
