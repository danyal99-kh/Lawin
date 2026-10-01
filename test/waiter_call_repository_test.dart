// تست Repositoryهای درخواست گارسون:
//  - API: مسیرها/query دقیقاً مطابق `waiter_calls/api_urls.py` و تبدیل خطای Django.
//  - Mock: همان قوانین `waiter_calls/services.py` (تکراری نشود، قوانین تغییر وضعیت).
import 'dart:convert';

import 'package:cafe_book_admin/core/config/app_config.dart';
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/waiter_call.dart';
import 'package:cafe_book_admin/providers/app_providers.dart';
import 'package:cafe_book_admin/providers/waiter_call_provider.dart';
import 'package:cafe_book_admin/repositories/api/api_waiter_call_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:cafe_book_admin/repositories/mock/mock_table_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_waiter_call_repository.dart';
import 'package:cafe_book_admin/repositories/waiter_call_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

Map<String, dynamic> callJson({
  String id = 'call-1',
  String status = 'pending',
  int tableId = 2,
}) =>
    {
      'id': id,
      'table_id': tableId,
      'table_number': tableId,
      'status': status,
      'created_at': '2026-10-01T12:00:00+03:30',
      'acknowledged_at': null,
      'completed_at': null,
    };

void main() {
  late Uri lastRequest;
  late String? lastMethod;
  late Map<String, String> lastHeaders;
  MockClient clientReturning(int status, String body) =>
      MockClient((req) async {
        lastRequest = req.url;
        lastMethod = req.method;
        lastHeaders = req.headers;
        return http.Response(body, status,
            headers: {'content-type': 'application/json'});
      });

  group('ApiWaiterCallRepository', () {
    test('GET /api/v1/waiter-calls/?active=1 asks only for active calls',
        () async {
      final repo = ApiWaiterCallRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(200, jsonEncode([callJson()]))));

      final result = await repo.getActiveCalls();

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull!.single.isPending, isTrue);
      expect(lastMethod, 'GET');
      expect(lastRequest.path, '/api/v1/waiter-calls/');
      expect(lastRequest.queryParameters['active'], '1');
      expect(lastHeaders['Authorization'], 'Token test-token');
    });

    test('acknowledge POSTs to /api/v1/waiter-calls/<id>/acknowledge/',
        () async {
      final repo = ApiWaiterCallRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(
              200, jsonEncode(callJson(status: 'acknowledged')))));

      final result = await repo.acknowledge('call-1');

      expect(result.dataOrNull!.status, WaiterCallStatus.acknowledged);
      expect(lastMethod, 'POST');
      expect(lastRequest.path, '/api/v1/waiter-calls/call-1/acknowledge/');
    });

    test('complete POSTs to /api/v1/waiter-calls/<id>/complete/', () async {
      final repo = ApiWaiterCallRepository(ApiClient(_FakeTokenStorage(),
          client:
              clientReturning(200, jsonEncode(callJson(status: 'completed')))));

      final result = await repo.complete('call-1');

      expect(result.dataOrNull!.status, WaiterCallStatus.completed);
      expect(lastRequest.path, '/api/v1/waiter-calls/call-1/complete/');
    });

    test('an empty active list is a valid success', () async {
      final repo = ApiWaiterCallRepository(
          ApiClient(_FakeTokenStorage(), client: clientReturning(200, '[]')));
      final result = await repo.getActiveCalls();
      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, isEmpty);
    });

    test('Django 409 becomes AppFailure.conflict with the server message',
        () async {
      final repo = ApiWaiterCallRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(
              409,
              jsonEncode({
                'error': {
                  'code': 'conflict',
                  'message': 'این درخواست قبلاً انجام شده است.',
                }
              }))));

      final result = await repo.acknowledge('call-1');

      expect(result.failureOrNull!.type, FailureType.conflict);
      expect(result.failureOrNull!.userMessage, contains('قبلاً انجام شده'));
    });

    test('Django 401 becomes AppFailure.unauthorized', () async {
      final repo = ApiWaiterCallRepository(ApiClient(_FakeTokenStorage(),
          client: clientReturning(
              401,
              jsonEncode({
                'error': {'code': 'unauthorized'}
              }))));

      final result = await repo.complete('call-1');

      expect(result.failureOrNull!.type, FailureType.unauthorized);
    });
  });

  group('MockWaiterCallRepository mirrors waiter_calls/services.py', () {
    late MockDatabase db;
    late MockWaiterCallRepository repo;

    setUp(() {
      db = MockDatabase.seeded();
      repo = MockWaiterCallRepository(db);
    });

    test('getActiveCalls returns only active calls, newest first', () async {
      final calls = (await repo.getActiveCalls()).dataOrNull!;
      expect(calls, isNotEmpty);
      expect(calls.every((c) => c.isActive), isTrue);
      for (var i = 1; i < calls.length; i++) {
        expect(
            calls[i - 1].createdAt.isAfter(calls[i].createdAt) ||
                calls[i - 1].createdAt == calls[i].createdAt,
            isTrue);
      }
    });

    test('the seeded mock has three sample calls: two pending, one seen',
        () async {
      final calls = (await repo.getActiveCalls()).dataOrNull!;
      expect(calls.map((c) => c.tableId).toSet(), {2, 5, 7});
      expect(
        calls.where((c) => c.isPending).map((c) => c.tableId).toSet(),
        {2, 7},
      );
      expect(calls.where((c) => c.isAcknowledged).single.tableId, 5);
    });

    test('the seeded calls show up in the mock table overview', () async {
      final tables = MockTableRepository(db);
      final active = (await tables.getTables()).dataOrNull!;
      final withCall = active.where((o) => o.waiterCall != null).toList();

      expect(withCall.map((o) => o.table.number).toSet(), {2, 5, 7});
      expect(
          withCall.firstWhere((o) => o.table.number == 2).waiterCall!.isPending,
          isTrue);
      expect(
          withCall
              .firstWhere((o) => o.table.number == 5)
              .waiterCall!
              .isAcknowledged,
          isTrue);
    });

    test('a customer request while a call is active is not duplicated', () {
      final first = repo.requestCall(7);
      final second = repo.requestCall(7);
      expect(second.id, first.id);
      expect(db.waiterCalls.where((c) => c.tableId == 7 && c.isActive),
          hasLength(1));
    });

    test('acknowledge moves pending to acknowledged and stamps the time',
        () async {
      final call = repo.requestCall(4);
      expect(call.status, WaiterCallStatus.pending);

      final result = await repo.acknowledge(call.id);

      final updated = result.dataOrNull!;
      expect(updated.status, WaiterCallStatus.acknowledged);
      expect(updated.acknowledgedAt, isNotNull);
      expect(db.waiterCallById(call.id)!.status, WaiterCallStatus.acknowledged);
    });

    test('acknowledge on an already acknowledged call is idempotent', () async {
      final call = repo.requestCall(4);
      final first = (await repo.acknowledge(call.id)).dataOrNull!;

      final second = (await repo.acknowledge(call.id)).dataOrNull!;

      expect(second.status, first.status);
      expect(second.acknowledgedAt, first.acknowledgedAt);
    });

    test('acknowledge on a completed call is a conflict', () async {
      final call = repo.requestCall(4);
      await repo.complete(call.id);

      final result = await repo.acknowledge(call.id);

      expect(result.failureOrNull!.type, FailureType.conflict);
    });

    test('complete removes the call from the active list', () async {
      final call = repo.requestCall(4);
      expect(
          (await repo.getActiveCalls()).dataOrNull!.any((c) => c.id == call.id),
          isTrue);

      final result = await repo.complete(call.id);

      expect(result.dataOrNull!.status, WaiterCallStatus.completed);
      expect(result.dataOrNull!.completedAt, isNotNull);
      expect(
          (await repo.getActiveCalls()).dataOrNull!.any((c) => c.id == call.id),
          isFalse);
    });

    test('an unknown id is not found', () async {
      expect((await repo.acknowledge('nope')).failureOrNull!.type,
          FailureType.notFound);
      expect((await repo.complete('nope')).failureOrNull!.type,
          FailureType.notFound);
    });
  });

  group('app_providers honours AppConfig.useMock', () {
    Future<void> pumpApp(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const AppProviders(child: SizedBox()));
      await tester.pump();
    }

    testWidgets('the waiter call repository matches AppConfig.useMock',
        (tester) async {
      await pumpApp(tester);
      final ctx = tester.element(find.byType(SizedBox));
      final repo = Provider.of<WaiterCallRepository>(ctx, listen: false);

      if (AppConfig.useMock) {
        expect(repo, isA<MockWaiterCallRepository>());
      } else {
        expect(repo, isA<ApiWaiterCallRepository>());
      }
    });

    testWidgets('the waiter call provider is registered and reads that repo',
        (tester) async {
      await pumpApp(tester);
      final ctx = tester.element(find.byType(SizedBox));
      final provider = Provider.of<WaiterCallProvider>(ctx, listen: false);

      expect(provider.state.status.name, 'initial');
      expect(provider.calls, isEmpty);
      expect(provider.pendingCount, 0);
    });
  });
}
