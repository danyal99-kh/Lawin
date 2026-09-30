// تست سرتاسری واقعی: Repositoryهای Flutter → ApiClient → Django → دیتابیس.
// نیازمند اجرای Django روی 127.0.0.1:8000 و توکن معتبر در LAWIN_TEST_TOKEN.
//
//   cd Lawin && DJANGO_DEBUG=1 DJANGO_SECRET_KEY=... python manage.py runserver 127.0.0.1:8000 --noreload
//   flutter test test/purchase_waste_live_test.dart \
//       --dart-define=LAWIN_TEST_TOKEN=<token> --dart-define=LAWIN_TEST_ITEM_ID=<id>
//
// اگر توکن داده نشود، تست‌ها skip می‌شوند تا در CI شکست نخورند.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/purchase.dart';
import 'package:cafe_book_admin/models/waste.dart';
import 'package:cafe_book_admin/models/waste_reason.dart';
import 'package:cafe_book_admin/repositories/api/api_purchase_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_waste_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _token = String.fromEnvironment('LAWIN_TEST_TOKEN');
const _itemId = int.fromEnvironment('LAWIN_TEST_ITEM_ID', defaultValue: 0);

class _StaticTokenStorage implements TokenStorage {
  _StaticTokenStorage(this._token);
  final String _token;
  @override
  Future<String?> read() async => _token;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  if (_token.isEmpty || _itemId == 0) {
    test('skipped: set LAWIN_TEST_TOKEN and LAWIN_TEST_ITEM_ID', () {});
    return;
  }

  late ApiPurchaseRepository purchases;
  late ApiWasteRepository wastes;

  setUp(() {
    final api = ApiClient(_StaticTokenStorage(_token));
    purchases = ApiPurchaseRepository(api);
    wastes = ApiWasteRepository(api);
  });

  test('GET purchases returns a parsable list', () async {
    final result = await purchases.getPurchases();
    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull, isA<List<Purchase>>());
  });

  test('POST purchase then GET reflects the new record', () async {
    final created = await purchases.create(
      PurchaseDraft(itemId: _itemId, quantity: 3, unitCost: 500, note: 'تست'),
    );
    expect(created.failureOrNull, isNull);
    final p = created.dataOrNull!;
    expect(p.itemId, _itemId);
    expect(p.quantity, 3.0);
    expect(p.unitCost, 500.0);
    expect(p.totalCost, 1500.0);

    final list = await purchases.getPurchases();
    expect(list.dataOrNull!.map((e) => e.id), contains(p.id));
  });

  test('POST waste above stock surfaces insufficientStock', () async {
    final result = await wastes.create(
      WasteDraft(itemId: _itemId, quantity: 9999999, reason: WasteReason.damaged),
    );
    expect(result.failureOrNull, isNotNull);
    expect(
      result.failureOrNull!.type,
      FailureType.insufficientStock,
      reason: result.failureOrNull!.userMessage,
    );
  });

  test('POST waste succeeds and is listed', () async {
    final created = await wastes.create(
      WasteDraft(itemId: _itemId, quantity: 1, reason: WasteReason.spoiled),
    );
    expect(created.failureOrNull, isNull);
    final w = created.dataOrNull!;
    expect(w.itemId, _itemId);
    expect(w.quantity, 1.0); // به کاربر مثبت نشان داده می‌شود
    expect(w.reason, WasteReason.spoiled);

    final list = await wastes.getWastes();
    expect(list.dataOrNull!.map((e) => e.id), contains(w.id));
  });

  test('validation errors come back as AppFailure.validation', () async {
    final result = await purchases.create(
      PurchaseDraft(itemId: _itemId, quantity: 0, unitCost: 10),
    );
    expect(result.failureOrNull, isNotNull);
    expect(result.failureOrNull!.type, FailureType.validation);
  });

  test('invalid token is rejected as unauthorized', () async {
    final api = ApiClient(_StaticTokenStorage('not-a-real-token'));
    final result = await ApiPurchaseRepository(api).getPurchases();
    expect(result.failureOrNull, isNotNull);
    expect(result.failureOrNull!.type, FailureType.unauthorized);
  });
}
