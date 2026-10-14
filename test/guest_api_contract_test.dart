// قرارداد API مهمان‌نوازی با بک‌اند:
//   • خواندن گروه‌ها (`?q=`)، جمع کل و ثبت‌های یک نام (`?name=`)
//   • تغییر نام با بدنه‌ی دقیق PATCH
//   • لغو مهمان با POST روی مسیر cancel
// تست‌ها روی MockClient اجرا می‌شوند تا شبکه‌ای در کار نباشد.
import 'dart:convert';

import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/repositories/api/api_guest_repository.dart';
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

final String _groups = jsonEncode([
  {
    'name': 'آقای رضایی',
    'total_amount': 300000,
    'order_count': 2,
    'last_at': '2026-10-10T18:00:00+00:00',
  },
  {
    'name': 'خانم موسوی',
    'total_amount': 120000,
    'order_count': 1,
    'last_at': null,
  },
]);

final String _summary = jsonEncode({
  'total_amount': 420000,
  'guest_count': 3,
  'order_count': 3,
});

final String _orders = jsonEncode([
  {
    'id': 5,
    'name': 'آقای رضایی',
    'amount': 150000,
    'status': 'active',
    'order_id': '18b817d8-0000-0000-0000-000000000001',
    'order_number': 1001,
    'table_number': 3,
    'created_at': '2026-10-10T18:00:00+00:00',
    'cancelled_at': null,
  },
]);

final String _singleGuest = jsonEncode({
  'id': 5,
  'name': 'آقای رضایی',
  'amount': 150000,
  'status': 'active',
  'order_id': '18b817d8-0000-0000-0000-000000000001',
  'order_number': 1001,
  'table_number': 3,
  'created_at': '2026-10-10T18:00:00+00:00',
  'cancelled_at': null,
});

final String _cancelled = jsonEncode({
  'id': 5,
  'name': 'آقای رضایی',
  'amount': 150000,
  'status': 'cancelled',
  'order_id': '18b817d8-0000-0000-0000-000000000001',
  'order_number': 1001,
  'table_number': 3,
  'created_at': '2026-10-10T18:00:00+00:00',
  'cancelled_at': '2026-10-11T09:30:00+00:00',
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
    test('groups parse and forward ?q=', () async {
      final repo = ApiGuestRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _groups)),
      );
      final result = await repo.getGroups(query: 'رضایی');
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/guests/');
      expect(lastRequest.queryParameters['q'], 'رضایی');

      final groups = result.dataOrNull!;
      expect(groups, hasLength(2));
      expect(groups.first.name, 'آقای رضایی');
      expect(groups.first.totalAmount, 300000);
      expect(groups.first.orderCount, 2);
      expect(groups.last.lastAt, isNull);
    });

    test('summary parses the totals', () async {
      final repo = ApiGuestRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _summary)),
      );
      final result = await repo.getSummary();
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/guests/summary/');
      final summary = result.dataOrNull!;
      expect(summary.totalAmount, 420000);
      expect(summary.guestCount, 3);
    });

    test('orders parse and forward ?name=', () async {
      final repo = ApiGuestRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _orders)),
      );
      final result = await repo.getOrders('آقای رضایی');
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/guests/orders/');
      expect(lastRequest.queryParameters['name'], 'آقای رضایی');

      final orders = result.dataOrNull!;
      expect(orders, hasLength(1));
      expect(orders.first.status, GuestStatus.active);
      expect(orders.first.isActive, isTrue);
      expect(orders.first.orderNumber, 1001);
      expect(orders.first.tableNumber, 3);
    });
  });

  group('mutations', () {
    test('rename PATCHes the exact body', () async {
      final repo = ApiGuestRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _singleGuest)),
      );
      final result = await repo.rename(5, 'آقای رضایی');
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/guests/5/');
      expect(lastMethod, 'PATCH');
      expect(lastBody['name'], 'آقای رضایی');
    });

    test('cancel POSTs to the cancel endpoint and parses cancellation',
        () async {
      final repo = ApiGuestRepository(
        ApiClient(_FakeTokenStorage(), client: capturing(200, _cancelled)),
      );
      final result = await repo.cancel(5);
      expect(result.failureOrNull, isNull);

      expect(lastRequest.path, '/api/v1/guests/5/cancel/');
      expect(lastMethod, 'POST');

      final guest = result.dataOrNull!;
      expect(guest.status, GuestStatus.cancelled);
      expect(guest.isActive, isFalse);
      expect(guest.cancelledAt, isNotNull);
    });
  });
}
