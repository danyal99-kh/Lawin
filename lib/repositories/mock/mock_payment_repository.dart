// lib/repositories/mock/mock_payment_repository.dart
import '../../core/errors/app_failure.dart';
import '../../core/errors/result.dart';
import '../../models/enums.dart';
import '../../models/table_overview.dart';
import '../payment_repository.dart';
import 'mock_database.dart';
import 'mock_session_engine.dart';
import 'mock_table_repository.dart';

/// پرداخت صورتحساب میز: همه‌ی سفارش‌های باز نشست را پرداخت‌شده می‌کند و طبق
/// قانون ۲ (MockSessionEngine) نشست را می‌بندد. وقتی Django آماده شد، این
/// منطق در یک تراکنش سمت Backend اجرا می‌شود و این کلاس حذف می‌شود.
class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository(this._db, this._tables)
      : _sessions = MockSessionEngine(_db);

  final MockDatabase _db;
  final MockTableRepository _tables;
  final MockSessionEngine _sessions;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<Result<TableOverview>> pay(int tableId,
      {required PaymentMethod method}) async {
    try {
      await _latency();
      final tableIndex = _db.tables.indexWhere((t) => t.id == tableId);
      if (tableIndex == -1) return Failure(AppFailure.notFound());

      final openOrders = _db.orders
          .where((o) => o.tableId == tableId && o.status.isOpen)
          .toList();
      if (openOrders.isEmpty) {
        return Failure(
            AppFailure.conflict('سفارش بازی برای پرداخت وجود ندارد.'));
      }

      final now = DateTime.now();
      // قانون ۲: پرداخت صورتحساب، نشست را می‌بندد و میز را آزاد می‌کند.
      final closedSession = _sessions.close(tableId, now);
      if (closedSession == null) {
        return Failure(AppFailure.conflict('نشست بازی برای این میز پیدا نشد.'));
      }

      for (final order in openOrders) {
        final index = _db.orders.indexWhere((o) => o.id == order.id);
        if (index == -1) continue;
        _db.orders[index] = order.copyWith(
          status: OrderStatus.paid,
          paymentStatus: PaymentStatus.paid,
          paymentMethod: method,
          paidAt: now,
        );
      }

      return Success(_tables.overviewFor(_db.tables[tableIndex]));
    } catch (e) {
      return Failure(AppFailure.paymentFailed());
    }
  }
}
