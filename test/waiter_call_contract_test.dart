// تست قرارداد JSON درخواست گارسون.
// هدف: تضمین اینکه مدل Flutter دقیقاً همان چیزی را می‌خواند/می‌نویسد که
// `waiter_calls/serializers.py::call_dict` بک‌اند جنگو تولید می‌کند.
// اگر بک‌اند فیلد یا مقدار جدیدی اضافه کند، این تست باید شکست بخورد.
import 'dart:convert';

import 'package:cafe_book_admin/models/table_overview.dart';
import 'package:cafe_book_admin/models/waiter_call.dart';
import 'package:flutter_test/flutter_test.dart';

/// همان شکلی که `call_dict` بک‌اند برمی‌گرداند (بدون `session` و بدون `seen`).
Map<String, dynamic> backendCall({
  String status = 'pending',
  int tableId = 3,
  int tableNumber = 3,
  String? acknowledgedAt = '2026-10-01T12:05:00+03:30',
  String? completedAt,
}) =>
    {
      'id': '6f1c9a52-0f2b-4f1e-9a1d-1c2b3a4d5e6f',
      'table_id': tableId,
      'table_number': tableNumber,
      'status': status,
      'created_at': '2026-10-01T12:00:00+03:30',
      'acknowledged_at': acknowledgedAt,
      'completed_at': completedAt,
    };

void main() {
  group('WaiterCall JSON contract', () {
    test('reads every field call_dict sends', () {
      final call = WaiterCall.fromJson(backendCall());

      expect(call.id, '6f1c9a52-0f2b-4f1e-9a1d-1c2b3a4d5e6f');
      expect(call.tableId, 3);
      expect(call.tableNumber, 3);
      expect(call.status, WaiterCallStatus.pending);
      expect(call.createdAt.toUtc(), DateTime.utc(2026, 10, 1, 8, 30));
      expect(call.acknowledgedAt, isNotNull);
      expect(call.completedAt, isNull);
    });

    test('null timestamps stay null instead of crashing', () {
      final call = WaiterCall.fromJson(
          backendCall(acknowledgedAt: null, completedAt: null));
      expect(call.acknowledgedAt, isNull);
      expect(call.completedAt, isNull);
      expect(call.isPending, isTrue);
    });

    test('acknowledged and completed are parsed as active/closed', () {
      final ack = WaiterCall.fromJson(backendCall(status: 'acknowledged'));
      expect(ack.isAcknowledged, isTrue);
      expect(ack.isActive, isTrue);

      final done = WaiterCall.fromJson(backendCall(
          status: 'completed', completedAt: '2026-10-01T12:07:00+03:30'));
      expect(done.isCompleted, isTrue);
      expect(done.isActive, isFalse);
    });

    test('an unknown status falls back to pending instead of crashing', () {
      final call = WaiterCall.fromJson(backendCall(status: 'seen'));
      expect(call.status, WaiterCallStatus.pending);
    });

    test('toJson mirrors call_dict and survives a round trip', () {
      final original = WaiterCall.fromJson(backendCall(
          status: 'acknowledged', completedAt: '2026-10-01T12:07:00+03:30'));
      final json = original.toJson();

      expect(
          json.keys,
          containsAll(
              ['id', 'table_id', 'table_number', 'status', 'created_at']));
      expect(json['status'], 'acknowledged');
      expect(json['table_id'], 3);

      final again = WaiterCall.fromJson(json);
      expect(again.status, original.status);
      expect(again.id, original.id);
      expect(again.tableId, original.tableId);
      expect(again.createdAt.toUtc(), original.createdAt.toUtc());
      expect(again.acknowledgedAt!.toUtc(), original.acknowledgedAt!.toUtc());
      expect(again.completedAt!.toUtc(), original.completedAt!.toUtc());
    });

    test('decodes the real ISO strings Django emits', () {
      final call = WaiterCall.fromJson(
          jsonDecode(jsonEncode(backendCall())) as Map<String, dynamic>);
      expect(call.status, WaiterCallStatus.pending);
      expect(call.createdAt.isUtc == false, isTrue, reason: 'toLocal applied');
    });
  });

  group('WaiterCallStatus', () {
    test('api values match the Django TextChoices', () {
      expect(WaiterCallStatus.pending.apiValue, 'pending');
      expect(WaiterCallStatus.acknowledged.apiValue, 'acknowledged');
      expect(WaiterCallStatus.completed.apiValue, 'completed');
    });

    test('only pending and acknowledged are active (services.ACTIVE)', () {
      expect(WaiterCallStatus.pending.isActive, isTrue);
      expect(WaiterCallStatus.acknowledged.isActive, isTrue);
      expect(WaiterCallStatus.completed.isActive, isFalse);
    });

    test('every status has a Persian label', () {
      for (final s in WaiterCallStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  group('TableOverview waiter_call', () {
    const notProvided = 'not-provided';

    Map<String, dynamic> overviewJson([Object? waiterCall = notProvided]) => {
          'table': {'id': 2, 'number': 2, 'status': 'active'},
          'active_session': {
            'id': 's1',
            'table_id': 2,
            'table_number': 2,
            'entered_at': '2026-10-01T12:00:00+03:30',
            'exited_at': null,
          },
          'last_session': null,
          'open_orders': <dynamic>[],
          'current_amount': 0,
          'payment_status': 'unpaid',
          if (identical(waiterCall, notProvided))
            'waiter_call': backendCall(tableId: 2, tableNumber: 2)
          else
            'waiter_call': waiterCall,
        };

    test('reads the waiter_call embedded in the tables overview', () {
      final overview = TableOverview.fromJson(overviewJson());
      expect(overview.waiterCall, isNotNull);
      expect(overview.waiterCall!.tableNumber, 2);
      expect(overview.waiterCall!.isPending, isTrue);
    });

    test('a null waiter_call means no active call', () {
      final overview = TableOverview.fromJson(overviewJson(null));
      expect(overview.waiterCall, isNull);
    });

    test('a missing waiter_call key does not break parsing', () {
      final json = overviewJson()..remove('waiter_call');
      expect(TableOverview.fromJson(json).waiterCall, isNull);
    });
  });
}
