// مدل‌های آفر: تجزیه‌ی JSON مطابق قرارداد Backend و محاسبه‌ی قیمت مؤثر محصول.
import 'package:cafe_book_admin/models/offer.dart';
import 'package:cafe_book_admin/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product offer fields', () {
    test('parses effective price, percent and offer window', () {
      final p = Product.fromJson({
        'id': 1,
        'name': 'لاته',
        'category_id': 1,
        'price': 95000,
        'description': null,
        'image_url': null,
        'is_active': true,
        'effective_price': 76000,
        'discount_percent': 20,
        'offer_active': true,
        'offer_ends_at': '2026-11-01T20:00:00+00:00',
      });
      expect(p.price, 95000);
      expect(p.finalPrice, 76000);
      expect(p.discountPercent, 20);
      expect(p.hasOffer, isTrue);
      expect(p.offerEndsAt, isNotNull);
    });

    test('without offer fields falls back to base price', () {
      final p = Product.fromJson({
        'id': 1,
        'name': 'لاته',
        'category_id': 1,
        'price': 95000,
        'is_active': true,
      });
      expect(p.effectivePrice, isNull);
      expect(p.finalPrice, 95000);
      expect(p.hasOffer, isFalse);
    });

    test('applyDraft keeps server-provided offer fields', () {
      const p = Product(
        id: 1,
        name: 'لاته',
        categoryId: 1,
        price: 95000,
        effectivePrice: 76000,
        discountPercent: 20,
        offerActive: true,
      );
      final updated = p.applyDraft(const ProductDraft(
        name: 'لاته بزرگ',
        categoryId: 1,
        price: 100000,
      ));
      expect(updated.price, 100000);
      expect(updated.effectivePrice, 76000);
      expect(updated.hasOffer, isTrue);
    });
  });

  group('Offer', () {
    test('parses product scope', () {
      final o = Offer.fromJson({
        'id': 7,
        'scope': 'product',
        'product': 3,
        'product_name': 'اسپرسو',
        'category': null,
        'category_name': null,
        'percent': 15,
        'is_active': true,
        'starts_at': null,
        'ends_at': null,
        'created_at': '2026-10-14T09:00:00+00:00',
      });
      expect(o.scope, OfferScope.product);
      expect(o.productId, 3);
      expect(o.targetName, 'اسپرسو');
      expect(o.createdAt, isNotNull);
    });

    test('validAt respects active flag and time window', () {
      final now = DateTime.parse('2026-10-14T12:00:00+00:00');
      final future = Offer(
        id: 1,
        scope: OfferScope.product,
        percent: 10,
        startsAt: now.add(const Duration(hours: 1)),
      );
      expect(future.validAt(now), isFalse);
      final expired = Offer(
        id: 2,
        scope: OfferScope.product,
        percent: 10,
        endsAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(expired.validAt(now), isFalse);
      final active = Offer(id: 3, scope: OfferScope.product, percent: 10);
      expect(active.validAt(now), isTrue);
    });
  });

  group('OfferPreview', () {
    test('parses items, count and fingerprint', () {
      final preview = OfferPreview.fromJson({
        'scope': 'category',
        'percent': 50,
        'starts_at': null,
        'ends_at': null,
        'product_count': 1,
        'fingerprint': 'abc123',
        'products': [
          {
            'product_id': 1,
            'product_name': 'لاته',
            'base': 95000,
            'before': 76000,
            'final': 38000,
            'saving': 57000,
            'current_percent': 20,
          }
        ],
      });
      expect(preview.scope, OfferScope.category);
      expect(preview.productCount, 1);
      expect(preview.fingerprint, 'abc123');
      expect(preview.products.single.before, 76000);
      expect(preview.products.single.finalPrice, 38000);
      expect(preview.products.single.currentPercent, 20);
    });
  });

  group('OfferRequest', () {
    test('serializes scope, target and percent only', () {
      const req = OfferRequest(
          scope: OfferScope.product, percent: 25, productId: 4);
      expect(req.toJson(), {'scope': 'product', 'product_id': 4, 'percent': 25});
    });

    test('category request carries category_id and window', () {
      final req = OfferRequest(
        scope: OfferScope.category,
        percent: 10,
        categoryId: 2,
        endsAt: DateTime.utc(2026, 11, 1, 20),
      );
      final json = req.toJson();
      expect(json['scope'], 'category');
      expect(json['category_id'], 2);
      expect(json.containsKey('product_id'), isFalse);
      expect(json['ends_at'], contains('2026-11-01'));
    });
  });
}
