// قرارداد API آفر با بک‌اند:
//   • خواندن فهرست با فیلترهای product/category/active
//   • پیش‌نمایش با بدنه‌ی scope/target/percent
//   • فعال‌سازی روی مسیر create با fingerprint (و idempotency_key اختیاری)
//   • غیرفعال‌سازی روی مسیر deactivate
// تست‌ها روی MockClient اجرا می‌شوند تا شبکه‌ای در کار نباشد.
import 'dart:convert';

import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/offer.dart';
import 'package:cafe_book_admin/repositories/api/api_offer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

final String _offerJson = jsonEncode({
  'id': 7,
  'scope': 'product',
  'product': 1,
  'product_name': 'لاته',
  'category': null,
  'category_name': null,
  'percent': 20,
  'is_active': true,
  'starts_at': null,
  'ends_at': null,
  'created_at': '2026-10-14T09:00:00+00:00',
});

final String _previewJson = jsonEncode({
  'scope': 'product',
  'percent': 20,
  'starts_at': null,
  'ends_at': null,
  'product_count': 1,
  'fingerprint': 'fp-123',
  'products': [
    {
      'product_id': 1,
      'product_name': 'لاته',
      'base': 95000,
      'before': 95000,
      'final': 76000,
      'saving': 19000,
      'current_percent': 0,
    }
  ],
});

void main() {
  late Uri lastRequest;
  late String lastMethod;
  late Map<String, dynamic> lastBody;

  MockClient capturing(int status, String body) => MockClient((req) async {
        lastRequest = req.url;
        lastMethod = req.method;
        lastBody = req.body.isEmpty
            ? {}
            : jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(body, status,
            headers: {'content-type': 'application/json'});
      });

  ApiOfferRepository repoWith(int status, String body) =>
      ApiOfferRepository(ApiClient(_FakeTokenStorage(),
          client: capturing(status, body)));

  group('reads', () {
    test('list forwards product/category/active filters', () async {
      final repo = repoWith(200, jsonEncode([jsonDecode(_offerJson)]));
      final result = await repo.getOffers(productId: 1, activeOnly: true);
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/offers/');
      expect(lastMethod, 'GET');
      expect(lastRequest.queryParameters['product'], '1');
      expect(lastRequest.queryParameters['active'], '1');

      final offers = result.dataOrNull!;
      expect(offers, hasLength(1));
      expect(offers.single.percent, 20);
      expect(offers.single.targetName, 'لاته');
    });
  });

  group('mutations', () {
    test('preview POSTs scope/target/percent and parses the result', () async {
      final repo = repoWith(200, _previewJson);
      final result = await repo.preview(const OfferRequest(
          scope: OfferScope.product, percent: 20, productId: 1));
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/offers/preview/');
      expect(lastMethod, 'POST');
      expect(lastBody['scope'], 'product');
      expect(lastBody['product_id'], 1);
      expect(lastBody['percent'], 20);

      final preview = result.dataOrNull!;
      expect(preview.fingerprint, 'fp-123');
      expect(preview.products.single.finalPrice, 76000);
    });

    test('activate POSTs to create with the fingerprint', () async {
      final repo = repoWith(201, _offerJson);
      final result = await repo.activate(
        const OfferRequest(
            scope: OfferScope.product, percent: 20, productId: 1),
        fingerprint: 'fp-123',
        idempotencyKey: 'idem-1',
      );
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/offers/create/');
      expect(lastMethod, 'POST');
      expect(lastBody['fingerprint'], 'fp-123');
      expect(lastBody['idempotency_key'], 'idem-1');
      expect(result.dataOrNull!.scope, OfferScope.product);
    });

    test('conflict on create surfaces as a conflict failure', () async {
      final repo = repoWith(
        409,
        jsonEncode({
          'error': {'code': 'conflict', 'message': 'قیمت‌ها تغییر کرده‌اند'}
        }),
      );
      final result = await repo.activate(
        const OfferRequest(
            scope: OfferScope.product, percent: 20, productId: 1),
        fingerprint: 'stale',
      );
      expect(result.failureOrNull?.type, FailureType.conflict);
      expect(result.failureOrNull?.userMessage, 'قیمت‌ها تغییر کرده‌اند');
    });

    test('deactivate POSTs to the deactivate endpoint', () async {
      final repo = repoWith(200, _offerJson);
      final result = await repo.deactivate(7);
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/offers/7/deactivate/');
      expect(lastMethod, 'POST');
    });
  });
}
