import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../offer_repository.dart';
import 'mock_database.dart';
import 'mock_pricing.dart';

/// پیاده‌سازی Mock آفرها با همان قوانین Backend:
/// درصد بین ۱ تا ۹۹، زنجیره‌ی ضربی، فعال‌سازی فقط با اثر انگشت معتبر، و
/// آفر دسته‌ای روی دسته‌ی بدون محصول فعال نمی‌شود.
class MockOfferRepository implements OfferRepository {
  MockOfferRepository(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final MockDatabase _db;
  final DateTime Function() _clock;

  static const int minPercent = 1;
  static const int maxPercent = 99;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  AppFailure? _validatePercent(int percent) {
    if (percent < minPercent || percent > maxPercent) {
      return AppFailure.validation('درصد تخفیف باید بین ۱ تا ۹۹ باشد.');
    }
    return null;
  }

  List<Product> _targets(OfferRequest req) {
    if (req.scope == OfferScope.product) {
      return _db.products.where((p) => p.id == req.productId).toList();
    }
    return _db.products
        .where((p) => p.categoryId == req.categoryId && p.isActive)
        .toList();
  }

  OfferPreview _buildPreview(OfferRequest req) {
    final items = <OfferPreviewItem>[];
    for (final p in _targets(req)) {
      final quote = quoteProduct(_db.offers, p, now: _clock());
      final after = applyPercent(quote.finalPrice, req.percent);
      items.add(OfferPreviewItem(
        productId: p.id,
        productName: p.name,
        base: quote.base,
        before: quote.finalPrice,
        finalPrice: after,
        saving: quote.base - after,
        currentPercent: quote.totalPercent,
      ));
    }
    return OfferPreview(
      scope: req.scope,
      percent: req.percent,
      products: items,
      productCount: items.length,
      fingerprint: previewFingerprint(
          req.scope, req.percent, req.startsAt, req.endsAt, items),
      startsAt: req.startsAt,
      endsAt: req.endsAt,
    );
  }

  AppFailure? _validateRequest(OfferRequest req) {
    final percentFailure = _validatePercent(req.percent);
    if (percentFailure != null) return percentFailure;
    if (req.startsAt != null &&
        req.endsAt != null &&
        !req.endsAt!.isAfter(req.startsAt!)) {
      return AppFailure.validation('زمان پایان باید بعد از زمان شروع باشد.');
    }
    if (req.scope == OfferScope.product) {
      if (!_db.products.any((p) => p.id == req.productId)) {
        return AppFailure.notFound();
      }
    } else if (!_db.categories.any((c) => c.id == req.categoryId)) {
      return AppFailure.notFound();
    }
    return null;
  }

  @override
  Future<Result<List<Offer>>> getOffers({
    int? productId,
    int? categoryId,
    bool? activeOnly,
  }) async {
    try {
      await _latency();
      final list = _db.offers.where((o) {
        if (productId != null && o.productId != productId) return false;
        if (categoryId != null && o.categoryId != categoryId) return false;
        if (activeOnly == true && !o.isActive) return false;
        if (activeOnly == false && o.isActive) return false;
        return true;
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<OfferPreview>> preview(OfferRequest request) async {
    try {
      await _latency();
      final invalid = _validateRequest(request);
      if (invalid != null) return Failure(invalid);
      return Success(_buildPreview(request));
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Offer>> activate(
    OfferRequest request, {
    required String fingerprint,
    String? idempotencyKey,
  }) async {
    try {
      await _latency();
      final invalid = _validateRequest(request);
      if (invalid != null) return Failure(invalid);
      final preview = _buildPreview(request);
      if (preview.fingerprint != fingerprint) {
        return Failure(AppFailure.conflict(
            'قیمت‌ها از زمان پیش‌نمایش تغییر کرده‌اند؛ دوباره پیش‌نمایش بگیرید.'));
      }
      if (request.scope == OfferScope.category && preview.productCount == 0) {
        return Failure(
            AppFailure.validation('آفر دسته‌ای روی دسته‌ی بدون محصول فعال نمی‌شود.'));
      }
      final product = request.scope == OfferScope.product
          ? _db.products.firstWhere((p) => p.id == request.productId)
          : null;
      final category = request.scope == OfferScope.category
          ? _db.categories.firstWhere((c) => c.id == request.categoryId)
          : null;
      final offer = Offer(
        id: _db.nextOfferId(),
        scope: request.scope,
        percent: request.percent,
        productId: product?.id,
        productName: product?.name,
        categoryId: category?.id,
        categoryName: category?.name,
        startsAt: request.startsAt,
        endsAt: request.endsAt,
        createdAt: _clock(),
      );
      _db.offers.add(offer);
      return Success(offer);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<Offer>> deactivate(int id) async {
    try {
      await _latency();
      final index = _db.offers.indexWhere((o) => o.id == id);
      if (index == -1) return Failure(AppFailure.notFound());
      final updated =
          _db.offers[index].copyWith(isActive: false, endsAt: _clock());
      _db.offers[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
