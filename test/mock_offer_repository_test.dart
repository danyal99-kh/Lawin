// رفتار Mock آفرها باید با قواعد Backend هم‌خوان باشد: زنجیره‌ی ضربی،
// فعال‌سازی فقط با اثر انگشت معتبر، رد آفر دسته‌ی خالی و بازگشت قیمت با غیرفعال‌سازی.
import 'package:cafe_book_admin/models/offer.dart';
import 'package:cafe_book_admin/models/product.dart';
import 'package:cafe_book_admin/models/product_category.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:cafe_book_admin/repositories/mock/mock_offer_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDatabase db;
  late MockOfferRepository offers;
  final now = DateTime.parse('2026-10-14T12:00:00+00:00');

  Product latte() => db.products.firstWhere((p) => p.id == 1); // ۹۵٬۰۰۰

  setUp(() {
    db = MockDatabase.seeded(now: now);
    offers = MockOfferRepository(db, clock: () => now);
  });

  group('preview', () {
    test('product preview shows before/after and stores nothing', () async {
      final result = await offers
          .preview(const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1));
      final preview = result.dataOrNull!;
      expect(preview.productCount, 1);
      expect(preview.products.single.base, 95000);
      expect(preview.products.single.before, 95000);
      expect(preview.products.single.finalPrice, 76000);
      expect(preview.fingerprint, isNotEmpty);
      expect(db.offers, isEmpty);
    });

    test('category preview lists only active products', () async {
      final result = await offers.preview(
          const OfferRequest(scope: OfferScope.category, percent: 50, categoryId: 1));
      final preview = result.dataOrNull!;
      expect(preview.productCount, greaterThan(1));
      expect(preview.products.any((i) => i.productId == 1), isTrue);
    });

    test('percent outside 1..99 is rejected', () async {
      for (final pct in [0, 100, -3]) {
        final result = await offers.preview(
            OfferRequest(scope: OfferScope.product, percent: pct, productId: 1));
        expect(result.failureOrNull, isNotNull, reason: 'percent=$pct');
      }
    });
  });

  group('activate', () {
    test('with a matching fingerprint persists the offer', () async {
      final preview = (await offers.preview(
              const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1)))
          .dataOrNull!;
      final result = await offers.activate(
        const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1),
        fingerprint: preview.fingerprint,
      );
      expect(result.failureOrNull, isNull);
      expect(db.offers, hasLength(1));
      expect(quoteProduct(db.offers, latte()).finalPrice, 76000);
      // قیمت پایه دست‌نخورده می‌ماند.
      expect(latte().price, 95000);
    });

    test('a stale fingerprint is rejected (prices changed)', () async {
      final preview = (await offers.preview(
              const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1)))
          .dataOrNull!;
      // قیمت پایه تغییر کرد (نه با آفر؛ مثلاً ویرایش محصول).
      db.products[0] = Product(
          id: 1,
          name: latte().name,
          categoryId: latte().categoryId,
          price: 100000);
      final result = await offers.activate(
        const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1),
        fingerprint: preview.fingerprint,
      );
      expect(result.failureOrNull, isNotNull);
      expect(db.offers, isEmpty);
    });

    test('offers chain multiplicatively, not additively', () async {
      Future<void> add(int percent) async {
        final preview = (await offers.preview(OfferRequest(
                scope: OfferScope.product, percent: percent, productId: 1)))
            .dataOrNull!;
        await offers.activate(
          OfferRequest(scope: OfferScope.product, percent: percent, productId: 1),
          fingerprint: preview.fingerprint,
        );
      }

      await add(20);
      await add(10);
      // ۹۵٬۰۰۰ → ۷۶٬۰۰۰ → ۶۸٬۴۰۰ (نه ۷۰٪).
      expect(quoteProduct(db.offers, latte()).finalPrice, 68400);
    });

    test('an empty category cannot receive a category offer', () async {
      db.categories.add(const ProductCategory(id: 99, name: 'خالی'));
      final result = await offers.activate(
        const OfferRequest(scope: OfferScope.category, percent: 30, categoryId: 99),
        fingerprint: 'whatever',
      );
      expect(result.failureOrNull, isNotNull);
      expect(db.offers, isEmpty);
    });
  });

  group('deactivate', () {
    test('turns the offer off and restores the base price', () async {
      final preview = (await offers.preview(
              const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1)))
          .dataOrNull!;
      final created = (await offers.activate(
              const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1),
              fingerprint: preview.fingerprint))
          .dataOrNull!;
      expect(quoteProduct(db.offers, latte()).finalPrice, 76000);

      final result = await offers.deactivate(created.id);
      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull!.isActive, isFalse);
      expect(quoteProduct(db.offers, latte()).finalPrice, 95000);
    });

    test('list can filter to active offers only', () async {
      final preview = (await offers.preview(
              const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1)))
          .dataOrNull!;
      await offers.activate(
        const OfferRequest(scope: OfferScope.product, percent: 20, productId: 1),
        fingerprint: preview.fingerprint,
      );
      final active =
          (await offers.getOffers(productId: 1, activeOnly: true)).dataOrNull!;
      expect(active, hasLength(1));
      expect(active.single.percent, 20);
    });
  });

  group('applyPercent rounding', () {
    test('rounds half up like the backend', () {
      expect(applyPercent(999, 1), 989);
      expect(applyPercent(50, 1), 50);
      expect(applyPercent(95000, 0), 95000);
    });
  });
}
