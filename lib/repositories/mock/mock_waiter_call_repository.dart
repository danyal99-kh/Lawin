import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/waiter_call.dart';
import '../waiter_call_repository.dart';
import 'mock_database.dart';

/// قوانین این کلاس همان قوانین `waiter_calls/services.py` است:
/// فقط `pending → acknowledged` و هر وضعیت فعال → `completed`؛ تکراری ساخته نمی‌شود.
class MockWaiterCallRepository implements WaiterCallRepository {
  MockWaiterCallRepository(this._db);

  final MockDatabase _db;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  @override
  Future<Result<List<WaiterCall>>> getActiveCalls() async {
    try {
      await _latency();
      final list = _db.waiterCalls.where((c) => c.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<WaiterCall>> acknowledge(String callId) async {
    try {
      await _latency();
      final call = _db.waiterCallById(callId);
      if (call == null) return Failure(AppFailure.notFound());
      if (call.isAcknowledged) return Success(call);
      if (!call.isPending) {
        return Failure(AppFailure.conflict('این درخواست قبلاً انجام شده است.'));
      }
      final updated = call.copyWith(
        status: WaiterCallStatus.acknowledged,
        acknowledgedAt: DateTime.now(),
      );
      _db.replaceWaiterCall(updated);
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  @override
  Future<Result<WaiterCall>> complete(String callId) async {
    try {
      await _latency();
      final call = _db.waiterCallById(callId);
      if (call == null) return Failure(AppFailure.notFound());
      if (call.isCompleted) return Success(call);
      final updated = call.copyWith(
        status: WaiterCallStatus.completed,
        completedAt: DateTime.now(),
      );
      _db.replaceWaiterCall(updated);
      return Success(updated);
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  /// فقط برای دمو/تست: ثبت درخواست از سمت مشتریِ میز.
  WaiterCall requestCall(int tableId) => _db.requestWaiterCall(tableId).$1;
}
