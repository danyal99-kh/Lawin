// قرارداد API نسیه با بک‌اند:
//   • خواندن بدهکارها/نسیه‌ها/وصول‌ها
//   • ثبت تسویه (oldest-first) با بدنه‌ی دقیق POST
//   • بیش‌پرداخت هرگز پذیرفته نمی‌شود (409)
// تست‌ها روی MockClient اجرا می‌شوند تا شبکه‌ای در کار نباشد.
import 'dart:convert';

import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/credit.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/api/api_credit_repository.dart';
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

final String _debtors = jsonEncode([
  {
    'id': 1,
    'name': 'شرکت آریا',
    'phone': '09120000001',
    'note': null,
    'debt': 320000,
    'open_credits': 2,
    'extended': 920000,
    'last_activity': '2026-10-07T20:30:00+00:00',
    'created_at': '2026-09-01T10:00:00+00:00',
  },
  {
    'id': 2,
    'name': 'دفتر مرکزی نگین',
    'phone': null,
    'note': null,
    'debt': 0,
    'open_credits': 0,
    'extended': 150000,
    'last_activity': null,
    'created_at': '2026-09-15T10:00:00+00:00',
  },
]);

final String _credits = jsonEncode([
  {
    'id': 1,
    'debtor_id': 1,
    'debtor_name': 'شرکت آریا',
    'order_id': '18b817d8-0000-0000-0000-000000000001',
    'order_number': 1001,
    'amount': 600000,
    'remaining_amount': 300000,
    'status': 'open',
    'created_at': '2026-09-20T14:00:00+00:00',
  },
  {
    'id': 2,
    'debtor_id': 1,
    'debtor_name': 'شرکت آریا',
    'order_id': '18b817d8-0000-0000-0000-000000000002',
    'order_number': 1002,
    'amount': 420000,
    'remaining_amount': 20000,
    'status': 'open',
    'created_at': '2026-10-02T09:00:00+00:00',
  },
]);

final String _settled = jsonEncode({
  'payments': [
    {
      'id': 7,
      'credit_id': 1,
      'debtor_id': 1,
      'debtor_name': 'شرکت آریا',
      'order_id': '18b817d8-0000-0000-0000-000000000001',
      'order_number': 1001,
      'amount': 200000,
      'account': 'cash',
      'note': null,
      'created_at': '2026-10-08T11:30:00+00:00',
    },
  ],
  'credits': [
    {
      'id': 1,
      'debtor_id': 1,
      'debtor_name': 'شرکت آریا',
      'order_id': '18b817d8-0000-0000-0000-000000000001',
      'order_number': 1001,
      'amount': 600000,
      'remaining_amount': 100000,
      'status': 'open',
      'created_at': '2026-09-20T14:00:00+00:00',
    },
  ],
  'total': 200000,
  'debtor_id': 1,
  'debtor_name': 'شرکت آریا',
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

  group('reads', () {
    test('debtors parse with totals and forward ?q=', () async {
      final repo = ApiCreditRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _debtors)),
      );
      final result = await repo.getDebtors(query: 'آریا');
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/credits/debtors/');
      expect(lastRequest.queryParameters['q'], 'آریا');

      final debtors = result.dataOrNull!;
      expect(debtors, hasLength(2));
      expect(debtors.first.name, 'شرکت آریا');
      expect(debtors.first.debt, 320000);
      expect(debtors.first.openCredits, 2);
      // last_activity فقط از تاریخچه‌ی مالی می‌آید؛ null یعنی هنوز فعالیتی نیست.
      expect(debtors.last.lastActivity, isNull);
    });

    test('credits parse and forward status/debtor filters', () async {
      final repo = ApiCreditRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _credits)),
      );
      final result = await repo.getCredits(
          debtorId: 1, status: CreditStatus.open);
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/credits/');
      expect(lastRequest.queryParameters['debtor'], '1');
      expect(lastRequest.queryParameters['status'], 'open');

      final credits = result.dataOrNull!;
      expect(credits, hasLength(2));
      expect(credits.first.isOpen, isTrue);
      expect(credits.first.remainingAmount, 300000);
      expect(credits.first.orderNumber, 1001);
    });
  });

  group('settle', () {
    test('POSTs the exact body and parses the result', () async {
      final repo = ApiCreditRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(201, _settled)),
      );
      final result = await repo.settle(
        debtorId: 1,
        amount: 200000,
        account: CashAccount.cash,
        idempotencyKey: 'adm-123',
      );
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/credits/payments/');
      expect(lastMethod, 'POST');
      expect(lastBody['debtor_id'], 1);
      expect(lastBody['amount'], 200000);
      expect(lastBody['account'], 'cash');
      expect(lastBody['idempotency_key'], 'adm-123');
      expect(lastBody.containsKey('credit_id'), isFalse);

      final settled = result.dataOrNull!;
      expect(settled.total, 200000);
      expect(settled.debtorId, 1);
      expect(settled.debtorName, 'شرکت آریا');
      expect(settled.payments, hasLength(1));
      expect(settled.payments.first.account, CashAccount.cash);
      expect(settled.credits.first.remainingAmount, 100000);
    });

    test('an overpayment is rejected by the server (principle: no overpay credit)',
        () async {
      final repo = ApiCreditRepository(
        ApiClient(
          _FakeTokenStorage(),
          client: capturing(
              409,
              jsonEncode({
                'error': {
                  'code': 'conflict',
                  'message': 'مبلغ تسویه از مانده‌ی نسیه بیشتر است.'
                }
              })),
        ),
      );
      final result = await repo.settle(
        debtorId: 1,
        amount: 999999999,
        account: CashAccount.cash,
      );
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull!.type, FailureType.conflict);
    });
  });
}