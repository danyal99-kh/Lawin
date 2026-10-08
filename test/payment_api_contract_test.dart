// قرارداد API پرداخت با بک‌اندِ ledger-based:
//   • پرداخت چندروشی (پرداخت نقدی + کارت‌خوان روی یک سفارش)
//   • برگشت کامل وجه و اثرش روی وضعیت سفارش
// تست‌ها روی MockClient اجرا می‌شوند تا شبکه‌ای در کار نباشد.
import 'dart:convert';

import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/api/api_payment_repository.dart';
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

/// پاسخ واقعی POST pay وقتی یک میز تسویه می‌شود: میز خالی شده و سفارشِ
/// پرداخت‌شده دیگر «باز» نیست، پس در `open_orders` نمی‌آید.
final String _paidTable = jsonEncode({
  'table': {'id': 3, 'number': 3, 'status': 'empty'},
  'active_session': null,
  'last_session': {
    'id': '18',
    'table_id': 3,
    'table_number': 3,
    'entered_at': '2026-10-05T20:30:00+00:00',
    'exited_at': '2026-10-05T21:51:00+00:00',
  },
  'open_orders': <dynamic>[],
  'waiter_call': null,
});

/// پاسخ واقعی POST refund. نکته‌ی مهم: بک‌اند `refunded` می‌فرستد، نه `cancelled`
/// و نه `paid` — پول برگشته ولی فروش در دفتر با یک entry معکوس خنثی شده است.
final String _refundedOrder = jsonEncode({
  'id': '42',
  'number': 1007,
  'status': 'cancelled',
  'payment_status': 'refunded',
  'total': 700000,
  'payment_method': 'cash',
  'created_at': '2026-10-05T21:00:00+00:00',
  'paid_at': '2026-10-05T21:51:00+00:00',
  'cancelled_at': '2026-10-05T22:10:00+00:00',
  'items': [],
});

void main() {
  late Uri lastRequest;
  late String lastMethod;
  late Map<String, dynamic> lastBody;
  MockClient capturing(int status, String body) => MockClient((req) async {
        lastRequest = req.url;
        lastMethod = req.method;
        if (req.body.isNotEmpty) {
          lastBody = jsonDecode(req.body) as Map<String, dynamic>;
        }
        return http.Response(body, status,
            headers: {'content-type': 'application/json'});
      });

  group('pay', () {
    test('a single-method payment sends only `method`', () async {
      final repo = ApiPaymentRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _paidTable)),
      );

      final result = await repo.pay(3, method: PaymentMethod.cash);
      expect(result.failureOrNull, isNull);
      final overview = result.dataOrNull!;
      expect(overview.table.number, 3);
      expect(overview.status, TableStatus.empty); // میز بعد از pay آزاد است

      expect(lastRequest.path, '/api/v1/tables/3/pay/');
      expect(lastBody['method'], 'cash');
      // تک‌روشی نباید کلید `payments` بفرستد؛ بک‌اند آن را خالی می‌بیند.
      expect(lastBody.containsKey('payments'), isFalse);
    });

    test('a split payment sends every share with its own amount', () async {
      final repo = ApiPaymentRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _paidTable)),
      );

      final result = await repo.pay(
        3,
        method: PaymentMethod.cash,
        shares: const [
          PaymentShare(method: PaymentMethod.cash, amount: 500000),
          PaymentShare(method: PaymentMethod.cardReader, amount: 200000),
        ],
      );
      expect(result.failureOrNull, isNull);

      expect(lastBody['method'], 'cash'); // روش اول، برای بک‌اند قدیمی
      final shares = lastBody['payments'] as List;
      expect(shares, hasLength(2));
      expect(shares[0], {'method': 'cash', 'amount': 500000});
      expect(shares[1], {'method': 'card_reader', 'amount': 200000});
    });

    test('card_transfer and card_reader are different methods to the server',
        () async {
      final repo = ApiPaymentRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _paidTable)),
      );

      await repo.pay(3, method: PaymentMethod.cardTransfer);
      expect(lastBody['method'], 'card_transfer');
      expect(PaymentMethod.cardTransfer.apiValue,
          isNot(PaymentMethod.cardReader.apiValue));
    });

    test('a server error becomes AppFailure and never throws', () async {
      final repo = ApiPaymentRepository(
        ApiClient(_FakeTokenStorage(),
            client: capturing(500, jsonEncode({'detail': 'خطای سرور'}))),
      );
      final result = await repo.pay(3, method: PaymentMethod.cash);
      expect(result.failureOrNull!.type, FailureType.server);
      expect(result.dataOrNull, isNull);
    });
  });

  group('refund', () {
    test('POSTs to the order refund endpoint and returns the refunded order',
        () async {
      final repo = ApiPaymentRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _refundedOrder)),
      );

      final result = await repo.refund('42');
      expect(result.failureOrNull, isNull);

      final order = result.dataOrNull!;
      expect(order.id, '42');
      expect(order.paymentStatus, PaymentStatus.refunded);
      expect(order.status, OrderStatus.cancelled);

      expect(lastRequest.path, '/api/v1/orders/42/refund/');
      expect(lastMethod, 'POST');
    });

    test('a rejected refund surfaces the server message', () async {
      final repo = ApiPaymentRepository(
        ApiClient(_FakeTokenStorage(),
            client: capturing(
                409, jsonEncode({'detail': 'این سفارش پرداخت نشده'}))),
      );
      final result = await repo.refund('42');
      expect(result.failureOrNull, isNotNull);
      expect(result.dataOrNull, isNull);
    });
  });

  group('PaymentStatus', () {
    test('has a distinct refunded value so it cannot be confused with paid',
        () {
      expect(PaymentStatus.refunded.apiValue, 'refunded');
      expect(PaymentStatus.paid.apiValue, 'paid');
      // «لغو شدن» روی OrderStatus است، نه PaymentStatus. اگر refund را با
      // unpaid یکی می‌کردیم، UI پولِ برگشتی را اشتباه درآمدِ وصول‌نشده نشان
      // می‌داد؛ پس refund سه حالت مستقل خودش را دارد.
      expect(PaymentStatus.refunded, isNot(PaymentStatus.unpaid));
      expect(PaymentStatus.values, hasLength(4));
      expect(PaymentStatus.refunded.label, isNotEmpty);
    });

    test('credit closes the order but keeps the money uncollected', () {
      // نسیه هم یک حالت مستقل است: سفارشِ پرداختِ نسیه‌ای وضعیت «نسیه» می‌گیرد
      // تا UI نگوید پول وصول شده. distinction با paid حیاتی است چون دفتر
      // درآمد را موقع نسیه می‌شناسد ولی وجه نقد را موقع تسویه.
      expect(
        PaymentStatus.credit.apiValue,
        isNot(PaymentStatus.paid.apiValue),
      );
      expect(PaymentStatus.credit.label, isNotEmpty);
    });
  });
}
