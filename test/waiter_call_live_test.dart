// تست سرتاسری واقعی درخواست گارسون:
// ApiWaiterCallRepository → ApiClient → Django → دیتابیس.
// نیازمند اجرای Django روی 127.0.0.1:8000 و توکن معتبر در LAWIN_TEST_TOKEN.
//
//   cd Lawin_User && DJANGO_DEBUG=1 python manage.py runserver 127.0.0.1:8000 --noreload
//   flutter test test/waiter_call_live_test.dart --dart-define=LAWIN_TEST_TOKEN=<token>
//
// بدون توکن، تست‌ها skip می‌شوند. این تست هیچ درخواستی «می‌سازد»؛ فقط
// endpointهای خواندنی را صدا می‌زند تا داده‌ی واقعی کسی تغییر نکند.
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/api_endpoints.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/waiter_call.dart';
import 'package:cafe_book_admin/repositories/api/api_table_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_waiter_call_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _token = String.fromEnvironment('LAWIN_TEST_TOKEN');

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
  if (_token.isEmpty) {
    test('skipped: set LAWIN_TEST_TOKEN', () {});
    return;
  }

  late ApiWaiterCallRepository repo;

  setUp(() {
    repo = ApiWaiterCallRepository(ApiClient(_StaticTokenStorage(_token)));
  });

  test('GET waiter-calls/?active=1 succeeds and parses', () async {
    final result = await repo.getActiveCalls();
    expect(result.failureOrNull, isNull, reason: '${result.failureOrNull}');
    expect(result.dataOrNull, isA<List<WaiterCall>>());
  });

  test('the server only sends active calls', () async {
    final calls = (await repo.getActiveCalls()).dataOrNull!;
    expect(calls.every((c) => c.isActive), isTrue,
        reason: 'pending + acknowledged فقط');
  });

  test('every field of call_dict is parsed (uuid id, table number, timestamps)',
      () async {
    final calls = (await repo.getActiveCalls()).dataOrNull!;
    for (final c in calls) {
      expect(c.id, isNotEmpty);
      expect(Uri.parse(c.id).path, isNotEmpty);
      expect(c.tableId, greaterThan(0));
      expect(c.tableNumber, greaterThan(0));
      expect(c.createdAt, isNotNull);
    }
  });

  test('endpoints match the Django routes', () {
    expect(ApiEndpoints.waiterCalls, '/api/v1/waiter-calls/');
    expect(
        ApiEndpoints.waiterAck('abc'), '/api/v1/waiter-calls/abc/acknowledge/');
    expect(ApiEndpoints.waiterComplete('abc'),
        '/api/v1/waiter-calls/abc/complete/');
  });

  test('a non-existent id is a not-found failure', () async {
    final result =
        await repo.acknowledge('00000000-0000-0000-0000-000000000000');
    expect(result.failureOrNull, isNotNull);
  });

  test('the table overview carries waiter_call when a call is active',
      () async {
    final tables =
        await ApiTableRepository(ApiClient(_StaticTokenStorage(_token)))
            .getTables();
    expect(tables.failureOrNull, isNull, reason: '${tables.failureOrNull}');
    for (final overview in tables.dataOrNull!) {
      final call = overview.waiterCall;
      if (call != null) {
        expect(call.isActive, isTrue);
        expect(call.tableId, overview.table.id);
      }
    }
  });
}
