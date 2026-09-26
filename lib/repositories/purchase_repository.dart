// lib/repositories/purchase_repository.dart
import '../core/errors/result.dart';
import '../models/purchase.dart';

abstract interface class PurchaseRepository {
  /// تاریخچه‌ی خریدها، جدیدترین اول.
  Future<Result<List<Purchase>>> getPurchases();

  /// ثبت خرید؛ موجودی و قیمت خرید کالای مربوطه هم به‌روز می‌شود.
  Future<Result<Purchase>> create(PurchaseDraft draft);
}
