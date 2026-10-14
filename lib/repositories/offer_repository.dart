import '../core/errors/result.dart';
import '../models/offer.dart';

/// دسترسی به آفر/تخفیف‌ها. Backend قیمت پایه را تغییر نمی‌دهد و فقط قیمت مؤثر
/// را محاسبه می‌کند؛ همه‌ی محاسبه‌ها سمت سرور است.
abstract interface class OfferRepository {
  /// فهرست آفرها؛ می‌توان بر اساس محصول/دسته و فقط فعال‌ها فیلتر کرد.
  Future<Result<List<Offer>>> getOffers({
    int? productId,
    int? categoryId,
    bool? activeOnly,
  });

  /// پیش‌نمایش بدون هیچ تغییری؛ برای گرفتن `fingerprint` لازم است.
  Future<Result<OfferPreview>> preview(OfferRequest request);

  /// فعال‌سازی آفر با اثر انگشت پیش‌نمایش. [idempotencyKey] از ساخت تکراری
  /// آفر در اثر تلاش مجدد جلوگیری می‌کند.
  Future<Result<Offer>> activate(
    OfferRequest request, {
    required String fingerprint,
    String? idempotencyKey,
  });

  /// غیرفعال‌سازی یک آفر. سفارش‌های قبلی دست‌نخورده می‌مانند.
  Future<Result<Offer>> deactivate(int id);
}
