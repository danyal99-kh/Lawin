// تست اتصال رویدادهای واقعی بک‌اند به Provider گارسون.
// نام رویدادها دقیقاً همان `Lawin_User/core/events.py` است و payload هم
// همان `{"call": {...}}` است که `waiter_calls/services.py` می‌فرستد.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/models/waiter_call.dart';
import 'package:cafe_book_admin/providers/dashboard_provider.dart';
import 'package:cafe_book_admin/providers/incoming_orders_provider.dart';
import 'package:cafe_book_admin/providers/order_provider.dart';
import 'package:cafe_book_admin/providers/table_provider.dart';
import 'package:cafe_book_admin/providers/waiter_call_provider.dart';
import 'package:cafe_book_admin/repositories/mock/mock_database.dart';
import 'package:cafe_book_admin/repositories/mock/mock_dashboard_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_order_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_payment_repository.dart';
import 'package:cafe_book_admin/repositories/mock/mock_table_repository.dart';
import 'package:cafe_book_admin/repositories/waiter_call_repository.dart';
import 'package:cafe_book_admin/services/realtime_service.dart';
import 'package:cafe_book_admin/services/waiter_alert_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> callPayload({
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

class _EmptyWaiterRepository implements WaiterCallRepository {
  @override
  Future<Result<List<WaiterCall>>> getActiveCalls() async => Success([]);
  @override
  Future<Result<WaiterCall>> acknowledge(String id) async =>
      Failure(AppFailure.notFound());
  @override
  Future<Result<WaiterCall>> complete(String id) async =>
      Failure(AppFailure.notFound());
}

class _CountingAlerter implements WaiterAlerter {
  int plays = 0;
  @override
  Future<void> play() async => plays++;
}

void main() {
  late WaiterCallProvider waiterCalls;
  late RealtimeSync sync;

  setUp(() {
    final db = MockDatabase.seeded();
    final tables = MockTableRepository(db);
    waiterCalls = WaiterCallProvider(_EmptyWaiterRepository(),
        alerter: _CountingAlerter());
    sync = RealtimeSync(
      // سرویس ساخته می‌شود ولی start() صدا زده نمی‌شود؛ فقط مسیر رویداد تست می‌شود.
      service: RealtimeService(() async => null),
      orders: OrderProvider(MockOrderRepository(db)),
      tables: TableProvider(tables, MockPaymentRepository(db, tables)),
      dashboard: DashboardProvider(MockDashboardRepository(db)),
      waiterCalls: waiterCalls,
    );
  });

  test('waiter_call_created is applied to the waiter provider', () {
    sync.handleEvent(
        RealtimeEvent('waiter_call_created', {'call': callPayload()}));

    expect(waiterCalls.calls, hasLength(1));
    expect(waiterCalls.calls.single.isPending, isTrue);
    expect(waiterCalls.callForTable(2), isNotNull);
    expect(waiterCalls.pendingCount, 1);
  });

  test('waiter_call_acknowledged keeps one row and stops the alert loop', () {
    sync.handleEvent(
        RealtimeEvent('waiter_call_created', {'call': callPayload()}));
    sync.handleEvent(RealtimeEvent('waiter_call_acknowledged',
        {'call': callPayload(status: 'acknowledged')}));

    expect(waiterCalls.calls, hasLength(1), reason: 'dedup بر اساس id');
    expect(waiterCalls.calls.single.isAcknowledged, isTrue);
    expect(waiterCalls.hasPending, isFalse);
  });

  test('waiter_call_completed removes the call', () {
    sync.handleEvent(
        RealtimeEvent('waiter_call_created', {'call': callPayload()}));
    sync.handleEvent(RealtimeEvent(
        'waiter_call_completed', {'call': callPayload(status: 'completed')}));

    expect(waiterCalls.calls, isEmpty);
  });

  test('the same event twice does not duplicate the call', () {
    final event = RealtimeEvent('waiter_call_created', {'call': callPayload()});
    sync.handleEvent(event);
    sync.handleEvent(event);

    expect(waiterCalls.calls, hasLength(1));
  });

  test('an event without a call payload is ignored', () {
    sync.handleEvent(const RealtimeEvent('waiter_call_created', {}));

    expect(waiterCalls.calls, isEmpty);
  });
}
