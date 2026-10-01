// تست منطق Provider درخواست گارسون:
//  - بارگذاری اولیه و نگه‌داشتن داده‌ی قبلی هنگام خطا
//  - dedup بر اساس id و حذف شدن درخواست completed
//  - هشدار صوتی: یادآوری هر ۳۰ ثانیه برای pending، توقف بعد از acknowledge
//  - توقف تایمر و listenerها در dispose
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/utils/view_state.dart';
import 'package:cafe_book_admin/models/waiter_call.dart';
import 'package:cafe_book_admin/providers/waiter_call_provider.dart';
import 'package:cafe_book_admin/repositories/waiter_call_repository.dart';
import 'package:cafe_book_admin/services/waiter_alert_service.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

WaiterCall call({
  String id = 'call-1',
  int tableId = 2,
  WaiterCallStatus status = WaiterCallStatus.pending,
  DateTime? createdAt,
}) =>
    WaiterCall(
      id: id,
      tableId: tableId,
      tableNumber: tableId,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 10, 1, 12),
    );

/// Repository ساختگی که پاسخ‌ها از تست کنترل می‌شود.
class _FakeRepository implements WaiterCallRepository {
  _FakeRepository([List<WaiterCall>? initial]) : stored = [...?initial];

  List<WaiterCall> stored;
  AppFailure? activeError;
  AppFailure? actionError;
  int loadCalls = 0;
  final List<String> actions = [];

  @override
  Future<Result<List<WaiterCall>>> getActiveCalls() async {
    loadCalls++;
    if (activeError != null) return Failure(activeError!);
    return Success([
      for (final c in stored)
        if (c.isActive) c
    ]);
  }

  @override
  Future<Result<WaiterCall>> acknowledge(String callId) async {
    actions.add('ack:$callId');
    if (actionError != null) return Failure(actionError!);
    final c = stored.firstWhere((e) => e.id == callId);
    final updated = c.copyWith(status: WaiterCallStatus.acknowledged);
    stored = [
      for (final e in stored)
        if (e.id == callId) updated else e,
    ];
    return Success(updated);
  }

  @override
  Future<Result<WaiterCall>> complete(String callId) async {
    actions.add('complete:$callId');
    if (actionError != null) return Failure(actionError!);
    final c = stored.firstWhere((e) => e.id == callId);
    final updated = c.copyWith(status: WaiterCallStatus.completed);
    stored = [
      for (final e in stored)
        if (e.id == callId) updated else e,
    ];
    return Success(updated);
  }
}

/// شمارنده‌ی صدا تا بشود دقیقاً بررسی کرد چند بار پخش شده.
class _FakeAlerter implements WaiterAlerter {
  int plays = 0;
  @override
  Future<void> play() async => plays++;
}

void main() {
  group('load', () {
    test('loads active calls and exposes per-table helpers', () async {
      final repo = _FakeRepository([
        call(id: 'a', tableId: 2),
        call(id: 'b', tableId: 5, status: WaiterCallStatus.acknowledged),
      ]);
      final provider = WaiterCallProvider(repo, alerter: _FakeAlerter());

      await provider.load();

      expect(provider.state.status, ViewStatus.success);
      expect(provider.calls, hasLength(2));
      expect(provider.pendingCount, 1);
      expect(provider.pending.single.id, 'a');
      expect(provider.acknowledged.single.id, 'b');
      expect(provider.callForTable(2)!.id, 'a');
      expect(provider.callForTable(5)!.id, 'b');
      expect(provider.callForTable(9), isNull);
      expect(provider.hasPending, isTrue);
    });

    test('keeps previous calls when a reload fails', () async {
      final repo = _FakeRepository([call()]);
      final provider = WaiterCallProvider(repo, alerter: _FakeAlerter());
      await provider.load();

      repo.activeError = AppFailure.network();
      await provider.load();

      expect(provider.state.status, ViewStatus.error);
      expect(provider.state.failure!.type, FailureType.network);
      expect(provider.calls, hasLength(1), reason: 'داده‌ی قبلی از بین نرود');
    });
  });

  group('realtime events (dedup)', () {
    test('the same call twice is stored once', () {
      final provider =
          WaiterCallProvider(_FakeRepository(), alerter: _FakeAlerter());

      provider.applyCall(call());
      provider.applyCall(call());

      expect(provider.calls, hasLength(1));
    });

    test('acknowledged is upserted, not duplicated', () {
      final provider =
          WaiterCallProvider(_FakeRepository(), alerter: _FakeAlerter());

      provider.applyCall(call());
      provider.applyCall(call(status: WaiterCallStatus.acknowledged));

      expect(provider.calls, hasLength(1));
      expect(provider.calls.single.isAcknowledged, isTrue);
      expect(provider.hasPending, isFalse);
    });

    test('completed removes the call from the active list', () {
      final provider =
          WaiterCallProvider(_FakeRepository(), alerter: _FakeAlerter());
      provider.applyCall(call());

      provider.applyCall(call(status: WaiterCallStatus.completed));

      expect(provider.calls, isEmpty);
    });

    test('listeners are notified', () {
      final provider =
          WaiterCallProvider(_FakeRepository(), alerter: _FakeAlerter());
      var notified = 0;
      provider.addListener(() => notified++);

      provider.applyCall(call());

      expect(notified, 1);
    });
  });

  group('reminder sound', () {
    test('reminds every 30 seconds while a call is pending', () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider =
            WaiterCallProvider(_FakeRepository([call()]), alerter: alerter);

        async.elapse(const Duration(seconds: 1));
        expect(alerter.plays, 0, reason: 'بارگذاری اولیه صدا نمی‌زند');

        provider.applyCall(call(id: 'b', tableId: 3));
        expect(alerter.plays, 1, reason: 'درخواست تازه بلافاصله هشدار می‌دهد');

        async.elapse(const Duration(seconds: 29));
        expect(alerter.plays, 1);
        async.elapse(const Duration(seconds: 1));
        expect(alerter.plays, 2, reason: 'بعد از ۳۰ ثانیه یادآوری دوم');
        async.elapse(const Duration(seconds: 30));
        expect(alerter.plays, 3);
      });
    });

    test('an acknowledged call stops the reminder', () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider =
            WaiterCallProvider(_FakeRepository([call()]), alerter: alerter);
        provider.applyCall(call());

        async.elapse(const Duration(seconds: 31));
        final playsBeforeAck = alerter.plays;
        expect(playsBeforeAck, greaterThan(0));

        // رویداد واقعی waiter_call_acknowledged از WebSocket
        provider.applyCall(call(status: WaiterCallStatus.acknowledged));
        expect(provider.hasPending, isFalse);

        async.elapse(const Duration(seconds: 120));
        expect(alerter.plays, playsBeforeAck,
            reason: 'بعد از «دیدم» دیگر صدا نباید بخورد');
      });
    });

    test('an acknowledged-only list never rings', () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider = WaiterCallProvider(
          _FakeRepository(),
          alerter: alerter,
        );
        provider.applyCall(call(status: WaiterCallStatus.acknowledged));

        async.elapse(const Duration(minutes: 5));

        expect(alerter.plays, isZero);
      });
    });

    test('completing the last pending call stops the reminder', () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider =
            WaiterCallProvider(_FakeRepository([call()]), alerter: alerter);
        provider.applyCall(call());

        async.elapse(const Duration(seconds: 30));
        final before = alerter.plays;

        // رویداد واقعی waiter_call_completed از WebSocket
        provider.applyCall(call(status: WaiterCallStatus.completed));
        expect(provider.calls, isEmpty);

        async.elapse(const Duration(minutes: 3));
        expect(alerter.plays, before);
      });
    });

    test('dispose cancels the timer: no sound after the provider is gone', () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider =
            WaiterCallProvider(_FakeRepository(), alerter: alerter);
        provider.applyCall(call());

        async.elapse(const Duration(seconds: 31));
        final before = alerter.plays;
        expect(before, 2, reason: 'یک‌بار هنگام ورود، یک‌بار بعد از ۳۰ ثانیه');

        provider.dispose();

        async.elapse(const Duration(minutes: 5));
        expect(alerter.plays, before, reason: 'تایمر باید لغو شده باشد');
      });
    });

    test('a duplicate event does not create a second timer or a second sound',
        () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider =
            WaiterCallProvider(_FakeRepository(), alerter: alerter);

        final event = call(id: 'a', tableId: 2);
        provider.applyCall(event);
        provider.applyCall(event);
        provider.applyCall(event);

        expect(alerter.plays, 1, reason: 'فقط یک‌بار برای ورود درخواست تازه');

        async.elapse(const Duration(seconds: 30));
        expect(alerter.plays, 2, reason: 'یک تایمر یادآوری، نه چند تایمر');
        async.elapse(const Duration(seconds: 60));
        expect(alerter.plays, 4);
      });
    });

    test('startup: pending calls already on the server get a reminder', () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider = WaiterCallProvider(
          _FakeRepository([
            call(id: 'a', tableId: 2),
            call(id: 'b', tableId: 5, status: WaiterCallStatus.acknowledged),
          ]),
          alerter: alerter,
        );

        provider.load();
        async.flushMicrotasks();

        expect(provider.pendingCount, 1,
            reason: 'فقط pending وارد سیستم هشدار می‌شود');
        expect(provider.calls, hasLength(2));

        async.elapse(const Duration(seconds: 29));
        expect(alerter.plays, 0, reason: 'در startup صدا فوری پخش نمی‌شود');
        async.elapse(const Duration(seconds: 1));
        expect(alerter.plays, 1, reason: 'بعد از ۳۰ ثانیه یادآوری');
        async.elapse(const Duration(seconds: 30));
        expect(alerter.plays, 2);
      });
    });

    test('startup with only acknowledged calls never rings', () {
      fakeAsync((async) {
        final alerter = _FakeAlerter();
        final provider = WaiterCallProvider(
          _FakeRepository([call(status: WaiterCallStatus.acknowledged)]),
          alerter: alerter,
        );

        provider.load();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 10));

        expect(alerter.plays, isZero);
      });
    });

    test('a failing alert never breaks the provider', () {
      fakeAsync((async) {
        final provider = WaiterCallProvider(
          _FakeRepository([call()]),
          alerter: _ThrowingAlerter(),
        );

        provider.applyCall(call(id: 'b', tableId: 3));

        async.elapse(const Duration(seconds: 30));
        expect(provider.hasPending, isTrue);
      });
    });
  });

  group('actions', () {
    test('acknowledge calls the repository and updates the state', () async {
      final repo = _FakeRepository([call()]);
      final provider = WaiterCallProvider(repo, alerter: _FakeAlerter());
      await provider.load();

      final failure = await provider.acknowledge('call-1');

      expect(failure, isNull);
      expect(repo.actions, ['ack:call-1']);
      expect(provider.calls.single.isAcknowledged, isTrue);
      expect(provider.hasPending, isFalse);
      expect(provider.busy, isFalse);
    });

    test('an acknowledged call is completed and leaves the list', () async {
      final repo =
          _FakeRepository([call(status: WaiterCallStatus.acknowledged)]);
      final provider = WaiterCallProvider(repo, alerter: _FakeAlerter());
      await provider.load();
      expect(provider.acknowledged.single.id, 'call-1');

      final failure = await provider.complete('call-1');

      expect(failure, isNull);
      expect(repo.actions, ['complete:call-1']);
      expect(provider.calls, isEmpty);
    });

    test('complete removes the call and a failure is returned', () async {
      final repo = _FakeRepository([call()]);
      final provider = WaiterCallProvider(repo, alerter: _FakeAlerter());
      await provider.load();

      repo.actionError =
          AppFailure.conflict('این درخواست قبلاً انجام شده است.');
      final failure = await provider.complete('call-1');

      expect(failure!.type, FailureType.conflict);
      expect(provider.calls, hasLength(1),
          reason: 'در صورت خطا وضعیت عوض نشود');
      expect(provider.isBusy('call-1'), isFalse);
    });

    test('a double tap does not send the request twice', () async {
      final repo = _FakeRepository([call()]);
      final provider = WaiterCallProvider(repo, alerter: _FakeAlerter());
      await provider.load();

      await Future.wait([
        provider.acknowledge('call-1'),
        provider.acknowledge('call-1'),
      ]);

      expect(repo.actions, hasLength(1));
    });
  });
}

class _ThrowingAlerter implements WaiterAlerter {
  @override
  Future<void> play() => Future<void>.error(StateError('no sound'));
}
